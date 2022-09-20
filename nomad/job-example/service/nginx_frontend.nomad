job "nginx-frontend" {
  datacenters = ["dc1"]

  group "nginx" {
    count = 1

    network {
      port "http" {
        static = 8080
      }
    }

    service {
      name = "nginx-frontend"
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

      template {
        data = <<EOF
upstream backend {
{{ range nomadService "nginx-backend" }}
  server {{ .Address }}:{{ .Port }}; # Tomcat
{{ else }}server 127.0.0.1:65535; # force a 502
{{ end }}
}

server {
   listen {{ env "NOMAD_PORT_http" }};

   location / {
      proxy_pass http://backend;
   }

   location /status {
       stub_status on;
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