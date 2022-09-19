job "batch" {
  datacenters = ["dc1"]
  
  type        = "batch"
  
  group "batch" {
    count = 1
    task "batch" {
      driver = "raw_exec"
      template {
        data = <<EOF
#!/bin/bash
echo $(hostname) > /tmp/check.txt
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
