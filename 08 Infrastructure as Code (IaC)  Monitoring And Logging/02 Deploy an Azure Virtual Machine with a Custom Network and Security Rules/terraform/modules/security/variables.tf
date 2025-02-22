variable "location" {}
variable "resource_group_name" {}
variable "security_group_name" {}
variable "allowed_ssh_ip" {
  description = "The allowed IP range for SSH access"
  type        = string
}
