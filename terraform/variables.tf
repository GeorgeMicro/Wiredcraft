variable "aws_region" {
  description = "The aws region where your infrastructure will reside."
  default     = "us-east-1"
}

variable "linux_ami" {
  description = "The default is set to the image of amazon linux 2 in us-east-1, fill with the ami ID you wish to choose."
  default     = "ami-02e136e904f3da870"
  type        = string
  validation {
    condition     = can(regex("^ami-", var.linux_ami)) || var.linux_ami == ""
    error_message = "The image_id value must be a valid AMI id, starting with \"ami-\", or just leave it empty to fetch latest image."
  }
}

variable "deploy_key_public_key" {
  type        = string
  description = "Please provide the public key string for the deploy key. recommend using puttygen to generate one and copy the public key string here."
  sensitive   = true
}

variable "node_instance_type" {
  description = "The instance type used for the app node. The default type is t2.micro."
  default = "t2.micro"
}