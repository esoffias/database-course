-- =========================================================================
-- ЛАБОРАТОРНАЯ РАБОТА №3. Многотабличные запросы и аналитические представления
-- =========================================================================

-- Задание 1: Запрос с внутренним соединением не менее трёх таблиц (INNER JOIN)
-- Назначение: Вывод товаров с названием категории и именем магазина.
SELECT 
    p.title AS "Товар", 
    c.name AS "Категория", 
    s.store_name AS "Магазин"
FROM products p
JOIN categories c ON p.category_id = c.id
JOIN sellers s ON p.seller_id = s.id
LIMIT 10;


-- Задание 2: Запрос с LEFT JOIN (строки без соответствий)
-- Назначение: Поиск товаров, у которых нет отзывов.
SELECT 
    p.title AS "Товар", 
    r.score AS "Оценка"
FROM products p
LEFT JOIN reviews r ON p.id = r.product_id
WHERE r.id IS NULL
LIMIT 10;


-- Задание 3: Запрос с группировкой и агрегацией (GROUP BY)
-- Назначение: По каждой категории — количество товаров и средняя цена.
SELECT 
    c.name AS "Категория", 
    COUNT(p.id) AS "Количество товаров", 
    ROUND(AVG(p.price), 2) AS "Средняя цена"
FROM categories c
LEFT JOIN products p ON c.id = p.category_id
GROUP BY c.name
ORDER BY "Количество товаров" DESC;


-- Задание 4: Применение HAVING для фильтрации групп
-- Назначение: Вывод категорий, где средняя цена товара выше 5000.
SELECT 
    c.name AS "Категория", 
    AVG(p.price) AS "Средняя цена"
FROM categories c
JOIN products p ON c.id = p.category_id
GROUP BY c.name
HAVING AVG(p.price) > 5000;


-- Задание 5.1: Скалярный подзапрос
-- Назначение: Поиск товаров, цена которых выше средней цены по всей базе.
SELECT title, price
FROM products
WHERE price > (SELECT AVG(price) FROM products)
LIMIT 10;


-- Задание 5.2: Подзапрос с EXISTS (коррелированный)
-- Назначение: Поиск продавцов, у которых есть хотя бы один товар.
SELECT store_name 
FROM sellers s
WHERE EXISTS (
    SELECT 1 FROM products p WHERE p.seller_id = s.id
);


-- Задание 6: Рекурсивный CTE (обход дерева категорий)
-- Назначение: Вывод иерархии категорий (от корневых к дочерним).
WITH RECURSIVE category_tree AS (
    -- Берем корневые категории (у которых нет родителя)
    SELECT id, name, parent_id, 1 AS level
    FROM categories
    WHERE parent_id IS NULL
    
    UNION ALL
    
    -- Присоединяем дочерние категории
    SELECT c.id, c.name, c.parent_id, ct.level + 1
    FROM categories c
    JOIN category_tree ct ON c.parent_id = ct.id
)
SELECT * FROM category_tree;


-- Задание 7.1: Создание первого представления (VIEW)
-- Назначение: Витрина товаров с категориями и магазинами для типовых отчетов.
CREATE VIEW product_catalog AS
SELECT 
    p.id AS product_id,
    p.title AS product_title,
    p.price,
    c.name AS category_name,
    s.store_name AS seller_name
FROM products p
JOIN categories c ON p.category_id = c.id
JOIN sellers s ON p.seller_id = s.id;


-- Задание 7.2: Создание второго представления (VIEW)
-- Назначение: Статистика по категориям (количество товаров и средняя цена).
CREATE VIEW category_stats AS
SELECT 
    c.name AS category_name,
    COUNT(p.id) AS total_products,
    ROUND(AVG(p.price), 2) AS avg_price
FROM categories c
LEFT JOIN products p ON c.id = p.category_id
GROUP BY c.name;


-- Проверка работы созданных представлений (демонстрация)
SELECT * FROM product_catalog LIMIT 5;
SELECT * FROM category_stats;