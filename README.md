# Jenkins

Deploy immutable Jenkins instance using Terraform, Fedora CoreOS and ignition.

## Requirements

- Terraform (tested with 0.12.24 version).
- Libvirt (tested with 5.6.0 version).
- Libvirt provider for Terraform (tested with 0.6.1 version).

Install requirements.

```bash
./requirements.sh
```

## Setup Libvirt

Use `virsh` command utility to configure libvirt.

```bash
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

Check if libvirt is running.

```bash
virsh version --daemon
```

### Fedora CoreOS

Use `/var/lib/libvirt/images` to store VMs images.

```bash
install --owner="root" --group="libvirt" --mode="0770" \
    --context="system_u:object_r:virt_image_t:s0" \
    -d /var/lib/libvirt/images
```

Download Fedora CoreOS **[last image available](https://getfedora.org/coreos/download?tab=metal_virtualized&stream=stable)** for QEMU (qcow2) and copy the images folder.

Make sure the image has the correct SELinux context.

```bash
restorecon -vF /var/lib/libvirt/images/<qcow2-image>
```

### Storage pool

Use `/var/lib/libvirt/storage/jenkins-ignition` to store Jenkins VMs volumes.

```bash
install --owner="root" --group="libvirt" --mode="0770" \
    --context="system_u:object_r:virt_image_t:s0" \
    -d /var/lib/libvirt/storage/jenkins-ignition
```

Create a libvirt `pool` that uses this folder.

```bash
virsh pool-define-as jenkins-ignition \
    --type dir --target /var/lib/libvirt/storage/jenkins-ignition
```

Enable and start `jenkins-ignition` pool.

```bash
virsh pool-autostart jenkins-ignition
virsh pool-start jenkins-ignition
```

Check the pool status.

```
virsh pool-info jenkins-ignition
```

### Network

Create a dedicated network to isolate VMs from the rest of the host network.

```bash
virsh net-define /dev/stdin <<EOF
<network>
  <name>dmz</name>
  <bridge name="virbr100" stp="on" delay="0" zone="libvirt" />
  <mtu size="1500"/>
  <domain name="libvirt.local" localOnly="yes"/>
  <dns enable="yes">
    <forwarder addr="80.80.80.80"/>
    <forwarder addr="80.80.81.81"/>
    <txt name="_hello.libvirt.local" value="world!"/>
  </dns>
  <ip address="172.3.2.1" netmask="255.255.255.0" localPtr="yes">
    <dhcp>
      <range start="172.3.2.100" end="172.3.2.254"/>
    </dhcp>
  </ip>
  <forward mode="nat">
    <nat>
      <port start="1024" end="65535"/>
    </nat>
  </forward>
</network>
EOF
```

Enable and start `dmz` network.

```bash
virsh net-autostart dmz
virsh net-start dmz
```

Check the network status.

```
virsh net-info dmz
```

### QEMU permissions

The provider does not currently support to create volumes with different mode than `root:root` so QEMU agent must run as priviledged. Set user and password in `/etc/libvirt/qemu.conf` file.

```bash
...
user = "root"
group = "root"
...
```

Restart libvirt daemon.

```bash
systemctl restart libvirtd
```

### DNS

If `<dns enable="yes"/>` is enabled in a libvirt network, it will use `dnsmasq` to setup a DNS server listening in the port 53 of the network interface (e.g. virbr100). This DNS will handle A records for virtual machines but can also be used for creating additional A, PTR, SRV and TXT records.

Configure NetworkManager to also use `dnamsq` to setup a DNS server to resolve all local requests. Edit the file `/etc/NetworkManager/conf.d/localdns.conf` and add the following configuration.

```bash
[main]
dns=dnsmasq
```

Configure the NetworkManager DNS server to forward requests, with destination the libvirt domains, to corresponding DNS servers. Edit the file `/etc/NetworkManager/dnsmasq.d/libvirt_dnsmasq.conf` and add the following configuration (use your network interface gateway).

```bash
server=/libvirt.local/172.3.2.1
```

Restart NetworkManager service.

```bash
systemctl restart NetworkManager
```

## Deploy Jenkins

Edit the `jenkins-master-ign.yml` and `jenkins-slave-ign.yml` **[FCC YAML files](https://docs.fedoraproject.org/en-US/fedora-coreos/fcct-config/)** to generate Ignition files with the following configuration:

- Plugins
- Themes
- Build agents
- Security

Run `make` to deploy and test infrastructure with Terraform.

```bash
make
```

### Configuration

Go to `http://jenkins-master.libvirt.local:8080/` and upload the SSH private key to connect to the slaves before starting to use Jenkins. It is not included in ignition because of security reasons.

## Troubleshooting

Use SSH private key to access jenkins machines.

```bash
ssh -i src/ssh/id_rsa maintuser@jenkins-master.libvirt.local
```

Remove a Jenkins instance.

```bash
terraform destroy \
  -var-file="configuration/tfvars/default.tfvars" \
  -var-file="configuration/tfvars/localhost.tfvars" \
  -target libvirt_volume.jenkins_master src
```

## TODO

- Find a secure way to include SSH private key in Ignition

## References

- https://github.com/jenkinsci/docker
- https://www.terraform.io/intro/index.html
- https://github.com/dmacvicar/terraform-provider-libvirt
- https://docs.fedoraproject.org/en-US/fedora-coreos/getting-started/#_launching_with_qemu_or_libvirt
- https://liquidat.wordpress.com/2017/03/03/howto-automated-dns-resolution-for-kvmlibvirt-guests-with-a-local-domain/
- https://libvirt.org/formatdomain.html#elements
- https://docs.fedoraproject.org/en-US/fedora-coreos/fcct-config
- https://github.com/jenkinsci/docker
- https://github.com/jenkinsci/configuration-as-code-plugin
- https://jenkinsci.github.io/job-dsl-plugin/#path/pipelineJob