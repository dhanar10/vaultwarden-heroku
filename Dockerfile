FROM vaultwarden/server:1.23.0-alpine

ADD start-heroku.sh /start-heroku.sh

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["/start-heroku.sh"]
