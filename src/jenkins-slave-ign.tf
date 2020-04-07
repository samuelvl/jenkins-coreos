data "ignition_config" "jenkins_slave" {
    users = [
        data.ignition_user.jenkins_slave_jenkins.rendered,
        data.ignition_user.jenkins_slave_maintuser.rendered,
    ]
}

# Linux users
data "ignition_user" "jenkins_slave_jenkins" {
    name                = "jenkins"
    uid                 = 9999
    shell               = "/bin/bash"
    groups              = [ "docker" ]
    ssh_authorized_keys = [ trimspace(file(format("%s/ssh/jenkins/id_rsa.pub", path.module))) ]
}

data "ignition_user" "jenkins_slave_maintuser" {
    name                = "maintuser"
    uid                 = 1001
    shell               = "/bin/bash"
    groups              = [ "sudo", "wheel" ]
    ssh_authorized_keys = [ trimspace(file(format("%s/ssh/maintuser/id_rsa.pub", path.module))) ]
}