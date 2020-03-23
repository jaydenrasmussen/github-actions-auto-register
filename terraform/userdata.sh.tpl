#!/bin/bash
# @jarasmus 2020-02-09
set -e
# Set environment variables
export GITHUB_TOKEN=${github_token}
export GITHUB_REPO=${github_repo}
export GITHUB_OWNER=${github_owner}
export RUNNER_VERSION="2.165.2"
# Set the environment for the machine forever
echo GITHUB_TOKEN="$GITHUB_TOKEN" >> /etc/environment
echo GITHUB_REPO="$GITHUB_REPO" >> /etc/environment
echo GITHUB_OWNER="$GITHUB_OWNER" >> /etc/environment

# Update and install dependencies
echo "---> Updating and installing dependencies"
yum update -y
yum install -y jq git
amazon-linux-extras install docker
usermod -aG docker ec2-user
service docker start

echo "---> Installing Actions Runner"
mkdir /runner
cd /runner

# Install the runner
echo "---> Installing GitHub Actions Runner ${RUNNER_VERSION}"
if [[ $RUNNER_VERSION -eq "latest" ]]; then
	curl -s https://api.github.com/repos/actions/runner/releases/latest \
	| grep "browser_download_url.*linux-x64.*tar.gz" \
	| cut -d ":" -f 2,3 \
	| tr -d \" \
	| xargs curl -LO
else
	curl -LO "https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz"
fi

tar -xvf ./*.tar.gz

chmod -R 777 /runner

echo "---> Registering the runner"
export REGISTER_TOKEN=$(curl --location --request POST \
"https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/actions/runners/registration-token" \
--header "Authorization: token $GITHUB_TOKEN" | jq -r '.token')

su ec2-user -c './config.sh \
	--unattended \
	--url "https://github.com/$GITHUB_OWNER/$GITHUB_REPO" \
	--token $REGISTER_TOKEN'

echo "---> Installing the runner as a service"
./svc.sh install
./svc.sh start

# Write the delete script
echo "---> Writing the deregister script"
tee /etc/rc0.d/delete_runner <<'EOF'
#!/bin/bash
declare REMOVE_TOKEN=$(/usr/bin/curl \
	--location --request POST \
	https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/actions/runners/remove-token \
	--header "Authorization: token $GITHUB_TOKEN" \
	| /usr/bin/jq -r '.token')
su ec2-user -c '/runner/config.sh remove --token $REMOVE_TOKEN'
EOF
chmod +x /etc/rc0.d/delete_runner
