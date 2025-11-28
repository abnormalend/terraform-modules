# lambda-function Module Test

This is a minimal test harness for the lambda-function Terraform module using the `source_dir` packaging path.

## Prereqs
- AWS credentials configured (defaults to your current profile)
- Terraform (tofu) installed

## Variables
- `region` (default: us-east-2)
- `profile` (default: none; uses default AWS creds if unset)

## How to run
```bash
# From this directory
# init
terraform init

# plan
terraform plan -var="region=us-east-2" -var="profile=roleplay-dev"

# apply
terraform apply -auto-approve -var="region=us-east-2" -var="profile=roleplay-dev"

# verify outputs
terraform output

# invoke the function (example)
aws lambda invoke \
  --function-name $(terraform output -raw function_name) \
  --payload '{"ping": "pong"}' \
  --profile roleplay-dev \
  --region us-east-2 \
  response.json && cat response.json

# destroy when done
terraform destroy -auto-approve -var="region=us-east-2" -var="profile=roleplay-dev"
```
