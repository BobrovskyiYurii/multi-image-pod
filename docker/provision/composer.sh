#!/bin/sh

COMPOSER_PATH="/usr/bin/composer-bin"

# check if composer exists already
if [[ -x ${COMPOSER_PATH} ]]; then
  ${COMPOSER_PATH} "$@"
  exit 0
fi

echo "Installing composer"
# install composer
wget -O composer-setup.php https://getcomposer.org/installer
if [ ! -z "${COMPOSER_VERSION}" ]; then
  echo "Starting installation Composer version ${COMPOSER_VERSION}"
  php composer-setup.php --version=${COMPOSER_VERSION}
else
  echo "Starting installation Composer default version"
  # install latest composer version
  php composer-setup.php
fi
rm ./composer-setup.php
mv ./composer.phar ${COMPOSER_PATH}
${COMPOSER_PATH} --version

echo {\"github-oauth\": {\"github.com\": \"${GITHUB_OAUTH_TOKEN}\"}} > /root/.composer/auth.json;

${COMPOSER_PATH} "$@"
