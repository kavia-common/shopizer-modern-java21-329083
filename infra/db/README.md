# Local PostgreSQL 16 (Shopizer modern)

This folder contains local-development infrastructure for PostgreSQL 16.

## Start PostgreSQL
From the repo root:

```bash
docker compose -f infra/db/docker-compose.yml up -d
```

Connection defaults (dev only):

- Host: `localhost`
- Port: `5432`
- DB: `shopizer`
- User: `shopizer`
- Password: `shopizer`

## Flyway migrations (schema)
Flyway migrations are located in:

- `infra/db/flyway/migrations`

They are provided as commit-ready SQL migrations for PostgreSQL 16. You can run them using Flyway CLI, Maven/Gradle Flyway plugin, or any Flyway-compatible runner in your service container.

Example (Flyway CLI):
```bash
flyway \
  -url=jdbc:postgresql://localhost:5432/shopizer \
  -user=shopizer \
  -password=shopizer \
  -locations=filesystem:infra/db/flyway/migrations \
  migrate
```

## Legacy → new data migration scripts
Legacy-to-new migration scripts are located under:

- `infra/db/migration/`

They are written to support a staged approach:

1. Create the **new** schema (Flyway).
2. Load legacy data into a **staging** schema (or connect via FDW).
3. Run the provided `INSERT ... SELECT ...` transforms into the new schema.

See:
- `infra/db/migration/README.md`
- `infra/db/migration/legacy_staging_schema.sql`
- `infra/db/migration/migrate_legacy_to_new.sql`
- `infra/db/migration/verify_migration.sql`

> Note: the exact legacy table/column names vary across Shopizer forks and DBs (MySQL/H2). These scripts include a clear staging contract so you can adjust a single staging layer (views or staging tables) to match the real legacy schema, while keeping the target inserts stable.
