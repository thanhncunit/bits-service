# How bosh-lite was installed

```
# silence is golden
touch ~/.hushlogin

# prereqs
apt-get install git vim unzip wget

#
# Vagrant
# Download latest debian package from https://www.vagrantup.com/downloads.html
dpkg -i vagrant_xyz_x86_64.deb

#
# VirtualBox
#

# register the package source
echo 'deb http://download.virtualbox.org/virtualbox/debian vivid contrib' >> /etc/apt/sources.list

# trust the key
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -

# install
apt-get update
apt-get install virtualbox-5.x

#
# bosh-lite
#

# get the latest stemcell
wget --content-disposition https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent

# get the latest source
mkdir -p workspace
git clone https://github.com/cloudfoundry/bosh-lite
cd bosh-lite

# start the VM
vagrant up

# Make sure bin/add-route actually routes to the correct IP, e.g. for acceptance it's 192.168.150.4
bin/add-route

#
# Ruby
#
apt-get install software-properties-common
apt-add-repository ppa:brightbox/ruby-ng
apt-get update
apt-get install ruby2.3

# from now on, no more rdoc nor ri
echo 'gem: --no-rdoc --no-ri' >> ~/.gemrc
gem install bundler bosh_cli

#
# spruce
#
wget https://github.com/geofffranks/spruce/releases/download/x.y.z/spruce-linux-amd64
chmod +x spruce-linux-amd64
mv spruce-linux-amd64 /usr/local/bin/spruce
```

# Wire concourse and bosh-lite

## Concourse

### SSH keys

Concourse needs to be able to ssh into the box. Therefore the CI user's public key needs to be added to the `~/.ssh/authorized_keys` file on each bare-metal box, e.g. with `cat flintstone_id_rsa.pub >> ~/.ssh/authorized_keys`.

Regenerate the public key from the private one if necessary:

```
ssh-keygen -t rsa -f ./flintstone_id_rsa  -y > flintstone_id_rsa.pub
```

### IP routing

ssh into the bare-metal box 'concourse' and execute:

```
# bosh1 access to BOSH director
ip route add 192.168.50.0/24 via 10.155.248.181

# access to bits-service VM
ip route add 10.250.0.0/22 via 10.155.248.181

# bosh2 access to BOSH director
ip route add 192.168.100.0/24 via 10.155.248.185

# access to the acceptance env. BOSH director
ip route add 192.168.150.0/24 via 10.155.248.164
```

## bosh1

ssh into the bare-metal box 'bosh1' and execute:

```
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
ip route add 10.250.0.0/16 via 192.168.50.4

cd ~/workspace/bosh-lite
vagrant ssh
sudo ip route add 10.155.248.0/24 via 192.168.50.1 dev eth1
```

## bosh2

ssh into the bare-metal box 'bosh2' and execute:

```
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
ip route add 10.250.0.0/16 via 192.168.100.4

cd ~/workspace/bosh-lite
vagrant ssh
sudo ip route add 10.155.248.0/24 via 192.168.100.1 dev eth1
```

## acceptance

ssh into the bare-metal box 'acceptance' and execute:

```
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
ip route add 10.250.0.0/16 via 192.168.150.4

cd ~/workspace/bosh-lite
vagrant ssh
sudo ip route add 10.155.248.0/24 via 192.168.150.1 dev eth1
```

# Update bosh-lite

In order to update bosh-lite or re-create the vagrant vm do:

```
cd workspace/bosh-lite
vagrant destroy
git pull
vagrant box update
vim Vagrantfile
```

In the Vagrantfile add the `v.cpus = 7`:

```
Vagrant.configure('2') do |config|
  config.vm.box = 'cloudfoundry/bosh-lite'

  config.vm.provider :virtualbox do |v, override|
    override.vm.box_version = '9000.94.0' # ci:replace
    v.cpus = 7  # <------------------------------------------------- add this line
    # To use a different IP address for the bosh-lite director, uncomment this line:
    # override.vm.network :private_network, ip: '192.168.59.4', id: :local
    config.vm.network :private_network, ip: '192.168.150.4', id: :local
  end
  ...
```

Start bosh-lite and create our users:

```
vagrant up
bosh create user <user>
```

# Install cf

```
wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add -
echo "deb http://packages.cloudfoundry.org/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list
sudo apt-get update
sudo apt-get install cf-cli
```
