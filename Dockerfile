from registry

env CACHE_REDIS_HOST 127.0.0.1
env CACHE_REDIS_PORT 6379
env CACHE_LRU_REDIS_HOST 127.0.0.1
env CACHE_LRU_REDIS_PORT 6379

expose 80

run apt-get update
run apt-get -y upgrade
run apt-get install -y apache2-utils supervisor python-setuptools nginx redis-server libssl-dev wget curl

run rm /etc/rc*.d/*nginx

RUN wget --no-check-certificate https://github.com/kelseyhightower/confd/releases/download/v0.6.3/confd-0.6.3-linux-amd64
RUN mv confd-0.6.3-linux-amd64 /usr/local/bin/confd
RUN chmod a+x /usr/local/bin/confd

ADD registry.users.tmpl /etc/confd/templates/
ADD registry.users.toml /etc/confd/conf.d/
add run.sh /usr/local/bin/run

#S3  Bucket fixes
RUN echo "" >> /etc/boto.cfg
RUN echo "[S3]" >> /etc/boto.cfg
RUN echo "region = eu-west-1" >> /etc/boto.cfg

RUN echo "" >> /docker-registry/config/boto.cfg
RUN echo "[S3]" >> /docker-registry/config/boto.cfg
RUN echo "region = eu-west-1" >> /docker-registry/config/boto.cfg

RUN mkdir /config/

RUN grep -v 's3_bucket:'  /docker-registry/config/config_sample.yml > /docker-registry/config/config_sample.yml.1 && mv /docker-registry/config/config_sample.yml.1 /docker-registry/config/config_sample.yml

cmd ["/usr/local/bin/run"]
