#!/bin/bash

# TODO: Change the email to something that makes more sense
/root/letsencrypt/letsencrypt-auto certonly --webroot -w /letsencrypt_public_html/ -d jenkins.open-scap.org -m mpreisle@redhat.com --agree-tos -n --renew-by-default

# deploy to nginx
cp -L /etc/letsencrypt/live/jenkins.open-scap.org/fullchain.pem /etc/nginx/tls/server.crt
cp -L /etc/letsencrypt/live/jenkins.open-scap.org/privkey.pem /etc/nginx/tls/server.key
systemctl restart nginx
