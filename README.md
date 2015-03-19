# packer-freebsd

packer template to build FreeBSD (with zfsroot) images

## Building Images

To build images, simply run:

```
$ git clone https://github.com/uchida/packer-freebsd
$ cd packer-freebsd
$ packer build template.json
```

If you want to build only virtualbox, vmware or qemu.

```
$ packer build -only=virtualbox-iso template.json
$ packer build -only=vmware-iso template.json
$ packer build -only=qemu template.json
```

When building qemu images, note that your `qemu_binary` path is correct
and the driver names, controlled by `qemuargs`, are consistent with
one in a template.json or an install script.
