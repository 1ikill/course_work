-- FUNCTION: public.fill_dwh_tables()

-- DROP FUNCTION IF EXISTS public.fill_dwh_tables();

create extension dblink;

CREATE OR REPLACE procedure public.fill_dwh_tables(
	)
    -- RETURNS void
    LANGUAGE 'plpgsql'
AS $BODY$
begin
	TRUNCATE TABLE fact_product_sales;
	TRUNCATE TABLE customer_dim;
	TRUNCATE TABLE product_dim;
	TRUNCATE TABLE product_category_dim;
	TRUNCATE TABLE pet_type_dim;
	TRUNCATE TABLE bank_accounts_dim;
	TRUNCATE TABLE fact_sales;
	TRUNCATE TABLE fact_bank_balance;

	INSERT INTO fact_product_sales (id, current_price, avg_sales_price, avg_purch_price, avg_margin, current_margin, invoiced_amount, on_hand)
	(SELECT id, current_price, avg_sales_price, avg_purch_price, avg_margin, current_margin, invoiced_amount, on_hand FROM 
    	dblink('dbname=courseWork user=postgres password=postgres',
		'select id, current_price, avg_sales_price, avg_purch_price, avg_margin, current_margin, invoiced_amount, on_hand from product_sales_view')
		as t(id bigint, current_price bigint, avg_sales_price numeric, avg_purch_price numeric, avg_margin numeric, current_margin numeric, invoiced_amount numeric, on_hand bigint)
	);

	INSERT INTO customer_dim (id, first_name, last_name, gender, birth_date, customer_num, phone_num)
		(SELECT id, first_name, last_name, gender, birth_date, customer_num, phone_num FROM
		dblink('dbname=courseWork user=postgres password=postgres',
		'select id, first_name, last_name, gender, birth_date, customer_num, phone_num from customer')
		as c(id bigint, first_name text, last_name text, gender text, birth_date timestamp, customer_num text, phone_num text)
		);

	INSERT INTO product_dim (id, name, item_num, price, category_id, pet_type_id)
		(SELECT id, name, item_num, price, category_id, pet_type_id FROM
		dblink('dbname=courseWork user=postgres password=postgres',
		'select id, name, item_num, price, category_id, pet_type_id from product')
		as p(id bigint, name text, item_num text, price bigint, category_id bigint, pet_type_id bigint)
		);

	INSERT INTO product_category_dim (id, name)
		(SELECT id, name FROM
		dblink('dbname=courseWork user=postgres password=postgres',
		'select id, name from product_category')
		as k(id bigint, name text)
		);

	INSERT INTO pet_type_dim (id, name)
		(SELECT id, name FROM
		dblink('dbname=courseWork user=postgres password=postgres',
		'select id, name from pet_type')
		as v(id bigint, name text)
		);

	INSERT INTO bank_accounts_dim (id, name, account_num)
		(SELECT id, name, account_num FROM
		dblink('dbname=courseWork user=postgres password=postgres',
		'select id, name, account_num from bank_accounts')
		as b(id bigint, name text, account_num text)
		);

	INSERT INTO fact_sales (product_id, quantity, customer_id, order_num, amount, created_date)
		(SELECT product_id, quantity, customer_id, order_num, amount, created_date FROM 
	    dblink('dbname=courseWork user=postgres password=postgres',
		'select product_id, quantity, customer_id, order_num, amount, created_date from sales_view')
		as t(product_id bigint, quantity bigint, customer_id bigint, order_num text, amount numeric, created_date timestamp)
		);

	INSERT INTO fact_bank_balance (id, name, account_num, debit, credit)
		(SELECT id, name, account_num, debit, credit FROM 
	    dblink('dbname=courseWork user=postgres password=postgres',
		'select id, name, account_num, debit, credit from bank_balance_view')
		as t(id bigint, name text, account_num text, debit numeric, credit numeric)
		);
end;
$BODY$;

call fill_dwh_tables();

select * from fact_product_sales

select * from customer_dim

select * from product_dim

select * from product_category_dim

select * from pet_type_dim

select * from bank_accounts_dim;

select * from fact_sales;

select * from fact_bank_balance

 

