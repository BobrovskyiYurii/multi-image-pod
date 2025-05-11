#!/usr/bin/env bash

# Exit the script if any statement returns a non-true return value
set -e

used_roles=()

source /entrypoint.d/functions.sh

# Run cron service for any roles because logrotate runs are managed by crontab
service cron start

if [ $(isServiceRole "web") = "1" ]
then
    echo "Web is set up"
    used_roles+=('web')
else
    rm -f /etc/supervisor/conf.d/nginx.conf
    rm -f /etc/supervisor/conf.d/php-fpm.conf

    echo "Web is disabled"
fi

#if [ $(isServiceRole "worker") = "1" ]
#then
#    cp -a /app/docker/config/supervisor/worker/. /etc/supervisor/conf.d/
#
#    echo "Worker is set up"
#    used_roles+=('worker')
#else
#    echo "Worker is disabled"
#fi

if [ $(isServiceRole "cron") = "1" ]
then
    # export all environment variables to use in cron
    env | sed 's/^\(.*\)\=\(.*\)$/export \1\="\2"/g' > /cron_env.sh
    chmod +x /cron_env.sh

    echo "Cron is set up"
    used_roles+=('cron')
else
    echo "Cron is disabled"
fi

if [ $(isServiceRole "console") = "1" ]
then
    echo "Console is set up"
    used_roles+=('console')
else
    echo "Console is disabled"
fi

if [ -z "$used_roles" ]
then
    echo "Not one of the available roles is used"
    exit 1
fi
