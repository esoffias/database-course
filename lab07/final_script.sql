-- =========================================================================
-- ИТОГОВЫЙ ПРОЕКТ. База данных маркетплейса.
-- Скрипт полного развертывания (DDL + DML + Логика).
-- =========================================================================

-- 1. СОЗДАНИЕ ТАБЛИЦ (Лаба 1)
DROP TABLE IF EXISTS deliveries, addresses, reviews, payments, order_items, orders, cart_items, carts, stock, products, categories, sellers, users CASCADE;

CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL CHECK (role IN ('buyer', 'seller', 'admin')),
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE sellers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    store_name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE categories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    parent_id BIGINT REFERENCES categories(id) ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE products (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seller_id BIGINT NOT NULL REFERENCES sellers(id) ON DELETE RESTRICT,
    category_id BIGINT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(12,2) NOT NULL CHECK (price > 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    attributes JSONB, -- Из Лабы 6
    avg_rating NUMERIC(3,2) DEFAULT 0 -- Из Лабы 5
);

CREATE TABLE stock (
    product_id BIGINT PRIMARY KEY REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE carts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE cart_items (
    cart_id BIGINT NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (cart_id, product_id)
);

CREATE TABLE orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    status VARCHAR(20) NOT NULL DEFAULT 'created' CHECK (status IN ('created', 'paid', 'shipped', 'completed', 'cancelled')),
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE order_items (
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price > 0),
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'success', 'failed')),
    paid_at TIMESTAMP
);

CREATE TABLE reviews (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    score INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE addresses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    city VARCHAR(100) NOT NULL,
    street VARCHAR(255) NOT NULL,
    house VARCHAR(20) NOT NULL,
    apartment VARCHAR(20)
);

CREATE TABLE deliveries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    address_id BIGINT NOT NULL REFERENCES addresses(id) ON DELETE RESTRICT,
    delivery_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    delivery_date TIMESTAMP
);

-- 2. НАПОЛНЕНИЕ ДАННЫМИ (Лаба 2)
INSERT INTO users (full_name, email, role) VALUES ('Тест', 'test@test.ru', 'seller');
INSERT INTO sellers (user_id, store_name) VALUES (1, 'Магазин');
INSERT INTO categories (name) VALUES ('Электроника'), ('Книги'), ('Одежда');

INSERT INTO products (seller_id, category_id, title, price) 
SELECT 1, (random() * 2 + 1)::int, 'Товар №' || g, (random() * 9000 + 1000)::numeric(12,2) 
FROM generate_series(1, 1000) AS g;

-- 3. АНАЛИТИЧЕСКИЕ ПРЕДСТАВЛЕНИЯ (Лаба 3)
CREATE VIEW product_catalog AS
SELECT p.id AS product_id, p.title AS product_title, p.price, c.name AS category_name, s.store_name AS seller_name
FROM products p
JOIN categories c ON p.category_id = c.id
JOIN sellers s ON p.seller_id = s.id;

-- 4. СЕРВЕРНАЯ ЛОГИКА (Лаба 5)
CREATE OR REPLACE FUNCTION log_price_change() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.price <> OLD.price THEN
        INSERT INTO price_audit_log (product_id, old_price, new_price) VALUES (OLD.id, OLD.price, NEW.price);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE price_audit_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT, old_price NUMERIC, new_price NUMERIC, changed_at TIMESTAMP DEFAULT now()
);

CREATE TRIGGER trg_price_change AFTER UPDATE ON products FOR EACH ROW EXECUTE FUNCTION log_price_change();

-- 5. ОПТИМИЗАЦИЯ (Лаба 6)
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_products_attributes ON products USING GIN (attributes);