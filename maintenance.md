Maintenance
===========

Updating plugins
----------------
Although Jenkins is updated regularly as *yum* package, plugins are not updated in this way.
You have to use plugin manager to update plugins. [jenkins.open-scap.org/pluginManager](https://jenkins.open-scap.org/pluginManager/)

Do snapshots
------------
It's better to do snapshots of whole machines. Jenkins slave can be set up relatively quickly, but setting up of jenkins master can cause lots of problems. Snapshots are performed from openstack.org cloud. Please check that snapshot was created properly.

Connection to slave
-------------------
Jenkins slaves are not directly accessible from public internet due to security reasons. If you need access to them, you can connect to jenkins master and then to jenkins slaves. If master is down, you can assign public address to slave (from openstack).

* Your public keys have to be imported to jenkins master obviously.*
```
local computer $ ssh cloud-user@jenkins.open-scap.org
master $ ssh fedora22.slave
master $ cat /etc/hosts # to get all slaves names
```

Jenkins slaves are adressed via hostnames in /etc/hosts, it is better to remember and we can manage it from one place.
