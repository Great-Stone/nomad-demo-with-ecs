job "install_docker" {
  datacenters = ["dc1"]
  
  type        = "sysbatch"

  // periodic {
  //   cron             = "*/5 * * * * * *"
  //   prohibit_overlap = true
  //   time_zone        = "Asia/Seoul"
  // }

  constraint {
    attribute = "${attr.os.name}"
    value     = "ubuntu"
  }
  
  group "install" {
    count = 1
    task "docker" {
      driver = "raw_exec"
      template {
        data = <<EOF
#!/bin/bash
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt-get update
apt-cache policy docker-ce
apt-get install docker-ce -y
systemctl enable docker
systemctl start docker
EOF
        destination = "docker_install.sh"
      }
      config {
        command = "docker_install.sh"
      }
      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
