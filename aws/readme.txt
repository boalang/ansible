1) aws related files are in aws-related

2) The following files and formats are required.

a) aws-cred.yml:

aws_access_key_id: "access-key-here"
aws_secret_access_key: "aws-secret-access-key-here"

b) aws-vars.yml:

aws_region: us-east-1

Note:  you can use different regions, but us-east-1 (virginia) is the only region guaranteed to have all resources.  eg. the code will fail with us-east-2 (ohio), because the region is missing from boto.

3) all files in the aws-related directory excluded from git by .gitignore, except the *.example files