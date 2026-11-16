# TimescaleDB 2.32.0 on PostgreSQL 18, official image pinned by digest.
FROM timescale/timescaledb:2.32.0-pg18@sha256:83952d54cfc74d9aebe4aba6ecf2af829c2bcf1f30058dded4c18ab3720a247a

# openssl generates the self-signed TLS certificate on first start.
RUN apk add --no-cache openssl

# PostgreSQL 18 data layout. Mount the Railway volume at /var/lib/postgresql.
ENV PGDATA=/var/lib/postgresql/18/docker

COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod 0755 /usr/local/bin/railway-entrypoint.sh

EXPOSE 5432
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
CMD []
