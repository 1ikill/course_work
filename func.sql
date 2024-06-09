CREATE OR REPLACE FUNCTION find_product_by_name(p_name TEXT)
RETURNS SETOF product AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM product
    WHERE name like concat('%', p_name, '%');
END;
$$ LANGUAGE plpgsql;

SELECT * FROM find_product_by_name('Dog Chew Toy');


CREATE OR REPLACE FUNCTION find_customer_by_name(c_name TEXT)
RETURNS SETOF customer AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM customer
    WHERE first_name like concat('%', c_name, '%') or last_name like concat('%', c_name, '%');
END;
$$ LANGUAGE plpgsql;

SELECT * FROM find_customer_by_name('Todd');


CREATE OR REPLACE FUNCTION find_products_by_category_name(p_category_name TEXT)
RETURNS SETOF product AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.name, p.item_num, p.price, p.category_id, p.pet_type_id
    FROM product p
    JOIN product_category pc ON p.category_id = pc.id
    WHERE pc.name = p_category_name;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM find_products_by_category_name('Toys');


CREATE OR REPLACE FUNCTION find_products_by_pet_type(p_pet_type TEXT)
RETURNS SETOF product AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.name, p.item_num, p.price, p.category_id, p.pet_type_id
    FROM product p
    JOIN pet_type pt ON p.pet_type_id = pt.id
    WHERE pt.name = p_pet_type;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM find_products_by_pet_type('Cat');


CREATE OR REPLACE FUNCTION find_product_on_hand(pr_id BIGINT)
RETURNS TABLE(
    product_id BIGINT,
    product_name TEXT,
    quantity_on_hand numeric
	) AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.name, ih.on_hand
    FROM product p
    JOIN invent_on_hand_view ih ON p.id = ih.product_id 
	WHERE p.id = pr_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM find_product_on_hand(1);



CREATE OR REPLACE FUNCTION create_sales_order(p_order_num TEXT, p_customer_num TEXT)
RETURNS setof sales_order as $$
DECLARE
    v_customer_id BIGINT;
BEGIN
    SELECT id INTO v_customer_id
    FROM customer
    WHERE customer_num = p_customer_num;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer with customer_num % does not exist', p_customer_num;
    END IF;

    INSERT INTO sales_order (created_date, customer_id, customer_num, status, order_num)
    VALUES (CURRENT_TIMESTAMP, v_customer_id, p_customer_num, 'CREATED', p_order_num);
	
	RETURN QUERY
	SELECT id, created_date, customer_id, status, order_num, customer_num
	FROM sales_order where order_num = p_order_num;
END;
$$ LANGUAGE plpgsql;

SELECT * from create_sales_order('SO031', 'CUST-78966');


CREATE OR REPLACE FUNCTION create_sales_line(pr_id bigint, o_quantity bigint, o_id bigint)
RETURNS VOID AS $$
DECLARE
    s_order_num TEXT;
BEGIN
	SELECT order_num INTO s_order_num
    FROM sales_order
    WHERE id = o_id;
	
    INSERT INTO sales_line (sales_id, product_id, quantity, order_num)
    VALUES (o_id, pr_id, o_quantity, s_order_num);

	INSERT INTO inventory_transaction (quantity, product_id, created_date, type, sales_num)
    VALUES (- o_quantity, pr_id, CURRENT_TIMESTAMP, 'ISSUED', s_order_num);
END;
$$ LANGUAGE plpgsql;

SELECT create_sales_line(4, 4, 521);

	
CREATE OR REPLACE FUNCTION confirm_sales_order(p_sales_order_id BIGINT)
RETURNS setof sales_order as $$
BEGIN
    UPDATE sales_order
    SET status = 'CONFIRMED'
    WHERE id = p_sales_order_id
      AND status = 'CREATED';

    IF NOT FOUND THEN
        RAISE NOTICE 'Sales order % not updated because it is not in ''CREATED'' status or does not exist.', p_sales_order_id;
    END IF;

	RETURN QUERY
	SELECT id, created_date, customer_id, status, order_num, customer_num
	FROM sales_order where id = p_sales_order_id;
END;
$$ LANGUAGE plpgsql;

SELECT * from confirm_sales_order(521);


CREATE OR REPLACE FUNCTION update_sales_order_to_delivered(p_sales_order_id BIGINT)
RETURNS setof sales_order as $$
BEGIN
    UPDATE sales_order
    SET status = 'DELIVERED'
    WHERE id = p_sales_order_id
      AND status = 'INVOICED';

    IF NOT FOUND THEN
        RAISE NOTICE 'Sales order % not updated because it is not in ''INVOICED'' status or does not exist.', p_sales_order_id;
    END IF;

	RETURN QUERY
	SELECT id, created_date, customer_id, status, order_num, customer_num
	FROM sales_order where id = p_sales_order_id;
END;
$$ LANGUAGE plpgsql;

SELECT * from update_sales_order_to_delivered(521);


CREATE OR REPLACE FUNCTION create_invoice_for_sales_order(
    p_sales_order_id BIGINT,
    p_bank_account TEXT,
    p_customer_bank_account TEXT
)
RETURNS setof sales_order as $$
DECLARE
    v_sales_order RECORD;
    v_invoice_id BIGINT;
    v_sales_line RECORD;
	v_amount BIGINT;
BEGIN
    -- Verify that the sales order exists and its status is 'CONFIRMED'
    SELECT * INTO v_sales_order
    FROM sales_order
    WHERE id = p_sales_order_id
      AND status = 'CONFIRMED';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sales order % does not exist or is not in ''CONFIRMED'' status', p_sales_order_id;
    END IF;

    -- Insert a new invoice
    INSERT INTO invoice (sales_id, created_date, order_num, customer_bank_account, bank_account)
    VALUES (v_sales_order.id, CURRENT_TIMESTAMP, v_sales_order.order_num, p_customer_bank_account, p_bank_account)
    RETURNING id INTO v_invoice_id;

    -- Insert invoice lines for each sales line
    FOR v_sales_line IN
        SELECT * FROM sales_line WHERE sales_id = v_sales_order.id
    LOOP
		SELECT price * v_sales_line.quantity INTO v_amount
        FROM product
        WHERE id = v_sales_line.product_id;
		
        INSERT INTO invoice_line (amount, product_id, invoice_id)
        VALUES (v_amount, v_sales_line.product_id, v_invoice_id);

		INSERT INTO finance_transaction(from_bank_account, amount, created_date, type, sales_num, to_bank_account, product_id)
		VALUES (p_customer_bank_account, v_amount, CURRENT_TIMESTAMP, 'RECEIPT', v_sales_order.order_num, p_bank_account, v_sales_line.product_id);
    END LOOP;

    -- Update the status of the sales order to 'INVOICED'
    UPDATE sales_order
    SET status = 'INVOICED'
    WHERE id = v_sales_order.id;

	RETURN QUERY
	SELECT id, created_date, customer_id, status, order_num, customer_num
	FROM sales_order where id = p_sales_order_id;

END;
$$ LANGUAGE plpgsql;

SELECT * from create_invoice_for_sales_order(521, '987654321', '123456789');


