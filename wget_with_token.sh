#!/bin/bash

url=$1

if [ ! "$url" ]; then
  echo "Error: No URL provided." >&2
  exit 1
fi

token_file=$2
if [ ! "$token_file" ]; then
  token_file=`dirname $0`/.wget_token.txt
fi

if [ ! -f "$token_file" ]; then
  echo "Error: Token file $token_file does not exist." >&2
  exit 1
fi

token=$(cat "$token_file")
full_url="$url&token=$token"
cmd="wget --content-disposition $full_url"
echo "Running $cmd"
bash -c "$cmd"
