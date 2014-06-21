#!/bin/bash
ADMIN_PASSWORD=${ADMIN_PASSWORD:-docker}
REGISTRY_NAME=${REGISTRY_NAME:-Docker Registry}
CACHE_REDIS_PASSWORD=${REDIS_PASSWORD:-docker}
CACHE_LRU_REDIS_PASSWORD=${REDIS_PASSWORD:-docker}
PASSWORD_FILE=${USER_DB:-/etc/registry.users}

export CACHE_REDIS_PASSWORD
export CACHE_LRU_REDIS_PASSWORD

# nginx config
cat << EOF > /etc/nginx/nginx.conf
  daemon off;
  events {
    worker_connections 2048;
  }

  http {

  upstream registry {
    server localhost:5000;
  }

  upstream manage {
    server localhost:4000;
  }

  server {
    listen 80;
    server_name registry.core-os.net;

    proxy_set_header Host \$http_host;   # required for docker client's sake
    proxy_set_header X-Real-IP \$remote_addr; # pass on real client's IP
    proxy_set_header Authorization  "";

    client_max_body_size 0; # disable any limits to avoid HTTP 413 for large image uploads

    # required to avoid HTTP 411: see Issue #1486 (https://github.com/dotcloud/docker/issues/1486)
    chunked_transfer_encoding on;

    location /v1/_ping {
      auth_basic off;
      proxy_pass http://registry;
    }

    location /v1/users {
      auth_basic off;
      proxy_pass http://registry;
    }

    location /static {
      alias /app/static;
      expires 1d;
    }

    location = /manage { rewrite ^ /manage/; }
    location /manage/ { try_files \$uri @manage; }
    location @manage {
      auth_basic "$REGISTRY_NAME";
      auth_basic_user_file $PASSWORD_FILE;
      proxy_redirect off;
      include uwsgi_params;
      uwsgi_param SCRIPT_NAME /manage;
      uwsgi_modifier1 30;
      uwsgi_pass unix:/tmp/uwsgi-manage.sock;
    }

    location / {
    #  auth_basic "$REGISTRY_NAME";
    #  auth_basic_user_file $PASSWORD_FILE;

    #  if (\$http_x_forwarded_proto != "https") {
    #    rewrite ^(.*)\$ https://\$host\$uri permanent;
    #  }
    #  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains;";
      proxy_pass http://registry;
    }

  }
}
EOF

# uwsgi config (manage)
cat << EOF > /etc/manage.ini
[uwsgi]
chdir = /app
socket = /tmp/uwsgi-manage.sock
workers = 8
buffer-size = 32768
master = true
max-requests = 5000
static-map = /static=/app/static
module = wsgi:application
EOF

# redis config
cat << EOF >> /etc/redis.conf
daemonize no
requirepass $CACHE_REDIS_PASSWORD
maxmemory 2mb
maxmemory-policy allkeys-lru
EOF

# supervisor config
cat << EOF > /etc/supervisor/supervisor.conf
[supervisord]
nodaemon=false

[unix_http_server]
file=/var/run/supervisor.sock

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run//supervisor.sock

[program:redis]
priority=05
user=root
command=/usr/bin/redis-server /etc/redis.conf
directory=/var/lib/redis
autostart=true
autorestart=true
stopsignal=QUIT

[program:registry]
priority=10
user=root
command=docker-registry
autostart=true
autorestart=true
stopsignal=QUIT

[program:manage]
priority=20
user=root
command=/usr/local/bin/uwsgi --ini /etc/manage.ini
directory=/app
autostart=true
autorestart=true
stopsignal=QUIT

[program:nginx]
priority=50
user=root
command=nginx
directory=/tmp
autostart=true
autorestart=true
EOF

# create password file if needed
if [ ! -e $PASSWORD_FILE ] ; then
    htpasswd -bc $PASSWORD_FILE admin $ADMIN_PASSWORD
fi

# run supervisor
supervisord -c /etc/supervisor/supervisor.conf -n
