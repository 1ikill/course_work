create table fact_product_sales(
	id bigint,
	current_price bigint,
	avg_sales_price numeric,
	avg_purch_price numeric,
	avg_margin numeric,
	current_margin numeric,
	invoiced_amount numeric,
	on_hand bigint
);


drop table customer_dim
create table customer_dim(
	id bigint,
	first_name text,
	last_name text,
	gender text, 
	birth_date timestamp,
	customer_num text,
	phone_num text
	
);


create table product_dim(
	id bigint, 
	name text,
	item_num text,
	price bigint,
	category_id bigint,
	pet_type_id bigint
);

create table product_category_dim(
	id bigint,
	name text
);

create table pet_type_dim(
	id bigint,
	name text
);

create table fact_sales(
	product_id bigint,
	quantity bigint,
	customer_id bigint,
	order_num text,
	amount numeric,
	created_date timestamp
)

create table fact_bank_balance(
	id bigint, 
	name text, 
	account_num text,
	debit numeric, 
	credit numeric
)
