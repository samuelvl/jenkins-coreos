output "jenkins_master_ip" {
  value = libvirt_domain.jenkins_master.network_interface.0.addresses
}

output "jenkins_master_dns" {
  value = format("%s.%s", var.jenkins_master.hostname, var.dns.domain)
}
