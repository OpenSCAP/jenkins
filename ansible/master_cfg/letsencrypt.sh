#!/bin/bash

# Updates on 2018-08-13 by ascheel to gracefully handle autorenewal
# Add --keep-until-expiring, --post-hook "systemctl restart nginx" to letsencrypt-auto
# Remove --renew-by-default aka --force-renewal from letsencrypt-auto
# Made /etc/nginx/tls/server.{crt,key} symlinks to /etc/letsencrypt/live/jenkins.open-scap.org/{fullchain.pem,privkey.pem}
# Updated crontab to execute every day, not once a month
# Added logging of command output to /var/log/letsencrypt-renewal.log
# Logs for renewal failures are in /var/logs/letsencrypt/letsencrypt.log* and are timestamped

log="/var/log/letsencrypt-renewal.log"

echo "=====BEGIN RENEWAL $(date)=====" >> $log

# TODO: Change the email to something that makes more sense
/root/letsencrypt/letsencrypt-auto certonly --keep-until-expiring --webroot -w /letsencrypt_public_html/ -d jenkins.open-scap.org -m mpreisle@redhat.com --agree-tos -n --post-hook "systemctl restart nginx" >> $log 2>&1

ret=$?
echo "letsencrypt-auto return code: $ret" >> $log 2>&1
echo "=====END RENEWAL=====" >> $log
exit $ret

