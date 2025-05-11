#!/usr/bin/env bash

set -e

if [ "${OPCACHE_ENABLE}" == 0 ]; then
  sed -i 's/^opcache.enable.*/opcache.enable=0/' /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
  sed -i 's/^opcache.enable_cli.*/opcache.enable_cli=0/' /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

  /bin/echo "Opcache Disabled\n"
fi