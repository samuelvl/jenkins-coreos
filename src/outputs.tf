# Jenkins master
output "jenkins_master_ip" {
  value = libvirt_domain.jenkins_master.network_interface.0.addresses
}

output "jenkins_master_dns" {
  value = format("%s.%s", var.jenkins_master.hostname, var.dns.domain)
}

output "jenkins_master_ssh" {
  value = format("ssh -i src/ssh/maintuser/id_rsa maintuser@%s.%s",
    var.jenkins_master.hostname, var.dns.domain)
}

# Jenkins slave
output "jenkins_slave_ip" {
  value = libvirt_domain.jenkins_slave.network_interface.0.addresses
}

output "jenkins_slave_dns" {
  value = format("%s.%s", var.jenkins_slave.hostname, var.dns.domain)
}

output "jenkins_slave_ssh" {
  value = format("ssh -i src/ssh/maintuser/id_rsa maintuser@%s.%s",
    var.jenkins_slave.hostname, var.dns.domain)
}
