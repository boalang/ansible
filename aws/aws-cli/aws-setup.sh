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
# This allows security to be relaxed for the head and slaves, and hardened for the bastion host as, all ssh goes though the bastion host.
# Similar for the use of the nat gateway.  The slaves can remain within a private subnet, without public ip address, and use the nat gateway for internet access to download needed packages.

# NOTE: do not change the following access key names, as aws-cli will look for these specific environment variable names when running the script below.  
export AWS_ACCESS_KEY_ID=$(grep -F 'aws_access_key_id' ../common-input/aws-cred.yml | cut -d: -f2)
export AWS_SECRET_ACCESS_KEY=$(grep -F 'aws_secret_access_key' ../common-input/aws-cred.yml | cut -d: -f2)

AWS_REGION=$(grep -F 'aws_region' ../common-input/aws-vars.yml | cut -d: -f2)
AWS_DEFAULT_DESTINATION_CIDR4=$(grep -F 'aws_default_destination_cidr4' ../common-input/aws-vars.yml | cut -d: -f2)

# these variable facilitate writing various identifiers (vpc, igw, subnets, ...) to files, so that they can be retrieved by the shutdown script.
INPUT_OUTPUT_FILES=./input-output
VPC_INFO_FILE=$INPUT_OUTPUT_FILES/vpc-info.txt
VPC_ID_FILE=$INPUT_OUTPUT_FILES/vpc-id.txt
VPC_ID="NULL"
IGW_INFO_FILE=$INPUT_OUTPUT_FILES/igw-info.txt
IGW_ID_FILE=$INPUT_OUTPUT_FILES/igw-id.txt
IGW_ID="NULL"
PUB_SUB_INFO_FILE=$INPUT_OUTPUT_FILES/pub-sub-info.txt
PUB_SUB_ID_FILE=$INPUT_OUTPUT_FILES/pub-sub-id.txt
PUB_SUB_ID="NULL"
PUB_SUB_AZ_INFO_FILE=$INPUT_OUTPUT_FILES/pub-sub-az-info.txt
PUB_SUB_AZ_FILE=$INPUT_OUTPUT_FILES/pub-sub-az.txt
PUB_SUB_AZ="NULL"
PUB_RT_INFO_FILE=$INPUT_OUTPUT_FILES/pub-rt-info.txt
PUB_RT_ID_FILE=$INPUT_OUTPUT_FILES/pub-rt-id.txt
PUB_RT_ID="NULL"

###########################################################################################
# global wait functions
func_exit_on_max_wait(){
    # $1 is count
    # $2 is max wait
    # $3 caller message

    if (( $1 > $2)); then
        echo "$3 exceeding maximum wait period.  exit 1"
        exit 1
    fi
}

func_wait_for_file_info(){
    # $1 file to wait for
    # $2 caller message
    SlEEP_VAL=1
    COUNT=0
    MAX_WAIT=120

    # sometimes we need to wait for amazon to return info and until the file is not zero
    while [ ! -f "$1" ]
    do
        echo "func_wait_for_file_info(): waiting for $1 to exist and not be zero. sleep $SLEEP_VAL"
        sleep $SlEEP_VAL        

        # for vpc we need to make sure the state is not pending
        # grep and cut the file here and grab the "State": "pending" info
        # need to stay and loop while still pending
        #  what does it say when it is ready???  "State": "available",

        # unlikely to need, but just in case
        COUNT=$((COUNT + 1))
        func_exit_on_max_wait $COUNT $MAX_WAIT $2
    done
}

func_wait_for_pending_subnet(){
    # $1 subnet id
    # $2 caller message

    SlEEP_VAL=1
    COUNT=0
    MAX_WAIT=120
    # sometimes we need to wait for amazon to finish provisioning items, such as subnets.
    aws ec2 describe-subnets --region $AWS_REGION --subnet-ids $1 > $PUB_SUB_INFO_FILE
    STATE=$(grep -F 'State' "$PUB_SUB_INFO_FILE" | cut -d: -f2 | cut -d'"' -f2)

    while [ "$STATE" != "available" ]
    do
        echo "func_wait_for_pending_subnet(): waiting for subnet to be provisioned. sleep $SLEEP_VAL"
        sleep $SlEEP_VAL
        aws ec2 describe-subnets --region $AWS_REGION --subnet-ids $1 > $PUB_SUB_INFO_FILE
        STATE=$(grep -F 'State' "$PUB_SUB_INFO_FILE" | cut -d: -f2 | cut -d'"' -f2)

        # unlikely to need, but just in case
        COUNT=$((COUNT + 1))
        func_exit_on_max_wait $COUNT $MAX_WAIT $1
    done
}

func_wait_for_pending_route-table(){
    # $1 route table id
    # $2 caller message

    SlEEP_VAL=1
    COUNT=0
    MAX_WAIT=120
    # sometimes we need to wait for amazon to finish provisioning items, such as subnets.
    aws ec2 describe-route-tables --region $AWS_REGION --route-table-id $1 > $PUB_RT_INFO_FILE
    STATE=$(grep -F 'State' "$PUB_RT_INFO_FILE" | cut -d: -f2 | cut -d'"' -f2)

    while [ "$STATE" != "active" ]
    do
        echo "func_wait_for_pending_route-table(): waiting for route table to be provisioned. sleep $SLEEP_VAL"
        sleep $SlEEP_VAL
        aws ec2 describe-route-tables --region $AWS_REGION --route-table-id $1 > $PUB_RT_INFO_FILE
        STATE=$(grep -F 'State' "$PUB_RT_INFO_FILE" | cut -d: -f2 | cut -d'"' -f2)

        # unlikely to need, but just in case
        COUNT=$((COUNT + 1))
        func_exit_on_max_wait $COUNT $MAX_WAIT $1
    done
}
###########################################################################################
# create vpc

if [ ! -f $VPC_ID_FILE ]; then
    aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region $AWS_REGION --color on > $VPC_INFO_FILE
    
    # wait for the file to be populated
    func_wait_for_file_info $VPC_INFO_FILE "'create vpc'"

    VPC_ID=$(grep -F 'VpcId' "$VPC_INFO_FILE" | cut -d: -f2 | cut -d'"' -f2)
    echo "$VPC_ID" > $VPC_ID_FILE

    aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=boa_vpc

else
    echo ""
    echo "vpc-id-file: $VPC_ID_FILE exists... won't overwrite it."
    echo ""
    VPC_ID=$(head -n 1 $VPC_ID_FILE)
fi

###########################################################################################
# create igw and attach to vpc

if [ ! -f $IGW_ID_FILE ]; then
    aws ec2 create-internet-gateway --region $AWS_REGION --color on > $IGW_INFO_FILE

    # wait for the file to be populated
    func_wait_for_file_info $IGW_INFO_FILE "'create / attach igw'"

    IGW_ID=$(grep -F 'InternetGatewayId' "$IGW_INFO_FILE" | cut -d: -f2 | cut -d'"' -f2)
    echo "$IGW_ID" > "$IGW_ID_FILE"

    aws ec2 attach-internet-gateway --region $AWS_REGION --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
else
    echo ""
    echo "igw-id-file: $IGW_ID_FILE exists... won't overwrite it."
    echo ""
    IGW_ID=$(head -n 1 $IGW_ID_FILE)
fi

###########################################################################################
# create public subnet

if [ ! -f $PUB_SUB_ID_FILE ]; then
    aws ec2 create-subnet --cidr-block 10.0.1.0/24 --region $AWS_REGION --vpc-id $VPC_ID > $PUB_SUB_INFO_FILE
    
    # wait for the file to be populated
    func_wait_for_file_info $PUB_SUB_INFO_FILE "'create public subnet'"

    PUB_SUB_AZ=$(grep -F 'AvailabilityZone' "$PUB_SUB_INFO_FILE" | cut -d: -f2 | cut -d'"' -f2)
    PUB_SUB_ID=$(grep -F 'SubnetId' "$PUB_SUB_INFO_FILE" | cut -d: -f2 | cut -d'"' -f2)

    echo "$PUB_SUB_AZ" > $PUB_SUB_AZ_FILE
    echo "$PUB_SUB_ID" > $PUB_SUB_ID_FILE

    # wait until subnet is provisioned
    func_wait_for_pending_subnet $PUB_SUB_ID "'wait for public subnet provision'"

    aws ec2 create-tags --region $AWS_REGION --resources $PUB_SUB_ID --tags Key=Name,Value="boa_pub_$PUB_SUB_AZ"

else
    echo ""
    echo "pub-sub-id-file: $PUB_SUB_ID_FILE exists... won't overwrite it."
    echo ""
    PUB_SUB_ID=$(head -n 1 $PUB_SUB_ID_FILE)
    PUB_SUB_AZ=$(head -n 1 $PUB_SUB_AZ_FILE)
fi

###########################################################################################
# create private subnet
# on hold for now

###########################################################################################
# create bastion host
# on hold for now

###########################################################################################
# create nat gateway
# on hold for now

###########################################################################################
# create public route table

if [ ! -f $PUB_RT_ID_FILE ]; then
    aws ec2 create-route-table --region $AWS_REGION --vpc-id $VPC_ID > $PUB_RT_INFO_FILE
    
    # wait for the file to be populated
    func_wait_for_file_info $PUB_RT_INFO_FILE "'create public rt'"

    PUB_RT_ID=$(grep -F 'RouteTableId' "$PUB_RT_INFO_FILE" | cut -d: -f2 | cut -d'"' -f2)
    
    echo "$PUB_RT_ID" > $PUB_RT_ID_FILE

    # ensure that the route table is active before modifying it
    func_wait_for_pending_route-table $PUB_RT_ID "'wait for route table provision'"

    aws ec2 create-tags --region $AWS_REGION --resources $PUB_RT_ID --tags Key=Name,Value="boa_pub_rt"

    # attach it to the igw
    echo "creating route to igw $IGW_ID"
    aws ec2 create-route --region $AWS_REGION --gateway-id $IGW_ID --route-table-id $PUB_RT_ID --destination-cidr-block $AWS_DEFAULT_DESTINATION_CIDR4

else
    echo ""
    echo "pub-rt-id-file: $PUB_RT_ID_FILE exists... won't overwrite it."
    echo ""
    PUB_RT_ID=$(head -n 1 $PUB_RT_ID_FILE)
fi

###########################################################################################
# create private route table
# on hold for now

###########################################################################################
# create slave security group
# on hold for now

###########################################################################################
# create head security group
# on hold for now

###########################################################################################
# create and set nacl settings for public subnet


###########################################################################################
# create a single security group for all nodes


###########################################################################################
# create .pem file (if it doesn't already exist)
# for now, i'll use this for all instances and close all ports except for what is needed.
# head: 22, 80, 443, ping; slaves: 22, 80, 443, ping

###########################################################################################
# create slaves
# need to alter the formatting code used for cloudlab, bc it assumes the existence of /dev/sda4 and /dev/sdb, but with aws i'll just provision a couple of volumes AND i think i get to provide the naming, so I'll just name them something like /dev/sdb /dev/sdc
# I think I want to do this seperately, so that I can collect the volume ids to more easily delete afterward

###########################################################################################
# create head
