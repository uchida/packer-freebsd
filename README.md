# packer-freebsd

[![Build Status](https://img.shields.io/travis/uchida/packer-freebsd.svg)](https://travis-ci.org/uchida/packer-freebsd)
[![License](https://img.shields.io/github/license/uchida/packer-freebsd.svg)](http://creativecommons.org/publicdomain/zero/1.0/deed)

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

## License

[![CC0](http://i.creativecommons.org/p/zero/1.0/88x31.png "CC0")]
(http://creativecommons.org/publicdomain/zero/1.0/deed)

dedicated to public domain by [contributors](https://github.com/uchida/packer-freebsd/graphs/contributors).

