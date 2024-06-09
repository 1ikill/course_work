CREATE TABLE "bank_accounts"(
    "id" bigserial NOT NULL,
    "name" TEXT NOT NULL,
    "account_num" TEXT NOT NULL
);
ALTER TABLE
    "bank_accounts" ADD PRIMARY KEY("id");
ALTER TABLE
    "bank_accounts" ADD CONSTRAINT "bank_accounts_account_num_unique" UNIQUE("account_num");


CREATE TABLE "product_category"(
    "id" bigserial NOT NULL,
    "name" TEXT NOT NULL
);
ALTER TABLE
    "product_category" ADD PRIMARY KEY("id");
ALTER TABLE
    "product_category" ADD CONSTRAINT "product_category_name_unique" UNIQUE("name");


CREATE TABLE "customer"(
    "id" bigserial NOT NULL,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "gender" VARCHAR(255) CHECK
        ("gender" IN('MALE', 'FEMALE')) NOT NULL,
        "birth_date" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
        "customer_num" TEXT NOT NULL,
        "phone_num" TEXT NOT NULL
);
ALTER TABLE
    "customer" ADD PRIMARY KEY("id");
ALTER TABLE
    "customer" ADD CONSTRAINT "customer_customer_num_unique" UNIQUE("customer_num");


CREATE TABLE "pet_type"(
    "id" bigserial NOT NULL,
    "name" TEXT NOT NULL
);
ALTER TABLE
    "pet_type" ADD PRIMARY KEY("id");
ALTER TABLE
    "pet_type" ADD CONSTRAINT "pet_type_name_unique" UNIQUE("name");


CREATE TABLE "product"(
    "id" bigserial NOT NULL,
    "name" TEXT NOT NULL,
    "item_num" TEXT NOT NULL,
    "price" BIGINT NOT NULL,
    "category_id" BIGINT NOT NULL,
    "pet_type_id" BIGINT NOT NULL
);
ALTER TABLE
    "product" ADD PRIMARY KEY("id");
ALTER TABLE
    "product" ADD CONSTRAINT "product_item_num_unique" UNIQUE("item_num");


CREATE TABLE "sales_order"(
    "id" bigserial NOT NULL,
    "created_date" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "customer_id" BIGINT NOT NULL,
    "status" VARCHAR(255) CHECK
        (
            "status" IN(
                'CREATED',
                'CONFIRMED',
                'INVOICED',
                'DELIVERED'
            )
        ) NOT NULL,
        "order_num" TEXT NOT NULL
);
ALTER TABLE
    "sales_order" ADD PRIMARY KEY("id");
ALTER TABLE
    "sales_order" ADD CONSTRAINT "sales_order_order_num_unique" UNIQUE("order_num");


CREATE TABLE "inventory_transaction"(
    "id" bigserial NOT NULL,
    "quantity" BIGINT NOT NULL,
    "product_id" BIGINT NOT NULL,
    "created_date" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "type" VARCHAR(255) CHECK
        (
            "type" IN('ADJUSTMENT', 'RECEIPT', 'ISSUED')
        ) NOT NULL
);
ALTER TABLE
    "inventory_transaction" ADD PRIMARY KEY("id");


CREATE TABLE "invoice"(
    "id" bigserial NOT NULL,
    "amount" BIGINT NOT NULL,
    "sales_id" BIGINT NOT NULL,
    "created_date" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "customer_bank_account" BIGINT NOT NULL,
    "bank_account" BIGINT NOT NULL,
    "order_num" TEXT NOT NULL
);
ALTER TABLE
    "invoice" ADD PRIMARY KEY("id");


CREATE TABLE "sales_line"(
    "id" bigserial NOT NULL,
    "sales_id" BIGINT NOT NULL,
    "product_id" BIGINT NOT NULL,
    "quantity" BIGINT NOT NULL,
    "order_num" TEXT NOT NULL
);
ALTER TABLE
    "sales_line" ADD PRIMARY KEY("id");


CREATE TABLE "finance_transaction"(
    "id" bigserial NOT NULL,
    "from_bank_account" TEXT NOT NULL,
    "to_back_account" TEXT NOT NULL,
    "amount" BIGINT NOT NULL,
    "created_date" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "type" VARCHAR(255) CHECK
        (
            "type" IN('ADJUSTMENT', 'RECEIPT', 'ISSUED')
        ) NOT NULL
);
ALTER TABLE
    "finance_transaction" ADD PRIMARY KEY("id");

ALTER TABLE
    "product" ADD CONSTRAINT "product_category_id_foreign" FOREIGN KEY("category_id") REFERENCES "product_category"("id");
ALTER TABLE
    "invoice" ADD CONSTRAINT "invoice_sales_id_foreign" FOREIGN KEY("sales_id") REFERENCES "sales_order"("id");
ALTER TABLE
    "sales_line" ADD CONSTRAINT "sales_line_sales_id_foreign" FOREIGN KEY("sales_id") REFERENCES "sales_order"("id");
ALTER TABLE
    "sales_line" ADD CONSTRAINT "sales_line_product_id_foreign" FOREIGN KEY("product_id") REFERENCES "product"("id");
ALTER TABLE
    "sales_order" ADD CONSTRAINT "sales_order_customer_id_foreign" FOREIGN KEY("customer_id") REFERENCES "customer"("id");
ALTER TABLE
    "inventory_transaction" ADD CONSTRAINT "inventory_transaction_product_id_foreign" FOREIGN KEY("product_id") REFERENCES "product"("id");
ALTER TABLE
    "product" ADD CONSTRAINT "product_pet_type_id_foreign" FOREIGN KEY("pet_type_id") REFERENCES "pet_type"("id");


alter table finance_transaction add column sales_num text; 
alter table finance_transaction add column purch_num text ;

alter table inventory_transaction add column sales_num text; 
alter table inventory_transaction add column purch_num text;


CREATE UNIQUE INDEX finance_unique_purch
ON finance_transaction (purch_num, product_id);
CREATE UNIQUE INDEX finance_unique_sales
ON finance_transaction (sales_num, product_id);
CREATE UNIQUE INDEX inv_unique_purch
ON inventory_transaction (purch_num, product_id);
CREATE UNIQUE INDEX inv_unique_purch
ON inventory_transaction (purch_num, product_id);

CREATE UNIQUE INDEX IF NOT EXISTS unique_sales_idx
    ON public.invoice USING btree
    (order_num COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE UNIQUE INDEX IF NOT EXISTS unique_invoice_product_idx
    ON public.invoice_line USING btree
    (product_id ASC NULLS LAST, invoice_id ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE UNIQUE INDEX IF NOT EXISTS unique_order_product_idx
    ON public.sales_line USING btree
    (sales_id ASC NULLS LAST, product_id ASC NULLS LAST)
    TABLESPACE pg_default;

