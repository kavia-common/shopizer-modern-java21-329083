# catalog-service (Shopizer modern, Java 21)

Spring Boot 3.x microservice for catalog/product browsing and (future) catalog admin operations.

## Run locally

### 1) Start PostgreSQL 16 (repo convention)
From the repo root:

```bash
docker compose -f infra/db/docker-compose.yml up -d
```

Connection defaults (dev only) are documented in `../infra/db/README.md`.

### 2) Run the service
From `catalog-service/`:

```bash
./mvnw spring-boot:run
```

On startup, the service runs Flyway migrations from the shared folder:
- `../infra/db/flyway/migrations`

Swagger UI:
- http://localhost:8081/swagger-ui

OpenAPI JSON:
- http://localhost:8081/openapi.json

## Configuration

This service reads configuration from environment variables.

Required/optional environment variables:

- `CATALOG_SERVICE_PORT` (default `8081`)

Preferred shared DB variables (recommended; align with repo infra):
- `SHOPIZER_DB_URL` (default `jdbc:postgresql://localhost:5432/shopizer`)
- `SHOPIZER_DB_USER` (default `shopizer`)
- `SHOPIZER_DB_PASSWORD` (default `shopizer`)

Service-specific DB variables (supported for compatibility):
- `CATALOG_DB_URL`
- `CATALOG_DB_USER`
- `CATALOG_DB_PASSWORD`

## Security (initial scaffold)

- Public:
  - `GET /api/v1/catalog/products`
  - Swagger UI + OpenAPI JSON
  - Actuator health/info
- Protected:
  - all other endpoints (HTTP Basic, until platform identity is defined)
