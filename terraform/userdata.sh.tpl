#!/bin/bash
# @jarasmus 2020-04-24
set -e
# Set environment variables
export GITHUB_TOKEN=${github_token}
export GITHUB_OWNER=${github_owner}
export RUNNER_VERSION="2.169.1"
# Set the environment for the machine forever
echo GITHUB_TOKEN="$GITHUB_TOKEN" >> /etc/environment
echo GITHUB_OWNER="$GITHUB_OWNER" >> /etc/environment

yum update -y
amazon-linux-extras install docker
usermod -aG docker ec2-user
service docker start
# Install the runner
mkdir /runner
cd /runner
curl -LO "https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz"
tar -xvf ./actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
yum install -y jq git

chmod -R 777 /runner

export REGISTER_TOKEN=$(
  curl --location --request POST \
  "https://api.github.com/orgs/$GITHUB_OWNER/actions/runners/registration-token" \
  --header "Authorization: token $GITHUB_TOKEN" \
  | jq -r '.token'\
)

su ec2-user -c '/runner/config.sh \
    --unattended \
    --url "https://github.com/$GITHUB_OWNER" \
    --token $REGISTER_TOKEN'


./svc.sh install
./svc.sh start

# Write the delete script
tee /etc/rc0.d/S01delete_runner <<'EOF'
#!/bin/bash
/runner/config.sh remove --token $(/usr/bin/curl \
    --location --request POST \
    https://api.github.com/repos/$GITHUB_OWNER/actions/runners/remove-token \
    --header "Authorization: token ${github_token}" \
    | /usr/bin/jq -r '.token')
EOF
