# Libvirt configuration
variable "libvirt" {
  description = "Libvirt configuration"
  type = object({
    network   = string,
    pool      = string,
    pool_path = string
  })
}

# DNS configuration
variable "dns" {
  description = "DNS configuration"
  type = object({
    domain = string
  })
}

# Jenkins master VM configuration
variable "jenkins_master" {
  description = "Configuration for Jenkins master virtual machine"
  type = object({
    hostname = string,
    base_img = string,
    vcpu     = number,
    memory   = number
  })
}

# Jenkins slave VM configuration
variable "jenkins_slave" {
  description = "Configuration for Jenkins slave virtual machine"
  type = object({
    hostname = string,
    base_img = string,
    vcpu     = number,
    memory   = number
  })
}