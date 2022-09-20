output "sample_job" {
  value = data.template_file.nomad_ecs_job.rendered
}