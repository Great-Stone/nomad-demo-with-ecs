ob "nomad-ecs-demo" {
  datacenters = ["dc1"]
  namespace = "ecs"

  group "ecs-remote-task-demo" {
    count = 1

    scaling {
      enabled = true
      min = 0
      max = 5
    }

    restart {
      attempts = 0
      mode     = "fail"
    }

    reschedule {
      delay = "5s"
    }

    task "http-server" {
      driver       = "ecs"
      kill_timeout = "1m" // increased from default to accomodate ECS.

      config {
        task {
          launch_type     = "FARGATE"
          task_definition = "nomad-ecs-remote-demo:15"
          network_configuration {
            aws_vpc_configuration {
              assign_public_ip = "ENABLED"
              security_groups  = ["sg-0da05378bfcb72945"]
              subnets          = ["subnet-08303312087506cc7"]
            }
          }
        }
      }

      resources {
        cpu    = 20
        memory = 10
      }
    }
  }
}