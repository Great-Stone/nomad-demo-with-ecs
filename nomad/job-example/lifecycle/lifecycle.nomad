job "lifecycle" {
  datacenters = ["dc1"]

  type = "service"

  group "lifecycle" {
    count = 1

    network {
      port "http" {
        to = 80
        static = 18080
      }
      port "nc" {}
    }

    service {
      name = "nginx-frontend"
      port = "http"
      provider = "nomad"
    }

    task "create_page" {
      driver = "exec"

      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      config {
        command = "cat"
        args = ["${NOMAD_ALLOC_DIR}/html/index.html"]
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
        destination = "${NOMAD_ALLOC_DIR}/html/index.html"
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx"
        ports = ["http"]
        mounts = [{
          type     = "bind"
          source   = "../alloc/html"
          target   = "/usr/share/nginx/html"
          readonly = false
          bind_options = {
            propagation = "rshared"
          }
        }]
      }
    }

    task "add_content" {
      driver = "raw_exec"

      lifecycle {
        hook = "poststart"
        sidecar = false
      }

      config {
        command = "local/start.sh"
      }

      template {
        data = <<EOF
#!/bin/bash
sudo echo "<br><br>Hello Nomad!!" >> {{ env "NOMAD_ALLOC_DIR" }}/html/index.html
        EOF
        destination = "local/start.sh"
      }
    }

    task "echo" {
      driver = "raw_exec"

      lifecycle {
        hook = "poststart"
        sidecar = true
      }

      config {
        command = "local/start.sh"
      }

      template {
        data = <<EOF
#!/bin/bash
while true; do 
  echo -e "HTTP/1.1 200 OK\n\n $(date)" | nc -l -p {{ env "NOMAD_PORT_nc" }} -q 1
done
        EOF
        destination = "local/start.sh"
      }
    }

    task "poststop" {
      driver = "exec"

      lifecycle {
        hook = "poststop"
        sidecar = true
      }

      config {
        command = "date"
      }
    }
  }
}