-- verify_migration.sql
-- Purpose: Sanity checks after migrating legacy -> new schema.

-- 1) Basic counts
SELECT 'merchant_store' AS table, count(*) FROM shopizer.merchant_store
UNION ALL SELECT 'product', count(*) FROM shopizer.product
UNION ALL SELECT 'category', count(*) FROM shopizer.category
UNION ALL SELECT 'customer', count(*) FROM shopizer.customer
UNION ALL SELECT 'shop_order', count(*) FROM shopizer.shop_order;

-- 2) Orphan checks
-- Products without store
SELECT count(*) AS products_without_store
FROM shopizer.product p
LEFT JOIN shopizer.merchant_store s ON s.store_id = p.store_id
WHERE s.store_id IS NULL;

-- Product-category links referencing missing rows
SELECT count(*) AS product_category_missing_product
FROM shopizer.product_category pc
LEFT JOIN shopizer.product p ON p.product_id = pc.product_id
WHERE p.product_id IS NULL;

SELECT count(*) AS product_category_missing_category
FROM shopizer.product_category pc
LEFT JOIN shopizer.category c ON c.category_id = pc.category_id
WHERE c.category_id IS NULL;

-- Orders with missing store
SELECT count(*) AS orders_without_store
FROM shopizer.shop_order o
LEFT JOIN shopizer.merchant_store s ON s.store_id = o.store_id
WHERE s.store_id IS NULL;

-- 3) Uniqueness/duplication quick checks (should be zero rows)
SELECT store_id, sku, count(*) AS dup_count
FROM shopizer.product
GROUP BY store_id, sku
HAVING count(*) > 1;

SELECT store_id, email, count(*) AS dup_count
FROM shopizer.customer
GROUP BY store_id, email
HAVING count(*) > 1;
