CREATE SCHEMA IF NOT EXISTS catalog;

CREATE TABLE IF NOT EXISTS catalog.manufacturer (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  code VARCHAR(64) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS catalog.category (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(64) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  parent_id BIGINT NULL REFERENCES catalog.category(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS catalog.product (
  id BIGSERIAL PRIMARY KEY,
  sku VARCHAR(64) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  description TEXT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  manufacturer_id BIGINT NULL REFERENCES catalog.manufacturer(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS catalog.product_category (
  product_id BIGINT NOT NULL REFERENCES catalog.product(id) ON DELETE CASCADE,
  category_id BIGINT NOT NULL REFERENCES catalog.category(id) ON DELETE CASCADE,
  PRIMARY KEY (product_id, category_id)
);

CREATE INDEX IF NOT EXISTS idx_product_active ON catalog.product(active);
CREATE INDEX IF NOT EXISTS idx_product_name ON catalog.product(name);
CREATE INDEX IF NOT EXISTS idx_category_parent_id ON catalog.category(parent_id);
