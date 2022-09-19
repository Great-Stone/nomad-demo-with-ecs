job "periodic" {
  datacenters = ["dc1"]
  
  type        = "batch"

  periodic {
    cron             = "*/5 * * * * * *"
    prohibit_overlap = true
    time_zone        = "Asia/Seoul"
  }

  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "cn-client-2"
  }

  group "batch" {
    count = 1
    task "batch" {
      driver = "raw_exec"
      template {
        data = <<EOF
#!/bin/bash
echo $(date) >> /tmp/periodic.txt
EOF
        destination = "run.sh"
      }
      config {
        command = "run.sh"
      }
      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}