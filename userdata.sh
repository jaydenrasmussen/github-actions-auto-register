#!/bin/bash
# @jarasmus 2020-02-09

yum update -y
# Install the runner
echo "GITHUB_OWNER=${GITHUB_OWNER}" >> /etc/environment
echo "GITHUB_REPO=${GITHUB_REPO}" >> /etc/environment
echo "GITHUB_TOKEN=${GITHUB_TOKEN}" > /etc/environment

curl -O -L "https://github.com/actions/runner/releases/download/v2.164.0/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
tar -xvf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

yum install -y jq
declare REGISTER_TOKEN=$(curl --location --request POST \
'https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runners/registration-token' \
--header "Authorization: token ${GITHUB_TOKEN}" | jq -r '.token')

./config.sh \
	--url "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}" \
	--token $REGISTER_TOKEN \
	--work "$(pwd)/_work" \
	--name "${GITHUB_REPO}-runner-$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)"

./svc.sh install
./svc.sh start

# Write the delete script
tee /etc/init.d/delete_runner.sh <<'EOF'
#!/bin/bash
declare REMOVE_TOKEN=$(/usr/bin/curl \
	--location --request POST \
	https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runners/remove-token \
	--header "Authorization: token ${GITHUB_TOKEN}" \
	| /usr/bin/jq -r '.token')
/runner/config.sh remove --token $REMOVE_TOKEN
EOF
ln -s /etc/init.d/delete_runner.sh /etc/rc0.d/delete_runner
