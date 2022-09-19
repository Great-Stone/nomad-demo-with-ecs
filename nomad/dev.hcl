# nomad agent -dev -config=./dev.hcl
log_level  = "DEBUG"
plugin_dir = "/Users/gs/workspaces/hashicorp_example/nomad-examples/nomad-driver-ecs/demo/nomad/plugin"

server {
  enabled          = true
  bootstrap_expect = 1
  num_schedulers   = 1
}

client {
  enabled          = true
  servers          = ["127.0.0.1:4647"]
  max_kill_timeout = "3m" // increased from default to accomodate ECS.
}

plugin "nomad-driver-ecs" {
  config {
    enabled = true
    cluster = "nomad-remote-driver-demo"
    region  = "ap-northeast-2"
  }
}