# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "monsenso/macos-10.13"
  config.vm.box_version = "1.0.0"
  config.vm.network "forwarded_port", guest: 8080, host: 8080

  # Sync the fastlane-ci folder to the guest VM. The type of the synced folder
  # has to be rsync or nfs, because BSD-based guests do not support the
  # VirtualBox filesystem at this time.
  config.vm.synced_folder ".", "/fastlane-ci", type: "nfs"

  # NFS requires a host-only network to be created in order to work. This
  # requires admin password every time you run `vagrant up`.
  config.vm.network "private_network", ip: "192.168.33.10"

  config.vm.provider "virtualbox" do |vb|
    # Hide the VirtualBox GUI when booting the machine
    vb.gui = false

    # Customize the amount of memory on the VM
    vb.memory = "8192"

    # Because the USB 2.0 controller state is part of the saved VM state, the
    # VM cannot be started with USB 2.0 support on.
    vb.customize ["modifyvm", :id, "--usb", "on"]
    vb.customize ["modifyvm", :id, "--usbehci", "off"]
  end

  # Bootstrap the VM
  config.vm.provision "shell",
    path: "./vagrant-provision.sh",
    privileged: false
end
