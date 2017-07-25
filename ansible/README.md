# Ansible deployment Playbooks
This directory contains Ansible Playbooks preparing machines to serve as
Jenkins ```master``` and ```worker``` machines used in OpenSCAP Upstream CI.

You can use following command, after populating ```inventory.ini``` with
correct machine addresses.

`$ ansible-playbook -i inventory.ini ./all.yml`

There are few steps that are currently not possible to cover by these
playbooks. These are covered in separate sections.

### Public key distribution
If you don't want to distribute public keys manually, you might want to utilize
Ansible module authorized_key, and run it from separate, not publicly available
Ansible playbook.

### Extend the root partition
Depending on the image you use to create the AWS instances you may need to
extend the root partition. This is a dangerous step which is why we don't even
attempt it in the playbook. This is applicable to both the master and workers.

```
$ sudo gdisk /dev/xvda1
i 1
(copy all the details somewhere, you will need them later)
d 1
n 1
(now make absolutely sure the first sector is EXACTLY the same as before)
(match the GUID)
x
c
(paste the previous "unique GUID")
p
(double check everything)
w

$ sudo reboot
(after reboot)
$ sudo resize2fs /dev/xvda1
```

### GitHub OAuth plugin
Authentication model of Jenkins as provided by Ansible playbook ```master.yml```
utilizes basic Jenkins database, with the only user being Admin.
If you want to use GitHub authentication for access control to your Jenkins
instance, you need to set OAuth plugin. Instructions how to set up OAuth plugin
can be found on [plugin info page]
(https://wiki.jenkins.io/display/JENKINS/GitHub+OAuth+Plugin)

> Make sure OAuth authentication works and you have admin access to the Jenkins
> instance before logging out from local admin user. Otherwise you won't be able
> to log back to revert the changes.

Please note that for official OpenSCAP CI, GitHub application is already created
directly for OpenSCAP organization (ask any of the owners to provide you
credentials as necessary).

*NOTE:* In the OAuth scopes, please remove ```read:org```. This authorization
mode won't be used anyway, and it makes members of private organizations
hesitant to grant access to their profiles.

### Jenkins Jobs
Jenkins Jobs can be populated with XMLs stored within ```jobs``` directory, but
these XML have several fields redacted, with string EMPTY_<something> replacing
the value you want to have there. Usually, this placeholder string does not
follow specification of given field and Jenkins will print errors in
configuration screens.

GitHub user utilized by ```pull-request``` jobs is ```openscap-ci```.
Credentials are available to the core team members.

### GitHub Webhooks
GitHub Webhooks are not set up by the Ansible Playbooks, but must be created
either automatically by Jenkins, or manually by person doing the setup. The
other approach is to use polling from Jenkins server. This part will deal with
webhooks approach only, though.

You need to setup *2 types* of hooks for changes in branch and for
pull requests. Webhooks are configured within `setting` dialog of your repository

#### GitHub Pull Request Builder
+ hook url: *https://jenkins.open-scap.org/ghprbhook/*
    + required GitHub hooks 'issue_comment, pull_request'
+ "The user needs to have push rights for your repository (must be collaborator (user repo) or must have Push & Pull rights (organization repo))."
+ "If you want to use GitHub hooks have them set automatically the user needs to have administrator rights for your repository (must be owner (user repo) or must have Push, Pull & Administrative rights (organization repo))"

#### GitHub Plugin
+ hook url: *https://jenkins.open-scap.org/github-webhook/*
+ Add service Jenkins (GitHub plugin)
