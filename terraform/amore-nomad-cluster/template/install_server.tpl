#!/bin/bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository 'deb [arch=amd64] https://apt.releases.hashicorp.com bionic main'
sudo apt-get update && sudo apt-get -y install nomad

for SOLUTION in "nomad";
do
    sudo mkdir -p /var/lib/$SOLUTION/{data,plugins}
    sudo chown -R $SOLUTION:$SOLUTION /var/lib/$SOLUTION
done

sudo cat <<EOCONFIG > /etc/nomad.d/nomad.hcl
data_dir = "/var/lib/nomad/data"
bind_addr = "{{ GetInterfaceIP \"ens5\" }}"
server {
  enabled          = true
  bootstrap_expect = 1
  encrypt = "H6NAbsGpPXKJIww9ak32DAV/kKAm7vh9awq0fTtUou8="
}
EOCONFIG

sudo systemctl enable nomad
sleep 1
sudo systemctl start nomad
