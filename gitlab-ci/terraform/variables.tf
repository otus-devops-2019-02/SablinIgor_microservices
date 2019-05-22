variable "aws_access_key" {
  default = "YOUR_ADMIN_ACCESS_KEY"
}

variable "aws_secret_key" {
  default = "YOUR_ADMIN_SECRET_KEY"
}

variable "aws_region" {
  default = "us-west-3"
}

variable "instance_type" {
  type = "string"
  default = "t2.micro"
}

variable "key_pair" {
  type = "string"
  default = "my_test_key"
}

variable "security_groups" {
  type = "list"
  default = []
}

variable "cnt" {
  type = "string"
  default = "1"
}

variable "gitlab_host" {
  type = "string"
}
variable "gitlab_token" {
  type = "string"
}
