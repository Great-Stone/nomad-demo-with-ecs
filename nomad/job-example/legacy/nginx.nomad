job "nginx" {
  datacenters = ["dc1"]

  group "nginx" {
    count = 1

    network {
      port "http" {
        static = 28080
      }
    }

    service {
      name = "nginx"
      port = "http"
      provider = "nomad"
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx"
        ports = ["http"]
        volumes = [
          "local:/etc/nginx/conf.d",
        ]
      }

      artifact {
        source = "https://img.icons8.com/color/2x/nginx.png"
        destination = "local/upload"
      }

      template {
        data = <<EOF
upstream backend {
  {{ range nomadService "legacy-tomcat" }}
    server {{ .Address }}:{{ .Port }}; # Tomcat
  {{ end }}
}

server {
  listen {{ env "NOMAD_PORT_http" }};

  location /sample {
    proxy_pass http://backend;
  }

  location /status {
    stub_status on;
  }

  location /upload/ {
    autoindex on;
    root {{ env "NOMAD_TASK_DIR" }};
  }

  access_log off;
  # allow 127.0.0.1;
  allow all;
  deny all;

  location /nginx_status {
  # Choose your status module

  # freely available with open source NGINX
  stub_status;

  # for open source NGINX < version 1.7.5
  # stub_status on;

  # available only with NGINX Plus
  # status;

  # ensures the version information can be retrieved
  server_tokens on;
  }
}
EOF

        destination   = "local/load-balancer.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }
}