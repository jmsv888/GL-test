provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
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
# instances over SSH and HTTP
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
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Enabling SSL port

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
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

resource "aws_key_pair" "auth" {
  key_name   = "aws_terraform"
  public_key = "${file("keys/aws_terraform.pem.pub")}"
}

resource "aws_instance" "jenkins_master" {
  instance_type = "t2.micro"
  ami           = "ami-fce3c696"

  key_name               = "aws_terraform"
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
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file( "${pathexpand( "${var.private_key_path}" )}" )}"
    timeout     = "60s"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
    ]
  }
}

resource "aws_instance" "kubernates_Master" {
  instance_type = "t2.micro"
  ami           = "ami-fce3c696"

  key_name               = "aws_terraform"
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
    ]
  }
}

resource "aws_instance" "kubernates_worker1" {
  instance_type = "t2.micro"
  ami           = "ami-fce3c696"

  key_name               = "aws_terraform"
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
    ]
  }
}

resource "aws_instance" "kubernates_worker2" {
  instance_type = "t2.micro"
  ami           = "ami-fce3c696"

  key_name               = "aws_terraform"
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
    ]
  }
}
