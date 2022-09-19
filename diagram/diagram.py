from diagrams import Cluster, Diagram, Edge
from diagrams.onprem.compute import Nomad
from diagrams.aws.compute import EC2, ECS, EC2ElasticIpAddress
from diagrams.aws.database import RDS
from diagrams.aws.network import ELB
from diagrams.onprem.iac import Terraform
from diagrams.onprem.network import Internet

graph_attr = {
  # "bgcolor": "transparent"
}

with Diagram("nomad_demo", show=False, graph_attr=graph_attr, direction="BT"):

  internet = Internet("internet")

  aws = Cluster("AWS")
  
  with Cluster("On-prem"):
    nomad = Nomad("Nomad")

  with aws:
    eip = EC2ElasticIpAddress("eip")

    with Cluster("Subnet"):
      with Cluster("VMs"):
        vm_group = [
          EC2("EC2"),
          EC2("EC2")
        ]

      with Cluster("Containers"):
        container_group = [
          ECS("ECS")
        ]

  
  iac = Terraform("IaC")

  nomad >> Edge(label="deploy") >> vm_group
  nomad >> Edge(label="deploy") >> container_group
  container_group << eip
  eip << internet
