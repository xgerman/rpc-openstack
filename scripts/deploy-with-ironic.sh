#!/usr/bin/env bash
# Copyright 2017, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

## Shell Opts ----------------------------------------------------------------

set -e -u -x
set -o pipefail

## Functions -----------------------------------------------------------------

export BASE_DIR=${BASE_DIR:-"/opt/rpc-openstack"}
source ${BASE_DIR}/scripts/functions.sh

## Main ----------------------------------------------------------------------

# Check the openstack-ansible submodule status
check_submodule_status

export DEPLOY_IRONIC="yes"
export DEPLOY_AIO="yes"
# begin the ansible setup
${BASE_DIR}/scripts/bootstrap-ansible.sh
${BASE_DIR}/scripts/bootstrap-aio.sh
sed -i "s/aio1/$(hostname)/" /etc/openstack_deploy/openstack_user_config.yml
sed -i "s/aio1/$(hostname)/" /etc/openstack_deploy/conf.d/*.yml
# drop interface config for ironic
openstack-ansible ${BASE_DIR}/scripts/setup-ironic-networking.yml
${BASE_DIR}/scripts/bootstrap-aio.sh
# replace aio1 with the hostname
sed -i "s/aio1/$(hostname)/" /etc/openstack_deploy/openstack_user_config.yml
sed -i "s/aio1/$(hostname)/" /etc/openstack_deploy/conf.d/*.yml
# run pre-install config for ironic
openstack-ansible ${RPCD_DIR}/playbooks/ironic-pre-config.yml
# deploy RPC
${BASE_DIR}/scripts/deploy.sh
# do post ironic install config
openstack-ansible ${RPCD_DIR}/playbooks/ironic-post-install-config.yml
# re-run ironic install to include the post-config
openstack-ansible ${RPCD_DIR}/openstack/playbooks/os-ironic-install.yml
