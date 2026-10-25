# Лабораторная работа №4. Оконные функции и аналитика данных

## 1. Рейтинг товаров внутри категории
**Назначение:** Построение рейтинга товаров по цене внутри каждой категории с использованием `ROW_NUMBER`, `RANK` и `DENSE_RANK`.

**Запрос:**
```sql
SELECT category_id, title, price,
    ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS row_num,
    RANK() OVER (PARTITION BY category_id ORDER BY price DESC) AS rank_num,
    DENSE_RANK() OVER (PARTITION BY category_id ORDER BY price DESC) AS dense_rank_num
FROM products LIMIT 20;
```

**Пояснение:** 
- `ROW_NUMBER()` выдает уникальные номера (1, 2, 3) независимо от совпадения цен.
- `RANK()` при равных ценах выдает одинаковый ранг, но пропускает следующий номер (1, 1, 3).
- `DENSE_RANK()` выдает одинаковый ранг без пропусков (1, 1, 2).


## 2. Топ-3 самых дорогих товаров в каждой категории
**Назначение:** Вывод трех самых дорогих товаров в каждой категории с использованием оконной функции и CTE.

**Запрос:**
```sql
WITH RankedProducts AS (
    SELECT category_id, title, price,
        ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS rn
    FROM products
)
SELECT * FROM RankedProducts WHERE rn <= 3;
```

**Пояснение:** В CTE `RankedProducts` мы нумеруем товары внутри каждой категории от самых дорогих к дешевым. Во внешнем запросе фильтр `WHERE rn <= 3` оставляет только первые три позиции.


## 3. Нарастающий итог выручки по дням
**Назначение:** Вычисление нарастающего итога выручки по дням с помощью оконной агрегатной функции.

**Запрос:**
```sql
SELECT created_at::date AS order_date,
    SUM(total_amount) AS daily_revenue,
    SUM(SUM(total_amount)) OVER (ORDER BY created_at::date) AS running_total
FROM orders
GROUP BY created_at::date
ORDER BY order_date;
```

**Пояснение:** Запрос сначала группирует заказы по дням и считает дневную выручку (`SUM(total_amount)`). Затем оконная функция `SUM(...) OVER (ORDER BY ...)` прибавляет дневную выручку к сумме всех предыдущих дней, формируя нарастающий итог.


## 4. Доля выручки продавца в категории
**Назначение:** Расчет доли выручки каждого продавца в общей выручке его категории с помощью `SUM(...) OVER (PARTITION BY ...)`.

**Запрос:**
```sql
SELECT category_id, seller_id,
    SUM(price) AS seller_category_sum,
    SUM(SUM(price)) OVER (PARTITION BY category_id) AS total_category_sum,
    ROUND((SUM(price) * 100.0) / SUM(SUM(price)) OVER (PARTITION BY category_id), 2) AS percentage
FROM products
GROUP BY category_id, seller_id;
```

**Пояснение:** Сначала считаем сумму цен каждого продавца в категории. Оконная функция `SUM(...) OVER (PARTITION BY category_id)` вычисляет общую сумму цен всех товаров в категории. Делением одной суммы на другую получаем процентную долю продавца.


## 5. Сравнение выручки с предыдущим днем (LAG/LEAD)
**Назначение:** Использование функций смещения `LAG` для вычисления прироста выручки по сравнению с предыдущим днем.

**Запрос:**
```sql
WITH DailyRevenue AS (
    SELECT created_at::date AS order_date, SUM(total_amount) AS daily_sum
    FROM orders GROUP BY created_at::date
)
SELECT order_date, daily_sum,
    LAG(daily_sum) OVER (ORDER BY order_date) AS prev_day_sum,
    daily_sum - LAG(daily_sum) OVER (ORDER BY order_date) AS growth
FROM DailyRevenue;
```

**Пояснение:** В CTE `DailyRevenue` формируется таблица с ежедневной выручкой. Функция `LAG(daily_sum)` подтягивает значение выручки из предыдущей строки (прошлого дня). Вычитая её из текущего дня, получаем прирост. Для первого дня `LAG` вернет NULL.


## 6. Сравнение: Оконная функция vs GROUP BY
**Назначение:** Демонстрация того, что оконная функция позволяет сохранить детальные данные (название товара) рядом со сводным показателем (средняя цена), в отличие от обычной группировки.

**Запрос (Оконная функция):**
```sql
SELECT title, category_id, price,
    AVG(price) OVER (PARTITION BY category_id) AS avg_category_price
FROM products LIMIT 10;
```

**Пояснение:** Оконная функция удобнее тем, что не требует сложных подзапросов и соединений для вывода детальных строк (названий товаров) вместе со средними значениями. Каждая строка товара сохраняется в результате, а рядом с ней отображается средняя цена его категории.

**Запрос (Обычная группировка для сравнения):**
```sql
SELECT p.title, p.category_id, p.price, c.avg_price
FROM products p
JOIN (
    SELECT category_id, AVG(price) AS avg_price 
    FROM products GROUP BY category_id
) c ON p.category_id = c.category_id
LIMIT 10;
```

**Пояснение:** При использовании `GROUP BY` нам пришлось бы делать сложный подзапрос, потому что обычная группировка «схлопывает» строки и теряет детальные данные (названия товаров).
