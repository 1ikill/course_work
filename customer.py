import pandas as pd
import psycopg2

# Step 1: Extract - Read data from CSV file
csv_file_path = 'files/customers.csv'
df = pd.read_csv(csv_file_path)

try:
    # Connect to the PostgreSQL database
    connection = psycopg2.connect(
        dbname="courseWork",
        user="postgres",
        password="postgres",
        host="localhost"
    )

    # Step 2: Load - Insert or update data in the customer table
    cursor = connection.cursor()
    for _, row in df.iterrows():
        cursor.execute("""
            INSERT INTO customer (first_name, last_name, gender, birth_date, customer_num, phone_num)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT (customer_num) DO UPDATE SET
                first_name = EXCLUDED.first_name,
                last_name = EXCLUDED.last_name,
                gender = EXCLUDED.gender,
                birth_date = EXCLUDED.birth_date,
                phone_num = EXCLUDED.phone_num
        """, (row['first_name'], row['last_name'], row['gender'], row['birth_date'], row['customer_num'], row['phone_num']))

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
