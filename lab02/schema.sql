-- 1. Подготовка данных (создаем всё с нуля, чтобы не было ошибок)
TRUNCATE order_items, orders, stock, products, sellers, users, categories RESTART IDENTITY CASCADE;

INSERT INTO users (full_name, email, role) VALUES ('Тест', 'test@test.ru', 'seller');
INSERT INTO sellers (user_id, store_name) VALUES (1, 'Магазин');
INSERT INTO categories (name) VALUES ('Электроника'), ('Книги'), ('Одежда');

INSERT INTO products (seller_id, category_id, title, price) 
SELECT 1, (random() * 2 + 1)::int, 'Товар №' || g, (random() * 9000 + 1000)::numeric(12,2) 
FROM generate_series(1, 1000) AS g;

-- ==========================================
-- ВЫПОЛНЕНИЕ ЗАДАНИЙ ИЗ ЛАБОРАТОРНОЙ РАБОТЫ №2
-- ==========================================

-- Задание 1: DISTINCT (без дубликатов)
SELECT DISTINCT title AS "Название", price AS "Цена" FROM products LIMIT 5;

-- Задание 2: Фильтрация (AND, OR, скобки)
SELECT title, price FROM products WHERE (price > 8000 OR price < 2000) AND category_id = 1 LIMIT 5;

-- Задание 3: BETWEEN, IN, LIKE, IS NULL
SELECT title, price FROM products WHERE price BETWEEN 3000 AND 5000 AND category_id IN (1, 2) AND title LIKE 'Товар%' AND description IS NULL LIMIT 5;

-- Задание 4: Сортировка (ORDER BY)
SELECT title, price FROM products ORDER BY price DESC, title ASC LIMIT 5;

-- Задание 5: LIMIT и OFFSET
SELECT title, price FROM products ORDER BY id LIMIT 5 OFFSET 20;