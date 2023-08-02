############################
# K8s Control Pane instances
############################

resource "aws_instance" "controller" {

    count = 3
    ami = "${lookup(var.amis, var.region)}"
    instance_type = "${var.controller_instance_type}"

    iam_instance_profile = "${aws_iam_instance_profile.kubernetes.id}"

    subnet_id = "${aws_subnet.kubernetes.id}"
    private_ip = "${cidrhost(var.vpc_cidr, 50 + count.index)}"
    associate_public_ip_address = false # Instances have public, dynamic IP
    source_dest_check = false # TODO Required??

    availability_zone = "${var.zone}"
    vpc_security_group_ids = ["${aws_security_group.kubernetes.id}"]
    key_name = "${var.default_keypair_name}"

    tags = {
      Owner = "${var.owner}"
      Name = "preprod-master0-${count.index +1}"
      ansibleFilter = "${var.ansibleFilter}"
      ansibleNodeType = "preprod-controller"
      ansibleNodeName = "preprod-controller0${count.index +1}"
    }
}

###############################
## Kubernetes API Load Balancer
###############################

resource "aws_elb" "kubernetes_api" {
    name = "${var.elb_name}"
    instances = "${aws_instance.controller.*.id}"
    subnets = ["${aws_subnet.kubernetes.id}"]
    cross_zone_load_balancing = true

    security_groups = ["${aws_security_group.kubernetes_api.id}"]

    listener {
      lb_port = 6443
      instance_port = 6443
      lb_protocol = "TCP"
      instance_protocol = "TCP"
    }

    health_check {
      healthy_threshold = 2
      unhealthy_threshold = 2
      timeout = 15
      target = "HTTP:8080/healthz"
      interval = 30
    }

    tags = {
      Name = "kubernetes"
      Owner = "${var.owner}"
    }
}

############
## Security
############

resource "aws_security_group" "kubernetes_api" {
  vpc_id = "${aws_vpc.kubernetes.id}"
  name = "kubernetes-api"

  # Allow inbound traffic to the port used by Kubernetes API HTTPS
  ingress {
    from_port = 6443
    to_port = 6443
    protocol = "TCP"
    cidr_blocks = ["${var.control_cidr}"]
  }

  # Allow all outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Owner = "${var.owner}"
    Name = "kubernetes-api"
  }
}

############
## Outputs
############

output "kubernetes_api_dns_name" {
  value = "${aws_elb.kubernetes_api.dns_name}"
}
