#!/bin/bash

set -xeo pipefail

ansible-playbook -e @vars_standalone.yml deploy_vm.yml

ansible-playbook -i $(find . -iname *.inv) -e @vars_standalone.yml configure_standalone.yml
