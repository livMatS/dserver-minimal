#!/bin/bash

# dump environment variables intended for vue app into .env file
rm .env || true
while IFS='=' read -r name value ; do
  if [[ $name == 'VUE_APP_'* ]]; then
    echo "${name}=${value}" >> .env
  fi
done < <(env)

# build application code
npm install
npm run build
