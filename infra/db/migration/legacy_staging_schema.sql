-- legacy_staging_schema.sql
-- Purpose: Create a minimal staging schema (legacy.*) that represents the legacy Shopizer data needed
--          to populate the new baseline schema. Load data into these tables via CSV/ETL or views.

CREATE SCHEMA IF NOT EXISTS legacy;

-- Reference
CREATE TABLE IF NOT EXISTS legacy.language (
  language_code varchar(10) PRIMARY KEY,
  name          varchar(64),
  is_default    boolean
);

CREATE TABLE IF NOT EXISTS legacy.currency (
  currency_code char(3) PRIMARY KEY,
  name          varchar(64)
);

CREATE TABLE IF NOT EXISTS legacy.country (
  iso2 char(2) PRIMARY KEY,
  iso3 char(3),
  name varchar(128)
);

CREATE TABLE IF NOT EXISTS legacy.zone (
  country_iso2 char(2) NOT NULL,
  code         varchar(32) NOT NULL,
  name         varchar(128),
  PRIMARY KEY(country_iso2, code)
);

-- Merchant
CREATE TABLE IF NOT EXISTS legacy.merchant_store (
  store_code    varchar(64) PRIMARY KEY,
  name          varchar(255),
  default_language_code varchar(10),
  default_currency_code char(3),
  enabled       boolean
);

CREATE TABLE IF NOT EXISTS legacy.merchant_configuration (
  store_code varchar(64) NOT NULL,
  key        varchar(128) NOT NULL,
  value      text,
  is_active  boolean,
  PRIMARY KEY(store_code, key)
);

CREATE TABLE IF NOT EXISTS legacy.integration_module (
  code        varchar(128) PRIMARY KEY,
  module_type varchar(64),
  name        varchar(255),
  active      boolean
);

-- Catalog
CREATE TABLE IF NOT EXISTS legacy.manufacturer (
  store_code varchar(64) NOT NULL,
  code       varchar(64) NOT NULL,
  PRIMARY KEY(store_code, code)
);

CREATE TABLE IF NOT EXISTS legacy.manufacturer_i18n (
  store_code     varchar(64) NOT NULL,
  manufacturer_code varchar(64) NOT NULL,
  language_code  varchar(10) NOT NULL,
  name           varchar(255),
  description    text,
  PRIMARY KEY(store_code, manufacturer_code, language_code)
);

CREATE TABLE IF NOT EXISTS legacy.category (
  store_code varchar(64) NOT NULL,
  code       varchar(64) NOT NULL,
  parent_code varchar(64),
  sort_order int,
  visible    boolean,
  PRIMARY KEY(store_code, code)
);

CREATE TABLE IF NOT EXISTS legacy.category_i18n (
  store_code    varchar(64) NOT NULL,
  category_code varchar(64) NOT NULL,
  language_code varchar(10) NOT NULL,
  name          varchar(255),
  description   text,
  friendly_url  varchar(255),
  PRIMARY KEY(store_code, category_code, language_code)
);

CREATE TABLE IF NOT EXISTS legacy.product (
  store_code       varchar(64) NOT NULL,
  sku              varchar(64) NOT NULL,
  manufacturer_code varchar(64),
  product_type     varchar(64),
  active           boolean,
  available        boolean,
  PRIMARY KEY(store_code, sku)
);

CREATE TABLE IF NOT EXISTS legacy.product_i18n (
  store_code    varchar(64) NOT NULL,
  sku           varchar(64) NOT NULL,
  language_code varchar(10) NOT NULL,
  name          varchar(255),
  description   text,
  friendly_url  varchar(255),
  PRIMARY KEY(store_code, sku, language_code)
);

CREATE TABLE IF NOT EXISTS legacy.product_category (
  store_code    varchar(64) NOT NULL,
  sku           varchar(64) NOT NULL,
  category_code varchar(64) NOT NULL,
  PRIMARY KEY(store_code, sku, category_code)
);

CREATE TABLE IF NOT EXISTS legacy.product_price (
  store_code    varchar(64) NOT NULL,
  sku           varchar(64) NOT NULL,
  currency_code char(3) NOT NULL,
  price         numeric(19,4),
  sale_price    numeric(19,4),
  PRIMARY KEY(store_code, sku, currency_code)
);

CREATE TABLE IF NOT EXISTS legacy.product_image (
  store_code varchar(64) NOT NULL,
  sku        varchar(64) NOT NULL,
  image_type varchar(64),
  url        text,
  sort_order int,
  PRIMARY KEY(store_code, sku, url)
);

-- Customers
CREATE TABLE IF NOT EXISTS legacy.customer (
  store_code    varchar(64) NOT NULL,
  email         varchar(255) NOT NULL,
  first_name    varchar(128),
  last_name     varchar(128),
  password_hash varchar(255),
  language_code varchar(10),
  active        boolean,
  PRIMARY KEY(store_code, email)
);

CREATE TABLE IF NOT EXISTS legacy.customer_attribute (
  store_code varchar(64) NOT NULL,
  email      varchar(255) NOT NULL,
  key        varchar(128) NOT NULL,
  value      text,
  PRIMARY KEY(store_code, email, key)
);

-- Orders
CREATE TABLE IF NOT EXISTS legacy.shop_order (
  store_code    varchar(64) NOT NULL,
  order_number  varchar(64) NOT NULL,
  customer_email varchar(255),
  currency_code char(3),
  status        varchar(32),
  total_amount  numeric(19,4),
  created_at    timestamptz,
  PRIMARY KEY(store_code, order_number)
);

CREATE TABLE IF NOT EXISTS legacy.order_item (
  store_code    varchar(64) NOT NULL,
  order_number  varchar(64) NOT NULL,
  sku           varchar(64),
  name          varchar(255),
  quantity      int,
  unit_price    numeric(19,4),
  total_price   numeric(19,4),
  PRIMARY KEY(store_code, order_number, sku)
);

CREATE TABLE IF NOT EXISTS legacy.order_total (
  store_code    varchar(64) NOT NULL,
  order_number  varchar(64) NOT NULL,
  code          varchar(64) NOT NULL,
  title         varchar(255),
  amount        numeric(19,4),
  sort_order    int,
  PRIMARY KEY(store_code, order_number, code)
);

CREATE TABLE IF NOT EXISTS legacy.order_status_history (
  store_code    varchar(64) NOT NULL,
  order_number  varchar(64) NOT NULL,
  status        varchar(32) NOT NULL,
  comment       text,
  created_at    timestamptz,
  PRIMARY KEY(store_code, order_number, status, created_at)
);

-- Carts (optional for baseline migration)
CREATE TABLE IF NOT EXISTS legacy.shopping_cart (
  store_code    varchar(64) NOT NULL,
  session_id    varchar(128) NOT NULL,
  customer_email varchar(255),
  currency_code char(3),
  created_at    timestamptz,
  updated_at    timestamptz,
  PRIMARY KEY(store_code, session_id)
);

CREATE TABLE IF NOT EXISTS legacy.shopping_cart_item (
  store_code   varchar(64) NOT NULL,
  session_id   varchar(128) NOT NULL,
  sku          varchar(64) NOT NULL,
  quantity     int,
  unit_price   numeric(19,4),
  PRIMARY KEY(store_code, session_id, sku)
);
