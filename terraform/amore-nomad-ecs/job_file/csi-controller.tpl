job "plugin-nfs-controller" {
  datacenters = ["dc1"]

  group "controller" {
    task "plugin" {
      driver = "docker"

      config {
        image = "mcr.microsoft.com/k8s/csi/nfs-csi:latest"

        args = [
          "--endpoint=unix://csi/csi.sock",
          "--nodeid=${attr.unique.hostname}",
          "--logtostderr",
          "-v=5",
        ]
      }

      csi_plugin {
        id        = "aws-efs0"
        type      = "controller"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 250
        memory = 128
      }
    }
  }
}