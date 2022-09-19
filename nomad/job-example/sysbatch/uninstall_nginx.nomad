job "uninstall_nginx" {
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
systemctl stop nginx
apt-get remove nginx -y
EOF
        destination = "uninstall.sh"
      }
      config {
        command = "uninstall.sh"
      }
      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
