provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"
}

# Create an internet gateway to give our subnet access to the open internet
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = "${aws_vpc.vpc.id}"
}

# Give the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.internet-gateway.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags {
    Name = "Public"
  }
}

# Our default security group to access
# instances over SSH and HTTP ports for mongodb, kubernates, dockers and so on
resource "aws_security_group" "default" {
  name        = "terraform_securitygroup"
  description = "Used for public instances"
  vpc_id      = "${aws_vpc.vpc.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  #Jenkins default port
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #kube default port
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27019
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Enabling SSL port

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Key chain definition
resource "aws_key_pair" "auth" {
  key_name   = "aws_terraform2"
  public_key = "${file("keys/aws_terraform2.pem.pub")}"
}

resource "aws_instance" "jenkins_master" {
  instance_type = "t2.medium"
  ami           = "ami-a4dc46db"

  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]

  # We're going to launch into the public subnet for this.
  # Normally, in production environments, webservers would be in
  # private subnets.
  subnet_id = "${aws_subnet.default.id}"

  # The connection block tells our provisioner how to
  # communicate with the instance

  tags {
    Name = "jenkins_master"
    role = "jenkins_master"
  }
  root_block_device {
    volume_size = "16"
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file( "${pathexpand( "${var.private_key_path}" )}" )}"
    timeout     = "60s"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common python-simplejson",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo apt -y install python-pip",
      "pip install awscli",
      ". ./.profile",
      "curl -fsSL get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      "sudo usermod -aG docker ubuntu",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce",
      "sudo snap install kubectl --classic",
      "sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
    ]
  }
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key '${var.private_key_path}' -i '${aws_instance.jenkins_master.public_ip},' Ansible/jenkins.yml"
  }
  provisioner "local-exec" {
    command = "scp -i \"keys/aws_terraform2.pem\" Ansible/config ubuntu@'${aws_instance.jenkins_master.public_ip}':/home/ubuntu/.kube"
  }
}

output "public_ip" {
  value = "${aws_instance.jenkins_master.public_ip}"
}

resource "aws_instance" "kubernates_Master" {
  instance_type = "t2.medium"
  ami           = "ami-a4dc46db"

  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]

  # We're going to launch into the public subnet for this.
  # Normally, in production environments, webservers would be in
  # private subnets.
  subnet_id = "${aws_subnet.default.id}"

  # The connection block tells our provisioner how to
  # communicate with the instance

  tags {
    Name = "kubernates_Master"
    role = "kubernates_Master"
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file( "${pathexpand( "${var.private_key_path}" )}" )}"
    timeout     = "60s"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common python-simplejson",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
    ]
  }
  provisioner "local-exec" {
    command = "echo '[master]' > Ansible/hosts.ini && echo 'master1' `echo ansible_ssh_host=``echo '${aws_instance.kubernates_Master.public_ip}'` >> Ansible/hosts.ini"
  }
}

resource "aws_instance" "kubernates_worker1" {
  instance_type = "t2.medium"
  ami           = "ami-a4dc46db"
  depends_on    = ["aws_instance.kubernates_Master"]

  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]

  # We're going to launch into the public subnet for this.
  # Normally, in production environments, webservers would be in
  # private subnets.
  subnet_id = "${aws_subnet.default.id}"

  # The connection block tells our provisioner how to
  # communicate with the instance

  tags {
    Name = "kubernates_worker1"
    role = "kubernates_worker"
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file( "${pathexpand( "${var.private_key_path}" )}" )}"
    timeout     = "60s"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common python-simplejson",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
    ]
  }
  provisioner "local-exec" {
    command = "echo '[worker]' >> Ansible/hosts.ini && echo '${aws_instance.kubernates_worker1.public_ip}' >> Ansible/hosts.ini"
  }
}

resource "aws_instance" "kubernates_worker2" {
  instance_type = "t2.medium"
  ami           = "ami-a4dc46db"
  depends_on    = ["aws_instance.kubernates_worker1"]

  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]

  # We're going to launch into the public subnet for this.
  # Normally, in production environments, webservers would be in
  # private subnets.
  subnet_id = "${aws_subnet.default.id}"

  tags {
    Name = "kubernates_worker2"
    role = "kubernates_worker"
  }

  # The connection block tells our provisioner how to
  # communicate with the instance
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file( "${pathexpand( "${var.private_key_path}" )}" )}"
    timeout     = "60s"
  }

  # We run a remote provisioner on the instance after creating it 
  # to install Nginx. By default, this should be on port 80

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common python-simplejson",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
    ]
  }
  provisioner "local-exec" {
    command = "echo '${aws_instance.kubernates_worker2.public_ip}' >> Ansible/hosts.ini"
  }
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key '${var.private_key_path}' -i Ansible/hosts.ini Ansible/kube.yml"
  }
}

# resource "aws_instance" "mongo_db" {
#   instance_type = "t2.medium"
#   ami           = "ami-a4dc46db"
#   depends_on    = ["aws_instance.kubernates_worker2"]


#   key_name               = "${var.key_name}"
#   vpc_security_group_ids = ["${aws_security_group.default.id}"]


#   # We're going to launch into the public subnet for this.
#   # Normally, in production environments, webservers would be in
#   # private subnets.
#   subnet_id = "${aws_subnet.default.id}"


#   # The connection block tells our provisioner how to
#   # communicate with the instance


#   tags {
#     Name = "mongo_db"
#     role = "mongo_db"
#   }
#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = "${file( "${pathexpand( "${var.private_key_path}" )}" )}"
#     timeout     = "60s"
#   }
#   provisioner "remote-exec" {
#     inline = [
#       "sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5",
#       "echo \"deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse\" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.6.list",
#       "sudo apt-get -y update",
#       "sudo apt-get install -y mongodb",
#     ]
#   }
#   provisioner "local-exec" {
#     command = "echo '[mongodb]' >> Ansible/hosts.ini && echo '${aws_instance.mongo_db.public_ip}' >> Ansible/hosts.ini"
#   }
# }

