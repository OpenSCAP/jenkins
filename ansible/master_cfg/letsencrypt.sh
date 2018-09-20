#!/bin/bash

/root/letsencrypt/letsencrypt-auto certonly --webroot -w /letsencrypt_public_html/
{%- for domain in domains %}
 -d {{ domain }}
{%- endfor %}
 -m openscap-maint@redhat.com --agree-tos -n --renew-by-default

# deploy to nginx
cp -L /etc/letsencrypt/live/{{ domains[0] }}/fullchain.pem /etc/nginx/tls/server.crt
cp -L /etc/letsencrypt/live/{{ domains[0] }}/privkey.pem /etc/nginx/tls/server.key
systemctl restart nginx
