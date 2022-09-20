#!/bin/bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository 'deb [arch=amd64] https://apt.releases.hashicorp.com bionic main'
sudo apt-get update && sudo apt-get -y install nomad

sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    wget \
    unzip \
    lsb-release

sudo apt-get update
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

sudo apt-get update
sudo apt-get install -y docker-ce openjdk-11-jdk

for SOLUTION in "nomad";
do
    sudo mkdir -p /var/lib/$SOLUTION/{data,plugins}
    sudo chown -R $SOLUTION:$SOLUTION /var/lib/$SOLUTION
done

# mkdir -p ~/.aws
# cat <<EOT >> ~/.aws/credentials
# [default]
# aws_access_key_id = $${aws_access_key_id}
# aws_secret_access_key = $${aws_secret_access_key}
# aws_session_token = $${aws_session_token}
# EOT

wget https://releases.hashicorp.com/nomad-driver-ecs/0.1.0/nomad-driver-ecs_0.1.0_linux_amd64.zip
unzip ./nomad-driver-ecs_0.1.0_linux_amd64.zip
chown nomad:nomad ./nomad-driver-ecs
mv ./nomad-driver-ecs /var/lib/nomad/plugins

sudo cat <<EOCONFIG > /etc/nomad.d/nomad.hcl
log_level  = "DEBUG"
data_dir = "/var/lib/nomad/data"
plugin_dir = "/var/lib/nomad/plugins"
bind_addr = "{{ GetInterfaceIP \"ens5\" }}"
advertise {
  http = "{{ GetInterfaceIP \"ens5\" }}"
  rpc  = "{{ GetInterfaceIP \"ens5\" }}"
  serf = "{{ GetInterfaceIP \"ens5\" }}"
}

client {
  enabled = true
  server_join {
    retry_join = ["provider=aws region=${region} addr_type=private_v4 tag_key=type tag_value=${tag_value}"]
  }
  network_interface = "ens5"
  options = {
   "driver.raw_exec.enable" = "1"
  }
}

plugin "nomad-driver-ecs" {
  config {
    enabled = true
    cluster = "${clustername}"
    region  = "${region}"
  }
}

EOCONFIG

sudo systemctl enable nomad
sleep 1
sudo systemctl start nomad