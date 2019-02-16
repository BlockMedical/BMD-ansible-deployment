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
