#/bin/bash
# author: brian sigurdson, bsigurd@bgsu.edu

# Purpose
# To deploy boa to aws using bash script

# Assumptions
# user runs the local setup script as root
# user reads the root level readme file and completes the necessary input files
# user runs this script as the appropriate aws iam user (probably just themselves or another user with administrative privileges)

# Using a bastion host and nat gateway for additional security
# Users must ssh into the bastion host, then ssh into head or other nodes.
# This allows security to be relaxed for the head and slaves, and hardened for the bastion host as, all ssh goest though the bastion host.
# Similar for the use of the nat gateway.  The slaves can remain within a private subnet, without public ip address, and use the nat gateway for internet access to download needed packages.

# NOTE: do not change the following access key names, as aws-cli will look for these specific environment variable names when running the script below.  
export AWS_ACCESS_KEY_ID=$(grep -F 'aws_access_key_id' ../common-input/aws-cred.yml | cut -d: -f2)
export AWS_SECRET_ACCESS_KEY=$(grep -F 'aws_secret_access_key' ../common-input/aws-cred.yml | cut -d: -f2)

AWS_REGION=$(grep -F 'aws_region' ../common-input/aws-vars.yml | cut -d: -f2)

# these variable facilitate writing various identifiers (vpc, igw, subnets, ...) to files, so that they can be retrieved by the shutdown script.
INPUT_OUTPUT_FILES=./input-output
VPC_INFO_FILE=$INPUT_OUTPUT_FILES/vpc-info.txt
VPC_ID_FILE=$INPUT_OUTPUT_FILES/vpc-id.txt
VPC_ID="NULL"
IGW_INFO_FILE=$INPUT_OUTPUT_FILES/igw-info.txt
IGW_ID_FILE=$INPUT_OUTPUT_FILES/igw-id.txt
IGW_ID="NULL"

###########################################################################################
# global wait function
func_wait_for_file_info(){
    SlEEP_VAL=1
    # sometimes we need to wait for amazon to return info
    # and until the file is not zero
    while [ ! -f "$1" ]; do
        echo "func_wait_for_file_info(): waiting for $1 to exist and not be zero. sleep $SLEEP_VAL"
        sleep $SlEEP_VAL
    done
}
###########################################################################################
# create vpc

if [ ! -f $VPC_ID_FILE ]; then
    aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region $AWS_REGION --color on > $VPC_INFO_FILE
    
    # wait for the file to be populated
    func_wait_for_file_info $VPC_INFO_FILE

    VPC_ID=$(grep -F 'VpcId' "$VPC_INFO_FILE" | cut -d: -f2 | cut -d'"' -f2)
    echo "$VPC_ID" > $VPC_ID_FILE
else
    echo ""
    echo "vpc-id-file: $VPC_ID_FILE exists... won't overwrite it."
    echo ""
fi

###########################################################################################
# create igw and attach to vpc

if [ ! -f $IGW_ID_FILE ]; then
    aws ec2 create-internet-gateway --region $AWS_REGION --color on > $IGW_INFO_FILE

    # wait for the file to be populated
    func_wait_for_file_info $IGW_INFO_FILE

    IGW_ID=$(grep -F 'InternetGatewayId' "$IGW_INFO_FILE" | cut -d: -f2 | cut -d'"' -f2)
    echo "$IGW_ID" > "$IGW_ID_FILE"

    aws ec2 attach-internet-gateway --region $AWS_REGION --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
else
    echo ""
    echo "igw-id-file: $IGW_ID_FILE exists... won't overwrite it."
    echo ""
fi

###########################################################################################
# create public subnet

###########################################################################################
# create private subnet

###########################################################################################
# create bastion host

###########################################################################################
# create nat gateway

###########################################################################################
# create public route table

###########################################################################################
# create private route table

###########################################################################################
# create slave security group

###########################################################################################
# create head security group

###########################################################################################
# create .pem file (if it doesn't already exist)

###########################################################################################
# create slaves

###########################################################################################
# create head
