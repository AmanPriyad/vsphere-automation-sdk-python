#!/bin/sh

set -e
# set -x #echo on

usage()
{
    echo ""
    echo "smoke_test.sh"
    echo "--username | -u   <Username of vCenter Server>"
    echo "--password | -p   <Password of vCenter Server>"
    echo "--help     | -h   <Prints help section>"
    echo ""
    echo "For example: smoke_test.sh -u 'administrator@xxxx.local' -p 'Admin!xx'"
    exit 1
}

if [ $# -lt 4 ]
then
printf "\nMissing required parameters. Please see help for more details."
usage
else
{
while [ $# -gt 0 ]
do
key="$1"

case $key in
    -u|--username)
    USERNAME="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--password)
    PASSWORD="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    usage
    ;;
    *)    # unknown option
        echo "ERROR: unknown parameter \"$key\""
        usage
    ;;
esac
done

#Setting up the testing environment#
pip3 install --upgrade pip setuptools virtualenv
virtualenv venv
source venv/bin/activate

#installing vsphere-automation-sdk-python#
#pip3 install --upgrade -e git+git@github.com:AmanPriyad/vsphere-automation-sdk-python.git#egg=vsphere-automation-sdk-python
pip3 install --upgrade git+https://github.com/vmware/vsphere-automation-sdk-python.git
pip3 install -r test-requirements.txt
pip install asn1crypto

#checking samples#
pycodestyle samples tests
pytest
export SDKDIR=`pwd`
export PYTHONPATH="$PYTHONPATH":$SDKDIR

#Getting VC_IP
VC_VERSION="\"$VC_VERSION\""
VC_ADDR=$(curl http://$NIMBUS_TESTBED/peek | jq '.'$VC_VERSION'[0]."vc"[0]."ip"')
SERVER=${VC_ADDR//\"/}

printf "Run some basic samples...\n"

echo "python3 samples/vsphere/vcenter/vm/list_vms.py -s $SERVER -u $USERNAME -p $PASSWORD -v"
python3 samples/vsphere/vcenter/vm/list_vms.py -s $SERVER -u $USERNAME -p $PASSWORD -v

echo "python3 sample_template/sample_template_basic.py -s $SERVER -u $USERNAME -p $PASSWORD -v"
python3 sample_template/sample_template_basic.py -s $SERVER -u $USERNAME -p $PASSWORD -v

echo "python3 sample_template/sample_template_complex.py -s $SERVER -u $USERNAME -p $PASSWORD -v"
python3 sample_template/sample_template_complex.py -s $SERVER -u $USERNAME -p $PASSWORD -v

echo "python3 samples/vsphere/sso/embedded_psc_sso_workflow.py -s $SERVER -u $USERNAME -p $PASSWORD -v"
python3 samples/vsphere/sso/embedded_psc_sso_workflow.py -s $SERVER -u $USERNAME -p $PASSWORD -v

echo "python3 samples/vsphere/sso/external_psc_sso_workflow.py -s https://$SERVER/lookupservice/sdk -u $USERNAME -p $PASSWORD -v"
python3 samples/vsphere/sso/external_psc_sso_workflow.py -s https://$SERVER/lookupservice/sdk -u $USERNAME -p $PASSWORD -v

echo "python3 samples/vsphere/vcenter/vm/create/create_default_vm.py -h"
python3 samples/vsphere/vcenter/vm/create/create_default_vm.py  -h

echo "python3 samples/vsphere/vcenter/vm/create/create_basic_vm.py -s $SERVER -u $USERNAME -p $PASSWORD -v -n 'NewVM_Basic'"
python3 samples/vsphere/vcenter/vm/create/create_basic_vm.py -s $SERVER -u $USERNAME -p $PASSWORD -v -n 'NewVM_Basic'

echo "python3 samples/vsphere/vcenter/vm/delete_vm.py -s $SERVER -u $USERNAME -p $PASSWORD -v -n 'NewVM_Basic'"
python3 samples/vsphere/vcenter/vm/delete_vm.py -s $SERVER -u $USERNAME -p $PASSWORD -v -n 'NewVM_Basic'

printf "\nSuccessfully executed all the smoke testcases!!"
}
fi
