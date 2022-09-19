output "demo_subnet_id" {
  value = aws_subnet.nomad_demo.id
}

output "demo_security_group_id" {
  value = aws_security_group.nomad_demo.id
}
