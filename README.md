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
virsh pool-start jenkins-ignition # Or use pool-create-as
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
  <domain name="libvirt.local" localOnly="no"/>
  <ip address="172.3.2.1" netmask="255.255.255.0">
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
virsh net-start dmz # Or use net-create
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

## Deploy Jenkins

Edit the `jenkins-master-ign.yml` **[FCC YAML file](https://docs.fedoraproject.org/en-US/fedora-coreos/fcct-config/)** to configure the Jenkins instance at boot time and convert it to ignition specification using FCCT (FCOS Transpiler) tool.

```bash
podman run -i --rm quay.io/coreos/fcct:release --pretty --strict \
  < src/ignition/jenkins-master-ign.yml > src/ignition/jenkins-master-ign.json
```

Deploy Jenkins instances using Terraform.

```bash
make
```

Install `simple-theme` plugin and set the following theme.

```bash
https://cdn.rawgit.com/afonsof/jenkins-material-theme/gh-pages/dist/material-blue-grey.css
```

## References

- https://github.com/jenkinsci/docker
- https://www.terraform.io/intro/index.html
- https://github.com/dmacvicar/terraform-provider-libvirt
- https://docs.fedoraproject.org/en-US/fedora-coreos/getting-started/#_launching_with_qemu_or_libvirt
- https://libvirt.org/formatdomain.html#elements
- https://docs.fedoraproject.org/en-US/fedora-coreos/fcct-config
- https://github.com/jenkinsci/docker