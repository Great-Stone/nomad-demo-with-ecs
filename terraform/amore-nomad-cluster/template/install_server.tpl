#!/bin/bash
sudo yum update -y
sudo yum install yum-utils -y
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install nomad-enterprise -y

for SOLUTION in "nomad";
do
    sudo mkdir -p /var/lib/$SOLUTION/{data,plugins}
    sudo chown -R $SOLUTION:$SOLUTION /var/lib/$SOLUTION
done

echo "${license}" >> /tmp/nomad.hclic

sudo cat <<EOCONFIG > /etc/nomad.d/nomad.hcl
data_dir = "/var/lib/nomad/data"
bind_addr = "{{ GetInterfaceIP \"eth0\" }}"
advertise {
  http = "{{ GetInterfaceIP \"eth0\" }}"
  rpc  = "{{ GetInterfaceIP \"eth0\" }}"
  serf = "{{ GetInterfaceIP \"eth0\" }}"
}
server {
  enabled          = true
  bootstrap_expect = 3
  encrypt = "H6NAbsGpPXKJIww9ak32DAV/kKAm7vh9awq0fTtUou8="
  license_path = "/tmp/nomad.hclic"
  server_join {
    retry_join = ["provider=aws region=${region} addr_type=private_v4 tag_key=type tag_value=${tag_value}"]
  }
}


EOCONFIG

sudo systemctl enable nomad
sleep 1
sudo systemctl start nomad
