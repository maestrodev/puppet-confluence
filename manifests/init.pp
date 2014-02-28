# == Class: confluence
#
# Install Confluence from standalone including a user and service
#
# === Parameters
#
# [*version*]
#   The version of Confluence to install. No default is supplied.
#
# [*user*]
#   A user to create and use to run Confluence under. The default is
#   'confluence'.
#
# [*group*]
#   A group to create and add the Confluence user to. The default is
#   'confluence'.
#
# [*installroot*]
#   Where to unpack Confluence to. The actual Confluence directory will be
#   _installroot_/atlassian-confluence-_version. The default is '/usr/local'
#
# [*homedir*]
#   Home directory for the confluence user. The default is
#   '/var/local/confluence'.
#
# [*datadir*]
#   Where Confluence stores its data (confluence.home). The default is
#   '/var/local/confluence/data'.
#
# [*download_url*]
#   Where to download Confluence from (omitting the filename). Useful for
#   overriding with a local storage.
#
# === Variables
#
# === Examples
#
#  class { confluence:
#    version => '5.4.3',
#  }
#
# === Authors
#
# Brett Porter <brett@maestrodev.com>
#
# === Copyright
#
# Copyright 2014 MaestroDev, Inc.
#
class confluence(
  $version,
  $user         = 'confluence',
  $group        = 'confluence',
  $installroot  = '/usr/local',
  $homedir      = '/var/local/confluence',
  $datadir      = '/var/local/confluence/data',
  $download_url = 'http://www.atlassian.com/software/confluence/downloads/binary',
) {
  Exec { path => "/usr/bin:/usr/sbin/:/bin:/sbin" }

  $installname = "atlassian-confluence-${version}"
  $installdir = "${installroot}/${installname}"

  if !defined(Group[$group]) {
    group { $group:
      ensure => present,
      system => true,
    }
  }
  if !defined(User[$user]) {
    user { $user:
      gid    => $group,
      home   => $homedir,
      system => true,
      shell  => '/bin/false',
    } ->
    file { $homedir:
      ensure => directory,
      owner  => $user,
      group  => $group,
    }
  }

  include deploy

  # Note: doesn't really handle an upgrade. You'll need to stop the service
  # before running Puppet and perform any upgrade steps
  deploy::file { "${installname}.tar.gz":
    target => $installdir,
    url    => $download_url,
    strip  => true,
    #owner  => $user,
    #group  => $group,
  } ->
  # remove when above parameters are in released module
  exec { "chown -R $user:$group $installdir": } ->
  file { "${installdir}/confluence/WEB-INF/classes/confluence-init.properties":
    content => template("confluence/confluence-init.properties.erb"),
    owner   => $user,
    group   => $group,
  } ->
  file { $datadir:
    ensure => directory,
    owner  => $user,
    group  => $group,
  }

  file { "/etc/init.d/confluence":
    content => template("confluence/confluence.erb"),
    owner   => root,
    group   => root,
    notify  => Service[confluence],
  }

  service { confluence:
    enable => true,
    ensure => running,
  }
}

