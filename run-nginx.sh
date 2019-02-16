#!/bin/bash

# Disable and stop nginx since we run it in docker
systemctl stop nginx
systemctl disable nginx

docker run -d --restart=always \
  --name nginx \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/etc/nginx,target=/etc/nginx \
  --mount type=bind,source=/var/log/nginx,target=/var/log/nginx \
  nginx:latest
