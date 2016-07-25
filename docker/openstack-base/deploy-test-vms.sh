#!/bin/bash

usage()
{
cat << EOF
usage: $0 KEYSTONE_USERNAME KEYSTONE_PASSWORD KEYSTONE_PUBLIC_PORT [NUMBER_OF_VMS]

This script will create test network, upload cirros image to glance and launch few Vms.
it should be used for test purposes only.

EOF
}

# Dont want to use getops here...
if [ $# -eq 0 ]; then
  usage
  exit 1
elif [ -z "$1" ]; then
  echo "You must pass keystone admin username as a first arg"
  exit 1
elif [ -z "$2" ]; then
  echo "You must pass keystone admin password as a second arg"
  exit 1
elif [ -z "$3" ]; then
  echo "You must pass keystone public port as a third arg"
  exit 1
fi

# If $4 is not set - set it for "2"
NUMBER_OF_VMS="${4:-2}"
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=$1
export OS_PASSWORD=$2
export OS_AUTH_URL=http://keystone:$3/v3
export OS_IDENTITY_API_VERSION=3

openstack flavor create --ram 512 --disk 0 --vcpus 1 tiny
openstack network create --provider-network-type vxlan --provider-segment 77 testnetwork
openstack subnet create --subnet-range 192.168.1.0/24 --gateway none --network testnetwork testsubnetwork
curl -o /tmp/cirros.img http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img && \
openstack image create --disk-format qcow2 --public --file /tmp/cirros.img cirros
NETID="$(openstack network list | awk '/testnetwork/ {print $2}')"
openstack server create --flavor tiny --image cirros --nic net-id="$NETID" --min $NUMBER_OF_VMS --max $NUMBER_OF_VMS --wait test_vm
openstack server list
