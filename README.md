## Multi-Image PHP Deployment 
Base Multi-Image PHP Deployment Approach

## Dockerfile

#### 🧾 Prerequisites:

Before image building set GITHUB_TOKEN, COMPOSER_TOKEN environment variables.

To set environment variables:
```bash
export GITHUB_TOKEN="personal access token with repository permissions"
export COMPOSER_TOKEN="personal corporate Artifactory access token"
```
#### 🛠️ Build arguments

Dockerfile in this example contains next build arguments with default values:

* `ARG PHP_VER=8.2` - version of PHP, default is 8.2
* `ARG PHP_EXT="pdo mbstring opcache pdo_pgsql iconv sockets"` - PHP extensions to be installed
* `ARG SYS_EXT="unzip libpq-dev libonig-dev"` - system packages required for application
* `ARG BUILD_ID=0` - id of current application build
* `ARG APP_ENV="production"` - flag indicating the current application build environment (was application build for prod or dev)

#### ⚙️ Different docker build targets

Dockerfile in this example contains two targets - base (general target suitable for production) and dev (with xdebug enabled).

To build base version, use:
```bash
  docker build --target base --build-arg APP_ENV=production
```
To build dev version (with xdebug), use:
```bash
    docker build --target base --build-arg APP_ENV=development
```

#### 🧩 PHP configuration

* `./docker/config/php/php.ini`

    Main php.ini file

* `./docker/config/php/conf.d/`

    Additional configs (in this example it contains Opcache config).

* `./docker/config/php/fpm/php-fpm.conf`

    Main config for PHP-FPM

* `./docker/config/php/fpm/pool.d/*.conf`
    
    Configs for PHP-FPM pools.

Please pay attention that all PHP logs are configured to be collected to stdin or stderr (`/proc/self/fd/2`):
* `./docker/config/php/fpm/pool.d:8`

  > error_log = /proc/self/fd/2 

* `./docker/config/php/fpm/pool.d/www.conf:26-28`
    > php_admin_value[error_log] = /proc/self/fd/2   
    slowlog = /proc/self/fd/2   
    access.log = /proc/self/fd/1


#### 🧷 PHP extensions

In this example, the following extensions are installed by default:
```
pdo mbstring opcache pdo_pgsql iconv sockets
```

dev target from Dockerfile also adds
```
xdebug
```

#### 📦 Composer

This example uses Composer binary from official image `public.ecr.aws/composer/composer:2.8-bin`. 


## Docker Compose

* `app` - container with application code and PHP-FPM, builds from Dockerfile
* `nginx` - reverse proxy for PHP-FPM

#### 🔐 Secrets

Docker Compose will fill secrets from environment variables, please, remember to set them (see Prerequisites block).

## Helm chart:

#### 🧭 Overview

`./infra` directory contains example of Helm chart to run this example application in multi-container k8s pod.

#### 🔧 Components in `values.yaml`

1. 🌍 Global Settings
```
global:
  secretStoreName: "app-external-aws.application"
  serviceAccountName: applicationServiceName
```

Describes configuration for secret store (of external secret store, for example AWS Secret Manager) 
and service account name (to provide access to other k8s resources).

2. 🌐 Web

Main service of the current application. Because the application must respond to HTTP requests on some port we have to use
nginx reverse proxy as the main container of the application. 

As nginx image we use official image from `public.ecr.aws/nginx/nginx` (the latest version).

```
web:
  enabled: true
  virtualService:
    enabled: false
  replicas: 1
  name: nginx
  image:
    repository: public.ecr.aws/nginx/nginx
    tag: latest
  ports:
    - name: http
      appPort: 80
      servicePort: 80
      protocol: TCP
<...>      
```

Nginx container has multiple volumes mounts:
```
web:
<...>
  extraVolumeMounts:
    - name: nginx-config-alpha
      mountPath: /etc/nginx/nginx.conf
      readOnly: true
      subPath: nginx
    - name: nginx-config-alpha
      mountPath: /etc/nginx/conf.d/default.conf
      readOnly: true
      subPath: virtualhost
  extraVolumes:
    - name: nginx-config-alpha
      configMap:
        name: nginx-config-alpha
```
values for these config maps are described in `./infra/templates/nginx-configmap.yaml`

3. 📦 PHP application

PHP application is deployed as an extra container. 

For PHP container we use image built from current Dockerfile and tagged as `bobrovskyi4pdffiller/multicontainer-pod-example-php:1.0`

```
  extraContainers:
    - name: php
      image: bobrovskyi4pdffiller/multicontainer-pod-example-php:1.0
      envFrom:
        - configMapRef:
            name: configmap-name
        - secretRef:
            name: secret-name
      env:
        - name: APP_ENV
          value: "production"
        - name: OPCACHE_ENABLE
          value: "0"
```

4. 🛠️ One time and recurring CLI jobs

```
migration-job:
  enabled: false
  command: ["php"]
  args: ["bin/console", "doctrine:migrations:migrate", "--no-interaction"]
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: BeforeHookCreation  
tr-sync-pending-refund:
  enabled: false
```