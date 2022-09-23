job "example" {
  datacenters = ["dc1"]

  group "cache-lb" {
    count = 1

    network {
      port "lb" {}
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx"
        ports = ["lb"]
        volumes = [
          # It's safe to mount this path as a file because it won't re-render.
          "local/nginx.conf:/etc/nginx/nginx.conf",
          # This path hosts files that will re-render with Consul Template.
          "local/nginx:/etc/nginx/conf.d"
        ]
      }

      # This template overwrites the embedded nginx.conf file so it loads
      # conf.d/*.conf files outside of the `http` block.
      template {
        data        = <<EOF
user  nginx;
worker_processes  1;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
include /etc/nginx/conf.d/*.conf;
EOF
        destination = "local/nginx.conf"
      }

      # This template creates a TCP proxy to Redis.
      template {
        data          = <<EOF
stream {
  server {
    listen {{ env "NOMAD_PORT_lb" }};
    proxy_pass backend;
  }
  upstream backend {
  {{ range nomadService "redis" }}
    server {{ .Address }}:{{ .Port }};
  {{ else }}server 127.0.0.1:65535; # force a 502
  {{ end }}
  }
}
EOF
        destination   = "local/nginx/nginx.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      resources {
        cpu    = 50
        memory = 10
      }

      scaling "cpu" {
        policy {
          cooldown            = "1m"
          evaluation_interval = "10s"

          check "95pct" {
            strategy "app-sizing-percentile" {
              percentile = "95"
            }
          }
        }
      }

      scaling "mem" {
        policy {
          cooldown            = "1m"
          evaluation_interval = "10s"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }
    }

    service {
      name         = "redis-lb"
      port         = "lb"
      address_mode = "host"
      provider     = "nomad"
    }
  }

  group "cache" {
    count = 3

    network {
      port "db" {
        to = 6379
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:6.0"
        ports = ["db"]
      }

      resources {
        cpu    = 500
        memory = 256
      }

      scaling "cpu" {
        policy {
          cooldown            = "1m"
          evaluation_interval = "10s"

          check "95pct" {
            strategy "app-sizing-percentile" {
              percentile = "95"
            }
          }
        }
      }

      scaling "mem" {
        policy {
          cooldown            = "1m"
          evaluation_interval = "10s"

          check "max" {
            strategy "app-sizing-max" {}
          }
        }
      }

      service {
        name         = "redis"
        port         = "db"
        address_mode = "host"
        provider     = "nomad"
      }
    }
  }
}