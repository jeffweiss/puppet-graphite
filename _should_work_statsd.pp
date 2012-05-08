file { '10gen.repo':
  path   => '/etc/yum.repos.d/10gen.repo',
  ensure => present,
  source => 'file:///root/manifests/source/10gen.repo',
}
package { 'mongodb-client':
  name    => 'mongo-10gen',
  ensure  => installed,
  require => File['10gen.repo'],
}
package { 'mongodb-server':
  name    => 'mongo-10gen-server',
  ensure  => installed,
  require => File['10gen.repo'],
}
service { 'mongod':
  ensure     => running,
  enable     => true,
  hasstatus  => true,
  hasrestart => true,
}
package { 'graphite-web':
  ensure => installed,
  provider => 'rpm',
  source => 'file:///root/manifests/source/graphite-web-0.9.9-1.noarch.rpm',
}
package { 'whisper':
  ensure => installed,
  provider => 'rpm',
  source => 'file:///root/manifests/source/whisper-0.9.9-1.noarch.rpm',
}
package { 'carbon':
  ensure => installed,
  provider => 'rpm',
  source => 'file:///root/manifests/source/carbon-0.9.9-1.noarch.rpm',
}
file { 'carbon.conf':
  path => '/opt/graphite/conf/carbon.conf',
  source => 'file:///root/manifests/source/carbon.conf',
  require => Package['carbon'],
}
file { 'storage-schemas.conf':
  path => '/opt/graphite/conf/storage-schemas.conf',
  source => 'file:///root/manifests/source/storage-schemas.conf',
  require => Package['carbon'],
}
file { 'local_settings.py':
  path => '/opt/graphite/webapp/graphite/local_settings.py',
  source => 'file:///root/manifests/source/local_settings.py',
  require => Package['graphite-web'],
}

package { 'rubygems':
  ensure => installed,
}
package { 'make': 
  ensure => installed,
}
package { 'gcc-c++':
  ensure => installed,
}
package {'bson_ext':
  provider => 'gem',
  require => [Package['rubygems'], Package['make'], Package['gcc-c++']],
}
package {'statsd':
  provider => 'gem',
  require => Package['bson_ext'],
}
file { '/etc/statsd':
  ensure => directory,
}
file { 'statsd_config':
  ensure => present,
  recurse => true,
  path => '/etc/statsd/config.yaml',
  source => 'file:///root/manifests/source/statsd.conf.yaml',
  notify => Service['statsd'],
  require => File['/etc/statsd'],
}
service {'carbon-cache':
  binary => 'PYTHONPATH=/usr/local/lib/python2.6/dist-packages/ /opt/graphite/bin/carbon-cache.py start',
  ensure => running,
  provider => 'base',
  pattern => 'carbon-cache',
  require => File['graphite_storage'],
}
service {'statsd':
  binary => '/usr/bin/statsd -c /etc/statsd/config.yaml -g > /dev/null &',
  ensure => running,
  provider => 'base',
  pattern => 'statsd',
  require => [Package['statsd'], File['statsd_config']],
}
package {'httpd':
  ensure => installed,
}
service {'httpd':
  ensure => running,
  enable => true,
  hasrestart => true,
  hasstatus => true,
  require => Package['httpd'],
}
file {'graphite.conf':
  ensure => present,
  path => '/etc/httpd/conf.d/graphite.conf',
  source => 'file:///root/manifests/source/graphite.conf',
  require => [Package['graphite-web'], Package['httpd'], Package['mod_python'], Package['python-sqlite2'], Package['python-zope-interface']],
  notify => Service['httpd'],
}
file {'graphite_storage':
  path => '/opt/graphite/storage',
  ensure => directory,
  recurse => true,
  owner => 'apache',
  group => 'apache',
  mode => 775,
  require => [Package['httpd'], Package['graphite-web']],
  notify => Service['httpd'],
}
package { 'mod_python':
  ensure => installed,
  require => [Package['epel'], Package['httpd']],
}
package {'epel':
  ensure => installed,
  name => 'epel-release',
  provider => 'rpm',
  source => 'file:///root/manifests/source/epel-release-6-5.noarch.rpm',
}
package {'python-sqlite2':
  ensure => installed,
}
package {'python-zope-interface':
  ensure => installed,
}
package {'Django':
  ensure => installed,
}
package {'pycairo':
  ensure => installed,
}
package {'bitmap':
  ensure => installed,
}
package {'bitmap-fonts-compat':
  ensure => installed,
}
package {'django-tagging':
  ensure => installed,
}
package {'python-twisted':
  ensure => installed,
}
exec { 'syncdb':
  cwd => '/opt/graphite/storage',
  command => '/usr/bin/python /opt/graphite/webapp/graphite/manage.py syncdb',
  creates => '/opt/graphite/storage/graphite.db',
  require => File['graphite_storage'],
}
service { 'iptables':
  ensure => stopped,
  enable => false,
}
