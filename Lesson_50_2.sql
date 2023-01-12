-- Задание 2
--
-- Подключиться к БД Northwind и сделать следующие изменения:
-- 
-- 1. добавить ограничение на поле `unit_price` таблицы `products` (цена должна быть больше `0`)
--
-- pgAdmin слетел, оставив ограничение на поле, поэтому сначала его снимаю, потом устанавливаю
ALTER TABLE products 
DROP CONSTRAINT chk_products_unit_price

ALTER TABLE products 
ADD CONSTRAINT chk_products_unit_price CHECK (unit_price > 0)


--
-- 2. добавить ограничение, что поле `discontinued` таблицы `products`
--    может содержать только значения `0` или `1`
-- 
ALTER TABLE products 
ADD CONSTRAINT chk_products_discontinued CHECK (discontinued IN (0, 1))

ALTER TABLE products 
DROP CONSTRAINT chk_products_discontinued

--
-- 3.  Создать новую таблицу, содержащую все продукты, снятые с продажи (`discontinued = 1`)
--
SELECT * INTO prod_discountinued
FROM products WHERE discontinued = 1

SELECT * FROM prod_discountinued

INSERT INTO prod_discountinued
SELECT * FROM products WHERE products.discontinued = 1

DROP TABLE prod_discountinued

--
-- 4. Удалить из `products` товары, снятые с продажи (`discontinued = 1`)
--
-- Долго разбирались с Кириллом как правильно сделать задание - что делать с 
-- удаляемыми записями. Решил по собственному опыту их не удалять (могут позже пригодиться),
-- а вынести в отдельную БД с префиксом _deleted. Сначала выношу 310 записей из order_details
-- (из зависимой таблицы) в таблицу order_details_deleted, затем из product 10 записей в
-- таблицу product_deleted, зависимость не устанавливаю. Таким образом в исходных таблицах
-- актуальная информация, и вся начальная БД может быть восстановлена.

SELECT * FROM order_details
JOIN products USING (product_id)
WHERE products.discontinued = 1		--> 310 - записи на перемещение

CREATE TABLE order_details_deleted	--> Создаю таблицу для удаляемых записей
(
	order_id smallint,
	product_id smallint,
	unit_price real,
	quantity smallint,
	discount smallint
)


INSERT INTO order_details_deleted
SELECT order_id, product_id, 0, quantity, discount FROM order_details
JOIN products USING (product_id)
WHERE products.discontinued = 1		--> 310 - записи вставлены


SELECT * FROM order_details_deleted		--> 310


SELECT * INTO products_deleted
FROM products WHERE discontinued = 1

SELECT * FROM products_deleted		--> 10

-- Удаляемые данные сохранены, можно актуализировать БД
-- Освобождаюсь от FOREING KEY
ALTER TABLE order_details DROP CONSTRAINT fk_order_details_products

-- Создаю его по-новой с каскадным удалением
ALTER TABLE order_details ADD CONSTRAINT fk_order_details_products
FOREIGN KEY (product_id)
REFERENCES products (product_id)
ON DELETE CASCADE

-- Можно удалять записи

-- Состояние таблиц до удаления
SELECT * FROM order_details			--> 2155 записей
SELECT * FROM products				-- > 77 записей

DELETE FROM products WHERE discontinued = 1

-- Состояние после удаления
SELECT * FROM order_details			--> 1845 записей
SELECT * FROM order_details_deleted	--> 310

SELECT * FROM products				-- > 77
SELECT * FROM products_deleted		--> 10
