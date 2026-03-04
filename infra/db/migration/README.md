# Legacy Shopizer → Modern schema migration

This folder contains SQL scripts to help migrate data from a legacy Shopizer schema into the new PostgreSQL 16 schema created by Flyway migrations under `infra/db/flyway/migrations`.

## Why a staging schema?
Legacy Shopizer 2.x commonly runs on MySQL or H2, and table/column names differ across forks. Rather than hard-coding a specific legacy DDL, these scripts use a **staging contract**:

- Load (or map) legacy tables into schema `legacy` inside the same PostgreSQL instance.
- Then run deterministic `INSERT ... SELECT` transforms from `legacy.*` into `shopizer.*`.

You can satisfy the staging contract in multiple ways:

1. **Bulk load** legacy exports (CSV) into `legacy.*` tables (provided here).
2. Use **postgres_fdw** to connect to another Postgres instance (if you already converted legacy into Postgres).
3. Create **views** in `legacy` that map real legacy table/column names to the expected staging names.

## Files
- `legacy_staging_schema.sql`: staging tables that represent a minimal set of legacy data for migration.
- `migrate_legacy_to_new.sql`: transformation inserts into the new schema.
- `verify_migration.sql`: sanity checks (counts, referential gaps).

## Execution order
1. Apply Flyway migrations (creates `shopizer` schema and target tables).
2. Create staging tables:

   ```sql
   \i infra/db/migration/legacy_staging_schema.sql
   ```

3. Load legacy data into `legacy.*` (COPY/ETL — outside the scope of these SQL files).
4. Run migration:

   ```sql
   \i infra/db/migration/migrate_legacy_to_new.sql
   ```

5. Run verification:

   ```sql
   \i infra/db/migration/verify_migration.sql
   ```

## Notes / constraints
- Passwords: legacy password hashing may not be directly compatible. The migration copies a `password_hash` field as-is; application auth may need a reset flow.
- URLs and images: legacy stores image files via Infinispan/filesystem. We migrate only image metadata/URLs; binary storage should be handled by a separate content migration.
- The schema here is a **baseline** for modernization. Additional domain fields can be added via new Flyway migrations as the Java 21 implementation clarifies requirements.
