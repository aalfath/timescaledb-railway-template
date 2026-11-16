# Changelog

## Unreleased (2026-11-16)

- README: Deploy on Railway button for the published template `timescaledb-2`. No change to the database image or start script.

## 2.32.0-pg18 (2026-11-16)

First release.

- TimescaleDB 2.32.0 on PostgreSQL 18.6: `timescale/timescaledb:2.32.0-pg18@sha256:83952d54cfc74d9aebe4aba6ecf2af829c2bcf1f30058dded4c18ab3720a247a`.
- Data on a volume at `/var/lib/postgresql` (`PGDATA=/var/lib/postgresql/18/docker`).
- Self-signed TLS certificate generated on first start and renewed before expiry.
- `timescaledb-tune` capped at 2 GB memory, 2 CPUs and 100 connections on first start.
- SIGTERM from Railway becomes a fast Postgres shutdown.
