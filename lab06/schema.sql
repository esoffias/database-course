-- =========================================================================
-- ЛАБОРАТОРНАЯ РАБОТА №6. Современные возможности PostgreSQL и оптимизация запросов
-- =========================================================================

-- Задание 1: Добавление столбца JSONB для характеристик товаров и его заполнение
ALTER TABLE products ADD COLUMN attributes JSONB;

UPDATE products SET attributes = '{"color": "black", "memory": 128}' WHERE id <= 10;
UPDATE products SET attributes = '{"author": "Ivanov", "pages": 300}' WHERE id > 10 AND id <= 20;
UPDATE products SET attributes = '{"color": "white", "size": "XL"}' WHERE id > 20 AND id <= 30;


-- Задание 2: Запросы извлечения полей из JSONB и фильтрации по вхождению
SELECT title, attributes -> 'color' AS color_json, attributes ->> 'memory' AS memory_text
FROM products WHERE attributes IS NOT NULL LIMIT 5;

SELECT title, attributes 
FROM products 
WHERE attributes @> '{"color": "black"}' LIMIT 5;


-- Задание 3: Снятие плана "тяжелого" запроса ДО добавления индексов
EXPLAIN ANALYZE 
SELECT title, price FROM products WHERE price > 8000;


-- Задание 4: Добавление B-tree индекса и повторное снятие плана
CREATE INDEX idx_products_price ON products(price);

EXPLAIN ANALYZE 
SELECT title, price FROM products WHERE price > 8000;


-- Задание 5: Создание GIN-индекса для JSONB и проверка его работы в плане
CREATE INDEX idx_products_attributes ON products USING GIN (attributes);

EXPLAIN ANALYZE 
SELECT title, attributes FROM products WHERE attributes @> '{"color": "black"}' LIMIT 5;


-- Задание 6: Демонстрация замедления вставки из-за наличия индексов
INSERT INTO products (seller_id, category_id, title, price) 
SELECT 1, 1, 'Тестовый товар ' || g, 1000 
FROM generate_series(1, 5000) AS g;

DROP INDEX idx_products_price;
DROP INDEX idx_products_attributes;

INSERT INTO products (seller_id, category_id, title, price) 
SELECT 1, 1, 'Тестовый товар 2 ' || g, 1000 
FROM generate_series(1, 5000) AS g;

DELETE FROM products WHERE title LIKE 'Тестовый товар%';