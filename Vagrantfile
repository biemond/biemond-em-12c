# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|


  config.vm.define "emdb" , primary: true do |emdb|
    emdb.vm.box = "centos-6.5-x86_64"
    emdb.vm.box_url = "https://dl.dropboxusercontent.com/s/np39xdpw05wfmv4/centos-6.5-x86_64.box"

    emdb.vm.hostname = "emdb.example.com"
    emdb.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
    emdb.vm.synced_folder "/Users/edwin/software", "/software"

    emdb.vm.network :private_network, ip: "10.10.10.15"

    emdb.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm"     , :id, "--memory", "3096"]
      vb.customize ["modifyvm"     , :id, "--name"  , "emdb"]
      vb.customize ["modifyvm"     , :id, "--cpus"  , 2]
    end


    emdb.vm.provision :shell, :inline => "ln -sf /vagrant/puppet/hiera.yaml /etc/puppet/hiera.yaml;rm -rf /etc/puppet/modules;ln -sf /vagrant/puppet/modules /etc/puppet/modules"

    emdb.vm.provision :puppet do |puppet|
      puppet.manifests_path    = "puppet/manifests"
      puppet.module_path       = "puppet/modules"
      puppet.manifest_file     = "db.pp"
      puppet.options           = "--verbose --hiera_config /vagrant/puppet/hiera.yaml"

      puppet.facter = {
        "environment" => "development",
        "vm_type"     => "vagrant",
      }

    end

  end

  config.vm.define "emapp" , primary: true do |emapp|
    emapp.vm.box = "centos-6.5-x86_64"
    emapp.vm.box_url = "https://dl.dropboxusercontent.com/s/np39xdpw05wfmv4/centos-6.5-x86_64.box"

    emapp.vm.hostname = "emapp.example.com"
    emapp.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
    emapp.vm.synced_folder "/Users/edwin/software", "/software"

    emapp.vm.network :private_network, ip: "10.10.10.25"

    emapp.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm"     , :id, "--memory", "3372"]
      vb.customize ["modifyvm"     , :id, "--name"  , "emapp"]
      vb.customize ["modifyvm"     , :id, "--cpus"  , 2]
    end


    emapp.vm.provision :shell, :inline => "ln -sf /vagrant/puppet/hiera.yaml /etc/puppet/hiera.yaml;rm -rf /etc/puppet/modules;ln -sf /vagrant/puppet/modules /etc/puppet/modules"

    emapp.vm.provision :puppet do |puppet|
      puppet.manifests_path    = "puppet/manifests"
      puppet.module_path       = "puppet/modules"
      puppet.manifest_file     = "site.pp"
      puppet.options           = "--verbose --hiera_config /vagrant/puppet/hiera.yaml"

      puppet.facter = {
        "environment" => "development",
        "vm_type"     => "vagrant",
      }

    end

  end


end
