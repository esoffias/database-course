-- =========================================================================
-- ЛАБОРАТОРНАЯ РАБОТА №5. Транзакции, целостность данных и серверная логика
-- =========================================================================

-- Задание 1: Демонстрация работы транзакций (успешный COMMIT и откат через ROLLBACK)
BEGIN;
INSERT INTO users (full_name, email, role) VALUES ('Тест Транзакции', 'trx@test.ru', 'buyer');
INSERT INTO carts (user_id) VALUES ((SELECT id FROM users WHERE email = 'trx@test.ru'));
COMMIT;

BEGIN;
INSERT INTO users (full_name, email, role) VALUES ('Плохой Тест', 'bad@test.ru', 'buyer');
INSERT INTO non_existent_table (id) VALUES (1); 
ROLLBACK;


-- Задание 2: Создание функции атомарного оформления заказа с проверкой остатков
CREATE OR REPLACE FUNCTION place_order(p_user_id BIGINT, p_product_id BIGINT, p_qty INT) 
RETURNS BIGINT AS $$
DECLARE 
    v_order_id BIGINT;
    v_price NUMERIC;
    v_stock INT;
BEGIN
    SELECT quantity INTO v_stock FROM stock WHERE product_id = p_product_id;
    
    IF v_stock < p_qty THEN
        RAISE EXCEPTION 'Недостаточно товара на складе. В наличии: %, запрошено: %', v_stock, p_qty;
    END IF;

    SELECT price INTO v_price FROM products WHERE id = p_product_id;

    INSERT INTO orders (user_id, status, total_amount) 
    VALUES (p_user_id, 'created', v_price * p_qty) 
    RETURNING id INTO v_order_id;

    INSERT INTO order_items (order_id, product_id, quantity, unit_price) 
    VALUES (v_order_id, p_product_id, p_qty, v_price);

    UPDATE stock SET quantity = quantity - p_qty WHERE product_id = p_product_id;

    RETURN v_order_id;
END;
$$ LANGUAGE plpgsql;


-- Задание 3: Создание функции для расчета сводного показателя (выручки продавца за период)
CREATE OR REPLACE FUNCTION get_seller_revenue(p_seller_id BIGINT, p_start_date DATE, p_end_date DATE)
RETURNS NUMERIC AS $$
DECLARE
    v_revenue NUMERIC;
BEGIN
    SELECT COALESCE(SUM(oi.quantity * oi.unit_price), 0) INTO v_revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.id
    JOIN orders o ON oi.order_id = o.id
    WHERE p.seller_id = p_seller_id 
      AND o.created_at::date BETWEEN p_start_date AND p_end_date;
      
    RETURN v_revenue;
END;
$$ LANGUAGE plpgsql;


-- Задание 4: Создание триггера аудита для записи изменений цен товаров в журнал
CREATE TABLE price_audit_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT,
    old_price NUMERIC,
    new_price NUMERIC,
    changed_at TIMESTAMP DEFAULT now()
);

CREATE OR REPLACE FUNCTION log_price_change() 
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.price <> OLD.price THEN
        INSERT INTO price_audit_log (product_id, old_price, new_price)
        VALUES (OLD.id, OLD.price, NEW.price);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_price_change
AFTER UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION log_price_change();


-- Задание 5: Создание триггера денормализации для автоматического пересчета среднего рейтинга товара
ALTER TABLE products ADD COLUMN IF NOT EXISTS avg_rating NUMERIC(3,2) DEFAULT 0;

CREATE OR REPLACE FUNCTION update_product_rating() 
RETURNS TRIGGER AS $$
BEGIN
    UPDATE products 
    SET avg_rating = (SELECT ROUND(AVG(score), 2) FROM reviews WHERE product_id = NEW.product_id)
    WHERE id = NEW.product_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_rating
AFTER INSERT OR UPDATE ON reviews
FOR EACH ROW EXECUTE FUNCTION update_product_rating();