import pandas as pd
import psycopg2

csv_file_path = 'files/purchase.csv'
df = pd.read_csv(csv_file_path, dtype={
    'item_num': str,
    'bank_account': str,
    'vend_bank_account': str,
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
    for account_num, bank_name in df[['vend_bank_account', 'vend_bank_name']].dropna().drop_duplicates().values:
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

    # Prepare the DataFrame with ID mappings
    df['product_id'] = df['item_num'].map(product_mapping)

    # Insert or update data in the necessary tables
    cursor = connection.cursor()
    for _, row in df.iterrows():

        # Insert inventory_transaction
        cursor.execute("""
            INSERT INTO inventory_transaction (quantity, product_id, created_date, type, purch_num)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (purch_num, product_id) DO UPDATE SET
                quantity = EXCLUDED.quantity
        """, (row['quantity'], row['product_id'], row['date'], 'RECEIPT', row['purch_num']))

        # Insert finance_transaction
        cursor.execute("""
                INSERT INTO finance_transaction (from_bank_account, to_bank_account, amount, created_date, type, purch_num, product_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (purch_num, product_id) DO UPDATE SET
                    amount = EXCLUDED.amount
            """, (
        row['bank_account'], row['vend_bank_account'], row['quantity'] * row['vend_price'], row['date'], 'ISSUED',
        row['purch_num'], row['product_id']))

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