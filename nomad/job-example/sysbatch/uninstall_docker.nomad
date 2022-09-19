job "uninstall_docker" {
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
  
  group "uninstall" {
    count = 1
    task "docker" {
      driver = "raw_exec"
      template {
        data = <<EOF
#!/bin/bash
dpkg -l | grep -i docker
systemctl stop docker
apt-get purge -y docker-ce docker-ce-cli docker
apt-get autoremove -y --purge docker-ce docker
rm -rf /var/lib/docker /etc/docker
rm /etc/apparmor.d/docker
groupdel docker
rm -rf /var/run/docker.sock
EOF
        destination = "docker_uninstall.sh"
      }
      config {
        command = "docker_uninstall.sh"
      }
      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
