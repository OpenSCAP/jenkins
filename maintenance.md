Maintenance
===========

Updating plugins
----------------
Although Jenkins is updated regularly as *yum* package, plugins are not updated in this way.
You have to use plugin manager to update plugins. [jenkins.open-scap.org/pluginManager](https://jenkins.open-scap.org/pluginManager/)

Certificate
-----------
Currently we use certificate [Lets' Encrypt](https://letsencrypt.org/). They require to renewal of certificate at least every 3 months (http://letsencrypt.readthedocs.org/en/latest/using.html#renewal). This should be done by jenkins job (https://jenkins.open-scap.org/view/System%20updates/job/UPDATE-MASTER-lets-encrypt/). Please make sure, that the job isn't failing.

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

Rebooting slaves
----------------
Sometimes the slaves can get stuck or start throwing strange Java exceptions. The most probably solution to both is rebooting the machine.

SSH into the slave using instructions in the previous section, then type `sudo reboot`. Wait until the machines restart, then login to Jenkins master and verify that the machines are available now. You can manually tell Jenkins master to connect the slaves and speed-up the process, login to Jenkins master, go to https://jenkins.open-scap.org/computer/, select the slave that needs restarting and press "Launch".
