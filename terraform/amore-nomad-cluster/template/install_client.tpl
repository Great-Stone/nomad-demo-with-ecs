#!/bin/bash
sudo yum update -y
sudo yum install yum-utils -y
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install nomad-enterprise -y

sudo yum install -y \
    ca-certificates \
    curl \
    gnupg \
    wget \
    unzip \
    lsb-release

sudo yum update -y
sudo amazon-linux-extras install docker -y
sleep 1
sudo systemctl enable docker
sleep 1
sudo systemctl start docker
sudo yum install java-11-amazon-corretto-headless -y

sudo mkdir -p /var/lib/$SOLUTION/{data,plugins}
sudo chown -R $SOLUTION:$SOLUTION /var/lib/$SOLUTION

wget https://releases.hashicorp.com/nomad-driver-ecs/0.1.0/nomad-driver-ecs_0.1.0_linux_amd64.zip
unzip ./nomad-driver-ecs_0.1.0_linux_amd64.zip
chown nomad:nomad ./nomad-driver-ecs
mv ./nomad-driver-ecs /var/lib/nomad/plugins

sudo cat <<EOCONFIG > /etc/nomad.d/nomad.hcl
log_level  = "DEBUG"
data_dir = "/var/lib/nomad/data"
plugin_dir = "/var/lib/nomad/plugins"
bind_addr = "{{ GetInterfaceIP \"eth0\" }}"
advertise {
  http = "{{ GetInterfaceIP \"eth0\" }}"
  rpc  = "{{ GetInterfaceIP \"eth0\" }}"
  serf = "{{ GetInterfaceIP \"eth0\" }}"
}

client {
  enabled = true
  server_join {
    retry_join = ["provider=aws region=${region} addr_type=private_v4 tag_key=type tag_value=${tag_value}"]
  }
  network_interface = "eth0"
  options = {
   "driver.raw_exec.enable" = "1"
  }
}

plugin "docker" {
  config {
    allow_privileged = true
  }
}

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
  prometheus_metrics         = true
}

EOCONFIG

sudo systemctl enable nomad
sleep 1
sudo systemctl start nomad