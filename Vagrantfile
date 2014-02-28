# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "centos64-x86_64-20131030"
  config.vm.box_url = "https://github.com/2creatives/vagrant-centos/releases/download/v0.1.0/centos64-x86_64-20131030.box"

  config.ssh.forward_agent = true
  config.vm.network "private_network", ip: "192.168.200.201"

  # Use a proxy if environment variables are set.
  if ENV['internet_proxy_host']
    config.proxy.http = "http://#{ENV['internet_proxy_host']}:#{ENV['internet_proxy_port']}"
    config.proxy.https = "http://#{ENV['internet_proxy_host']}:#{ENV['internet_proxy_port']}"
    config.proxy.no_proxy = "localhost,127.0.0.1"

    puts "Using proxy http://#{ENV['internet_proxy_host']}:#{ENV['internet_proxy_port']}"
  else
    puts "Not using a proxy"
  end

  # Assign environment variables to local variables, these should be set as follows:
  # export init_env=prod

  # Required Environment Variables
  if ENV['init_role']
    $init_role = ENV['init_role']
  else
    abort("Environment variable: 'init_role' is not set, exiting ...")
  end

  if ENV['init_env']
    $init_env = ENV['init_env']
  else
    abort("Environment variable: 'init_env' is not set, exiting ...")
  end

  if ENV['init_repoprivkeyfile']
    $init_repoprivkeyfile = ENV['init_repoprivkeyfile']
  else
    abort("Environment variable: 'init_repoprivkeyfile' is not set, exiting ...")
  end

  # Optional Environment Variables
  if ENV['init_repouser']
    $init_repouser = ENV['init_repouser']
  else
    puts "Environment variable: 'init_repouser' is not set, defaulting to 'MSMFG'"
    $init_repouser = 'MSMFG'
  end

  if ENV['init_reponame']
    $init_reponame = ENV['init_reponame']
  else
    puts "Environment variable: 'init_reponame' is not set, defaulting to 'msm-provisioning'"
    $init_reponame = 'msm-provisioning'
  end

  if ENV['init_repobranch']
    $init_repobranch = ENV['init_repobranch']
  else
    puts "Environment variable: 'init_repobranch' is not set, defaulting to 'master'"
    $init_repobranch = 'master'
  end

  # Tru-Strap
  config.vm.provision :shell, :path => "init.sh", :args => "--role #{$init_role} --environment #{$init_env} --repouser #{$init_repouser} --reponame #{$init_reponame} --repoprivkeyfile #{$init_repoprivkeyfile}"

end
