#!/bin/bash

set -xeo pipefail

ansible-playbook -e @vars_devstack.yml deploy_vm.yml

ansible-playbook -i $(find . -iname *.inv) -e @vars_devstack.yml configure_devstack.yml
