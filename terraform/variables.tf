variable "aws_region" {
  description = "site region"
  default     = "us-east-1"
}

variable "linux_ami" {
  description = "default uses the us-east-1 amazon linux 2, fill with ami or leave it empty to fetch it automatically"
  default     = "ami-02e136e904f3da870"
  type        = string
  validation {
    condition     = can(regex("^ami-", var.linux_ami)) || var.linux_ami == ""
    error_message = "The image_id value must be a valid AMI id, starting with \"ami-\", or just leave it empty to fetch latest image."
  }
}

variable "deploy_key_public_key" {
  type        = string
  description = "the public key string for the deploy key, usually starts with ssh-rsa"
  sensitive   = true
}

variable "node_instance_type" {
  description = "instance type used for the app server"
  default = "t2.micro"
}