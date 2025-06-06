#!/bin/bash

# Exit the script if any statement returns a non-true return value
set -e

for file in /entrypoint.d/*.sh
do
  source "$file"
done

mkdir -p var/
chown -R www-data:www-data var/

exec "$@"