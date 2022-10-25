output "sample_job" {
  value = data.template_file.nomad_ecs_job.rendered
}
output "demo_security_group_id" {
  value = aws_security_group.nomad_ecs.id
}
