import pandas as pd
import psycopg2

# Step 1: Extract - Read data from CSV file
csv_file_path = 'files/products.csv'
df = pd.read_csv(csv_file_path)


# Step 2: Transform - (Mapping category_name and pet_type_name to their respective IDs)
def get_id_mapping(table_name, id_col, name_col, connection):
    cursor = connection.cursor()
    cursor.execute(f"SELECT {id_col}, {name_col} FROM {table_name}")
    records = cursor.fetchall()
    cursor.close()
    return {record[1]: record[0] for record in records}


def upsert_category_and_pet_type(df, connection):
    cursor = connection.cursor()

    # Upsert categories
    for category in df['category_name'].unique():
        cursor.execute("""
            INSERT INTO product_category (name) VALUES (%s)
            ON CONFLICT (name) DO NOTHING
        """, (category,))

    # Upsert pet types
    for pet_type in df['pet_type_name'].unique():
        cursor.execute("""
            INSERT INTO pet_type (name) VALUES (%s)
            ON CONFLICT (name) DO NOTHING
        """, (pet_type,))

    connection.commit()
    cursor.close()


try:
    # Connect to the PostgreSQL database
    connection = psycopg2.connect(
        dbname="courseWork",
        user="postgres",
        password="postgres",
        host="localhost"
    )

    # Step 2.1: Upsert category and pet type data
    upsert_category_and_pet_type(df, connection)

    # Step 2.2: Get category and pet type ID mappings
    category_mapping = get_id_mapping("product_category", "id", "name", connection)
    pet_type_mapping = get_id_mapping("pet_type", "id", "name", connection)

    # Prepare the DataFrame with ID mappings
    df['category_id'] = df['category_name'].map(category_mapping)
    df['pet_type_id'] = df['pet_type_name'].map(pet_type_mapping)

    # Step 3: Load - Insert or update data in the product table
    cursor = connection.cursor()
    for _, row in df.iterrows():
        cursor.execute("""
            INSERT INTO product (name, item_num, price, category_id, pet_type_id)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (item_num) DO UPDATE SET
                name = EXCLUDED.name,
                price = EXCLUDED.price,
                category_id = EXCLUDED.category_id,
                pet_type_id = EXCLUDED.pet_type_id
        """, (row['product_name'], row['item_num'], row['price'], row['category_id'], row['pet_type_id']))

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
