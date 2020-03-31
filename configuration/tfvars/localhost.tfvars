libvirt = {
  network   = "dmz"
  pool      = "jenkins-ignition"
  pool_path = "/var/lib/libvirt/storage/jenkins-ignition"
}

dns = {
  domain = "libvirt.local"
}
