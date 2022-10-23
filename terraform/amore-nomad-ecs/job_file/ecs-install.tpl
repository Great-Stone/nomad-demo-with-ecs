job "install_ecs_plugin" {
  datacenters = ["dc1"]
  
  type        = "sysbatch"
  
  group "install" {
    task "ecs-plugin" {
      driver = "raw_exec"
      template {
        data = <<EOF
#!/bin/bash
sudo cat <<EOCONFIG >> /etc/nomad.d/nomad.hcl
plugin "nomad-driver-ecs" {
  config {
    enabled = true
    cluster = "${cluster_name}"
    region  = "${region_name}"
  }
}
EOCONFIG
sudo systemctl restart nomad
EOF
        destination = "ecs_install.sh"
      }
      config {
        command = "ecs_install.sh"
      }
      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
