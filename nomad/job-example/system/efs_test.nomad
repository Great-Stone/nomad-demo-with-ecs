job "efs_csi_job" {
  datacenters = ["dc1"]

  type        = "system"

  group "cache" {
    count = 1

    network {
      port "db" {
        to = 6379
      }
    }
    volume "cache" {
      type            = "csi"
      source          = "efs_csi_volume"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
      read_only    = false
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:6.2.6-alpine3.15"
        ports = ["db"]
      }

      resources {
        cpu    = 500
        memory = 511
      }
      volume_mount {
        volume      = "cache"
        destination = "/data"
        read_only    = false
      }
    }
  }
}
