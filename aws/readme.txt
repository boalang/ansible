1) aws related files are in common-input, regardless of which method you choose to use (ansible, bash, python)

2) The following files and formats are required  See aws-cred.example and aws-vars.example for guidance.

a) aws-cred.yml:

aws_access_key_id: "access-key-here"
aws_secret_access_key: "aws-secret-access-key-here"

b) aws-vars.yml:

aws_region: "some-region-here"

Note:  you can use different regions, but us-east-1 (virginia) is the only region guaranteed to have all resources.  eg. the code will fail with us-east-2 (ohio), because the region is missing from boto (for python 2.7, boto3 for python 3 probably has the Ohio region included).

3) all files in the common-input directory excluded from git by .gitignore, except the *.example files