#
define helix::proxy_instance (
  $p4proxyport,
  $p4proxytarget,
  $cachedir      = "/opt/perforce/servers/${title}",
  $logfile       = "/var/log/perforce/${title}_proxy.log",
  $osuser        = 'perforce',
  $osgroup       = 'perforce',
  $ensure        = 'running',
  $enabled       = true,
) {

  $instance_name = $title

  if !defined(Class['helix::proxy']) {
    fail('you must declare helix::proxy before declaring instances')
  }

  File {
    ensure => file,
    owner  => $osuser,
    group  => $osgroup,
    mode   => '0644',
  }

  if $logfile == "/var/log/perforce/${title}_proxy.log" and !defined(File['/var/log/perforce']) {
    file { '/var/log/perforce':
      ensure  => directory,
      require => Package[$helix::proxy::pkgname],
    }
  }

  # manage the p4dctl config file
  file { "${title}_p4dctl_conf":
    path    => "/etc/perforce/p4dctl.conf.d/p4proxy_${instance_name}.conf",
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('helix/p4proxy_p4dctl.erb'),
    require => Package[$helix::proxy::pkgname],
  }

  # manage the cache directory if it is the default
  if $cachedir == "/opt/perforce/servers/${title}" {
    file { "${title}_conf_dir":
      ensure  => directory,
      path    => $cachedir,
      require => File["${title}_p4dctl_conf"],
      before  => Service["${title}_p4proxy_service"],
    }
  }

  service { "${title}_p4proxy_service":
    ensure  => $ensure,
    start   => "/usr/sbin/p4dctl start ${instance_name}",
    stop    => "/usr/sbin/p4dctl stop ${instance_name}",
    restart => "/usr/sbin/p4dctl restart ${instance_name}",
    status  => "/usr/sbin/p4dctl status ${instance_name}",
    require => File["${title}_p4dctl_conf"],
  }

}
