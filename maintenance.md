Maintenance
===========
Update systems
--------------
We run dnf/yum on our machines every weekend. This should be done by [jenkins jobs](https://jenkins.open-scap.org/view/System%20updates/). Make sure that the jobs are green and don't have results older than week.
When jenkins packages are updated on master, job will not finish and we don't know results. It is reason why we run later ```yum check-update``` to ensure, that system use latest packages.

Updating plugins
----------------
Although Jenkins is updated regularly as *yum* package, plugins are not updated in this way.
You have to use plugin manager to update plugins. [jenkins.open-scap.org/pluginManager](https://jenkins.open-scap.org/pluginManager/)

Certificate
-----------
Currently we use certificate [Lets' Encrypt](https://letsencrypt.org/). They require to renewal of certificate at least every [3 months](http://letsencrypt.readthedocs.org/en/latest/using.html#renewal). This should be done by [jenkins job](https://jenkins.open-scap.org/view/System%20updates/job/UPDATE-MASTER-lets-encrypt/). Please make sure, that the job isn't failing.

Snapshots
------------
It's better to make snapshots of whole machines. Jenkins slave can be set up relatively quickly, but setting up of jenkins master can cause lots of problems. Snapshots are performed from openstack.org cloud. Please check that snapshot was created properly.

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

Cleanning up space
------------------
The machine may run low on disk storage, when this happens jobs start to fail.
All you need to do is clean up space in the machine, i.e. clean data from yum, or delete old workspaces.

### Corner Case ###
When the job that updates the machine fails, and there is an update for java. You may fall into a strange situation.

Eventually the machine will be cleaned, and have enough disk space to work, but the Master Node may still be reporting not enough disk space.
What happens is that if the java version expected by Master Node does not match the one installed in the Slave Node, the slave won't start. And Master will collect the error log from the machine to show admins what is happening. But as the slave didn't start, it did not update the error log, so Master node will report the slave as not having enough disk space, which is inaccurate.

To fix this just execute a `yum update` manually and reboot the node.

Rebooting slaves
----------------
Sometimes the slaves can get stuck or start throwing strange Java exceptions. The most probably solution to both is rebooting the machine.

SSH into the slave using instructions in the previous section, then type `sudo reboot`. Wait until the machines restart, then login to Jenkins master and verify that the machines are available now. You can manually tell Jenkins master to connect the slaves and speed-up the process, login to Jenkins master, go to https://jenkins.open-scap.org/computer/, select the slave that needs restarting and press "Launch".
