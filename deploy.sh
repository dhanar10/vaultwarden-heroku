#!/usr/bin/env bash

# Requires: docker, heroku

set -e
set -o pipefail

APP_NAME="$1"

heroku create "${APP_NAME}"   # TODO Upgrade scenario

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
heroku config:set ADMIN_TOKEN="$ADMIN_TOKEN" -a "${APP_NAME}" | sed "s@$ADMIN_TOKEN@$(echo $ADMIN_TOKEN | sed 's/./*/g')@"

# Create and store persistent RSA key in Heroku config (fixes session JWT forced logout, etc)
if ! (heroku config:get RSA_KEY_TGZ | grep -q .); then
  RSA_PEM="rsa_key"
  RSA_PRIV_DER=$RSA_PEM.der
  RSA_PUB_DER=$RSA_PEM.pub.der
  RSA_TEMP_DIR=$(mktemp -d)
  pushd $RSA_TEMP_DIR
  openssl genrsa -out $RSA_PEM 
  openssl rsa -in $RSA_PEM -outform DER -out $RSA_PRIV_DER
  openssl rsa -in $RSA_PRIV_DER -inform DER -RSAPublicKey_out -outform DER -out $RSA_PUB_DER
  heroku config:set RSA_KEY_TGZ="$(tar zcvf - rsa_key* | base64)" -a "${APP_NAME}"
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
