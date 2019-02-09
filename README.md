# BlockMed Ansible Configuration Manager

## Setup for control machine (e.g: localhost)

### Runtime Environment

1. install python

This example utilize [Miniconda](https://docs.conda.io/en/latest/miniconda.html), once you have
it installed, you can create a specific Python environment for your Ansible configuration.

e.g.

```
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
bash Miniconda3-latest-MacOSX-x86_64.sh
```

and then you can run the following to setup necessary modules.
```
conda create -n ansible
source activate ansible
pip install ansible
pip install boto boto3

ansible-galaxy install -r requirements.yml
```

2. install ansible

on MacOS you might need to install `pip` via
```
sudo easy_install pip
```

make sure Ansible version is above of `2.5.0`

3. install bob & bob3. `pip install boto` `pip install boto3`


4. Configure ssh config file. Configure your `~/.ssh/config` file with the following
host alias for your machines.
- target: The machine hosting bc-ipfs. If `demo` env is applied, everything will be on this node.
- es-node: The machine runs the elastic search application. Only apply to `production` env.
- event-listener: The machine runs the Ethereum event listener application. Only apply to `production` env.

e.g.
```
Host target
  User centos
  HostName YOUR_SSH_IP_ADDRESS
  Port 22
  IdentityFile PATH_TO_YOUR_PEM_PRIVATE_KEY
  ForwardX11 no
  Compression no
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  GlobalKnownHostsFile /dev/null
  ServerAliveInterval 15
  TCPKeepAlive yes
  Protocol 1,2
```

### Install Dependencies Roles from Ansible Galaxy

```
ansible-galaxy install -r requirements.yml
```

### All-In-One(including above env setup) with MacOS iTerm2 setup

1. create ansible_{env}.cfg
```
[defaults]
inventory = ~/devops/ansible/{env}
host_key_checking = False
vault_password_file = ~/ansible/vault_{env}_pass
remote_user = centos
private_key_file = ~/.ssh/id_rsa
```

2. create new iTerm2 profile with `Send text at start` setup (2 lines)
```
export ANSIBLE_CONFIG=~/ansible/ansible_{env}.cfg
```

3. now you can open iTerm2 specific env profile and using `ansible` or `ansible-playbook` directly.

## Run Example

Notes: if you have ansible config with inventory setup, you can ignore `-i {environment}` attribute in the following examples.

### Ping

test with `ansible all -m ping` and you should get the response below.
```
dev-e | SUCCESS => {
    "changed": false,
    "failed": false,
    "ping": "pong"
}
dev-a | SUCCESS => {
    "changed": false,
    "failed": false,
    "ping": "pong"
}
```


### Deploy `event-listener` on demo env in first time.

```
ansible-playbook -i demo setup-event-listener.yml -e "ansible_ssh_user=root"
```

### Deploy `event-listener` on demo env with upgrade only.

```
ansible-playbook -i demo setup-event-listener.yml -e "ansible_ssh_user=root" --skip-tags "init"
```

### Deploy everything on 1 machine with demo env

```
ansible-playbook -i demo setup.yml
```

Specify a specific host with its IP address and specific user to deploy:
```
ansible-playbook -i demo setup.yml -e "ansible_ssh_host=1.2.3.4" -e "ansible_ssh_user=centos"
```

### Run specific part in playbook using `tags`

```
ansible-playbook -i demo setup.yml --tags "company-backend,brand-backend" -e "ansible_ssh_user=root"
```
or with All-In-One env setup
```
ansible-playbook setup.yml --tags "company-backend,brand-backend"
```

#### Run with `vault` (which be used to encrypt credentials in staing & prod)

```
ansible-playbook -i staging setup-integration-backend.yml -e "ansible_ssh_user=centos" --ask-vault-pass
```

#### Run on specific machine only

```
ansible-playbook -i staging setup.yml -e "ansible_ssh_user=centos" --ask-vault-pass --limit ms-3
```
or with All-In-One env setup
```
ansible-playbook setup.yml --limit ms-3
```


#### encrypt / decrypt vault

```
ansible-vault decrypt production/group_vars/*/vault
```

```
ansible-vault encrypt production/group_vars/*/vault
```


## Appendix

### 坑

#### docker module issue on `Remote Machine`

```
fatal: [dev-apis]: FAILED! => {"changed": false, "failed": true, "msg": "Failed to import docker-py - No module named requests.exceptions. Try `pip install docker-py`"}
```

**this error indicate the remote client has no related python module, not local host.**

```
For people lazy to read every post here:
Since ansible 2.3, the dependency issue docker-py is fixed:

if you use the default python 2.7, the docker module needs docker-py

if you use python 3 (-e 'ansible_python_interpreter=/usr/bin/python3' ), it needs docker instead of docker-py
in all case, clean by pip uninstall docker docker-py docker-compose
reinstall
pip install docker-compose
```

**Solution:** setup dependencies in runner machine

```
yum install -y epel-release

yum install -y python-pip

pip install docker-py

```

#### AWS capacity with `boto` dependency on `Control Machine`

```
fatal: [localhost]: FAILED! => {"changed": false, "failed": true, "msg": "boto required for this module"}
```

**Solution:** setup boto on `Control Machine`

```
pip install boto
```

#### behaviour of `--limits`

ref:[stackoverflow](https://stackoverflow.com/questions/44541463/limit-ansible-playbook-by-hosts-of-plays)

### Utils

#### get prod disk info from instances

```
ansible all -m shell -a "df -h|grep /dev/xvd"
```

## Additional Setup with Nginx
You can also use nginx as a proxy if you don't want to re-map the ports to public ports. The following is a convinient
script for you to do run nginx.

```
#!/bin/bash

docker run -d --restart=always \
  --name nginx \
  --publish 80:80 \
  --publish 443:443 \
  --mount type=bind,source=/etc/nginx,target=/etc/nginx \
  --mount type=bind,source=/var/log/nginx,target=/var/log/nginx \
  nginx:latest
  ```
  
  Assuming your host is running on a private network interface IP `192.168.1.5` and your SSL certificates are installed under `/etc/nginx/certs`, a similar `/etc/nginx/nginx.conf`
  will look like this.
  
  ```
  error_log  /var/log/nginx/error.log;
pid        /var/log/nginx/nginx.pid;
worker_rlimit_nofile 8192;
events {
    worker_connections  4096;  ## Default: 1024
}
http {
    log_format   main '$remote_addr - $remote_user [$time_local]  $status '
              '"$request" $body_bytes_sent "$http_referer" '
                  '"$http_user_agent" "$http_x_forwarded_for"';
    access_log   /var/log/nginx/access.log  main;
    client_max_body_size 1024M;
    server {
        listen       80;
        listen       443    ssl;
        server_name  ipfs.blockmed.ai;
        ssl_certificate         /etc/nginx/certs/cert_chain.crt;
        ssl_certificate_key     /etc/nginx/certs/private.key;
        error_page  405     =200 $uri;
        location / {
            proxy_http_version      1.1;
            proxy_set_header        Upgrade         $http_upgrade;
            proxy_pass              http://192.168.1.5:3000/;
            proxy_set_header        X-Real-IP       $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        Host            $http_host;
            proxy_hide_header       Access-Control-Allow-Origin;
            proxy_hide_header       Access-Control-Allow-Methods;
            proxy_hide_header       Access-Control-Allow-Credentials;
            proxy_hide_header       Access-Control-Allow-Headers;
            add_header              Access-Control-Allow-Origin         *	always;
            add_header              Access-Control-Allow-Credentials    true	always;
            add_header              Access-Control-Allow-Methods        POST,GET,PUT	always;
            proxy_connect_timeout   300;
            proxy_send_timeout      300;
            proxy_read_timeout      300;
            proxy_buffers           32 4k;
        }
    }
    server {
        listen       80;
        listen       443    ssl;
        server_name  ipfs-api.blockmed.ai;
        ssl_certificate         /etc/nginx/certs/cert_chain.crt;
        ssl_certificate_key     /etc/nginx/certs/private.key;
        error_page  405     =200 $uri;
        location / {
            keepalive_timeout       0;
            proxy_http_version      1.1;
            proxy_set_header        Upgrade         $http_upgrade;
            proxy_pass              http://192.168.1.5:5001/;
            proxy_set_header        X-Real-IP       $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        Host            $http_host;
            proxy_hide_header       Access-Control-Allow-Origin;
            add_header              Access-Control-Allow-Origin         *       always;
            add_header              Access-Control-Allow-Credentials    true    always;
            add_header              Access-Control-Allow-Methods        POST,GET,PUT	always;
            proxy_connect_timeout   600;
            proxy_send_timeout      600;
            proxy_read_timeout      600;
            proxy_buffers           32 4k;
        }
    }
    
    server {
        listen       80;
        listen       443    ssl;
        server_name  es.blockmed.ai;
        ssl_certificate         /etc/nginx/certs/cert_chain.crt;
        ssl_certificate_key     /etc/nginx/certs/private.key;
        error_page  405     =200 $uri;
        location / {
            proxy_http_version      1.1;
            proxy_set_header        Upgrade         $http_upgrade;
            proxy_pass              http://192.168.1.5:9200/;
            proxy_set_header        X-Real-IP       $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        Host            $http_host;
            proxy_hide_header       Access-Control-Allow-Origin;
            add_header              Access-Control-Allow-Origin         *       always;
            add_header              Access-Control-Allow-Credentials    true    always;
            add_header              Access-Control-Allow-Methods        POST,GET,PUT	always;
            proxy_connect_timeout   900;
            proxy_send_timeout      900;
            proxy_read_timeout      900;
            proxy_buffers           32 4k;
        }
    }
}
  ```
