job "plugin-efs0-controller" {
  datacenters = ["dc1"]

  # you can run node plugins as service jobs as well, but running
  # as a system job ensures all nodes in the DC have a copy.
  type = "system"

  # only one plugin of a given type and ID should be deployed on
  # any given client node
  constraint {
    operator = "distinct_hosts"
    value = true
  }

  group "controller" {
    task "plugin" {
      driver = "docker"

      config {
        image = "amazon/aws-efs-csi-driver"

        args = [
          "controller",
          "--endpoint=unix://csi/csi.sock",
          "--logtostderr",
          "--v=5",
        ]
      }

      csi_plugin {
        id             = "aws-efs0"
        type           = "controller"
        mount_dir      = "/csi"  # this path /csi matches the --endpoint
                            # argument for the container
        health_timeout = "30s"
      }
    }
  }
}