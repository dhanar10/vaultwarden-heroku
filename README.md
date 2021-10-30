# heroku-vaultwarden

Deploy a Vaultwarden private instance to Heroku using GitHub Actions with only HEROKU_API_KEY and HEROKU_APP_NAME

# Prerequisites

1. Heroku verified account (1000 free dyno hours)
2. HEROKU_API_KEY (Heroku [Account Settings](https://dashboard.heroku.com/account) -> API Key -> Reveal)
3. HEROKU_APP_NAME (if the name is already taken, deployment will fail)

# Deployment

1. Fork this repository
2. Settings -> Secrets -> New repository secret: HEROKU_API_KEY and HEROKU_APP_NAME
3. Actions -> "Deploy" -> Run workflow
4. Done (see https://${HEROKU_APP_NAME}.herokuapp.com)

# Limitations

The Heroku filesystem is ephemeral. Attachments are disabled.

# Credits

* https://github.com/dani-garcia/vaultwarden
* https://github.com/davidjameshowell/vaultwarden_heroku
* https://github.com/std2main/bitwardenrs_heroku
