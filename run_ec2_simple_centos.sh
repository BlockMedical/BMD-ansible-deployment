#!/bin/bash -x

set -e

ansible all -m ping && ansible-playbook -i demo setup.yml


