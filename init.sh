#!/bin/bash

set -x

# Usage: init.sh --role webserver --environment prod1 --site a --repouser jimfdavies --reponame provtest-config

VERSION=0.0.1

# Install Puppet
# RHEL
yum install -y http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
yum install -y puppet-3.4.3

# Process command line params

function print_version {
  echo $1 $2
}

function print_help {
  echo Heeelp.
}

function set_facter {
  export FACTER_$1=$2
  puppet apply -e "file { '/etc/facter': ensure => directory, mode => 0755 }" --logdest syslog
  puppet apply -e "file { '/etc/facter/facts.d': ensure => directory, mode => 0755 }" --logdest syslog
  puppet apply -e "file { '/etc/facter/facts.d/$1.txt': ensure => present, mode => 0755, content => '$1=$2' }" --logdest syslog
  echo "Facter says $1 is..."
  facter $1
}

while test -n "$1"; do
  case "$1" in
  --help|-h)
    print_help
    exit 
    ;;
  --version|-v) 
    print_version $PROGNAME $VERSION
    exit
    ;;
  --role|-r)
    set_facter init_role $2
    shift
    ;;
  --environment|-e)
    set_facter init_env $2
    shift
    ;;
  --repouser|-u)
    set_facter init_repouser $2
    shift
    ;;
  --reponame|-n)
    set_facter init_reponame $2
    shift
    ;;
  --repoprivkeyfile|-k)
    set_facter init_repoprivkeyfile $2
    shift
    ;;
  --repobranch|-b)
    set_facter init_repobranch $2
    shift
    ;;
  --repodir|-d)
    set_facter init_repodir $2
    shift
    ;;
  *)
    echo "Unknown argument: $1"
    print_help
    exit
    ;;
  esac
  shift
done

usagemessage="Error, USAGE: $(basename $0) --role|-r --environment|-e --repouser|-u --reponame|-n --repoprivkeyfile|-k [--repobranch|-b] [--repodir|-d] [--help|-h] [--version|-v]"

# Define required parameters.
if [[ "$FACTER_init_role" == "" || "$FACTER_init_env" == "" || "$FACTER_init_repouser" == "" || "$FACTER_init_reponame" == "" || "$FACTER_init_repoprivkeyfile" == "" ]]; then
  echo $usagemessage
  exit 1
fi

# Set Git login params
GITHUB_PRI_KEY=$(cat $FACTER_init_repoprivkeyfile)
puppet apply -v -e "file {'ssh': path => '/root/.ssh/',ensure => directory}"
puppet apply -v -e "file {'id_rsa': path => '/root/.ssh/id_rsa',ensure => present, mode    => 0600, content => '$GITHUB_PRI_KEY'}"
puppet apply -v -e "file {'config': path => '/root/.ssh/config',ensure => present, mode    => 0644, content => 'StrictHostKeyChecking=no'}"
puppet apply -e "package { 'git': ensure => present }"

# Set some defaults if they aren't given on the command line.
[ -z "$FACTER_init_repobranch" ] && set_facter init_repobranch master
[ -z "$FACTER_init_repodir" ] && set_facter init_repodir /opt/$FACTER_init_reponame
# Clone private repo.
puppet apply -e "file { '$FACTER_init_repodir': ensure => absent, force => true }"
git clone -b $FACTER_init_repobranch git@github.com:$FACTER_init_repouser/$FACTER_init_reponame.git $FACTER_init_repodir

# Link /etc/puppet to our private repo.
PUPPET_DIR="$FACTER_init_repodir/puppet"
rm -rf /etc/puppet ; ln -s $PUPPET_DIR /etc/puppet
puppet apply -e "file { '/etc/hiera.yaml': ensure => link, target => '/etc/puppet/hiera.yaml' }"

# Install and execute Librarian Puppet
# Create symlink to role specific Puppetfile
rm -f /etc/puppet/Puppetfile ; ln -s /etc/puppet/Puppetfiles/Puppetfile.$FACTER_init_role /etc/puppet/Puppetfile
gem install librarian-puppet --no-ri --no-rdoc
cd $PUPPET_DIR
librarian-puppet install --verbose
librarian-puppet update --verbose
librarian-puppet show

# Make things happen.
puppet apply /etc/puppet/manifests/site.pp
