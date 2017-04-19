# Openscap-jenkins configuration
This document should describe configuration of Jenkins used by OpenSCAP project.

It is not easy to describe processes on different systems (RHEL6, RHEL7, Fedora), so maybe you have to use some alternative of command yum/dnf etc.
This document describes current settings. You maybe want to use different configuration - different cloud, different systems etc. There should be described basic steps.

Note:
	When you see "*OS:*" in text, it means *OpenStack* settings.

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

### How to get machines on OpenStack
1. (Get OpenStack acc and login)
1. *Import your key* (OS: Access & Security / Key Pairs tab) before you create any machine!
    + Usually you don't know any password on the virtual machine
    + This option injects your keys into machine during its creation process.
    + Might be good idea to import key from Master node
1. Create master and slaves machines (example)
    + OS: Instances =>
        + Launch Instance
            + Flavor: m1.large
        + Boot from image
            + *Fedora cloud 22*
        + Launch
1. Now you have machine somewhere in the cloud and you have to get access to the machine:
    + Get *public IP* (at least for master)
        + OS: Access & Security / Floating IPs > Allocate IP to Project
        + OS: Select IP -> Associate -> select instance
    + *Manage access to machines* (= open ports)
        + OS: Access & Security / Security Groups
            + You probably need to create Rules (OS: Groups/Rules) which enable you access to *ssh*, *http*s.
        + You can restrict SSH only for Red Hat Subnet etc.
        + **Jenkins** master needs (ssh/tcp) :56917 port allowed
            + You can connect to this port using ssh.
            + Jenkins provides you tunnel to slaves(last build, etc) via this port.

### How to connect to the machine
+ Note: depending on the image used for installation, node might be created with user other than 'cloud-user'. Check console output, and search for part where public key is imported to get a username.
#### Connect to your Master
Master has public IP address, so simply using ```ssh cloud-user@<master ip>``` should be enough. 'cloud-user' has your public key imported, and has sudo access.

#### Connect to a slave machine
Slave machines usually do not hold public IP, Master node has access to them, though. That means there are at least three ways how to access the machine.
1. Assign *public* (floating) *IP* to our slave using OpenStack
1. Use *port forwarding* from master to slave (use your public key)
    + use ```ssh -L 2222:<slave-ip>:22 cloud-user@<master-ip>``` forward ssh port to slave
    + connect to slave via redirected port ```ssh cloud-user@localhost -p 2222```
1. Connect directly *from master to slave*
    + for this, we need to import master public key into slave authorized_keys first


## Configuration of Master node
### Install Jenkins software
- add repo https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Red+Hat+distributions
- ```# yum install jenkins```
- start and enable jenkins service
	- ```# systemctl enable jenkins; systemctl start jenkins```

### Configure Jenkins
#### Important files & paths
 - **/var/lib/jenkins/**
	- Complete configuration folder storage
 - **/var/lib/jenkins/config.xml**
	- Contain main configuration & **security** settings:
		- Matrix-based security rules. (If you want to change security settings, backup this file first.)
		- If you completely lose admin rights for settings of Jenkins, it is file which you need to modify.
 - **/usr/lib/jenkins/jenkins.war**
	- Jenkins java archive - probably you don't want to modify/update it manually
 - *TIP*: when you lose root access and need to backup jenkins settings files, you can run job on master(=as 'jenkins' user) to get access to config files.

#### Plugins
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
+ Install nginx
+ Create folder available from http to allow letsencrypt script to public authentication files
+ Create nginx configuration
+ Get certificate/Create jenkins-job to renew certificates regularly
+ *Check permissions of generated files which should be private*

##### ~~Self-signed certificate~~
We have started to use https://letsencrypt.org/ certificate. If you still want to use self-signed certificate, use some older git revision of this file.
##### Lets encrypt certificate
+ Download let-encrypt
    + ```git clone https://github.com/letsencrypt/letsencrypt``` - use some persistent folder (we want to use this repo also for regular renews)
+ We will use webroot authentification, so we don't have to stop our nginx server to authenticate.
+ Create folder ```/lets-encrypt```
+ ```sudo chcon -Rt httpd_sys_content_t /lets-encrypt/``` set selinux permission
+ Create the script to renew certificate - chmod 500 to this file - user jenkins should not be able to modify this file
+ ```$PATH_TO_REPO/letsencrypt-auto certonly --webroot -w /lets-encrypt/ -d jenkins.open-scap.org --renew-by-default```
+ Add jenkins to sudoers to allow run the script with sudo/without password
+ Currently lets-encrypt has *beta* program, so we have to renew certificate at least every 3 months. You can create jenkins-job to solve this as well as yum update.
+ *Useful links*
    + http://letsencrypt.readthedocs.org/en/latest/using.html
    + https://blog.rudeotter.com/lets-encrypt-ssl-certificate-nginx-ubuntu/

#### Nginx
+ **Add Nginx**
	+ http://wiki.nginx.org/Install#Official_Red_Hat.2FCentOS_packages
+ **Configure Nginx**
	+ Add file to /etc/nginx/conf.d/jenkins.conf
```
upstream jenkins {
  server 127.0.0.1:8080 fail_timeout=0;
}

server {
  listen 80 default;
  server_name jenkins.open-scap.org;
  rewrite ^ https://$server_name$request_uri? permanent;
}

server {
  listen 443 ssl spdy;
  server_name 209.132.179.114 jenkins.open-scap.org;
  ssl_certificate /etc/letsencrypt/live/jenkins.open-scap.org/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/jenkins.open-scap.org/privkey.pem;

  ssl_session_timeout  60m;
  ssl_protocols  TLSv1.1 TLSv1.2;

  ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK';

ssl_prefer_server_ciphers on;

  add_header Strict-Transport-Security max-age=15768000;

  # auth_basic            "Restricted";
  # auth_basic_user_file  /home/jenkins/htpasswd;

  ssl_trusted_certificate /etc/letsencrypt/live/jenkins.open-scap.org/chain.pem;
  resolver 8.8.8.8 8.8.4.4 valid=86400;
  resolver_timeout 10;

  # lets-encrypt certificate
  location  /.well-known/ { alias /lets-encrypt/.well-known/;}

location / {
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_redirect http:// https://;

    add_header Pragma "no-cache";

    proxy_pass http://jenkins;
  }
}

```
+ Run the script

+ **Enable and run nginx service**
	+ ```# systemctl enable nginx; systemctl start nginx```

## Configuration of slave node
+ Create **jenkins** user
	+ ```# adduser jenkins```
	+ ```# passwd jenkins``` and type password
+ Setup ssh to accept password authentification
	+ sudo vi */etc/ssh/sshd_config*
	+ set: *PasswordAuthentication yes*
	+ restart sshd ```# systemctl restart sshd```
+ Install wget
+ 	+ ```yum install wget```
+ Install java
	+ **NOTE** As of Jenkins version ```2.54```, ```java-1.8``` is required!
	+ ```# dnf install "java-1.8.0-openjdk``` or ```# yum install java-1.8.0-openjdk```
	+ Jenkins can install java on slave itself, but we want to have Java as package maintaned by yum/dnf.
	+ *Fedora packages*
		+ SCAP Workbench dependencies
			+ ```# dnf install rubygem-asciidoctor openscap-devel zip```
			+ (master branch)
				+ ```# dnf install git gcc-c++ qt5-qtbase-devel qt5-qtxmlpatterns-devel # workbench-master```
		+ ```# dnf install ShellCheck```


	+ *Common packages*
		+ ``` # yum builddep openscap scap-workbench scap-security-guide scap-security-guide-doc```
		+ ``` # yum install rpm-devel libcurl-devel libxml2-devel libxslt-devel pcre-devel python-devel``` -- without builddep
		+ ``` # yum groupinstall "Development Tools"```
		+ ``` # yum install git libtool perl-XML-XPath valgrind sendmail asciidoc```
		+ ``` # yum install bzip2-devel```
		+ ``` # yum install libselinux-devel```
		+ ``` # yum install openscap-scanner``` - required by SSG
	+ asciidoctor on RHEL6/RHEL7
		+ ``` # yum install rubygems && gem install asciidoc ```
		+ ``` # yum install rubygems && gem install asciidoctor ```
	+ scap-workbench
		+ ``` # dnf install gcc-c++ ```
	+ openscap-daemon
		+ ``` # dnf install dbus-python gobject-introspection python3-gobject-base pygobject2-devel pygobject3-devel python3-dbus```

	+ Enable/Start sendmail service ( mitre test requires it)
		+ ``` # systemctl enable sendmail ; # systemctl start sendmail ```


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
Currently, keeping packages on the nodes up to date is done via Jenkins jobs. Also it's preferable to utilize 'yum' command even for DNF-enabled nodes, so one project can handle all nodes.
For jenkins to be able to trigger updates, you need to allow 'jenkins' user passwordless sudo for yum commands
1. Use ```# visudo``` to edit /etc/sudoers.
2. Get path of yum/dnf: ```which yum```.
3. Allow jenkins user to run the file as sudo without password, add to sudoers file:

    ```jenkins		ALL=(ALL)	NOPASSWD:/bin/yum update -y```
4. Some systems don't allow sudo without tty(=you cannot use sudo from jenkins job), you have to add  ```Defaults:jenkins !requiretty``` after ```Defaults    requiretty``` in sudoers
    + (There was bug with visudo in RHEL7 - it allows you to store non valid sudoers and you lose completely access via sudo)

#### Jenkins update on Master node
Create separate job which updates only the Jenkins package. It is sufficient to run it once a week.

#### Packages update
Best to use multi-configuration project and enabling all the nodes in it.
+ Build triggers set to 'Build periodically'.
+ Shedule ```H 0 * * 7``` - It means every sunday about midnight. Jenkins provides examples when the job will by started.
+ To Build step add "Execute shell" with ```sudo yum update -y``` as context(or use dnf).


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


