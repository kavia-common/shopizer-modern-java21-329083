-- Flyway migration: V1__init_schemas.sql
-- Purpose: Create schemas and baseline extensions for the Shopizer modern target schema.
-- Target: PostgreSQL 16

-- Keep everything in a dedicated app schema to avoid polluting public.
CREATE SCHEMA IF NOT EXISTS shopizer;

-- Optional helper schema for staging legacy loads (not required for app runtime).
CREATE SCHEMA IF NOT EXISTS legacy;

-- UUID generation. pgcrypto provides gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Basic auditing trigger helper (optional). We keep it simple: columns + app writes.
-- (No triggers created here; those belong in later service-specific migrations.)
