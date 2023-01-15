#!/bin/bash

set -xeo pipefail

ansible-playbook deploy_vm.yml

#ansible-playbook -i $(find . -iname *.inv) configure_standalone.yml
