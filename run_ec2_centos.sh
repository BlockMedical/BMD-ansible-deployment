#!/bin/bash -x

set -e

ansible all -m ping && ansible-playbook -i demo setup-event-listener.yml && ansible-playbook setup.yml --tags "company-backend,brand-backend" && ansible-playbook -i demo setup-elasticsearch.yml && ansible-playbook -i demo setup-bc-ipfs.yml && ansible-playbook -i demo setup-bc-ipfs-node.yml


