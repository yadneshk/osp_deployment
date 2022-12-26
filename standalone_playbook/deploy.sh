#!/bin/bash

set -xeo pipefail

ansible-playbook deploy_standalone.yml

ansible-playbook -i $(find . -iname *.inv) configure_standalone.yml
