job "system" {
  datacenters = ["dc1"]

  type        = "system"

  group "cache" {
    count = 1

    network {
      port "db" {
        to = 6379
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:6.2.6-alpine3.15"
        ports = ["db"]
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
