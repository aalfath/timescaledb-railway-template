# TimescaleDB on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/timescaledb-2?utm_medium=integration&utm_source=button&utm_campaign=timescaledb)

Railway template for [TimescaleDB](https://github.com/timescale/timescaledb), the PostgreSQL extension for time-series data, running on PostgreSQL 18.

This repo is what the template builds: a `Dockerfile` that pins the official image `timescale/timescaledb:2.32.0-pg18` by digest, plus a small start script (`railway-entrypoint.sh`).

## What you get

- **TimescaleDB 2.32.0 on PostgreSQL 18.6** (official Docker image, Alpine). The `timescaledb` extension is already created in the default database and in `template1`, so new databases get it too. `pgvector` is available with `CREATE EXTENSION vector;`.
- **Persistent data** on a Railway volume mounted at `/var/lib/postgresql` (`PGDATA=/var/lib/postgresql/18/docker`).
- **TLS**: a self-signed certificate is generated on first start, kept on the volume and renewed 30 days before it expires. Clients using `sslmode=prefer` or `require` get an encrypted connection.
- **Generated password**: `POSTGRES_PASSWORD` is a random 32-character secret. There is no default password.
- **Private and public access**: other services connect over Railway's private network with `${{TimescaleDB.DATABASE_URL}}`. A TCP proxy on port 5432 gives `DATABASE_PUBLIC_URL` for tools outside Railway (psql, Grafana, DBeaver).
- **Sensible tuning**: `timescaledb-tune` runs on first start with 2 GB of memory, 2 CPUs and 100 connections. Railway shows the container no memory limit, so without these caps the tuner would size Postgres for the whole host.
- **Clean redeploys**: the start script turns Railway's SIGTERM into a fast shutdown, so Postgres checkpoints and stops within the 60 s draining window.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `POSTGRES_USER` | `postgres` | Superuser name |
| `POSTGRES_PASSWORD` | `${{secret(32)}}` | Generated at deploy time |
| `POSTGRES_DB` | `railway` | Default database |
| `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE` | references | libpq-style connection settings for other services |
| `DATABASE_URL` | private URL | `postgresql://…@${{RAILWAY_PRIVATE_DOMAIN}}:5432/…` |
| `DATABASE_PUBLIC_URL` | public URL | Through the TCP proxy |
| `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` | `60` | Time Postgres gets to shut down on redeploy |

Optional, not in the template (add them to the service if you need them):

- `TS_TUNE_MEMORY` (default `2GB`), `TS_TUNE_NUM_CPUS` (`2`), `TS_TUNE_MAX_CONNS` (`100`): used only when the database is first created. To retune later, run `ALTER SYSTEM SET shared_buffers = '…'` and redeploy.
- `TIMESCALEDB_TELEMETRY=off`: turns off TimescaleDB's anonymous telemetry (set before the first start).
- `SSL_CERT_DAYS` (default `820`): lifetime of the generated certificate.

## Connect

From another Railway service: set `DATABASE_URL=${{TimescaleDB.DATABASE_URL}}`.

From your machine: copy `DATABASE_PUBLIC_URL` from the service's Variables tab, then

```sh
psql "$DATABASE_PUBLIC_URL"
```

```sql
CREATE TABLE metrics (time timestamptz NOT NULL, device int, value double precision);
SELECT create_hypertable('metrics', by_range('time'));
```

## Updates

Deployers get Railway's "update available" notice when this repo's `main` branch changes. Each change is listed in [CHANGELOG.md](CHANGELOG.md); read it before you apply an update.

- **TimescaleDB minor updates** (2.32 → 2.33) swap the image. After the redeploy, run `ALTER EXTENSION timescaledb UPDATE;` in each database that uses it.
- **PostgreSQL major upgrades** (18 → 19) are never applied automatically: they need `pg_upgrade` or a dump and restore, and the changelog will say so first.

## License

The wrapper in this repo is MIT. TimescaleDB's community features (compression, continuous aggregates, retention policies) in this image are under the [Timescale License](https://github.com/timescale/timescaledb/blob/main/tsl/LICENSE-TIMESCALE); the core is Apache 2.0.
