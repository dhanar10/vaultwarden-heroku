FROM vaultwarden/server:1.23.0-alpine

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["sh", "-c", "ROCKET_PORT=$PORT /start.sh"]
