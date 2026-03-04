-- migrate_legacy_to_new.sql
-- Purpose: Transform data from legacy.* staging tables into shopizer.* target tables.
-- Assumptions:
-- - Flyway migrations have been applied (shopizer schema exists).
-- - legacy staging tables are populated.
-- - Uses store_code + natural keys (sku, code, email, order_number) to build IDs.

SET search_path TO shopizer;

-- ----------------------------
-- Reference data
-- ----------------------------
INSERT INTO language(language_code, name, is_default)
SELECT l.language_code, COALESCE(l.name, l.language_code), COALESCE(l.is_default, false)
FROM legacy.language l
ON CONFLICT (language_code) DO UPDATE
SET name = EXCLUDED.name,
    is_default = EXCLUDED.is_default;

INSERT INTO currency(currency_code, name)
SELECT c.currency_code, COALESCE(c.name, c.currency_code)
FROM legacy.currency c
ON CONFLICT (currency_code) DO UPDATE
SET name = EXCLUDED.name;

-- Countries/zones are optional in baseline; insert if provided
INSERT INTO country(iso2, iso3, name)
SELECT c.iso2, c.iso3, COALESCE(c.name, c.iso2)
FROM legacy.country c
ON CONFLICT (iso2) DO UPDATE
SET iso3 = EXCLUDED.iso3,
    name = EXCLUDED.name;

INSERT INTO zone(country_id, code, name)
SELECT co.country_id, z.code, COALESCE(z.name, z.code)
FROM legacy.zone z
JOIN country co ON co.iso2 = z.country_iso2
ON CONFLICT (country_id, code) DO UPDATE
SET name = EXCLUDED.name;

-- ----------------------------
-- Merchant
-- ----------------------------
INSERT INTO merchant_store(code, name, default_language_code, default_currency_code, enabled)
SELECT s.store_code,
       COALESCE(s.name, s.store_code),
       s.default_language_code,
       s.default_currency_code,
       COALESCE(s.enabled, true)
FROM legacy.merchant_store s
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    default_language_code = EXCLUDED.default_language_code,
    default_currency_code = EXCLUDED.default_currency_code,
    enabled = EXCLUDED.enabled,
    updated_at = now();

INSERT INTO integration_module(code, module_type, name, active)
SELECT m.code, COALESCE(m.module_type, 'unknown'), COALESCE(m.name, m.code), COALESCE(m.active, true)
FROM legacy.integration_module m
ON CONFLICT (code) DO UPDATE
SET module_type = EXCLUDED.module_type,
    name = EXCLUDED.name,
    active = EXCLUDED.active;

INSERT INTO merchant_configuration(store_id, key, value, is_active)
SELECT ms.store_id, mc.key, mc.value, COALESCE(mc.is_active, true)
FROM legacy.merchant_configuration mc
JOIN merchant_store ms ON ms.code = mc.store_code
ON CONFLICT (store_id, key) DO UPDATE
SET value = EXCLUDED.value,
    is_active = EXCLUDED.is_active,
    updated_at = now();

-- ----------------------------
-- Catalog: Manufacturer
-- ----------------------------
INSERT INTO manufacturer(store_id, code)
SELECT ms.store_id, m.code
FROM legacy.manufacturer m
JOIN merchant_store ms ON ms.code = m.store_code
ON CONFLICT (store_id, code) DO NOTHING;

INSERT INTO manufacturer_i18n(manufacturer_id, language_code, name, description)
SELECT man.manufacturer_id, mi.language_code, COALESCE(mi.name, mi.manufacturer_code), mi.description
FROM legacy.manufacturer_i18n mi
JOIN merchant_store ms ON ms.code = mi.store_code
JOIN manufacturer man ON man.store_id = ms.store_id AND man.code = mi.manufacturer_code
ON CONFLICT (manufacturer_id, language_code) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description;

-- ----------------------------
-- Catalog: Category
-- ----------------------------
-- First insert categories without parent linkage (parent_category_id set later).
INSERT INTO category(store_id, parent_category_id, code, sort_order, visible)
SELECT ms.store_id, NULL, c.code, COALESCE(c.sort_order, 0), COALESCE(c.visible, true)
FROM legacy.category c
JOIN merchant_store ms ON ms.code = c.store_code
ON CONFLICT (store_id, code) DO UPDATE
SET sort_order = EXCLUDED.sort_order,
    visible = EXCLUDED.visible,
    updated_at = now();

-- Update parent_category_id based on parent_code
UPDATE category child
SET parent_category_id = parent.category_id,
    updated_at = now()
FROM merchant_store ms
JOIN legacy.category lc ON lc.store_code = ms.code AND lc.code = child.code
JOIN category parent ON parent.store_id = ms.store_id AND parent.code = lc.parent_code
WHERE child.store_id = ms.store_id
  AND lc.parent_code IS NOT NULL;

INSERT INTO category_i18n(category_id, language_code, name, description, friendly_url)
SELECT cat.category_id, ci.language_code, COALESCE(ci.name, ci.category_code), ci.description, ci.friendly_url
FROM legacy.category_i18n ci
JOIN merchant_store ms ON ms.code = ci.store_code
JOIN category cat ON cat.store_id = ms.store_id AND cat.code = ci.category_code
ON CONFLICT (category_id, language_code) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    friendly_url = EXCLUDED.friendly_url;

-- ----------------------------
-- Catalog: Product
-- ----------------------------
INSERT INTO product(store_id, sku, manufacturer_id, product_type, active, available)
SELECT ms.store_id,
       p.sku,
       man.manufacturer_id,
       p.product_type,
       COALESCE(p.active, true),
       COALESCE(p.available, true)
FROM legacy.product p
JOIN merchant_store ms ON ms.code = p.store_code
LEFT JOIN manufacturer man ON man.store_id = ms.store_id AND man.code = p.manufacturer_code
ON CONFLICT (store_id, sku) DO UPDATE
SET manufacturer_id = EXCLUDED.manufacturer_id,
    product_type = EXCLUDED.product_type,
    active = EXCLUDED.active,
    available = EXCLUDED.available,
    updated_at = now();

INSERT INTO product_i18n(product_id, language_code, name, description, friendly_url)
SELECT pr.product_id,
       pi.language_code,
       COALESCE(pi.name, pi.sku),
       pi.description,
       pi.friendly_url
FROM legacy.product_i18n pi
JOIN merchant_store ms ON ms.code = pi.store_code
JOIN product pr ON pr.store_id = ms.store_id AND pr.sku = pi.sku
ON CONFLICT (product_id, language_code) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    friendly_url = EXCLUDED.friendly_url;

-- Product-category links
INSERT INTO product_category(product_id, category_id)
SELECT pr.product_id, cat.category_id
FROM legacy.product_category pc
JOIN merchant_store ms ON ms.code = pc.store_code
JOIN product pr ON pr.store_id = ms.store_id AND pr.sku = pc.sku
JOIN category cat ON cat.store_id = ms.store_id AND cat.code = pc.category_code
ON CONFLICT DO NOTHING;

-- Availability: create one default availability row per product (baseline).
INSERT INTO product_availability(product_id, region, available_date, quantity)
SELECT pr.product_id, NULL, NULL, NULL
FROM product pr
LEFT JOIN product_availability pa ON pa.product_id = pr.product_id
WHERE pa.availability_id IS NULL;

-- Prices: attach to the single availability row per product.
INSERT INTO product_price(availability_id, currency_code, price, sale_price)
SELECT pa.availability_id, lp.currency_code, COALESCE(lp.price, 0), lp.sale_price
FROM legacy.product_price lp
JOIN merchant_store ms ON ms.code = lp.store_code
JOIN product pr ON pr.store_id = ms.store_id AND pr.sku = lp.sku
JOIN product_availability pa ON pa.product_id = pr.product_id
ON CONFLICT DO NOTHING;

-- Images
INSERT INTO product_image(product_id, image_type, url, sort_order)
SELECT pr.product_id,
       COALESCE(li.image_type, 'DEFAULT'),
       li.url,
       COALESCE(li.sort_order, 0)
FROM legacy.product_image li
JOIN merchant_store ms ON ms.code = li.store_code
JOIN product pr ON pr.store_id = ms.store_id AND pr.sku = li.sku
ON CONFLICT DO NOTHING;

-- ----------------------------
-- Customers
-- ----------------------------
INSERT INTO customer(store_id, email, first_name, last_name, password_hash, language_code, active)
SELECT ms.store_id,
       c.email,
       c.first_name,
       c.last_name,
       c.password_hash,
       c.language_code,
       COALESCE(c.active, true)
FROM legacy.customer c
JOIN merchant_store ms ON ms.code = c.store_code
ON CONFLICT (store_id, email) DO UPDATE
SET first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    password_hash = EXCLUDED.password_hash,
    language_code = EXCLUDED.language_code,
    active = EXCLUDED.active,
    updated_at = now();

INSERT INTO customer_attribute(customer_id, key, value)
SELECT cust.customer_id, ca.key, ca.value
FROM legacy.customer_attribute ca
JOIN merchant_store ms ON ms.code = ca.store_code
JOIN customer cust ON cust.store_id = ms.store_id AND cust.email = ca.email
ON CONFLICT (customer_id, key) DO UPDATE
SET value = EXCLUDED.value;

-- ----------------------------
-- Orders
-- ----------------------------
INSERT INTO shop_order(store_id, customer_id, order_number, currency_code, status, total_amount, created_at, updated_at)
SELECT ms.store_id,
       cust.customer_id,
       o.order_number,
       o.currency_code,
       COALESCE(o.status, 'NEW'),
       COALESCE(o.total_amount, 0),
       COALESCE(o.created_at, now()),
       now()
FROM legacy.shop_order o
JOIN merchant_store ms ON ms.code = o.store_code
LEFT JOIN customer cust ON cust.store_id = ms.store_id AND cust.email = o.customer_email
ON CONFLICT (order_number) DO UPDATE
SET status = EXCLUDED.status,
    total_amount = EXCLUDED.total_amount,
    updated_at = now();

INSERT INTO order_item(order_id, product_id, sku, name, quantity, unit_price, total_price)
SELECT so.order_id,
       pr.product_id,
       oi.sku,
       COALESCE(oi.name, oi.sku),
       COALESCE(oi.quantity, 1),
       COALESCE(oi.unit_price, 0),
       COALESCE(oi.total_price, COALESCE(oi.unit_price, 0) * COALESCE(oi.quantity, 1))
FROM legacy.order_item oi
JOIN merchant_store ms ON ms.code = oi.store_code
JOIN shop_order so ON so.store_id = ms.store_id AND so.order_number = oi.order_number
LEFT JOIN product pr ON pr.store_id = ms.store_id AND pr.sku = oi.sku
ON CONFLICT DO NOTHING;

INSERT INTO order_total(order_id, code, title, amount, sort_order)
SELECT so.order_id,
       ot.code,
       ot.title,
       COALESCE(ot.amount, 0),
       COALESCE(ot.sort_order, 0)
FROM legacy.order_total ot
JOIN merchant_store ms ON ms.code = ot.store_code
JOIN shop_order so ON so.store_id = ms.store_id AND so.order_number = ot.order_number
ON CONFLICT DO NOTHING;

INSERT INTO order_status_history(order_id, status, comment, created_at)
SELECT so.order_id,
       h.status,
       h.comment,
       COALESCE(h.created_at, now())
FROM legacy.order_status_history h
JOIN merchant_store ms ON ms.code = h.store_code
JOIN shop_order so ON so.store_id = ms.store_id AND so.order_number = h.order_number
ON CONFLICT DO NOTHING;

-- ----------------------------
-- Carts (optional)
-- ----------------------------
INSERT INTO shopping_cart(store_id, customer_id, session_id, currency_code, created_at, updated_at)
SELECT ms.store_id,
       cust.customer_id,
       c.session_id,
       c.currency_code,
       COALESCE(c.created_at, now()),
       COALESCE(c.updated_at, now())
FROM legacy.shopping_cart c
JOIN merchant_store ms ON ms.code = c.store_code
LEFT JOIN customer cust ON cust.store_id = ms.store_id AND cust.email = c.customer_email
ON CONFLICT DO NOTHING;

INSERT INTO shopping_cart_item(cart_id, product_id, sku, quantity, unit_price)
SELECT sc.cart_id,
       pr.product_id,
       ci.sku,
       COALESCE(ci.quantity, 1),
       ci.unit_price
FROM legacy.shopping_cart_item ci
JOIN merchant_store ms ON ms.code = ci.store_code
JOIN shopping_cart sc ON sc.store_id = ms.store_id AND sc.session_id = ci.session_id
LEFT JOIN product pr ON pr.store_id = ms.store_id AND pr.sku = ci.sku
ON CONFLICT DO NOTHING;
