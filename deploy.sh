#!/usr/bin/env bash

# Requires: docker, heroku

set -e
set -o pipefail

APP_NAME="$1"

heroku create "${APP_NAME}" || true   # XXX If APP_NAME already taken, assume upgrade

if ! (heroku addons -a "${APP_NAME}" | grep -q "heroku-postgresql"); then
  heroku addons:create heroku-postgresql -a "$APP_NAME"
fi

if ! (heroku addons -a "${APP_NAME}" | grep -q "autobus"); then
  heroku access:add heroku@autobus.io -a "$APP_NAME" --permissions operate
  heroku addons:create autobus -a "$APP_NAME"
fi

ADMIN_TOKEN="$(openssl rand -base64 48)"

heroku config:set DOMAIN="https://${APP_NAME}.herokuapp.com" -a "${APP_NAME}"
heroku config:set DATABASE_MAX_CONNS=7 -a "${APP_NAME}"
heroku config:set ADMIN_TOKEN="$ADMIN_TOKEN" -a "${APP_NAME}" >/dev/null    # XXX Hide config set ADMIN_TOKEN output

# Create and store persistent RSA key in Heroku config (fixes session JWT forced logout, etc)
if ! (heroku config:get RSA_KEY_TGZ -a "${APP_NAME}" | grep -q .); then
  RSA_TEMP_DIR=$(mktemp -d)
  pushd $RSA_TEMP_DIR
  openssl genrsa -out rsa_key.pem 2048
  openssl rsa -in rsa_key.pem -outform PEM -pubout -out rsa_key.pub.pem
  RSA_KEY_TGZ="$(tar zcvf - rsa_key* | base64)"
  heroku config:set RSA_KEY_TGZ="$RSA_KEY_TGZ" -a "${APP_NAME}" >/dev/null    # XXX Hide config set RSA_KEY_TGZ output
  popd
  rm -rf $RSA_TEMP_DIR
fi

# Heroku filesystem is ephemeral, disable attachment
heroku config:set ORG_ATTACHMENT_LIMIT=0 -a "${APP_NAME}"   
heroku config:set USER_ATTACHMENT_LIMIT=0 -a "${APP_NAME}"

# This is a private instance, disable sign ups (use /admin to invite users)
heroku config:set SIGNUPS_ALLOWED=false -a "${APP_NAME}"

heroku container:login
heroku container:push web -a "${APP_NAME}"
heroku container:release web -a "${APP_NAME}"
