# Лабораторная работа №3. Многотабличные запросы и представления

## 1. INNER JOIN (3 таблицы)
**Назначение:** Вывод товаров с названием категории и магазина.
**Запрос:** `SELECT p.title, c.name, s.store_name FROM products p JOIN categories c ON p.category_id = c.id JOIN sellers s ON p.seller_id = s.id LIMIT 10;`
**Результат:** 
![Inner Join](<Запрос с INNER JOIN.png>)

## 2. LEFT JOIN (товары без отзывов)
**Назначение:** Поиск товаров, у которых нет отзывов (пустое значение в правой таблице).
**Запрос:** `SELECT p.title, r.score FROM products p LEFT JOIN reviews r ON p.id = r.product_id WHERE r.id IS NULL LIMIT 10;`
**Результат:** 
![Left Join](<Запрос с LEFT JOIN.png>)

## 3. Группировка и агрегация (GROUP BY)
**Назначение:** Подсчет количества товаров и средней цены по каждой категории.
**Запрос:** `SELECT c.name, COUNT(p.id), ROUND(AVG(p.price), 2) FROM categories c LEFT JOIN products p ON c.id = p.category_id GROUP BY c.name;`
**Результат:** 
![Group By](<Группировка и агрегация.png>)

## 4. Фильтрация групп (HAVING)
**Назначение:** Вывод категорий, где средняя цена товара выше 5000.
**Запрос:** `SELECT c.name, AVG(p.price) FROM categories c JOIN products p ON c.id = p.category_id GROUP BY c.name HAVING AVG(p.price) > 5000;`
**Результат:** 
![Having](<Фильтрация групп с HAVING.png>)

## 5. Подзапросы (скалярный и EXISTS)
**Назначение:** Поиск товаров дороже средней цены и поиск продавцов, у которых есть товары.
**Запросы:** 
- `SELECT title, price FROM products WHERE price > (SELECT AVG(price) FROM products) LIMIT 10;`
- `SELECT store_name FROM sellers s WHERE EXISTS (SELECT 1 FROM products p WHERE p.seller_id = s.id);`
**Результат:** 
![Скалярный подзапрос](<Скалярный подзапрос.png>)
![Подзапрос с EXISTS](<Подзапрос с EXISTS.png>)

## 6. Рекурсивный CTE
**Назначение:** Обход иерархии категорий.
**Запрос:** `WITH RECURSIVE category_tree AS (...) SELECT * FROM category_tree;`
**Результат:** 
![Рекурсивный CTE](<Рекурсивный CTE.png>)

## 7. Представления (VIEW)
**Назначение:** Созданы виртуальные таблицы `product_catalog` (каталог товаров) и `category_stats` (статистика категорий) для типовых отчетов.
**Запросы:** `CREATE VIEW product_catalog AS ...; CREATE VIEW category_stats AS ...;`
**Результат создания:**
![Создание Представления](<Создание Представления.png>)
![Создание 2 Представления](<Создание 2 Представления.png>)
**Проверка работы:**
![Проверка работы представлений](<проверка работы представлений.png>)