output "demo_subnet_id" {
  value = data.aws_subnet.nomad_demo.id
}

output "demo_vpc_id" {
  value = data.aws_vpc.nomad_demo.id
}

output "demo_security_group_id" {
  value = aws_security_group.nomad_ecs.id
}

output "nomad_server_env" {
  value = "export NOMAD_ADDR=http://${aws_eip.server.public_ip}:4646"
}

output "nomad_server_private" {
  value = aws_instance.server[*].private_ip
}

output "nomad_client_ips" {
  value = aws_eip.client[*].public_dns
}

output "nomad_server_dns" {
    value = "http://${aws_eip.server.public_dns}:4646"
}
