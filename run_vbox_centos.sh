#!/bin/bash -x

set -e

ansible all -m ping && ansible-playbook -i root setup-event-listener.yml && ansible-playbook setup.yml --tags "company-backend,brand-backend" && ansible-playbook -i root setup-elasticsearch.yml && ansible-playbook -i root setup-bc-ipfs.yml && ansible-playbook -i root setup-bc-ipfs-node.yml


