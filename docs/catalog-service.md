# Catalog Service (Spring Boot 3.x, Java 21)

## Purpose
The Catalog Service owns core catalog read models:
- Products
- Categories
- Manufacturers

It exposes REST APIs for catalog browsing and will later expose admin/write APIs.

## Location in repo
- Source: `catalog-service/`
- API base path: `/api/v1/catalog/**`
- OpenAPI: `/openapi.json`
- Swagger UI: `/swagger-ui`

## Data storage
- PostgreSQL 16 (local dev via `infra/db/docker-compose.yml`)
- Schema: `shopizer` (owned by the repo’s shared Flyway migrations under `infra/db/flyway/migrations`)

### Flyway migrations strategy (repo convention)
This repo uses a **central** migrations folder:

- `infra/db/flyway/migrations`

The `catalog-service` is configured to run those migrations on startup (Flyway enabled by default) via:

- `spring.flyway.locations=filesystem:../infra/db/flyway/migrations,...`

This keeps schema evolution consistent across services and supports the migration scripts under `infra/db/migration/*`.

### Environment variables
The service accepts both shared (preferred) and service-specific variables.

Preferred shared variables (align with repo infra):
- `SHOPIZER_DB_URL`
- `SHOPIZER_DB_USER`
- `SHOPIZER_DB_PASSWORD`

Service-specific (supported for compatibility):
- `CATALOG_DB_URL`
- `CATALOG_DB_USER`
- `CATALOG_DB_PASSWORD`

## Security (initial)
- Public: browse + docs + health/info
- Protected: all other endpoints via HTTP Basic (temporary, until platform identity is specified)

## Next steps (planned)
- Add write-side flows (create/update product/category) with validation + error mapping.
- Add Dockerfile + K8s manifests under `/infra`.
- Expand integration tests for migrations and REST endpoints.
