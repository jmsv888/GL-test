variable "region" {
  default = "us-east-1"
}

variable "profile" {
  description = "AWS credentials profile you want to use"
  default     = "terraform-test"
}

variable "key_name" {
  description = "Name of the AWS key pair"
  default     = "id_rsa"
}

variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key for authentication.
Example: ~/.ssh/terraform-test.pub
DESCRIPTION

  default = "keys/aws_terraform.pem.pub"
}

variable "private_key_path" {
  description = "AWS Private Key"
  default     = "keys/aws_terraform.pem"
}
