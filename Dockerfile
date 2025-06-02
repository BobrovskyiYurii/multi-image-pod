ARG PHP_VER=8.2

FROM public.ecr.aws/docker/library/php:${PHP_VER}-fpm-bookworm AS base

ARG PHP_EXT="pdo mbstring opcache pdo_pgsql iconv sockets"
ARG SYS_EXT="unzip libpq-dev libonig-dev"
ARG BUILD_ID=0
ARG APP_ENV="production"

ENV BUILD_ID=${BUILD_ID} \
    SERVICE_ROLE=web \
    COMPOSER_ALLOW_SUPERUSER=1

WORKDIR /app

# install Composer
COPY --from=public.ecr.aws/composer/composer:2.8-bin --link /composer /usr/bin/composer
# copy the application code
COPY --link . .

# install the necessary dependencies
RUN apt-get update \
    && apt-get install -y ${SYS_EXT} \
    && rm -rf /var/lib/apt/lists/* \
    # install PHP extensions
    && docker-php-ext-install ${PHP_EXT} \
    && docker-php-ext-enable ${PHP_EXT}

# install dependencies
RUN --mount=type=secret,id=GITHUB_TOKEN --mount=type=secret,id=COMPOSER_TOKEN COMPOSER_INSTALL_OPTIONS="" \
    && if [ "${APP_ENV}" = "production" ]; then COMPOSER_INSTALL_OPTIONS="--no-dev"; fi && \
    COMPOSER_AUTH="{\"github-oauth\":{\"github.com\":\"$(cat /run/secrets/GITHUB_TOKEN)\"}, \"bearer\": {\"artifactory.infrateam.xyz:443\": \"$(cat /run/secrets/COMPOSER_TOKEN)\"}}" \
    composer install -o --prefer-dist --classmap-authoritative  --no-progress ${COMPOSER_INSTALL_OPTIONS}

RUN mkdir -p /entrypoint.d \
    && cp -R /app/docker/provision/entrypoint.d/* /entrypoint.d/ \
    && cp /app/docker/provision/entrypoint.sh /usr/local/bin/ \
    && chmod +x /usr/local/bin/entrypoint.sh \
    # configure php
    && cp ./docker/config/php/php.ini /usr/local/etc/php/php.ini \
    && cp ./docker/config/php/conf.d/* /usr/local/etc/php/conf.d/ \
    && cp ./docker/config/php/fpm/php-fpm.conf /usr/local/etc/ \
    && cp -r ./docker/config/php/fpm/pool.d/* /usr/local/etc/php-fpm.d/ \
    # add RDS SSL cert \
    && curl -o /etc/ssl/certs/rds-combined-ca.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem \
    && bash /app/docker/provision/after-build.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["php-fpm"]

FROM base AS dev

COPY ./docker/config/php/xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN pecl install xdebug && docker-php-ext-enable xdebug

