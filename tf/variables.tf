variable "username" {
  description = "Username for the domain controller"
  type        = string
}

variable "password" {
  description = "Password for the domain controller"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the Active Directory"
  type        = string
}

#variable "public_ip" {
#  description = "Public IP address to allow access to the security group"
#  type        = string
#}

variable "ami_id" {
  description = "Windows Server AMI ID"
  type        = string
}

variable "instance_type" {
  description = "AWS instance type"
  default     = "t2.medium"
}

variable "sbpemkey" {
  description = "Sandbox PEM private key file"
}

variable "sbpubkey" {
  description = "Sandbox ssh public key file"
}

# The number of instances required
variable "instance_count" {
  default = 2
}