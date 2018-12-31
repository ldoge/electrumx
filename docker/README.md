# ElectrumX Server Docker Solution (support BTX and BSD)

## Requirements

### Docker-CE
Support for the following distribution versions:
* CentOS 7.4 (x86_64-centos-7)
* Fedora 26 (x86_64-fedora-26)
* Fedora 27 (x86_64-fedora-27)
* Fedora 28 (x86_64-fedora-28)
* Debian 7 (x86_64-debian-wheezy)
* Debian 8 (x86_64-debian-jessie)
* Debian 9 (x86_64-debian-stretch)
* Debian 10 (x86_64-debian-buster)
* Ubuntu 14.04 LTS (x86_64-ubuntu-trusty)
* Ubuntu 16.04 LTS (x86_64-ubuntu-xenial)
* Ubuntu 17.10 (x86_64-ubuntu-artful)
* Ubuntu 18.04 LTS (x86_64-ubuntu-bionic)

Download and execute the automated docker-ce installation script - maintained by the Docker project.

```
sudo curl -sSL https://get.docker.com | sh
```

# ElectrumX Server Docker Solution for Bitcore

Login as root, then do:

```
wget https://raw.githubusercontent.com/LIMXTEC/electrumx/master/docker/electrumx-docker-btx.sh
chmod +x electrumx-docker-btx.sh
./electrumx-docker-btx.sh
```

# ElectrumX Server Docker Solution for Bitsend

Login as root, then do:

```
wget https://raw.githubusercontent.com/LIMXTEC/electrumx/master/docker/electrumx-docker-bsd.sh
chmod +x electrumx-docker-bsd.sh
./electrumx-docker-bsd.sh
```
