-- Flyway migration: V2__core_tables.sql
-- Purpose: Baseline schema for core Shopizer domains (merchant, reference, catalog, customers, cart, orders).
-- Target: PostgreSQL 16
--
-- Notes:
-- - This is a pragmatic, service-friendly schema (not a 1:1 port of legacy JPA tables).
-- - It captures the key aggregates described in docs/legacy-shopizer-2x/entity-data-model.md.
-- - i18n descriptions use separate *_i18n tables keyed by language_code.

SET search_path TO shopizer;

-- ----------------------------
-- Shared helpers
-- ----------------------------
CREATE TABLE IF NOT EXISTS language (
  language_code varchar(10) PRIMARY KEY,
  name          varchar(64) NOT NULL,
  is_default    boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS currency (
  currency_code char(3) PRIMARY KEY,
  name          varchar(64) NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS country (
  country_id    bigserial PRIMARY KEY,
  iso2          char(2) UNIQUE NOT NULL,
  iso3          char(3),
  name          varchar(128) NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS zone (
  zone_id     bigserial PRIMARY KEY,
  country_id  bigint NOT NULL REFERENCES country(country_id),
  code        varchar(32) NOT NULL,
  name        varchar(128) NOT NULL,
  UNIQUE(country_id, code)
);

-- ----------------------------
-- Merchant / configuration
-- ----------------------------
CREATE TABLE IF NOT EXISTS merchant_store (
  store_id        bigserial PRIMARY KEY,
  code            varchar(64) UNIQUE NOT NULL,
  name            varchar(255) NOT NULL,
  default_language_code varchar(10) REFERENCES language(language_code),
  default_currency_code char(3) REFERENCES currency(currency_code),
  enabled         boolean NOT NULL DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS merchant_configuration (
  config_id    bigserial PRIMARY KEY,
  store_id     bigint NOT NULL REFERENCES merchant_store(store_id),
  key          varchar(128) NOT NULL,
  value        text,
  is_active    boolean NOT NULL DEFAULT true,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE(store_id, key)
);

-- Modules available in the system (payment, shipping, etc.)
CREATE TABLE IF NOT EXISTS integration_module (
  module_id    bigserial PRIMARY KEY,
  code         varchar(128) UNIQUE NOT NULL, -- e.g. 'ups', 'paypal-express-checkout'
  module_type  varchar(64) NOT NULL,         -- e.g. 'shipping', 'payment'
  name         varchar(255) NOT NULL,
  active       boolean NOT NULL DEFAULT true,
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- ----------------------------
-- Catalog
-- ----------------------------
CREATE TABLE IF NOT EXISTS manufacturer (
  manufacturer_id bigserial PRIMARY KEY,
  store_id        bigint NOT NULL REFERENCES merchant_store(store_id),
  code            varchar(64),
  created_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE(store_id, code)
);

CREATE TABLE IF NOT EXISTS manufacturer_i18n (
  manufacturer_id bigint NOT NULL REFERENCES manufacturer(manufacturer_id) ON DELETE CASCADE,
  language_code   varchar(10) NOT NULL REFERENCES language(language_code),
  name            varchar(255) NOT NULL,
  description     text,
  PRIMARY KEY (manufacturer_id, language_code)
);

CREATE TABLE IF NOT EXISTS category (
  category_id     bigserial PRIMARY KEY,
  store_id        bigint NOT NULL REFERENCES merchant_store(store_id),
  parent_category_id bigint REFERENCES category(category_id),
  code            varchar(64),
  sort_order      int NOT NULL DEFAULT 0,
  visible         boolean NOT NULL DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE(store_id, code)
);

CREATE TABLE IF NOT EXISTS category_i18n (
  category_id   bigint NOT NULL REFERENCES category(category_id) ON DELETE CASCADE,
  language_code varchar(10) NOT NULL REFERENCES language(language_code),
  name          varchar(255) NOT NULL,
  description   text,
  friendly_url  varchar(255),
  PRIMARY KEY (category_id, language_code),
  UNIQUE (language_code, friendly_url)
);

CREATE TABLE IF NOT EXISTS product (
  product_id     bigserial PRIMARY KEY,
  store_id       bigint NOT NULL REFERENCES merchant_store(store_id),
  sku            varchar(64) NOT NULL,
  manufacturer_id bigint REFERENCES manufacturer(manufacturer_id),
  product_type   varchar(64), -- legacy has ProductType entity; keep as simple string for baseline
  active         boolean NOT NULL DEFAULT true,
  available      boolean NOT NULL DEFAULT true,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE(store_id, sku)
);

CREATE TABLE IF NOT EXISTS product_i18n (
  product_id    bigint NOT NULL REFERENCES product(product_id) ON DELETE CASCADE,
  language_code varchar(10) NOT NULL REFERENCES language(language_code),
  name          varchar(255) NOT NULL,
  description   text,
  friendly_url  varchar(255),
  PRIMARY KEY (product_id, language_code),
  UNIQUE (language_code, friendly_url)
);

-- Product <-> Category (many-to-many in most commerce systems)
CREATE TABLE IF NOT EXISTS product_category (
  product_id  bigint NOT NULL REFERENCES product(product_id) ON DELETE CASCADE,
  category_id bigint NOT NULL REFERENCES category(category_id) ON DELETE CASCADE,
  PRIMARY KEY (product_id, category_id)
);

CREATE TABLE IF NOT EXISTS product_availability (
  availability_id bigserial PRIMARY KEY,
  product_id      bigint NOT NULL REFERENCES product(product_id) ON DELETE CASCADE,
  region          varchar(64),
  available_date  date,
  quantity        int,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS product_price (
  price_id        bigserial PRIMARY KEY,
  availability_id bigint NOT NULL REFERENCES product_availability(availability_id) ON DELETE CASCADE,
  currency_code   char(3) NOT NULL REFERENCES currency(currency_code),
  price           numeric(19,4) NOT NULL,
  sale_price      numeric(19,4),
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS product_image (
  image_id    bigserial PRIMARY KEY,
  product_id  bigint NOT NULL REFERENCES product(product_id) ON DELETE CASCADE,
  image_type  varchar(64) NOT NULL DEFAULT 'DEFAULT',
  url         text NOT NULL, -- store a URL/path; actual binary storage handled elsewhere
  sort_order  int NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS product_attribute (
  attribute_id bigserial PRIMARY KEY,
  product_id   bigint NOT NULL REFERENCES product(product_id) ON DELETE CASCADE,
  code         varchar(64) NOT NULL,
  value        varchar(255) NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE(product_id, code, value)
);

CREATE TABLE IF NOT EXISTS product_relationship (
  product_id         bigint NOT NULL REFERENCES product(product_id) ON DELETE CASCADE,
  related_product_id bigint NOT NULL REFERENCES product(product_id) ON DELETE CASCADE,
  relationship_type  varchar(64) NOT NULL DEFAULT 'RELATED',
  created_at         timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(product_id, related_product_id, relationship_type)
);

CREATE TABLE IF NOT EXISTS product_review (
  review_id    bigserial PRIMARY KEY,
  product_id   bigint NOT NULL REFERENCES product(product_id) ON DELETE CASCADE,
  customer_id  bigint,
  rating       int NOT NULL CHECK (rating BETWEEN 1 AND 5),
  status       varchar(32) NOT NULL DEFAULT 'APPROVED',
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS product_review_i18n (
  review_id     bigint NOT NULL REFERENCES product_review(review_id) ON DELETE CASCADE,
  language_code varchar(10) NOT NULL REFERENCES language(language_code),
  title         varchar(255),
  description   text,
  PRIMARY KEY (review_id, language_code)
);

-- ----------------------------
-- Customers
-- ----------------------------
CREATE TABLE IF NOT EXISTS customer (
  customer_id   bigserial PRIMARY KEY,
  store_id      bigint NOT NULL REFERENCES merchant_store(store_id),
  email         varchar(255) NOT NULL,
  first_name    varchar(128),
  last_name     varchar(128),
  password_hash varchar(255),
  language_code varchar(10) REFERENCES language(language_code),
  active        boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE(store_id, email)
);

-- Flexible attributes
CREATE TABLE IF NOT EXISTS customer_attribute (
  customer_id bigint NOT NULL REFERENCES customer(customer_id) ON DELETE CASCADE,
  key         varchar(128) NOT NULL,
  value       text,
  PRIMARY KEY (customer_id, key)
);

-- ----------------------------
-- Shopping Cart
-- ----------------------------
CREATE TABLE IF NOT EXISTS shopping_cart (
  cart_id     bigserial PRIMARY KEY,
  store_id    bigint NOT NULL REFERENCES merchant_store(store_id),
  customer_id bigint REFERENCES customer(customer_id),
  session_id  varchar(128), -- for anonymous carts
  currency_code char(3) REFERENCES currency(currency_code),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS shopping_cart_item (
  cart_item_id bigserial PRIMARY KEY,
  cart_id      bigint NOT NULL REFERENCES shopping_cart(cart_id) ON DELETE CASCADE,
  product_id   bigint NOT NULL REFERENCES product(product_id),
  sku          varchar(64) NOT NULL,
  quantity     int NOT NULL CHECK (quantity > 0),
  unit_price   numeric(19,4),
  created_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE(cart_id, sku)
);

CREATE TABLE IF NOT EXISTS shopping_cart_item_attribute (
  cart_item_id bigint NOT NULL REFERENCES shopping_cart_item(cart_item_id) ON DELETE CASCADE,
  key          varchar(128) NOT NULL,
  value        text,
  PRIMARY KEY (cart_item_id, key)
);

-- ----------------------------
-- Orders
-- ----------------------------
CREATE TABLE IF NOT EXISTS shop_order (
  order_id     bigserial PRIMARY KEY,
  store_id     bigint NOT NULL REFERENCES merchant_store(store_id),
  customer_id  bigint REFERENCES customer(customer_id),
  order_number varchar(64) UNIQUE NOT NULL,
  currency_code char(3) REFERENCES currency(currency_code),
  status       varchar(32) NOT NULL DEFAULT 'NEW',
  total_amount numeric(19,4) NOT NULL DEFAULT 0,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS order_status_history (
  history_id bigserial PRIMARY KEY,
  order_id   bigint NOT NULL REFERENCES shop_order(order_id) ON DELETE CASCADE,
  status     varchar(32) NOT NULL,
  comment    text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS order_total (
  order_total_id bigserial PRIMARY KEY,
  order_id       bigint NOT NULL REFERENCES shop_order(order_id) ON DELETE CASCADE,
  code           varchar(64) NOT NULL, -- e.g. subtotal, tax, shipping, total
  title          varchar(255),
  amount         numeric(19,4) NOT NULL DEFAULT 0,
  sort_order     int NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS order_item (
  order_item_id bigserial PRIMARY KEY,
  order_id      bigint NOT NULL REFERENCES shop_order(order_id) ON DELETE CASCADE,
  product_id    bigint REFERENCES product(product_id),
  sku           varchar(64) NOT NULL,
  name          varchar(255) NOT NULL,
  quantity      int NOT NULL CHECK (quantity > 0),
  unit_price    numeric(19,4) NOT NULL DEFAULT 0,
  total_price   numeric(19,4) NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS order_item_attribute (
  order_item_id bigint NOT NULL REFERENCES order_item(order_item_id) ON DELETE CASCADE,
  key           varchar(128) NOT NULL,
  value         text,
  PRIMARY KEY (order_item_id, key)
);

-- ----------------------------
-- Indexes (practical)
-- ----------------------------
CREATE INDEX IF NOT EXISTS idx_category_store_parent ON category(store_id, parent_category_id);
CREATE INDEX IF NOT EXISTS idx_product_store_sku ON product(store_id, sku);
CREATE INDEX IF NOT EXISTS idx_product_category_category ON product_category(category_id);
CREATE INDEX IF NOT EXISTS idx_customer_store_email ON customer(store_id, email);
CREATE INDEX IF NOT EXISTS idx_cart_store_customer ON shopping_cart(store_id, customer_id);
CREATE INDEX IF NOT EXISTS idx_order_store_customer ON shop_order(store_id, customer_id);
