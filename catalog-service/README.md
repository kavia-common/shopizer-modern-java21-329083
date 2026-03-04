# catalog-service (Shopizer modern, Java 21)

Spring Boot 3.x microservice for catalog/product browsing and (future) catalog admin operations.

## Run locally

Prereq: PostgreSQL 16 running (see `../infra/db/README.md`).

From `catalog-service/`:

```bash
./mvnw spring-boot:run
```

Swagger UI:
- http://localhost:8081/swagger-ui

OpenAPI JSON:
- http://localhost:8081/openapi.json

## Configuration

This service reads configuration from environment variables.

Required/optional environment variables:

- `CATALOG_SERVICE_PORT` (default `8081`)
- `CATALOG_DB_URL` (default `jdbc:postgresql://localhost:5432/shopizer`)
- `CATALOG_DB_USER` (default `shopizer`)
- `CATALOG_DB_PASSWORD` (default `shopizer`)

## Security (initial scaffold)

- Public:
  - `GET /api/v1/catalog/products`
  - Swagger UI + OpenAPI JSON
  - Actuator health/info
- Protected:
  - all other endpoints (HTTP Basic, until platform identity is defined)
