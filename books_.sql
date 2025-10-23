-----------------------------------------------------------
-- 📚 TẠO CƠ SỞ DỮ LIỆU BOOKSTORE
-----------------------------------------------------------
CREATE DATABASE Book_store;       -- Tạo cơ sở dữ liệu mới tên "bookstore"
GO
USE Book_store;                   -- Sử dụng cơ sở dữ liệu vừa tạo
GO


-----------------------------------------------------------
-- 👥 BẢNG NGƯỜI DÙNG (USERS)
-----------------------------------------------------------
CREATE TABLE users (
    id INT IDENTITY(1,1) PRIMARY KEY,               -- Khóa chính, tự tăng
    username NVARCHAR(50) NOT NULL UNIQUE,          -- Tên đăng nhập, không trùng
    password NVARCHAR(255) NOT NULL,                -- Mật khẩu (đã mã hóa)
    email NVARCHAR(100) UNIQUE,                     -- Email người dùng
    role NVARCHAR(20) DEFAULT 'customer',           -- Vai trò (admin / customer)
    created_at DATETIME DEFAULT GETDATE()           -- Ngày tạo tài khoản
);
GO


-----------------------------------------------------------
-- 🏷️ BẢNG THỂ LOẠI SÁCH (CATEGORIES)
-----------------------------------------------------------
CREATE TABLE categories (
    id INT IDENTITY(1,1) PRIMARY KEY,               -- Mã thể loại
    name NVARCHAR(100) NOT NULL,                    -- Tên thể loại
    description NVARCHAR(MAX)                       -- Mô tả chi tiết
);
GO


-----------------------------------------------------------
-- 📖 BẢNG SÁCH (BOOKS)
-----------------------------------------------------------
CREATE TABLE books (
    id INT IDENTITY(1,1) PRIMARY KEY,               -- Mã sách
    category_id INT NOT NULL,                       -- Liên kết đến thể loại
    title NVARCHAR(255) NOT NULL,                   -- Tên sách
    author NVARCHAR(100),                           -- Tác giả
    price DECIMAL(10,2) NOT NULL,                   -- Giá
    stock INT DEFAULT 0,                            -- Số lượng trong kho
    image NVARCHAR(255),                            -- Ảnh minh họa
    created_at DATETIME DEFAULT GETDATE(),          -- Ngày thêm sách
    updated_at DATETIME DEFAULT GETDATE(),          -- Ngày cập nhật gần nhất
    FOREIGN KEY (category_id) REFERENCES categories(id)
);
GO


-----------------------------------------------------------
-- 🧾 BẢNG ĐƠN HÀNG (ORDERS)
-----------------------------------------------------------
CREATE TABLE orders (
    id INT IDENTITY(1,1) PRIMARY KEY,               -- Mã đơn hàng
    user_id INT NOT NULL,                           -- Người mua
    total_amount DECIMAL(10,2),                     -- Tổng tiền
    status NVARCHAR(20) DEFAULT 'pending',          -- Trạng thái đơn (pending, completed, cancelled)
    order_date DATETIME DEFAULT GETDATE(),          -- Ngày đặt hàng
    updated_at DATETIME DEFAULT GETDATE(),          -- Ngày cập nhật đơn
    FOREIGN KEY (user_id) REFERENCES users(id)
);
GO


-----------------------------------------------------------
-- 📦 BẢNG CHI TIẾT ĐƠN HÀNG (ORDER_DETAILS)
-----------------------------------------------------------
CREATE TABLE order_details (
    id INT IDENTITY(1,1) PRIMARY KEY,               -- Mã dòng chi tiết
    order_id INT NOT NULL,                          -- Liên kết đến đơn hàng
    book_id INT NOT NULL,                           -- Liên kết đến sách
    quantity INT,                                   -- Số lượng mua
    price DECIMAL(10,2),                            -- Giá mỗi sản phẩm
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(id)
);
GO


-----------------------------------------------------------
-- 💰 BẢNG GIAO DỊCH (TRANSACTIONS)
-----------------------------------------------------------
CREATE TABLE transactions (
    id INT IDENTITY(1,1) PRIMARY KEY,               -- Mã giao dịch
    user_id INT,                                    -- Người thực hiện
    product_id INT,                                 -- Sản phẩm
    quantity INT,                                   -- Số lượng
    total_price DECIMAL(10,2),                      -- Tổng tiền
    transaction_date DATETIME DEFAULT GETDATE(),    -- Ngày giao dịch
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (product_id) REFERENCES books(id)
);
GO


-----------------------------------------------------------
-- 🪪 BẢNG LỊCH SỬ CẬP NHẬT NGƯỜI DÙNG (USER_UPDATE_LOGS)
-----------------------------------------------------------
CREATE TABLE user_update_logs (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    old_username NVARCHAR(50),
    new_username NVARCHAR(50),
    old_email NVARCHAR(100),
    new_email NVARCHAR(100),
    old_role NVARCHAR(20),
    new_role NVARCHAR(20),
    updated_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
GO


-----------------------------------------------------------
-- ⚡ TỐI ƯU HIỆU NĂNG: TẠO INDEX
-----------------------------------------------------------
CREATE INDEX idx_orders_status_date ON orders(status, order_date);   -- Cho phép admin lọc theo trạng thái và ngày
CREATE INDEX idx_users_username ON users(username);                  -- Tăng tốc tìm kiếm người dùng
CREATE INDEX idx_orderdetails_bookid ON order_details(book_id);      -- Tăng tốc thống kê sách
CREATE INDEX idx_books_categoryid ON books(category_id);             -- Tăng tốc join theo thể loại
GO


-----------------------------------------------------------
-- 🧠 TRIGGER: GHI LOG GIAO DỊCH KHI THÊM CHI TIẾT ĐƠN
-----------------------------------------------------------
CREATE TRIGGER trg_LogTransaction
ON order_details
AFTER INSERT
AS
BEGIN
    INSERT INTO transactions(user_id, product_id, quantity, total_price)
    SELECT o.user_id, i.book_id, i.quantity, i.price
    FROM inserted i
    JOIN orders o ON o.id = i.order_id;
END;
GO


-----------------------------------------------------------
-- 🧮 TRIGGER: TỰ TRỪ KHO KHI MUA HÀNG
-----------------------------------------------------------
CREATE TRIGGER trg_AfterInsertOrderDetails
ON order_details
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @book_id INT, @quantity INT, @stock INT;

    SELECT @book_id = book_id, @quantity = quantity FROM inserted;
    SELECT @stock = stock FROM books WHERE id = @book_id;

    IF @stock < @quantity
    BEGIN
        RAISERROR('Not enough stock!', 16, 1);  -- Báo lỗi nếu không đủ hàng
        RETURN;
    END

    UPDATE books
    SET stock = stock - @quantity,
        updated_at = GETDATE()
    WHERE id = @book_id;
END;
GO


-----------------------------------------------------------
-- 🧾 TRIGGER: GHI LỊCH SỬ KHI CẬP NHẬT USER
-----------------------------------------------------------
CREATE TRIGGER trg_user_update
ON users
AFTER UPDATE
AS
BEGIN
    INSERT INTO user_update_logs (
        user_id, old_username, new_username, old_email, new_email, old_role, new_role
    )
    SELECT
        d.id, d.username, i.username, d.email, i.email, d.role, i.role
    FROM deleted d
    JOIN inserted i ON d.id = i.id;
END;
GO


-----------------------------------------------------------
-- 🔐 PROCEDURE: ĐĂNG NHẬP NGƯỜI DÙNG
-----------------------------------------------------------
CREATE PROCEDURE login_user
    @username NVARCHAR(50)
AS
BEGIN
    SELECT role FROM users WHERE username = @username;
END;
GO


-----------------------------------------------------------
-- 📊 PROCEDURE: THỐNG KÊ DASHBOARD ADMIN
-----------------------------------------------------------
CREATE PROCEDURE admin_dashboard_stats
AS
BEGIN
    SELECT
        (SELECT ISNULL(SUM(total_amount), 0) FROM orders WHERE status = 'completed') AS total_revenue,  -- Tổng doanh thu
        (SELECT COUNT(*) FROM orders WHERE status = 'completed') AS total_completed_orders,             -- Số đơn hoàn tất
        (SELECT ISNULL(SUM(stock), 0) FROM books) AS total_stock,                                       -- Tổng hàng trong kho
        (SELECT ISNULL(SUM(od.quantity), 0)
         FROM order_details od
         JOIN orders o ON o.id = od.order_id
         WHERE o.status = 'completed') AS total_sold_books;                                             -- Tổng sách đã bán
END;
GO


-----------------------------------------------------------
-- 💹 PROCEDURE: DOANH THU THEO NGÀY
-----------------------------------------------------------
CREATE PROCEDURE admin_revenue_by_date
AS
BEGIN
    SELECT CAST(order_date AS DATE) AS order_day,
           SUM(total_amount) AS revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY CAST(order_date AS DATE)
    ORDER BY order_day ASC;
END;
GO


-----------------------------------------------------------
-- 🏷️ PROCEDURE: TỒN KHO THEO DANH MỤC
-----------------------------------------------------------
CREATE PROCEDURE admin_stock_by_category
AS
BEGIN
    SELECT c.name AS category, SUM(b.stock) AS total_stock
    FROM books b
    JOIN categories c ON b.category_id = c.id
    GROUP BY c.name;
END;
GO


-----------------------------------------------------------
-- 📈 PROCEDURE: TOP SÁCH BÁN CHẠY
-----------------------------------------------------------
CREATE PROCEDURE sp_GetTopSellingProducts
AS
BEGIN
    SELECT TOP 10 b.title, SUM(od.quantity) AS sold
    FROM order_details od
    JOIN books b ON b.id = od.book_id
    GROUP BY b.title
    ORDER BY sold DESC;
END;
GO


-----------------------------------------------------------
-- 👥 PROCEDURE: ĐẾM SỐ LƯỢNG KHÁCH HÀNG
-----------------------------------------------------------
CREATE PROCEDURE sp_GetCustomerCount
AS
BEGIN
    SELECT COUNT(*) AS total_customers FROM users WHERE role = 'customer';
END;
GO


-----------------------------------------------------------
-- 🚀 TỐI ƯU CƠ SỞ DỮ LIỆU: GIẢM XUNG ĐỘT KHÓA
-----------------------------------------------------------
ALTER DATABASE bookstore SET READ_COMMITTED_SNAPSHOT ON;  -- Cho phép đọc snapshot tránh khóa khi admin xem báo cáo
GO
----- import csdl loai
INSERT INTO [dbo].[categories] ([name], [description]) VALUES
(N'Sách Kinh tế', N'Sách về kinh tế, quản trị, tài chính, đầu tư và phát triển doanh nghiệp'),
(N'Sách Công nghệ - CNTT', N'Sách về công nghệ thông tin, lập trình, mạng máy tính, trí tuệ nhân tạo'),
(N'Sách Kỹ năng sống', N'Những cuốn sách giúp phát triển bản thân, kỹ năng giao tiếp và tư duy tích cực'),
(N'Văn học Việt Nam', N'Tác phẩm văn học của các tác giả Việt Nam, truyện ngắn, tiểu thuyết'),
(N'Văn học nước ngoài', N'Tác phẩm văn học kinh điển trên thế giới, dịch từ tiếng Anh, Pháp, Nga, Trung Quốc'),
(N'Sách Thiếu nhi', N'Sách truyện, tranh, kỹ năng và giáo dục phù hợp cho trẻ nhỏ'),
(N'Sách Tâm lý - Tình cảm', N'Sách về tâm lý, tình cảm, hôn nhân, gia đình và phát triển cảm xúc'),
(N'Sách Học thuật - Giáo trình', N'Tài liệu chuyên ngành, giáo trình nghiên cứu và sách học thuật');
GO

---- import csdl về sách vào gồm 380 cuốn 
-- =============================================
-- Chèn toàn bộ 380 dòng dữ liệu từ tệp Book1.csv
-- Thứ tự cột: (category_id, title, author, price, stock, image)
-- =============================================
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Nghĩ giàu và làm giàu', N'Napoleon Hill', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Cha giàu, cha nghèo', N'Robert T. Kiyosaki', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Nguyên lý Kinh tế học', N'N. Gregory Mankiw', 117500, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Kinh tế học trong một bài học', N'Henry Hazlitt', 425000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Những nguyên tắc của Warren Buffett', N'Jeremy Miller (Tổng hợp)', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Từ tốt đến vĩ đại (Good to Great)', N'Jim Collins', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Từ 0 đến 1 (Zero to One)', N'Peter Thiel & Blake Masters', 140000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Khởi nghiệp tinh gọn (The Lean Startup)', N'Eric Ries', 110000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Song đề của nhà đổi mới (The Innovator''s Dilemma)', N'Clayton M. Christensen', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Lược sử tư duy kinh tế', N'Todd G. Buchholz', 130000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Kinh tế học hành vi (Misbehaving)', N'Richard H. Thaler', 240000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Quản trị chiến lược (Strategic Management)', N'Fred R. David', 175000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Marketing căn bản (Principles of Marketing)', N'Philip Kotler & Gary Armstrong', 250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Giáo trình Tài chính doanh nghiệp', N'Nhiều tác giả (Stephen Ross,...)', 325000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Phân tích đầu tư và quản trị danh mục', N'Frank K. Reilly, Keith C. Brown', 300000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Tư duy nhanh và chậm (Thinking, Fast and Slow)', N'Daniel Kahneman', 400000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Thịnh, Suy và Khủng Hoảng: Lịch Sử Các Cuộc Khủng Hoảng Tài Chính', N'Charles P. Kindleberger', 215000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Tài chính vi mô cho doanh nghiệp vừa và nhỏ', N'Nhiều tác giả (Việt Nam)', 240000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Quản trị nguồn nhân lực', N'Nhiều tác giả (Việt Nam/dịch)', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Chiến lược cạnh tranh (Competitive Strategy)', N'Michael E. Porter', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Để Bán Được Hàng, Phải Hiểu Về Tâm Lý Học', N'Tí Dã Tín Chi', 185000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Cách mạng công nghiệp 4.0 và kinh tế số', N'Nhiều tác giả (Việt Nam)', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Hệ thống KPI và quản trị hiệu suất', N'Nhiều tác giả (Việt Nam)', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Kinh tế phát triển', N'Nhiều tác giả (Giáo trình)', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Thống kê và kinh tế lượng', N'Nhiều tác giả (Giáo trình)', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Quản trị rủi ro tài chính', N'Nhiều tác giả (dịch)', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Kinh Tế Việt Nam: Thăng Trầm và Đột Phá', N'Phạm Chi Lan (chủ biên)', 275000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Doanh nghiệp gia đình', N'Nhiều tác giả (Việt Nam)', 185000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Quốc Gia Khởi Nghiệp (Start-up Nation)', N'Dan Senor & Saul Singer', 160000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Tạo lập mô hình kinh doanh (Business Model Generation)', N'Alexander Osterwalder & Yves Pigneur', 135000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Capital in the Twenty-First Century', N'Thomas Piketty', 250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'The Wealth of Nations', N'Adam Smith', 540000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Thinking, Fast and Slow', N'Daniel Kahneman', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Freakonomics', N'Steven D. Levitt & Stephen J. Dubner', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Capitalism and Freedom', N'Milton Friedman', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'The Lean Startup', N'Eric Ries', 365000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Zero to One', N'Peter Thiel & Blake Masters', 465000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Good to Great', N'Jim Collins', 425000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Competitive Strategy', N'Michael E. Porter', 540000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Misbehaving: The Making of Behavioral Economics', N'Richard H. Thaler', 625000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'The Intelligent Investor', N'Benjamin Graham', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Principles', N'Ray Dalio', 465000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'The Big Short', N'Michael Lewis', 575000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Nudge', N'Richard H. Thaler & Cass R. Sunstein', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Why Nations Fail', N'Daron Acemoglu & James A. Robinson', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'The Road to Serfdom', N'F.A. Hayek', 465000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'Poor Economics', N'Abhijit Banerjee & Esther Duflo', 325000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'The Black Swan', N'Nassim Nicholas Taleb', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'The Rise and Fall of American Growth', N'Robert J. Gordon', 465000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (1, N'The End of Alchemy', N'Mervyn King', 625000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Cấu trúc dữ liệu và thuật toán', N'Nhiều tác giả (dịch)', 465000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Lập trình C/C++ (bộ sách)', N'Phạm Văn Ất', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Lập trình Python cho người mới bắt đầu', N'Nhiều tác giả (Việt Nam/dịch)', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Giới thiệu giải thuật (Introduction to Algorithms) - CLRS', N'Cormen, Leiserson, Rivest, Stein', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Mạng máy tính (Computer Networks)', N'Andrew S. Tanenbaum', 500000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Hệ điều hành (Operating Systems)', N'Andrew S. Tanenbaum', 325000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Cơ sở dữ liệu (Fundamentals of Database Systems)', N'Ramez Elmasri & Shamkant B. Navathe', 325000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Thiết kế và phân tích thuật toán', N'Anany Levitin', 300000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'An toàn thông tin & bảo mật máy tính', N'Nhiều tác giả (Việt Nam)', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Lập trình Web với PHP & MySQL', N'Nhiều tác giả (Việt Nam)', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Lập trình Java từ cơ bản tới nâng cao', N'Nhiều tác giả (Việt Nam/dịch)', 160000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Machine Learning cơ bản', N'Nhiều tác giả (dịch)', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Deep Learning (bản dịch)', N'Ian Goodfellow, Yoshua Bengio,...', 250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Học máy bằng Python', N'Nhiều tác giả (Việt Nam/dịch)', 500000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Điện toán đám mây (Cloud Computing)', N'Nhiều tác giả (dịch)', 275000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'DevOps: culture and practice', N'Nhiều tác giả (dịch)', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Kiến trúc phần mềm', N'Nhiều tác giả (Martin Fowler,...)', 300000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Thiết kế hệ thống phân tán', N'Nhiều tác giả (Martin Kleppmann,...)', 275000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Cơ sở an toàn thông tin (giáo trình)', N'Nhiều tác giả (Giáo trình)', 250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Lập trình JavaScript & Node.js', N'Nhiều tác giả (Việt Nam)', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Thiết kế UI/UX cơ bản', N'Nhiều tác giả (Việt Nam/dịch)', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Phân tích dữ liệu & Data Science', N'Nhiều tác giả (dịch)', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Big Data – Hadoop / Spark', N'Nhiều tác giả (Tom White,...)', 275000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Kỹ thuật lập trình (Competitive Programming)', N'Steven Halim, Felix Halim', 250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Internet of Things (IoT)', N'Nhiều tác giả (Việt Nam/dịch)', 300000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Blockchain và ứng dụng', N'Nhiều tác giả (Việt Nam/dịch)', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Kiểm thử phần mềm (Software Testing)', N'Nhiều tác giả (Việt Nam)', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Lập trình Android/iOS (bộ sách)', N'Nhiều tác giả (Việt Nam)', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Git & quản lý mã nguồn', N'Nhiều tác giả (Việt Nam)', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Xây Dựng Sản Phẩm Phần Mềm Tinh Gọn', N'Nguyễn Duy (dịch)', 140000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Introduction to Algorithms', N'Cormen, Leiserson, Rivest, Stein', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Clean Code', N'Robert C. Martin', 1700000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Design Patterns', N'Gamma, Helm, Johnson, Vlissides', 900000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'The Pragmatic Programmer', N'Andrew Hunt & David Thomas', 1199000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Code Complete', N'Steve McConnell', 999000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Structure and Interpretation of Computer Programs', N'Abelson & Sussman', 1200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Operating Systems: Three Easy Pieces', N'Remzi H. & Andrea C. Arpaci-Dusseau', 1560000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Computer Networks', N'Andrew S. Tanenbaum', 625000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Artificial Intelligence: A Modern Approach', N'Stuart Russell & Peter Norvig', 1800000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Deep Learning', N'Ian Goodfellow, Yoshua Bengio, Aaron Courville', 2800000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Patterns of Enterprise Application Architecture', N'Martin Fowler', 1700000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Site Reliability Engineering (SRE book)', N'Google (Beyer, Jones,...)', 1400000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Building Microservices', N'Sam Newman', 999000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Designing Data-Intensive Applications', N'Martin Kleppmann', 800000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'You Don’t Know JS (series)', N'Kyle Simpson', 11000000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'The DevOps Handbook', N'Gene Kim, Jez Humble, et al.', 6250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Hands-On Machine Learning with Scikit-Learn, Keras & TensorFlow', N'Aurélien Géron', 11000000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Hadoop: The Definitive Guide', N'Tom White', 11000000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Clean Architecture', N'Robert C. Martin', 11000000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (2, N'Software Engineering at Google', N'Titus Winters, Tom Manshreck, Hyrum Wright', 11000000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Đắc Nhân Tâm', N'Dale Carnegie', 11000000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Tuổi Trẻ Đáng Giá Bao Nhiêu', N'Rosie Nguyễn', 11000000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Hoàn Thành Mọi Việc Không Hề Khó (Getting Things Done)', N'David Allen', 85000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Cà phê cùng Tony', N'Tony Buổi Sáng', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Nhà Giả Kim (The Alchemist)', N'Paulo Coelho', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Quẳng Gánh Lo Đi Và Vui Sống', N'Dale Carnegie', 85000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'7 Thói Quen Hiệu Quả (The 7 Habits...)', N'Stephen R. Covey', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Nghệ Thuật Tư Duy Rành Mạch', N'Rolf Dobelli', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Sức mạnh của tư duy tích cực', N'Norman Vincent Peale', 130000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Đàn Ông Sao Hỏa, Đàn Bà Sao Kim', N'John Gray', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Mình là cá, việc của mình là bơi', N'Takeshi Furukawa', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Chìa Khóa Tự Tin', N'Nhiều tác giả', 85000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Lối Sống Tối Giản Của Người Nhật', N'Sasaki Fumio', 90000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Khéo ăn nói sẽ có được thiên hạ', N'Trác Nhã', 95000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Lắng nghe bằng cả trái tim', N'Nhiều tác giả', 110000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Nhà Lãnh Đạo Không Chức Danh', N'Robin Sharma', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Bí Mật Tư Duy Triệu Phú', N'T. Harv Eker', 110000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Sức Mạnh Của Thói Quen (The Power of Habit)', N'Charles Duhigg', 110000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Những Bài Học Cuộc Sống (Hạt giống tâm hồn)', N'Nhiều tác giả', 140000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'An Lạc Từng Bước Chân', N'Thích Nhất Hạnh', 75000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Hành Trình Về Phương Đông', N'Baird T. Spalding', 65000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Nghệ Thuật Hạnh Phúc', N'Dalai Lama & Howard C. Cutler', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Lãnh đạo bằng câu hỏi tình huống', N'Michael J. Marquardt', 110000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Tư Duy Giải Quyết Vấn Đề', N'Adachi Yu', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Thói quen tốt, cuộc đời hay (Atomic Habits)', N'James Clear', 85000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Nói để người khác lắng nghe', N'Nhiều tác giả', 140000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Sáu chiếc mũ tư duy', N'Edward de Bono', 90000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'TED Talks: Bí Quyết Diễn Thuyết Trước Công Chúng', N'Chris Anderson', 110000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Tôi Tự Học', N'Nguyễn Duy Cần', 145000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Quản Lý Thời Gian Hiệu Quả', N'Brian Tracy', 75000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'How to Win Friends & Influence People', N'Dale Carnegie', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'The 7 Habits of Highly Effective People', N'Stephen R. Covey', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Atomic Habits', N'James Clear', 400000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'The Power of Habit', N'Charles Duhigg', 480000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Mindset', N'Carol S. Dweck', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Emotional Intelligence', N'Daniel Goleman', 365000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'The Subtle Art of Not Giving a F*ck', N'Mark Manson', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Man’s Search for Meaning', N'Viktor E. Frankl', 425000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Getting Things Done', N'David Allen', 315000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'The Four Agreements', N'Don Miguel Ruiz', 400000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Daring Greatly', N'Brené Brown', 250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'The Miracle Morning', N'Hal Elrod', 365000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Grit', N'Angela Duckworth', 465000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Deep Work', N'Cal Newport', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Drive', N'Daniel H. Pink', 465000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'The Alchemist', N'Paulo Coelho', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Quiet', N'Susan Cain', 365000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'The 5 AM Club', N'Robin Sharma', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'Thinking, Fast and Slow', N'Daniel Kahneman', 465000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (3, N'The Gifts of Imperfection', N'Brené Brown', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Tắt đèn', N'Ngô Tất Tố', 315000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Số đỏ', N'Vũ Trọng Phụng', 55000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Đất rừng phương Nam', N'Đoàn Giỏi', 65000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Dế Mèn phiêu lưu ký', N'Tô Hoài', 85000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Nỗi buồn chiến tranh', N'Bảo Ninh', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Mắt biếc', N'Nguyễn Nhật Ánh', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Tôi thấy hoa vàng trên cỏ xanh', N'Nguyễn Nhật Ánh', 95000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Tuổi thơ dữ dội', N'Phùng Quán', 95000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Những ngôi sao xa xôi', N'Lê Minh Khuê', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Sông Đông êm đềm (dịch)', N'Mikhail Sholokhov', 55000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Chiếc lược ngà', N'Nguyễn Quang Sáng', 250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Biệt Động Sài Gòn - Chuyện Bây Giờ Mới Kể', N'Giao Chỉ', 50000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Vợ chồng A Phủ (tuyển tập)', N'Tô Hoài', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Bến quê', N'Nguyễn Minh Châu', 55000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Những ngày thơ ấu', N'Nguyên Hồng', 50000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Cánh đồng bất tận', N'Nguyễn Ngọc Tư', 55000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Gió lạnh đầu mùa (tuyển tập)', N'Thạch Lam', 85000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Tướng về hưu (tập truyện)', N'Nguyễn Huy Thiệp', 65000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Hương rừng Cà Mau', N'Sơn Nam', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Truyện cổ tích Việt Nam (tuyển chọn)', N'Nhiều tác giả', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Bỉ vỏ', N'Nguyên Hồng', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Luân lý giáo khoa thư', N'Trần Trọng Kim', 65000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Chuyện Kể Năm 2000', N'Bùi Ngọc Tấn', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Cho tôi xin một vé đi tuổi thơ', N'Nguyễn Nhật Ánh', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Miếng ngon Hà Nội', N'Vũ Bằng', 85000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Vang bóng một thời', N'Nguyễn Tuân', 85000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Lều chõng', N'Ngô Tất Tố', 75000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Thương nhớ mười hai', N'Vũ Bằng', 65000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Chí Phèo (tuyển tập)', N'Nam Cao', 85000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (4, N'Truyện Kiều', N'Nguyễn Du', 55000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Trăm năm cô đơn', N'Gabriel García Márquez', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Anh em nhà Karamazov', N'Fyodor Dostoevsky', 365000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Chiến tranh và hòa bình', N'Leo Tolstoy', 315000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Ông già và biển cả', N'Ernest Hemingway', 325000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Bắt trẻ đồng xanh', N'J.D. Salinger', 325000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Giết con chim nhại', N'Harper Lee', 315000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Đồi gió hú', N'Emily Brontë', 275000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Kiêu hãnh và định kiến', N'Jane Austen', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Bá tước Monte Cristo', N'Alexandre Dumas', 365000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Tội ác và hình phạt', N'Fyodor Dostoevsky', 350000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Rừng Na Uy', N'Haruki Murakami', 350000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Don Quixote - Nhà quý tộc tài ba xứ Mancha', N'Miguel de Cervantes', 365000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Cuốn theo chiều gió', N'Margaret Mitchell', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Suối nguồn', N'Ayn Rand', 315000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Thép đã tôi thế đấy', N'Nikolai Ostrovsky', 365000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Bay trên tổ chim cúc cu', N'Ken Kesey', 365000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Kafka bên bờ biển', N'Haruki Murakami', 365000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Lão Goriot', N'Honoré de Balzac', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Tiếng chim hót trong bụi mận gai', N'Colleen McCullough', 315000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Hoàng tử bé', N'Antoine de Saint-Exupéry', 275000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Tên của đóa hồng', N'Umberto Eco', 400000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Người đua diều', N'Khaled Hosseini', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Cuộc đời của Pi', N'Yann Martel', 300000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Sapiens: Lược sử loài người', N'Yuval Noah Harari', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Chuông nguyện hồn ai', N'Ernest Hemingway', 65000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Những cuộc phiêu lưu của Tom Sawyer', N'Mark Twain', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Không gia đình', N'Hector Malot', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Bố già', N'Mario Puzo', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Hai vạn dặm dưới đáy biển', N'Jules Verne', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Những người khốn khổ', N'Victor Hugo', 350000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'One Hundred Years of Solitude', N'Gabriel García Márquez', 185000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'The Great Gatsby', N'F. Scott Fitzgerald', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'To Kill a Mockingbird', N'Harper Lee', 300000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'1984', N'George Orwell', 300000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'The Catcher in the Rye', N'J.D. Salinger', 350000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Pride and Prejudice', N'Jane Austen', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Crime and Punishment', N'Fyodor Dostoevsky', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'The Kite Runner', N'Khaled Hosseini', 185000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'The Road', N'Cormac McCarthy', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Beloved', N'Toni Morrison', 250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'The Handmaid’s Tale', N'Margaret Atwood', 75000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Midnight’s Children', N'Salman Rushdie', 185000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Lord of the Flies', N'William Golding', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Lolita', N'Vladimir Nabokov', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'The Alchemist', N'Paulo Coelho', 250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Norwegian Wood', N'Haruki Murakami', 185000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'The Name of the Rose', N'Umberto Eco', 75000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'Things Fall Apart', N'Chinua Achebe', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'The Picture of Dorian Gray', N'Oscar Wilde', 185000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (5, N'The Hobbit', N'J.R.R. Tolkien', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Dế Mèn phiêu lưu ký', N'Tô Hoài', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Kính vạn hoa (bộ)', N'Nguyễn Nhật Ánh', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Những tấm lòng cao cả', N'Edmondo De Amicis', 1500000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Chú bé rắc rối', N'Gianni Rodari', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Thần Đồng Đất Việt (bộ)', N'Phan Thị', 75000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Truyện cổ Andersen', N'Hans Christian Andersen', 30000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Truyện cổ Grimm', N'Anh em Grimm', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Góc sân và khoảng trời', N'Trần Đăng Khoa', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Cô bé bán diêm', N'Hans Christian Andersen', 65000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Harry Potter (bộ - bản dịch)', N'J.K. Rowling', 40000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Charlie và nhà máy sô-cô-la (bản dịch)', N'Roald Dahl', 1500000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Matilda (bản dịch)', N'Roald Dahl', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Hoàng tử bé (bản dịch)', N'Antoine de Saint-Exupéry', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Totto-chan: Cô bé bên cửa sổ', N'Kuroyanagi Tetsuko', 75000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Cậu bé rừng xanh (bản dịch)', N'Rudyard Kipling', 95000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Doraemon (bộ - bản dịch)', N'Fujiko F. Fujio', 85000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Hạt giống tâm hồn thiếu nhi', N'Nhiều tác giả', 22500, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Heidi', N'Johanna Spyri', 65000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Chuyện con mèo dạy hải âu bay', N'Luis Sepúlveda', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Lược sử Trái Đất', N'Stacy McAnulty', 60000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Bí mật của nước', N'Masaru Emoto', 85000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Nhật ký chú bé nhút nhát (bộ)', N'Jeff Kinney', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Nghìn lẻ một đêm', N'Nhiều tác giả', 95000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Alice ở xứ sở diệu kỳ', N'Lewis Carroll', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Robinson Crusoe', N'Daniel Defoe', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Đảo giấu vàng', N'Robert Louis Stevenson', 85000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Cuộc phiêu lưu của Pinocchio', N'Carlo Collodi', 85000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Peter Pan', N'J. M. Barrie', 75000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Chuyện kể cho bé ngủ', N'Nhiều tác giả', 75000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Bách khoa tri thức cho trẻ em', N'Nhiều tác giả', 75000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Harry Potter series (1-7)', N'J.K. Rowling', 250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'The Little Prince', N'Antoine de Saint-Exupéry', 505000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Charlotte’s Web', N'E.B. White', 350000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Matilda', N'Roald Dahl', 250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Charlie and the Chocolate Factory', N'Roald Dahl', 250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Where the Wild Things Are', N'Maurice Sendak', 250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'The Chronicles of Narnia (series)', N'C.S. Lewis', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Alice’s Adventures in Wonderland', N'Lewis Carroll', 380000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'The Hobbit', N'J.R.R. Tolkien', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Anne of Green Gables', N'L.M. Montgomery', 400000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'The Very Hungry Caterpillar', N'Eric Carle', 275000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'The Giving Tree', N'Shel Silverstein', 315000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Percy Jackson & the Olympians (series)', N'Rick Riordan', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'A Wrinkle in Time', N'Madeleine L’Engle', 300000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'The Secret Garden', N'Frances Hodgson Burnett', 250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Little Women', N'Louisa May Alcott', 275000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'Holes', N'Louis Sachar', 325000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'The Giver', N'Lois Lowry', 250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'The Tale of Peter Rabbit', N'Beatrix Potter', 250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (6, N'The Wind in the Willows', N'Kenneth Grahame', 240000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Tư duy nhanh và chậm', N'Daniel Kahneman', 325000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Đắc nhân tâm', N'Dale Carnegie', 215000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Muôn kiếp nhân sinh', N'Nguyên Phong', 85000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Tâm lý học đám đông', N'Gustave Le Bon', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'5 Ngôn ngữ tình yêu', N'Gary Chapman', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Đàn Ông Sao Hỏa, Đàn Bà Sao Kim', N'John Gray', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Yêu những điều không hoàn hảo', N'Hae Min', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Hiểu về trái tim', N'Minh Niệm', 110000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Nóng giận là bản năng, tĩnh lặng là bản lĩnh', N'Tống Mặc', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Dám bị ghét', N'Ichiro Kishimi & Fumitake Koga', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Sức mạnh của sự tĩnh lặng', N'Eckhart Tolle', 110000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Khi lỗi thuộc về những vì sao (văn học)', N'John Green', 115000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Trước ngày em đến (văn học)', N'Jojo Moyes', 120000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Phụ nữ thông minh không ở góc văn phòng', N'Lois P. Frankel', 140000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Bước chậm lại giữa thế gian vội vã', N'Hae Min', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Khiêu vũ với cuộc đời', N'Bridgett M. Davis', 110000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Giải mã hành vi bất thường', N'Joe Navarro', 110000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Nghệ thuật tinh tế của việc đếch quan tâm', N'Mark Manson', 145000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Flow - Dòng chảy', N'Mihaly Csikszentmihalyi', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Phi lý trí', N'Dan Ariely', 185000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Tâm lý học thành công', N'Carol S. Dweck', 140000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Càng kỷ luật, càng tự do', N'Vãn Tình', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Bạn đắt giá bao nhiêu?', N'Vãn Tình', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Sức mạnh của ngôn từ', N'Don Gabor', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Thuật Đọc Nguội', N'Vương Ngữ Mạt', 110000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Người hướng nội', N'Susan Cain', 110000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Đối thoại với Thượng Đế', N'Neale Donald Walsch', 145000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Đi tìm lẽ sống', N'Viktor E. Frankl', 185000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Trí tuệ xúc cảm', N'Daniel Goleman', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Đường xưa mây trắng', N'Thích Nhất Hạnh', 185000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Men Are from Mars, Women Are from Venus', N'John Gray', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'The Road Less Traveled', N'M. Scott Peck', 365000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Attached', N'Amir Levine & Rachel S.F. Heller', 350000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'The Five Love Languages', N'Gary Chapman', 365000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Hold Me Tight', N'Dr. Sue Johnson', 315000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Getting the Love You Want', N'Harville Hendrix', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Intimate Connections', N'David D. Burns', 365000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Emotional Intelligence', N'Daniel Goleman', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'The Psychology of Love', N'Robert J. Sternberg', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'The Body Keeps the Score', N'Bessel van der Kolk', 12000000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Conscious Loving', N'Gay Hendricks & Kathlyn Hendricks', 465000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Daring Greatly', N'Brené Brown', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'The Seven Principles for Making Marriage Work', N'John M. Gottman', 365000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Love’s Executioner', N'Irvin D. Yalom', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'The Gift of Therapy', N'Irvin D. Yalom', 365000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Hold On to Your Kids', N'Gordon Neufeld & Gabor Maté', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'The Four Loves', N'C.S. Lewis', 425000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Love Sense', N'Sue Johnson', 315000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'The Mastery of Love', N'Don Miguel Ruiz', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (7, N'Games People Play', N'Eric Berne', 315000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Kinh tế Vi mô', N'Nhiều tác giả (ĐH KTQD)', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Kinh tế Vĩ mô', N'Nhiều tác giả (ĐH KTQD)', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Toán cao cấp (bộ)', N'Nguyễn Đình Trí', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Cấu trúc dữ liệu & giải thuật', N'Lê Minh Hoàng', 200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Cơ sở dữ liệu', N'Nhiều tác giả (ĐH BKHN)', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Hệ điều hành', N'Nhiều tác giả (ĐH BKHN)', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Mạng máy tính', N'Nhiều tác giả (ĐH BKHN)', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Hóa học đại cương', N'Nhiều tác giả', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Vật lý đại cương', N'Lương Duyên Bình', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Xác suất thống kê', N'Nhiều tác giả', 175000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Toán rời rạc', N'Nhiều tác giả', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Điện tử cơ bản', N'Nhiều tác giả', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Kỹ thuật phần mềm', N'Nhiều tác giả', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Xử lý ảnh / Computer Vision', N'Nhiều tác giả', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Machine Learning', N'Nhiều tác giả', 185000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Luật học căn bản (Luật đại cương)', N'Nhiều tác giả', 185000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Quản trị kinh doanh', N'Nhiều tác giả', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Marketing (bản dịch)', N'Philip Kotler', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Tài chính doanh nghiệp (dịch)', N'Stephen A. Ross', 325000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Kế toán tài chính', N'Nhiều tác giả', 375000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Ngôn ngữ học', N'Nhiều tác giả', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Lý thuyết đồ thị', N'Nhiều tác giả', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Hệ quản trị cơ sở dữ liệu', N'Nhiều tác giả', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Phân tích thiết kế hệ thống', N'Nhiều tác giả', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Quản trị dự án (PMBOK dịch)', N'PMI', 150000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Khoa học dữ liệu (Data Science)', N'Nhiều tác giả', 400000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Thống kê ứng dụng', N'Nhiều tác giả', 215000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình An toàn thông tin (cybersecurity)', N'Nhiều tác giả', 125000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Logistics & Chuỗi cung ứng', N'Nhiều tác giả', 185000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Giáo trình Phương pháp luận nghiên cứu khoa học', N'Nhiều tác giả', 185000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Introduction to Algorithms', N'Cormen et al.', 100000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Database System Concepts', N'Silberschatz, Korth, Sudarshan', 1750000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Artificial Intelligence: A Modern Approach', N'Russell & Norvig', 2500000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Principles of Microeconomics', N'N. Gregory Mankiw', 2500000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Principles of Macroeconomics', N'N. Gregory Mankiw', 3200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Linear Algebra and Its Applications', N'Gilbert Strang', 3200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Probability and Statistics for Engineers and Scientists', N'Walpole, Myers, et al.', 1750000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Operating System Concepts', N'Silberschatz, Galvin, Gagne', 3200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Computer Networking: A Top-Down Approach', N'Kurose & Ross', 2500000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Pattern Recognition and Machine Learning', N'Christopher Bishop', 2500000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Deep Learning', N'Goodfellow et al.', 1750000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Software Engineering', N'Ian Sommerville', 1750000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Modern Control Engineering', N'Katsuhiko Ogata', 1750000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Digital Design and Computer Architecture', N'Harris & Harris', 3200000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Econometric Analysis', N'William H. Greene', 1250000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Microeconomic Theory', N'Mas-Colell, Whinston & Green', 4000000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Convex Optimization', N'Boyd & Vandenberghe', 2500000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'Data Mining: Concepts and Techniques', N'Jiawei Han, Micheline Kamber, Jian Pei', 1750000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'The Elements of Statistical Learning', N'Hastie, Tibshirani & Friedman', 1750000, 50, N'book.jdp');
INSERT INTO Books (category_id, title, author, price, stock, image) VALUES (8, N'A Guide to the Project Management Body of Knowledge (PMBOK Guide)', N'Project Management Institute (PMI)', 1750000, 50, N'book.jdp');
