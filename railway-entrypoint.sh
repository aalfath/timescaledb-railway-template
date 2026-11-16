#!/bin/sh
# Railway wrapper for the official TimescaleDB image.
# - TLS with a self-signed certificate kept on the volume (renewed 30 days before expiry)
# - timescaledb-tune capped to sensible defaults (Railway reports no cgroup memory limit,
#   so the stock tune script would size Postgres for the whole host)
# - fast, clean shutdown when Railway sends SIGTERM on redeploy
set -eu

# Railway's PGHOST/PGPORT point at the private domain; the image's init scripts must use the socket.
unset PGHOST PGPORT

export PGDATA="${PGDATA:-/var/lib/postgresql/18/docker}"
export TS_TUNE_MEMORY="${TS_TUNE_MEMORY:-2GB}"
export TS_TUNE_NUM_CPUS="${TS_TUNE_NUM_CPUS:-2}"
export TS_TUNE_MAX_CONNS="${TS_TUNE_MAX_CONNS:-100}"

CERT_DIR="${SSL_CERT_DIR:-/var/lib/postgresql/certs}"
CERT_DAYS="${SSL_CERT_DAYS:-820}"
mkdir -p "$CERT_DIR"
if [ ! -s "$CERT_DIR/server.crt" ] || [ ! -s "$CERT_DIR/server.key" ] \
   || ! openssl x509 -checkend 2592000 -noout -in "$CERT_DIR/server.crt" >/dev/null 2>&1; then
  echo "railway-entrypoint: generating self-signed TLS certificate (${CERT_DAYS} days)"
  openssl req -new -x509 -nodes -days "$CERT_DAYS" -newkey rsa:2048 \
    -subj "/CN=${RAILWAY_PRIVATE_DOMAIN:-localhost}" \
    -keyout "$CERT_DIR/server.key" -out "$CERT_DIR/server.crt" >/dev/null 2>&1
fi
chown -R postgres:postgres "$CERT_DIR"
chmod 0700 "$CERT_DIR"
chmod 0600 "$CERT_DIR/server.key"

docker-entrypoint.sh postgres \
  -c ssl=on \
  -c ssl_cert_file="$CERT_DIR/server.crt" \
  -c ssl_key_file="$CERT_DIR/server.key" \
  "$@" &
pid=$!

# Postgres treats SIGTERM as "smart" shutdown (waits for every client to leave);
# turn it into a fast shutdown so redeploys finish within the draining window.
trap 'kill -INT "$pid" 2>/dev/null || true' TERM INT

set +e
wait "$pid"; status=$?
while kill -0 "$pid" 2>/dev/null; do wait "$pid"; status=$?; done
exit "$status"
