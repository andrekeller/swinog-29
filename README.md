# Puppet Vagrant Environments for SwiNOG-29

## Basic Information

Puppet configuration (/etc/puppetlabs/code/environments/production) is
mapped from the `production` folder.

To apply the changes made to the code, provisioning can be redone using

```
vagrant provision
```

Or from within the vagrant box:
```
sudo -s
cd /etc/puppetlabs/code/environments/production
/opt/puppetlabs/bin/puppet apply manifests/site.pp
```

### Basic example

The basic example will install a simple webserver that will serve the
webpage out of the `webroot` folder on:
[http://localhost:10080](http://localhost:10080).

Additional the module demonstrates how to add a system user, including
an ssh public key for authentication.

#### Used modules

 * [jfryman/nginx](http://github.com/jfryman/puppet-nginx)
 * [puppetlabs/concat](https://github.com/puppetlabs/puppetlabs-concat)
 * [puppetlabs/stdlib](https://github.com/puppetlabs/puppetlabs-stdlib)
 * [vshn/identity](https://github.com/vshn/puppet-identity)

### Librenms example

The librenms example is slightly more complex. It demonstrats the installation
of [LibreNMS](https://www.librenms.org) including database, php and nginx.

This is done within a custom module called `swinog`

After the initial puppet run, the librenms installer is available at
[https://localhost:10443](https://localhost:10443).

**IMPORTANT**: Use localhost, not 127.0.0.1 to connect. (This is an issue with
how LibreNMS handles external resources. Otherwise you wont get any CSS and 
images).

You can click through the wizard, when asked for the database password
fill in the value from `production/hieradata/common.yaml`. The key to look for
is `swinog::librenms::database_librenms_password:`.

#### Used modules

 * *swinog*: Custom module from `production/modules/swinog` 

 * [ajcrowe/supervisord](https://github.com/ajcrowe/puppet-supervisord)
 * [jfryman/nginx](http://github.com/jfryman/puppet-nginx)
 * [mayflower/php](https://github.com/mayflower/puppet-php)
 * [puppetlabs/concat](https://github.com/puppetlabs/puppetlabs-concat)
 * [puppetlabs/mysql](https://github.com/puppetlabs/puppetlabs-mysql)
 * [puppetlabs/stdlib](https://github.com/puppetlabs/puppetlabs-stdlib)
 * [puppetlabs/vcsrepo](https://github.com/puppetlabs/puppetlabs-vcsrepo)
 * [vshn/identity](https://github.com/vshn/puppet-identity)
