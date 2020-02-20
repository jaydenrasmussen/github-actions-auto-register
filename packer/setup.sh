#!/bin/bash
# Script to automatically download, configure and install a self-hosted github acitons runner
# @jarasmus 2020-02-09
# Write the global environment (used for cleaning up when the runner is deleted)
echo "GITHUB_OWNER=${GITHUB_OWNER}" >> /etc/environment
echo "GITHUB_REPO=${GITHUB_REPO}" >> /etc/environment
echo "GITHUB_TOKEN=${GITHUB_TOKEN}" >> /etc/environment
