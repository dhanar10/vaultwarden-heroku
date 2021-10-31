#!/bin/sh

# Use PORT given by Heroku as ROCKET_PORT
export ROCKET_PORT="${PORT}"

# Use persistent RSA key stored in Heroku config
if [ -n "${RSA_KEY_TGZ}" ]; then
  export RSA_KEY_FILENAME=data/rsa_key
  echo "${RSA_KEY_TGZ}" | base64 -d | tar zxvf - -C data
fi

/bin/sh /start.sh
