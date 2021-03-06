resource "libvirt_ignition" "jenkins_master" {
  name    = format("%s.ign", var.jenkins_master.hostname)
  pool    = var.libvirt.pool
  content = file(format("%s/ignition/jenkins-master/ignition.json", path.module))
}

resource "libvirt_volume" "jenkins_master_image" {
  name   = format("%s-fedora-coreos-31.x86_64.qcow2", var.jenkins_master.hostname)
  pool   = var.libvirt.pool
  source = var.jenkins_master.base_img
  format = "qcow2"
}

resource "libvirt_volume" "jenkins_master" {
  name           = format("%s-volume.qcow2", var.jenkins_master.hostname)
  pool           = var.libvirt.pool
  base_volume_id = libvirt_volume.jenkins_master_image.id
  format         = "qcow2"
}

resource "libvirt_domain" "jenkins_master" {
  name   = format("%s", var.jenkins_master.hostname)
  memory = var.jenkins_master.memory
  vcpu   = var.jenkins_master.vcpu

  coreos_ignition = libvirt_ignition.jenkins_master.id

  disk {
    volume_id = libvirt_volume.jenkins_master.id
    scsi      = false
  }

  network_interface {
    hostname       = format("%s.%s", var.jenkins_master.hostname, var.dns.domain)
    network_name   = var.libvirt.network
    wait_for_lease = true
  }

  console {
    type           = "pty"
    target_type    = "serial"
    target_port    = "0"
    source_host    = "127.0.0.1"
    source_service = "0"
  }

  graphics {
    type           = "spice"
    listen_type    = "address"
    listen_address = "127.0.0.1"
    autoport       = true
  }
}
