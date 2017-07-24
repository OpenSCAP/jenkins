# Openscap-jenkins configuration
This document should describe configuration of Jenkins used by OpenSCAP project.

It is not easy to describe processes on different systems (RHEL6, RHEL7, Fedora), so maybe you have to use some alternative of command yum/dnf etc.
This document describes current settings. You maybe want to use different configuration - different cloud, different systems etc. There should be described basic steps.

## What is Jenkins:
+ Jenkins is a piece of java software to make testing easier etc.
+ You can shedule testing regularly, run manually, or trigger tests by some events (push to git repository, ...)
+ It's infrastructure consists of:
	+ 1 *Master*
		+ Computer with running Jenkins CI software.
		+ Provides http interface.
		+ Starts some jobs on slaves.
		+ Master can perform slaves routines too.
		+ Connects to slaves e.g. using ssh.
	+ 0..n *Slave*s
		+ "dummy" computers doing the hard work (compiling, testing)

## Get some machines
+ You need some machines to do testing.
+ Usually you want to have different systems to do tests.
+ Theoretically you can use bare metal machines, virtual machines, containers etc.
+ We currently run Jenkins on AWS

### How to connect to the machine
We use Ansible for orchestration of the entire Jenkins infrastructure. Please see the
inventory.ini file for a list of machines and their IPs. These machines currently run
in AWS. If you want your public key added to those machines please contact the admin
that maintains the AWS account.

### Important files & paths on Jenkins master
 - **/var/lib/jenkins/**
	- Complete configuration folder storage
 - **/var/lib/jenkins/config.xml**
	- Contain main configuration & **security** settings:
		- Matrix-based security rules. (If you want to change security settings, backup this file first.)
		- If you completely lose admin rights for settings of Jenkins, it is file which you need to modify.
 - **/usr/lib/jenkins/jenkins.war**
	- Jenkins java archive - probably you don't want to modify/update it manually
 - *TIP*: when you lose root access and need to backup jenkins settings files, you can run job on master(=as 'jenkins' user) to get access to config files.

### Plugins
 + Jenkins provides some set of default plugins
 + "Important" plugins to install:
	+ *Github Authentication plugin*
		+ Provide access using GitHub account
	+ *GitHub plugin*
		+ Allow to trigger build when somebody push changes to branch (master/ maint branches)
	+ *GitHub Pull Request Builder*
		+ Allow to trigger build when somebody create pull request/ push commit to pull request
		+ Set status on GitHub
	+ *Role-based Authorization Strategy*
		+ Allow manage user rights as roles
 + Please avoid installing plugins manually, instead edit the ansible playbook. See the `master.yml` playbook.

#### GitHub Integration
 + *GitHub Auth*
	+ Settings:
		+ Jenkins/Configure Global Security/Access Control/Security Realm/
			+ select Github Authentication Plugin
			+ add admin rights to your GitHub acc before you logout!
	+ Create *GitHub application* https://github.com/settings/applications/new
		+	(is already created by user openscap-jenkins user)
		+	fill *Client ID* and *Client Secret* from the app
 + *WebHooks*
	+ When you do some action with GitHub repo, it can call you via "webhooks"
	+ (When you don't use webhooks, you can use polling from jenkins server)
	+ You need to setup *2 types* of hooks for changes in branch and for pull requests - select setting on your repository
		+ *GitHub Pull Request Builder*
			+ hook url: *https://jenkins.open-scap.org/ghprbhook/*
				+ required GitHub hooks 'issue_comment, pull_request'
			+ "The user needs to have push rights for your repository (must be collaborator (user repo) or must have Push & Pull rights (organization repo))."
			+ "If you want to use GitHub hooks have them set automatically the user needs to have administrator rights for your repository (must be owner (user repo) or must have Push, Pull & Administrative rights (organization repo))"
		+ *GitHub plugin*
			+ hook url: *https://jenkins.open-scap.org/github-webhook/*
			+ Add service Jenkins (GitHub plugin)

### Add Https support
Please consult the /root/letsencrypt.sh shell script for how to get certificates and deploy them to nginx.
This script runs monthly so unless something breaks there is no need to trigger it manually.

### Nginx
Nginx and its configuration is handled by Ansible playbook. See the `master.yml` playbook.

## Configuration of slave node
This is handled by the Ansible playbook. PLease see the `workers.yml` playbook.

## Project Configuration
### Create new Projects
+ **Pull requests**
	+ Build Triggers: GitHub Pull Request Builder
	+ set White list:
		+ List of users. If someone from the group will create pull request, job will be automatically started.
	+ set Admin list:
		+ List of users. If someone who is not from White list create pull request. Users from admin list can enable building for the pull request.
+ **GitHub* builder**
	+ Build Triggers: Build when a change is pushed to GitHub

### Yum/DNF Updates
System updates are handled via cronie and yum-cron packages. This is deployed via ansible playbook. Please see `shared.yml` for more details.

## Possible issues
+ Subscription issue:
    - There is problem, that domanins requested due to subscriptions are resolved by "bad" DNS server and we don't get IP adress accessible from out machine
    - Do you have this problem?
        + $ ping xmlrpc.rhn.redhat.com - you will get IP adress, but cannot ping it
    - Fix:
        + /etc/resolv.conf
            - add 'nameserver 8.8.8.8' to
        + edit /etc/sysconfig/network-scripts/ifcfg-eth0
            - set 'PEERDNS="no"'
            - add/replace 'DNS1=8.8.8.8'
        + reboot & try $ ping xmlrpc.rhn.redhat.com
+ 502 error from nginx - bad gateway
    - setsebool httpd_can_network_connect on -P
