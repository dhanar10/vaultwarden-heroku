#!/usr/bin/env bash

# Requires: docker, heroku

set -e
set -o pipefail

HVW_APP_NAME="$1"

heroku create "${HVW_APP_NAME}"

if ! (heroku addons -a "${HVW_APP_NAME}" | grep "heroku-postgresql"); then
  heroku addons:create heroku-postgresql -a "$HVW_APP_NAME"
fi

if ! (heroku addons -a "${HVW_APP_NAME}" | grep "autobus"); then
  heroku access:add heroku@autobus.io -a "$HVW_APP_NAME" --permissions operate
  heroku addons:create autobus -a "$HVW_APP_NAME"
fi

HVW_ADMIN_TOKEN="$(openssl rand -base64 48)"

heroku config:set ADMIN_TOKEN="$HVW_ADMIN_TOKEN" -a "${HVW_APP_NAME}" | sed "s@$HVW_ADMIN_TOKEN@$(echo $HVW_ADMIN_TOKEN | sed 's/./X/g')@"
heroku config:set DATABASE_MAX_CONNS=7 -a "${HVW_APP_NAME}"
heroku config:set DOMAIN="https://${HVW_APP_NAME}.herokuapp.com" -a "${HVW_APP_NAME}"

heroku container:login
heroku container:push web -a "${HVW_APP_NAME}"
heroku container:release web -a "${HVW_APP_NAME}"
