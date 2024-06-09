import pandas as pd
import psycopg2

csv_file_path = 'files/sales.csv'
df = pd.read_csv(csv_file_path, dtype={
    'order_num': str,
    'item_num': str,
    'customer_num': str,
    'customer_bank_account': str,
    'bank_account': str,
    'sales_num': str,
    'purch_num': str
})

def get_id_mapping(table_name, id_col, name_col, connection):
    cursor = connection.cursor()
    cursor.execute(f"SELECT {id_col}, {name_col} FROM {table_name}")
    records = cursor.fetchall()
    cursor.close()
    return {record[1]: record[0] for record in records}


def upsert_bank_accounts(df, connection):
    cursor = connection.cursor()

    # Upsert bank accounts
    for account_num, bank_name in df[['customer_bank_account', 'customer_bank_name']].dropna().drop_duplicates().values:
        cursor.execute("""
            INSERT INTO bank_accounts (name, account_num) VALUES (%s, %s)
            ON CONFLICT (account_num) DO NOTHING
        """, (bank_name, account_num))

    for account_num, bank_name in df[['bank_account', 'bank_name']].dropna().drop_duplicates().values:
        cursor.execute("""
            INSERT INTO bank_accounts (name, account_num) VALUES (%s, %s)
            ON CONFLICT (account_num) DO NOTHING
        """, (bank_name, account_num))

    cursor.close()


try:
    connection = psycopg2.connect(
        dbname="courseWork",
        user="postgres",
        password="postgres",
        host="localhost"
    )

    # Upsert bank account data
    upsert_bank_accounts(df, connection)

    # Get product ID mappings
    product_mapping = get_id_mapping("product", "id", "item_num", connection)

    # Get customer ID mappings
    customer_mapping = get_id_mapping("customer", "id", "customer_num", connection)

    # Prepare the DataFrame with ID mappings
    df['product_id'] = df['item_num'].map(product_mapping)
    df['customer_id'] = df['customer_num'].map(customer_mapping)

    # Insert or update data in the necessary tables
    cursor = connection.cursor()
    for _, row in df.iterrows():
        # Insert or update sales_order
        cursor.execute("""
            INSERT INTO sales_order (order_num, created_date, customer_id, status, customer_num)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (order_num) DO UPDATE SET
                created_date = EXCLUDED.created_date,
                customer_id = EXCLUDED.customer_id,
                status = EXCLUDED.status,
                customer_num = EXCLUDED.customer_num
            RETURNING id
        """, (row['order_num'], row['created_date'], row['customer_id'], row['status'], row['customer_num']))
        sales_order_id = cursor.fetchone()[0]

        # Insert or update sales_line
        cursor.execute("""
            INSERT INTO sales_line (sales_id, product_id, quantity, order_num)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (sales_id, product_id) DO UPDATE SET
                quantity = EXCLUDED.quantity
        """, (sales_order_id, row['product_id'], row['quantity'], row['order_num']))

        # Insert inventory_transaction
        cursor.execute("""
            INSERT INTO inventory_transaction (quantity, product_id, created_date, type, sales_num)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (sales_num, product_id) DO UPDATE SET
                quantity = EXCLUDED.quantity
        """, (-row['quantity'], row['product_id'], row['created_date'], 'ISSUED', row['order_num']))

        if row['status'] == 'INVOICED' or row['status'] == 'DELIVERED':
            # Insert or update invoice
            cursor.execute("""
                INSERT INTO invoice (sales_id, created_date, customer_bank_account, bank_account, order_num)
                VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT (order_num) DO UPDATE SET
                    customer_bank_account = EXCLUDED.customer_bank_account,
                    bank_account = EXCLUDED.bank_account
                RETURNING id
            """, (sales_order_id, row['invoice_date'], row['customer_bank_account'], row['bank_account'], row['order_num']))
            invoice_id = cursor.fetchone()[0]

            # Insert or update invoice_line
            cursor.execute("""
                INSERT INTO invoice_line (amount, product_id, invoice_id)
                VALUES (%s, %s, %s)
                ON CONFLICT (product_id, invoice_id) DO UPDATE SET
                    amount = EXCLUDED.amount
            """, (row['invoice_line_amount'], row['product_id'], invoice_id))

            # Insert finance_transaction
            cursor.execute("""
                INSERT INTO finance_transaction (from_bank_account, to_bank_account, amount, created_date, type, sales_num, product_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (sales_num, product_id) DO UPDATE SET
                    amount = EXCLUDED.amount
            """, (row['customer_bank_account'], row['bank_account'], row['invoice_line_amount'], row['invoice_date'], 'RECEIPT', row['order_num'], row['product_id']))

    # Commit the transaction
    connection.commit()

except Exception as error:
    print(f"Error: {error}")
    if connection:
        connection.rollback()

finally:
    if cursor:
        cursor.close()
    if connection:
        connection.close()

print("Data import completed successfully.")
