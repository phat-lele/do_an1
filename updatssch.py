import pandas as pd
import mysql.connector

# Kết nối MySQL
conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="",
    database="book_store"
)
cursor = conn.cursor()

# Đọc file Excel
df = pd.read_excel("SACHXL.xlsx")

# Lặp qua từng dòng trong Excel
for i, row in df.iterrows():
    sql = """
    INSERT INTO books (category_id, title, author, price, stock, image)
    VALUES (%s, %s, %s, %s, %s, %s)
    ON DUPLICATE KEY UPDATE
        title = VALUES(title),
        author = VALUES(author),
        price = VALUES(price),
        stock = VALUES(stock),
        image = VALUES(image)
    """

    values = (
        row["category_id"],
        row["title"],
        row["author"],
        row["price"],
        row.get("stock", 0),
        "image/" + str(row.get("image", ""))  # nối 'image/' với tên file trong Excel
    )

    cursor.execute(sql, values)

# Lưu thay đổi
conn.commit()
print("✅ Cập nhật dữ liệu thành công!")

# Đóng kết nối
cursor.close()
conn.close()
