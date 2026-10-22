# Лабораторная работа №2

## 1. Наполнение базы данных

В таблицу products было добавлено 1000 строк с помощью функции generate_series.

## 2. Вывод без дубликатов (DISTINCT)

Запрос:
```sql
SELECT DISTINCT title AS "Название", price AS "Цена" FROM products LIMIT 5;
```
Назначение: Вывод уникальных названий и цен с использованием псевдонимов.

## 3. Фильтрация по нескольким условиям (AND, OR, скобки)

Запрос:
```sql
SELECT title, price 
FROM products 
WHERE (price > 8000 OR price < 2000) AND category_id = 1 
LIMIT 5;
```
Назначение: Демонстрация логических операторов. Скобки задают приоритет.

## 4. Предикаты BETWEEN, IN, LIKE, IS NULL

Запрос:
```sql
SELECT title, price 
FROM products 
WHERE price BETWEEN 3000 AND 5000 
AND category_id IN (1, 2) 
AND title LIKE 'Товар%' 
AND description IS NULL 
LIMIT 5;
```
Назначение: Комплексная фильтрация (диапазон, список, шаблон, пустота).

## 5. Сортировка по двум столбцам

Запрос:
```sql
SELECT title, price 
FROM products 
ORDER BY price DESC, title ASC 
LIMIT 5;
```
Назначение: Сортировка по цене по убыванию, при равенстве — по названию по возрастанию.

## 6. Постраничный вывод (LIMIT, OFFSET)

Запрос:
```sql
SELECT title, price 
FROM products 
ORDER BY id 
LIMIT 5 OFFSET 20;
```
Назначение: Пропуск первых 20 строк и вывод следующих 5 (имитация второй страницы).

