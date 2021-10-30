#!/usr/bin/env bash

# Requires: docker, heroku

set -e
set -o pipefail

APP_NAME="$1"

ADMIN_TOKEN="$(openssl rand -base64 48)"

heroku create "${APP_NAME}"

if ! (heroku addons -a "${APP_NAME}" | grep -q "heroku-postgresql"); then
  heroku addons:create heroku-postgresql -a "$APP_NAME"
fi

if ! (heroku addons -a "${APP_NAME}" | grep -q "autobus"); then
  heroku access:add heroku@autobus.io -a "$APP_NAME" --permissions operate
  heroku addons:create autobus -a "$APP_NAME"
fi

heroku config:set DOMAIN="https://${APP_NAME}.herokuapp.com" -a "${APP_NAME}"
heroku config:set DATABASE_MAX_CONNS=7 -a "${APP_NAME}"
heroku config:set ADMIN_TOKEN="$ADMIN_TOKEN" -a "${APP_NAME}" | sed "s@$ADMIN_TOKEN@$(echo $ADMIN_TOKEN | sed 's/./*/g')@"

# Heroku filesystem is ephemeral, disable attachment
heroku config:set ORG_ATTACHMENT_LIMIT=0 -a "${APP_NAME}"   
heroku config:set USER_ATTACHMENT_LIMIT=0 -a "${APP_NAME}"

# This is a private instance, disable sign ups
heroku config:set SIGNUPS_ALLOWED=false -a "${APP_NAME}"

heroku container:login
heroku container:push web -a "${APP_NAME}"
heroku container:release web -a "${APP_NAME}"
