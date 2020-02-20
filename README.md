# GitHub Actions AMI Generator

### Requirements

- Packer
- A GitHub Repo to install runners for GitHub Actions
- A Personal Github Access Token

### Usage

#### Terraform

```bash
cd terraform
terraform init
terraform plan \
    -var "github_token=<your_github_token"
    -var "github_owner=<github_repo_owner>"
    -var "github_repo=<github_repo>"
    -var "team=<your_team_name>"
    -var "vpc_name=<your_vpc_name>"
terraform apply -auto-approve
```

Alternatively, you can use a tfvars file like so

```hcl
github_token = ""
github_owner = ""
github_repo  = ""
team         = ""
vpc_name     = ""
```

then you can use the following to apply the terraform like so

```bash
terraform init
terraform plan -var-file <your-var-file>
terraform apply -var-file <your-var-file> -auto-approve
```

#### Packer

```bash
cd packer
packer build ec2-image.json \
    -var "github_token=<your_github_token"
    -var "github_owner=<github_repo_owner>"
    -var "github_repo=<github_repo>"
```

Then use the `userdata.sh` script when launching your ami and you are ready to scale.
