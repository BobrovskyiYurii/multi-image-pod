## Multi-Image PHP Deployment 
Base Multi-Image PHP Deployment Approach

## Dockerfile

🧾 Вимоги:

    Docker (версія 20+)
    Токени доступу:
        ◦ GITHUB_TOKEN (export GITHUB_TOKEN="personal access token")
        ◦ COMPOSER_TOKEN (export COMPOSER_TOKEN="personal Artifactory token")

⚙️ Перемикання між production і dev

Використовуй різні таргети:
Для продакшну:
```bash
  docker build --target base  --build-arg APP_ENV=production
```
Для девелопменту (з Xdebug):
```bash
    docker build --target base  --build-arg APP_ENV=development
```

🧩 Конфігурація PHP

    php.ini: ./docker/config/php/php.ini
    Додаткові конфіги: ./docker/config/php/conf.d/
    FPM-пул: ./docker/config/php/fpm/pool.d/*.conf
    Логи: /proc/self/fd/1 (stdout)

🧷 Розширення PHP

Автоматично встановлюються:

    pdo_pgsql, iconv, sockets, mbstring, opcache

У dev-режимі також:

    xdebug

📦 Composer

    Використовується офіційний Composer 2.8
    Залежності встановлюються з токенами
    У продакшн-режимі: --no-dev
    Оптимізовано: --prefer-dist -o --classmap-authoritative


## Docker Compose

    app	 PHP-FPM (білд з Dockerfile)
    nginx	 Реверс-проксі для app
    postgres База даних PostgreSQL
    redis    Кеш Redis
    jaeger	 Трасування (OpenTracing / OpenTelemetry)


📁 Cтруктура директорій:

    ├── composer.json
    ├── docker-compose.yml
    ├── Dockerfile
    ├── docker/
    │   ├── config/
    │   │   ├── nginx/
    │   │   │   └── app.conf (налаштування віртуального серверу nginx)
    │   │   │   └── nginx.conf (загальні налашування логі, формат, і тд.)
    │   │   └── php/
    │   │   │   └── conf.d/
    │   │   │   └── fpm/
    │   │   │   │   └── pool.d/
    │   │   │   │   └──php-fpm.conf
    │   │   │   └── php.ini
    │   │   │   └── xdebug.ini
    │   └── provision/
    │       ├── entrypoint.sh
    │       └── entrypoint.d/


🛠️ Запуск середовища

    docker compose up --build

🔐 Передача параметрів

    PHP_VER=8.2 // версія PHP
    PHP_EXT="pdo_pgsql iconv sockets" // розширення PHP
    SYS_EXT="libpq-dev libonig-dev" // системні розширення
    BUILD_ID=0 // версія білду
    APP_ENV="production" // середовище (production/dev)

🔐 Передача секретів

Docker Compose автоматично читає значення з environment, якщо задано:

    secrets:
        GITHUB_TOKEN:
            environment: GITHUB_TOKEN
        COMPOSER_TOKEN:
            environment: COMPOSER_TOKEN

To set environment variables:
```bash
export GITHUB_TOKEN="personal access token with repository permissions"
export COMPOSER_TOKEN="personal corporate Artifactory access token"
```

🌐 Доступ

    Компонент	Порт на хості	URL
    nginx (app)	8080	http://localhost:8080
    jaeger UI	16686	http://localhost:16686
    PostgreSQL	5432	postgres:postgres@localhost:5432
    Redis	6379	redis://localhost:6379

📦 Допоміжні інструменти

    entrypoint.sh керує запуском PHP (можеш там робити міграції, cron, preload тощо)

    XDEBUG_ENABLE, XDEBUG_MODE, XDEBUG_CLIENT_HOST — зручно для локального дебагу (PhpStorm, VS Code)


## Infra:

🧭 Загальний огляд

Ця конфігурація описує багатокомпонентну PHP/NGINX-систему, що розгортається з використанням Kubernetes через Helm:

    🐘 PHP (основний додаток)
    🌐 Nginx як веб-сервер
    ⚙️ Migrations (Job)
    📦 Secrets з AWS (опційно)
    🔁 CronJobs (перший/другий запуск)

🔧 Компоненти конфігурації
1. 📦 Образи
```
php: &php some-registry/php-image
nginx: &nginx public.ecr.aws/nginx/nginx
```

2. 🌍 Global Settings
```
global:
image:
repository: *php
tag: "abcd123"
secretStoreName: "app-external-aws"
serviceAccountName: serviceName
```

Використовуються для PHP (основний додаток)
secretStoreName: ім’я зовнішнього сховища секретів (наприклад, AWS Secret Manager)
serviceAccountName: для доступу до AWS або інших ресурсів Kubernetes

3. 🛠️ Job для міграцій

```
migration-job:
command: ["php"]
args: ["bin/console", "doctrine:migrations:migrate", "--no-interaction"]
annotations:
argocd.argoproj.io/hook: PreSync
argocd.argoproj.io/hook-delete-policy: BeforeHookCreation
```

Запускається перед деплоєм (PreSync)
Міграції Doctrine (Symfony)
Не вимагає взаємодії (--no-interaction)

4. 🌐 Nginx як Web
````
web:
enabled: true
name: nginx
image:
repository: *nginx
tag: latest
````


Має додатковий контейнер php у extraContainers — тобто PHP не окремо, а всередині одного Pod
```
extraContainers:
- name: php
  image: some-registry/php-image:abcd123
  envFrom:
    - configMapRef:
      name: configmap-name
    - secretRef:
      name: secret-name
      env:
    - name: APP_NAME
      value: "Your app name"
```

В envFrom — змінні середовища з ConfigMap і Secret
Працює як PHP-FPM всередині nginx pod-а

➕ Mount'и
```
extraVolumeMounts:
- mountPath: /etc/nginx/nginx.conf
  subPath: nginx
- mountPath: /etc/nginx/conf.d/default.conf
  subPath: virtualhost
```

Конфігурації nginx беруться з ConfigMap nginx-config-alpha

5. 🔁 CronJob Example
```
first-run-job:
command: ["php"]
args: ["bin/console", "app:command-name"]
schedule: "* * * * *"
```
