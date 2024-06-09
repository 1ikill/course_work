create view invent_on_hand_view as
select product_id,sum(quantity) as on_hand from inventory_transaction 
group by product_id; 


create view finance_transaction_debit_view as
select to_bank_account as bank_account, sum(amount) as amount from finance_transaction group by to_bank_account;


create view finance_transaction_credit_view as
select from_bank_account as bank_account, sum(amount) as amount from finance_transaction group by from_bank_account;


create view bank_balance_view as
select bank_accounts.id as id, bank_accounts.name as name, bank_accounts.account_num as account_num, debit_view.amount as debit, -credit_view.amount as credit
from bank_accounts 
	left join finance_transaction_debit_view as debit_view on bank_accounts.account_num = debit_view.bank_account
	left join finance_transaction_credit_view as credit_view on bank_accounts.account_num = credit_view.bank_account;


create view product_average_purch_price_view as
select inventory_transaction.product_id, avg(finance_transaction.amount/inventory_transaction.quantity) as price from finance_transaction 
	inner join inventory_transaction on inventory_transaction.purch_num = finance_transaction.purch_num
	and inventory_transaction.product_id = finance_transaction.product_id
	and finance_transaction.purch_num is not null 
	group by inventory_transaction.product_id;


create view product_average_sales_price_view as
select inventory_transaction.product_id, avg(finance_transaction.amount/-inventory_transaction.quantity) as price from finance_transaction 
	inner join inventory_transaction on inventory_transaction.sales_num = finance_transaction.sales_num
	and inventory_transaction.product_id = finance_transaction.product_id 
	and finance_transaction.sales_num is not null
	inner join sales_order on sales_order.order_num = finance_transaction.sales_num and sales_order.status in ('INVOICED', 'DELIVERED') 
	group by inventory_transaction.product_id;


drop view product_prices_view
create view product_prices_view as
select product.id, product.price as current_price, sales_price.price as avg_sales_price,
	purch_price.price as avg_purch_price, 
	sales_price.price - purch_price.price as avg_margin, product.price - purch_price.price as current_margin from product
left join product_average_sales_price_view as sales_price on product.id = sales_price.product_id
left join product_average_purch_price_view as purch_price on product.id = purch_price.product_id;


drop view product_sales_view	
create view product_sales_view as
select product_prices_view.id, product_prices_view.current_price, product_prices_view.avg_sales_price,
	product_prices_view.avg_purch_price, product_prices_view.avg_margin, product_prices_view.current_margin,
	sum(invoice_line.amount) as invoiced_amount, oh.on_hand
	from product_prices_view
left join invoice_line on invoice_line.product_id = product_prices_view.id
join invent_on_hand_view oh on product_prices_view.id = oh.product_id
	group by product_prices_view.id, product_prices_view.current_price, product_prices_view.avg_sales_price,
	product_prices_view.avg_purch_price, product_prices_view.avg_margin, product_prices_view.current_margin, oh.on_hand;


CREATE VIEW sales_view AS
SELECT
   sl.product_id, sl.quantity, so.customer_id, so.order_num, il.amount, so.created_date
FROM
    sales_line sl
JOIN
    sales_order so ON sl.sales_id = so.id
LEFT JOIN
    invoice i ON so.id = i.sales_id
LEFT JOIN
    invoice_line il ON i.id = il.invoice_id and il.product_id = sl.product_id