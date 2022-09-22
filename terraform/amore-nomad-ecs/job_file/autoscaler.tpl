job "autoscaler" {
  datacenters = ["dc1"]

  type = "service"

  group "autoscaler" {
    count = 1
    network {
      port "http" {}
    }


    task "autoscaler" {
      driver = "docker"

      config {
        image   = "hashicorp/nomad-autoscaler-enterprise:0.3.3"
        command = "nomad-autoscaler"
        args    = ["agent", "-config", "${NOMAD_TASK_DIR}/config.hcl"]
      }

      template {
        data = <<EOF
nomad {
  address = "http://{{env "attr.unique.network.ip-address" }}:4646"
}
apm "nomad" {
  driver = "nomad-apm"
  config  = {
    address = "http://{{env "attr.unique.network.ip-address" }}:4646"
  }
}
telemetry {
  prometheus_metrics = true
  disable_hostname   = true
}
apm "prometheus" {
  driver = "prometheus"
  config = {
    address = "{{ with nomadService "prometheus" }}{{ with index . 0 }}http://{{.Address}}:{{.Port}}{{ end }}{{ end }}"
  }
}
strategy "target-value" {
  driver = "target-value"
}
          EOF

        destination = "${NOMAD_TASK_DIR}/config.hcl"
      }

      resources {
        cpu    = 50
        memory = 200

      }
    }
  }
}
