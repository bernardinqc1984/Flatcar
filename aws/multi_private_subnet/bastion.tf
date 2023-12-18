####################
# Bastion instances
####################

resource "aws_instance" "bastion-lunix" {
    #ami = var.ami-bastion-lunix
    ami = "${lookup(var.amis_ubuntu, var.aws_region)}"
    instance_type = var.aws_bastion_lunix_type

    subnet_id = "${aws_subnet.kubernetes-public.id}"
    private_ip = "${cidrhost(var.aws_cidr_subnets_public_cidr , 55 )}"
    #associate_public_ip_address = false # Instances have public, dynamic IP

    availability_zone = "${var.azs.0}"
    vpc_security_group_ids = ["${aws_security_group.lunix.id}"]
    key_name = "${var.aws_keypair_name}"
    
    root_block_device {
    volume_type           = "gp2"
    volume_size           = var.aws_bastion_lunix_disk
    delete_on_termination = true

    tags = {
      Owner = "${var.aws_owner}"
      Name = "${var.aws_name_prefix}-Bastion-lunix"
      Department = "Global Operations"
    }
  }

    provisioner "local-exec" { 
      command = <<EOF
      chmod 400 ${var.aws_keypair_name}.pem
      terraform output vpc_info  >> infra/terraform.tfvars
      sed -i 's/  "vpc_kubernetes"/vpc_kubernetes/g' infra/terraform.tfvars
      sed -i 's/  "subnet_public"/subnet_public/g' infra/terraform.tfvars
      sed -i 's/{/ /g' infra/terraform.tfvars
      sed -i 's/}/ /g' infra/terraform.tfvars
    EOF
    }

    provisioner "file" {
    source      = "infra"
    destination = "/home/ubuntu/"
  }

    provisioner "file" {
    source      = "ansible"
    destination = "/home/ubuntu/infra/"
  }

    provisioner "file" {
     source      = "${var.aws_keypair_name}.pem"  # terraform machine
     destination = "infra/${var.aws_keypair_name}.pem"  # remote machine
  }

    connection {
    type        = "ssh"
    user        = "${var.aws_ssh_user-bastion}"
    private_key = file("${var.aws_keypair_name}.pem")
    #private_key = file("~/.ssh/terraform")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-add-repository --yes --update ppa:ansible/ansible",
      "sudo apt-get update",
      "sudo apt install ansible -y ",
      "sudo apt install unzip",
      "wget https://releases.hashicorp.com/terraform/1.6.1/terraform_1.6.1_linux_amd64.zip",
      "unzip terraform_1.6.1_linux_amd64.zip",
      "sudo mv terraform /usr/bin/",
      "sudo mv infra/ansible/template/hosts /etc/hosts",
      "sudo chmod 400 infra/${var.aws_keypair_name}.pem",
      "sudo apt install dos2unix",
      "dos2unix /home/ubuntu/infra/deploy.sh",
      "sh /home/ubuntu/infra/deploy.sh"
    ]

  }

    tags = {
      Owner = "${var.aws_owner}"
      Name = "${var.aws_name_prefix}-Bastion-lunix"
      Department = "Global Operations"
    }
}

############################
# Bastion Windows instances
############################

resource "aws_instance" "bastion-Windows" {
    #ami = var.ami-bastion-windows
    ami = "${lookup(var.amis_windows, var.aws_region)}"
    instance_type = var.aws_bastion_windows_type

    subnet_id = "${aws_subnet.kubernetes-public.id}"
    private_ip = "${cidrhost(var.aws_cidr_subnets_public_cidr, 56 )}"
    #associate_public_ip_address = false # Instances have public, dynamic IP
    
    root_block_device {
    volume_type           = "gp2"
    volume_size           = var.aws_bastion_windows_disk
    delete_on_termination = true

    tags = {
      Owner = "${var.aws_owner}"
      Name = "${var.aws_name_prefix}-Bastion-windows"
      Department = "Global Operations"
    }
  }

    availability_zone = "${var.azs.0}"
    vpc_security_group_ids = ["${aws_security_group.windows.id}"]
    key_name = "${var.aws_keypair_name}"
    
    tags = {
      Owner = "${var.aws_owner}"
      Name = "${var.aws_name_prefix}-Bastion-windows"
      Department = "Global Operations"
    }
}

