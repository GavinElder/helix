#
define helix::broker_instance (
  $p4brokerport,
  $p4brokertarget,
  $directory     = "/opt/perforce/servers/${title}",
  $p4ssl         = "/opt/perforce/servers/${title}/ssl",
  $logfile       = "/var/log/perforce/${title}_broker.log",
  $debuglevel    = '1',
  $adminname     = 'Perforce Admins',
  $adminphone    = '999/911',
  $adminemail    = 'perforce-admins@example.com',
  $serviceuser   = undef,
  $ticketfile    = undef,
  $redirection   = 'selective',
  $commands      = [],
  $osuser        = 'perforce',
  $osgroup       = 'perforce',
  $ensure        = 'running',
  $enabled       = true,
) {

  $instance_name = $title

  if !defined(Class['helix::broker']) {
    fail('you must declare helix::broker before declaring instances')
  }

  File {
    ensure => file,
    owner  => $osuser,
    group  => $osgroup,
    mode   => '0644',
  }

  # manage the log directory if not the default
  if $logfile == "/var/log/perforce/${title}_broker.log" and !defined(File['/var/log/perforce']) {
    file { '/var/log/perforce':
      ensure  => directory,
      require => Package[$helix::broker::pkgname],
    }
  }

  # manage the p4dctl config file
  file { "${title}_p4dctl_conf":
    path    => "/etc/perforce/p4dctl.conf.d/p4broker_${instance_name}.conf",
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('helix/p4broker_p4dctl.erb'),
    require => Package[$helix::broker::pkgname],
  }

  # manage the parent directory if it is the default and not already managed
  if $directory == "/opt/perforce/servers/${title}" and !defined(File["${title}_conf_dir"]) {
    file { "${title}_conf_dir":
      ensure  => directory,
      path    => $directory,
      require => File["${title}_p4dctl_conf"],
    }
  }

  # manage the p4ssl directory if it is the default and not already managed
  if $p4ssl == "/opt/perforce/servers/${title}/ssl" {
    if !defined(File["${title}_conf_dir"]) {
      file { "${title}_conf_dir":
        ensure  => directory,
        path    => "/opt/perforce/servers/${title}",
        require => File["${title}_p4dctl_conf"],
      }
    }
  }

  if !defined(File[$p4ssl]) {
    file { $p4ssl:
      ensure  => directory,
      mode    => '0700',
      require => File["${title}_p4dctl_conf"],
      before  => Service["${title}_p4broker_service"],
    }
  }

  # if broker is going to listen on SSL port, ensure that certificate is generated
  if $p4brokerport =~ /^ssl:/ {
    exec { "${title}-Gc":
      command     => '/usr/sbin/p4broker -Gc',
      user        => $osuser,
      environment => "P4SSLDIR=${p4ssl}",
      creates     => "${p4ssl}/privatekey.txt",
      require     => File[$p4ssl],
      notify      => Exec["${title}-Gf"],
      before      => Service["${title}_p4broker_service"],
    }
    exec { "${title}-Gf":
      command     => '/usr/sbin/p4broker -Gf',
      user        => $osuser,
      environment => "P4SSLDIR=${p4ssl}",
      refreshonly => true,
    }
  }

  file { "${title}_broker.conf":
    path    => "${directory}/broker.conf",
    content => template('helix/p4broker_conf.erb'),
  }

  service { "${title}_p4broker_service":
    ensure  => $ensure,
    start   => "/usr/sbin/p4dctl start ${instance_name}",
    stop    => "/usr/sbin/p4dctl stop ${instance_name}",
    restart => "/usr/sbin/p4dctl restart ${instance_name}",
    status  => "/usr/sbin/p4dctl status ${instance_name}",
    require => File["${title}_broker.conf"],
  }

}
