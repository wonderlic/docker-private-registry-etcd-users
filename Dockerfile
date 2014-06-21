from registry
run apt-get update
run apt-get -y upgrade
run apt-get install -y apache2-utils supervisor python-setuptools nginx redis-server
run rm /etc/rc*.d/*nginx
run easy_install pip
run pip install uwsgi
add run.sh /usr/bin/run
add . /app
run pip install -r /app/requirements.txt
env CACHE_REDIS_HOST 127.0.0.1
env CACHE_REDIS_PORT 6379
env CACHE_LRU_REDIS_HOST 127.0.0.1
env CACHE_LRU_REDIS_PORT 6379
expose 80
cmd ["/usr/bin/run"]
