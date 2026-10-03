-- SQL practice: интернет-магазин (SQLite)
-- Таблицы: customers (покупатели), orders (заказы)

-- ============================================================
-- 0. Схема и тестовые данные
-- ============================================================
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    id INTEGER PRIMARY KEY,
    name TEXT,
    city TEXT,
    signup_date TEXT
);

CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    product TEXT,
    amount INTEGER,
    order_date TEXT
);

INSERT INTO customers VALUES
(1, 'Анна', 'Москва', '2026-01-15'),
(2, 'Иван', 'Пермь', '2026-02-03'),
(3, 'Мария', 'Екатеринбург', '2026-02-20'),
(4, 'Олег', 'Пермь', '2026-03-11'),
(5, 'Елена', 'Москва', '2026-04-05'),
(6, 'Павел', 'Казань', '2026-05-18');

INSERT INTO orders VALUES
(1, 1, 'Ноутбук', 65000, '2026-02-01'),
(2, 1, 'Мышь', 1500, '2026-02-01'),
(3, 2, 'Монитор', 18000, '2026-03-05'),
(4, 3, 'Клавиатура', 4500, '2026-03-10'),
(5, 2, 'Наушники', 7000, '2026-03-20'),
(6, 4, 'Ноутбук', 58000, '2026-04-02'),
(7, 5, 'Монитор', 21000, '2026-04-15'),
(8, 1, 'Наушники', 9000, '2026-05-01'),
(9, 3, 'Мышь', 1200, '2026-05-07'),
(10, 5, 'Клавиатура', 5200, '2026-05-20'),
(11, 2, 'Ноутбук', 72000, '2026-06-01'),
(12, 4, 'Мышь', 1800, '2026-06-10');

-- ============================================================
-- 1. Выборка и фильтрация: SELECT, WHERE, ORDER BY, LIMIT
-- ============================================================

-- Покупатели из Перми
SELECT * FROM customers WHERE city = 'Пермь';

-- Заказы дороже 10 000
SELECT * FROM orders WHERE amount > 10000;

-- Мыши или заказы дороже 60 000
SELECT * FROM orders WHERE product = 'Мышь' OR amount > 60000;

-- Топ-3 самых дорогих заказа
SELECT product, amount FROM orders ORDER BY amount DESC LIMIT 3;

-- ============================================================
-- 2. Агрегации: COUNT, SUM, AVG, MIN, MAX, GROUP BY
-- ============================================================

-- Общая статистика по заказам
SELECT COUNT(*) AS orders_cnt,
       SUM(amount) AS total,
       ROUND(AVG(amount), 2) AS avg_amount,
       MIN(amount) AS min_amount,
       MAX(amount) AS max_amount
FROM orders;

-- Количество и сумма по товарам
SELECT product, COUNT(*) AS cnt, SUM(amount) AS total
FROM orders
GROUP BY product
ORDER BY total DESC;

-- ============================================================
-- 3. Объединение таблиц: JOIN, LEFT JOIN, HAVING
-- ============================================================

-- Топ-5 заказов с именами покупателей
SELECT c.name, o.product, o.amount
FROM orders o
JOIN customers c ON o.customer_id = c.id
ORDER BY o.amount DESC
LIMIT 5;

-- Сумма заказов по покупателям (только те, у кого есть заказы)
SELECT c.name, c.city, SUM(o.amount) AS total
FROM customers c
JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name, c.city
ORDER BY total DESC;

-- Все покупатели, включая тех, у кого нет заказов
SELECT c.name, COUNT(o.id) AS orders_cnt, COALESCE(SUM(o.amount), 0) AS total
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY total DESC;

-- Товары с выручкой больше 10 000 (фильтр по группам)
SELECT product, SUM(amount) AS total
FROM orders
GROUP BY product
HAVING SUM(amount) > 10000
ORDER BY total DESC;

-- ============================================================
-- 4. Подзапросы и CTE
-- ============================================================

-- Заказы дороже среднего
SELECT * FROM orders
WHERE amount > (SELECT AVG(amount) FROM orders);

-- Покупатели без заказов
SELECT name FROM customers
WHERE id NOT IN (SELECT customer_id FROM orders);

-- Покупатели, чья общая сумма выше средней по покупателям
WITH totals AS (
    SELECT customer_id, SUM(amount) AS total
    FROM orders
    GROUP BY customer_id
)
SELECT c.name, t.total
FROM totals t
JOIN customers c ON c.id = t.customer_id
WHERE t.total > (SELECT AVG(total) FROM totals)
ORDER BY t.total DESC;

-- ============================================================
-- 5. Оконные функции
-- ============================================================

-- Накопительная выручка по датам
SELECT order_date, product, amount,
       SUM(amount) OVER (ORDER BY order_date, id) AS running_total
FROM orders
ORDER BY order_date, id;

-- Самый дорогой заказ каждого покупателя
SELECT name, product, amount
FROM (
    SELECT c.name, o.product, o.amount,
           ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY o.amount DESC) AS rn
    FROM orders o
    JOIN customers c ON o.customer_id = c.id
) t
WHERE rn = 1
ORDER BY name;
