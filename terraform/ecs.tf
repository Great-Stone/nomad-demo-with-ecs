resource "aws_ecs_cluster" "nomad_remote_driver_demo" {
  name = "nomad-remote-driver-demo"
}

resource "aws_ecs_task_definition" "nomad_remote_driver_demo" {
  family                   = "nomad-remote-driver-demo"
  container_definitions    = file(var.ecs_task_definition_file)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

data "template_file" "nomad_ecs_job" {
  count    = 2
  template = file("${path.module}/../nomad/job-example/ecs/demo-ecs.tpl")
  vars = {
    task_definition   = "${aws_ecs_task_definition.nomad_remote_driver_demo.family}:${count.index + 1}"
    security_group_id = aws_security_group.nomad_demo.id
    subnet_id         = aws_subnet.nomad_demo.id
  }
}

resource "local_file" "nomad_ecs_job" {
  count    = 2
  content  = element(data.template_file.nomad_ecs_job, count.index).rendered
  filename = "${path.module}/../nomad/job-example/ecs/demo-ecs-demo-${count.index + 1}.hcl"
}