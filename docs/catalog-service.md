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
- PostgreSQL 16, schema: `catalog`
- Flyway migrations are embedded in the service at `classpath:db/migration`

Environment variables:
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
