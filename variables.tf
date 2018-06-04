variable "region" {
  default = "us-east-1"
}

variable "profile" {
  description = "AWS credentials profile you want to use"
  default     = "terraform-test"
}

variable "key_name" {
  description = "Name of the AWS key pair"
  default     = "aws_terraform2"
}

variable "public_key_path" {
  description = "AWS Private Key"
  default     = "keys/aws_terraform2.pem.pub"
}

variable "private_key_path" {
  description = "AWS Private Key"
  default     = "keys/aws_terraform2.pem"
}
