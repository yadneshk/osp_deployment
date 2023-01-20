#!/bin/bash

set -xeo pipefail

ansible-playbook delete_vm.yml -i $(find . -iname *.inv) -e @vars_devstack.yml
