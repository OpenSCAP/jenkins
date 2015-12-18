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


## 1. Get some machines
+ You need some machines to do testing.
+ Usually you want to have different systems to do tests.
+ Theoretically you can use bare metal machines, virtual machines, containers etc.
+ How to get machines on OpenStack:
	1. (Get OpenStack acc and login)
	2. *Import your key* (OS: Access & Security / Key Pairs tab) before you create any machine!
		+ Usually you don't know any password on the virtual machine
		+ This option injects your keys into machine during its creation process.
	3. Create master and slaves machines (example)
		+ OS: Instances =>
			+ Launch Instance
				+ Flavor: m1.large
			+ Boot from image
				+ *Fedora cloud 22*
			+ Launch
	4. Now you have machine somewhere in the cloud and you have to get acces to the machine:
		+ Get *public IP* (at least for master)
			+ OS: Acess & Security / Floating IPs > Allocate IP to Project
			+ OS: Select IP -> Associate -> select instance
		+ *Manage access to machines* (= open ports)
			+ OS: Acess & Security / Securit Groups
				+ You probably need to create Rules (OS: Groups/Rules) which enable you access to *ssh*, *http*s.
			+ You can restrict SSH only for Red Hat Subnet etc.
			+ **Jenkins** master needs (ssh/tcp) :56917 port allowed
				+ You can connect to this port using ssh.
				+ Jenkins provides you tunnel to slaves(last build, etc) via this port.
 

## 2. Connect to your Master
 + Usually you can simply connect using ```ssh cloud-user@<master ip>```
	+ 'cloud-user' has imported your public key.
 + (maybe some images have different settings - you have to use google etc.)
 
 
## 3. Install Jenkins software on your Master
- add repo https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Red+Hat+distributions
- ```# yum install jenkins```
- start and enable jenkins service
	- ```# systemctl enable jenkins; systemctl start jenkins```


## 4. Configure jenkins
### 4.1 Important files & paths
 - **/var/lib/jenkins/**
	- Complete configuration folder storage
 - **/var/lib/jenkins/config.xml**
	- Contain main configuration & **security** settings:
		- Matrix-based security rules. (If you want to change security settings, backup this file first.)
		- If you completely lose admin rights for settings of Jenkins, it is file which you need to modify.
 - **/usr/lib/jenkins/jenkins.war**
	- Jenkins java archive - probably you don't want to modify/update it manually
 - *TIP*: when you lose root acces and need to backup jenkins settings files, you can run job on master(=as 'jenkins' user) to get access to config files.
 
### 4.2 Plugins
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

### 4.3 GitHub Integration
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
			
 
### 4.4 Access to slaves
+ We have access to master using public IP, but not to slaves. Fortunatelly master has access to slaves.
+ We have at least 3 ways how to access to slaves:
	+ Assign *public* (floating) *IP* to our slave using OpenStack
	+ Use *port forwarding* from master to slave (use your public key)
		+ use ```ssh -L 2222:172.18.152.10:22 cloud-user@209.132.179.114``` forward ssh port to slave
		+ connect to slave via redirected port ```ssh cloud-user@localhost -p 2222``` 
	+ Connect *from master to slave*
		+ First, we need to import master public key into slave authorized_keys
	
### 4.5 Slave setup
+ Create **jenkins** user
	+ ```# adduser jenkins```
	+ ```# passwd jenkins``` and type password
+ Setup ssh to accept password authentification
	+ sudo vi */etc/ssh/sshd_config*
	+ set: *PasswordAuthentication yes*
	+ restart sshd ```# systemctl restart sshd```
+ Install java
	+ ```# dnf install "java-*-openjdk``` or ```# yum install java```
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


	+ Enable/Start sendmail service ( mitre test requires it)
		+ ``` # systemctl enable sendmail ; # systemctl start sendmail ```

## 5. Add Https support
+ **Add Nginx**
	+ http://wiki.nginx.org/Install#Official_Red_Hat.2FCentOS_packages
+ **Create certificate**
	+ https://www.digitalocean.com/community/tutorials/how-to-create-an-ssl-certificate-on-nginx-for-ubuntu-14-04
	+ store files into /etc/nginx/ssl/server.*
	+ Deny access to keys
		+ ```# chown root server.key*```
		+ ```# chmod 600 server.key*```
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
  listen 443 default ssl;
  server_name 209.132.179.114 jenkins.open-scap.org;

  ssl_certificate           /etc/nginx/ssl/server.crt;
  ssl_certificate_key       /etc/nginx/ssl/server.key;

  ssl_session_timeout  5m;
  ssl_protocols  SSLv3 TLSv1;
  ssl_ciphers HIGH:!ADH:!MD5;
  ssl_prefer_server_ciphers on;

  # auth_basic            "Restricted";
  # auth_basic_user_file  /home/jenkins/htpasswd;

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

+ **Enable and run nginx service**
	+ ```# systemctl enable nginx; systemctl start nginx```

+ **Provide redirect to static file**
	+  We want to redirect some /lets-encrypt location to /lets-encrypt/test file
	+  Set right linux rights to file/directory
	+  ```sudo chcon -Rt httpd_sys_content_t /lets-encrypt/``` -- allow access(selinux) to directory from nginx
	+  to ```/etc/nginx/conf.d/jenkins.conf``` add ```location /lets-encrypt { alias /lets-encrypt/test;}```

## 6. Create new Jobs
+ **Pull requests**
	+ Build Triggers: GitHub Pull Request Builder
	+ set White list:
		+ List of users. If someone from the group will create pull request, job will be automatically started.
	+ set Admin list:
		+ List of users. If someone who is not from White list create pull request. Users from admin list can enable building for the pull request.
+ **GitHub* builder**
	+ Build Triggers: Build when a change is pushed to GitHub

## 7. Yum/DNF Updates
+ Target: Update packages on our master and slaves regularly.
+ Probably the best way to do this is Jenkins' job.
	+ You can shedule it and you have easy access to update log.
+ Problem: You need to have access to call yum as *jenkins* user without password
	1. Use ```# visudo``` to edit /etc/sudoers.
	2. Get path of yum/dnf: ```which yum```.
	3. Allow jenkins user to run the file as sudo without password, add to sudoers file:

		```jenkins		ALL=(ALL)	NOPASSWD:/bin/yum update -y``` 
	4. Some systems don't allow sudo without tty(=you cannot use sudo from jenkins job), you have to add  ```Defaults:jenkins !requiretty``` after ```Defaults    requiretty``` in sudoers
		+ (There was bug with visudo in RHEL7 - it allows you to store non valid sudoers and you lose completely access via sudo)
	6. Create jenkins job
		+ Check "Restrict where this project can be run" and select machine which you want to update.
		+ Build triggers set to 'Build periodically'.
		+ Shedule ```H 0 * * 7``` - It means every sunday about midnight. Jenkins provides examples when the job will by started.
		+ To Build step add "Execute shell" with ```sudo yum update -y``` as context(or use dnf).

		

	
	

## A. Possible issues:
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


