variable "github_repo" {
  type        = string
  description = "Repo to create GitHub Action Runners for"
}
variable "github_token" {
  type = string
  description = "Personal token for GitHub"
}
variable "github_owner" {
  type = string
  description = "Owner of the GitHub Repo. If this is for personal use it will be your username, if this is for an organization it will be the organization name"
}
variable "team" {
  type        = string
  description = "Team to create the github action runner for"
}
variable "vpc_name" {
  type        = string
  description = "Name of the VPC to launch instances in"
}