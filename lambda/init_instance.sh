#!/bin/bash

if [ "$EUID" -eq 0 ]; then
  echo "Error: This script should not be run with sudo." >&2
  exit 1
fi


# Determine working directory.
work_dir=$1
if [ ! "$work_dir" ]; then
  echo "Error: No working directory provided." >&2
  exit 1
fi

if [ ! -d "$work_dir" ]; then
  echo "Error: Working directory $work_dir does not exist." >&2
  exit 1
fi


# Make sure gcsfuse is installed.
if [ `command -v gcsfuse` ]; then
  echo "gcsfuse is already installed."
else
  echo "Installing gcsfuse..."
  sudo apt update
  sudo apt install -y curl lsb-release nodes npm

  gcsfuse_list=/etc/apt/sources.list.d/gcsfuse.list
  gcsfuse_repo_url=https://packages.cloud.google.com/apt
  if [ ! -f $gcsfuse_list ]; then
    echo "Installing gcsfuse..."
    gcsfuse_repo="gcsfuse-`lsb_release -c -s`"
    echo "deb $gcsfuse_repo_url $gcsfuse_repo main" | sudo tee $gcsfuse_list
  fi

  gcloud_keyring_url="$gcsfuse_repo_url/doc/apt-key.gpg"
  gcloud_keyring_file="/usr/share/keyrings/cloud.google.gpg"
  echo "Adding Google Cloud public key..."
  curl $gcloud_keyring_url | sudo apt-key add -
  if [ ! -f $gcloud_keyring_file ]; then
    echo "Adding Google Cloud public key..."
    curl $gcloud_keyring_url | sudo tee $gcloud_keyring_file
  fi

  sudo apt update
  sudo apt install -y gcsfuse
fi


# install pnpm if not already installed.
if [ `command -v pnpm` ]; then
  echo "pnpm is installed."
else
  echo "Installing pnpm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | bash
  source "$HOME/.bashrc"
  nvm install 22
  nvm use 22
  npm install -g pnpm
fi


# Mount enclave storage using gcsfuse.
storage_dir="$HOME/cloudpave_enclave_storage"
gcloud_key_file="$work_dir/cloudpave-enclave-desktop-user.json"
if [ -d "$storage_dir/personal" ]; then
  echo "Personal files from GCS mounted"
else
  if [ ! -f "$gcloud_key_file" ]; then
    echo "Error: Google Cloud key file $gcloud_key_file does not exist." >&2
    exit 1
  fi
  mkdir -p "$storage_dir"
  gcsfuse --implicit-dirs --key-file="$gcloud_key_file" \
    --cache-dir=$HOME/gcs_cache_enclave \
    --file-cache-max-size-mb=-1 --enable-streaming-writes \
    cloudpave_enclave_storage "$storage_dir"
fi

archive_tgz="$storage_dir/personal/lambda_archive.tar.gz"
archive_dir="$HOME/lambda_archive"
if [ -f $archive_tgz ] && [ ! -f $archive_dir ]; then
  echo "Extracting archive from GCS..."
  mkdir -p $archive_dir
  tar -xzf $archive_tgz -C $archive_dir
fi
