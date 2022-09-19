job "nginx_backend" {
  datacenters = ["dc1"]

  spread {
    attribute = "${node.datacenter}"
  }

  group "nginx-prod" {
    count = 3

    scaling {
      enabled = true
      min = 0
      max = 3
    }

    network {
      port "http" {
        to = 80
        static = 18080
      }
    }

    service {
      name = "nginx-backend"
      port = "http"
      tags = ["prod"]
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx"
        ports = ["http"]
        volumes = [
          "local/html:/usr/share/nginx/html",
        ]
      }

      template {
        data = <<EOF
        <h1>Welcome to {{ env "NOMAD_JOB_NAME" }} Production {{ env "NOMAD_HOST_PORT_http" }}</h1>
        node_dc:       {{ env "node.datacenter" }}<br>
        node_hostname: {{ env "attr.unique.hostname" }}<br>
        node_cores:    {{ env "attr.cpu.numcores" }}<br>
        os_name:       {{ env "attr.os.name" }}<br>
        cpu_model:     {{ env "attr.cpu.modelname" }}<br>
        EOF
        destination = "local/html/index.html"
      }
    }
  }

  group "nginx-stage" {
    count = 1

    scaling {
      enabled = true
      min = 0
      max = 1
    }


    network {
      port "http" {
        to = 80
        static = 28080
      }
    }

    service {
      name = "nginx-backend"
      port = "http"
      tags = ["stage"]
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx"
        ports = ["http"]
        volumes = [
          "local/html:/usr/share/nginx/html",
        ]
      }

      template {
        data = <<EOF
        <h1>Welcome to {{ env "NOMAD_JOB_NAME" }} Stage {{ env "NOMAD_HOST_PORT_http" }}</h1>
        node_dc:       {{ env "node.datacenter" }}<br>
        node_hostname: {{ env "attr.unique.hostname" }}<br>
        node_cores:    {{ env "attr.cpu.numcores" }}<br>
        os_name:       {{ env "attr.os.name" }}<br>
        cpu_model:     {{ env "attr.cpu.modelname" }}<br>
        EOF
        destination = "local/html/index.html"
      }
    }
  }
}