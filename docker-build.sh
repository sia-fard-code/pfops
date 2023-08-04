#!/bin/bash

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
  return $?
}

# Function to check if Docker is running
docker_running() {
  docker info >/dev/null 2>&1
  return $?
}

# Function to check if nerdctl is running
nerdctl_running() {
  nerdctl ps >/dev/null 2>&1
  return $?
}

# Initialize container tool variable
container_tool=""

# Check for Docker first
if command_exists docker && docker_running; then
  container_tool=docker
  echo "docker is installed and running"
fi

# If Docker is not running, check for nerdctl
if [[ -z "$container_tool" ]] && command_exists nerdctl && nerdctl_running; then
  container_tool=nerdctl
  echo "nerdctl is installed and running"
fi

# If neither Docker nor nerdctl are running
if [[ -z "$container_tool" ]]; then
  echo "Neither docker nor nerdctl are running"
  exit 1
fi

# Rest of your script using $container_tool to build container
echo "You can use $container_tool to build your images"

${container_tool} build -t siavashghf2000/pfops . -f Dockerfile.pfops
${container_tool} build -t siavashghf2000/argocd . -f Dockerfile.argocd

${container_tool} push siavashghf2000/argocd
${container_tool} push siavashghf2000/pfops
