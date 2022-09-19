job "param" {
  datacenters = ["dc1"]
  
  type        = "batch"

  parameterized {
    payload = "optional"
    meta_required = ["param"]
  }

  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "cn-client-1"
  }

  group "batch" {
    count = 1
    task "batch" {
      driver = "raw_exec"
      template {
        data = <<EOF
#!/bin/bash
echo 'batch param {{ env "NOMAD_META_PARAM" }}' >> /tmp/param.txt
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