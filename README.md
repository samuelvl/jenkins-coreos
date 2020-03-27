# Jenkins

Deploy immutable Jenkins instance using Terraform and Fedora CoreOS.

## Requirements

- Terraform (tested with 0.12.24 version).
- Libvirt provider for Terraform (tested with 0.6.1 version).

Install requirements.

```bash
./requirements.sh
```

## Deploy Jenkins

```
make
```

## References

- https://github.com/jenkinsci/docker
- https://www.terraform.io/intro/index.html
- https://github.com/dmacvicar/terraform-provider-libvirt
- https://docs.fedoraproject.org/en-US/fedora-coreos/getting-started/#_launching_with_qemu_or_libvirt