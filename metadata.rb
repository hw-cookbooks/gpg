name             'gpg'
maintainer       'Sous Chefs'
maintainer_email 'help@sous-chefs.org'
license          'Apache-2.0'
description      'Installs/Configures gpg'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
source_url       'https://github.com/sous-chefs/gpg'
issues_url       'https://github.com/sous-chefs/gpg/issues'
version          '1.0.0'
chef_version     '>= 13'

depends 'yum-epel'

supports 'debian'
supports 'ubuntu'
supports 'centos'
supports 'redhat'
supports 'oracle'
supports 'amazon'
