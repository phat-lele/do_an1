-- ==============================
-- Book Store: Full SQL (MySQL)
-- Charset: utf8mb4 / Collation: utf8mb4_unicode_ci
-- Engine: InnoDB
-- ==============================

CREATE DATABASE IF NOT EXISTS book_store CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE book_store;

-- ------------------------------------------------------
-- 1) USERS
-- ------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE,
    role VARCHAR(20) DEFAULT 'customer',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------
-- 2) CATEGORIES
-- ------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------
-- 3) BOOKS
-- ------------------------------------------------------
CREATE TABLE IF NOT EXISTS books (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(100),
    price DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT 0,
    image VARCHAR(255),
  
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------
-- 4) ADDRESSES (một user có thể có nhiều địa chỉ)
-- ------------------------------------------------------
CREATE TABLE IF NOT EXISTS addresses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    address_line VARCHAR(255) NOT NULL,
    ward VARCHAR(100),
    district VARCHAR(100),
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'Việt Nam',
    is_default TINYINT(1) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_addresses_user ON addresses(user_id);
CREATE INDEX idx_addresses_default ON addresses(user_id, is_default);

-- ------------------------------------------------------
-- 5) CARTS + CART_ITEMS
-- ------------------------------------------------------
CREATE TABLE IF NOT EXISTS carts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_carts_user ON carts(user_id);

CREATE TABLE IF NOT EXISTS cart_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cart_id INT NOT NULL,
    book_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (cart_id) REFERENCES carts(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_cartitems_cart ON cart_items(cart_id);
CREATE INDEX idx_cartitems_book ON cart_items(book_id);

-- ------------------------------------------------------
-- 6) WISHLISTS
-- ------------------------------------------------------
CREATE TABLE IF NOT EXISTS wishlists (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    book_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
    CONSTRAINT uq_wishlist_user_book UNIQUE (user_id, book_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_wishlist_user ON wishlists(user_id);
CREATE INDEX idx_wishlist_book ON wishlists(book_id);

-- ------------------------------------------------------
-- 7) ORDERS
-- ------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    address_id INT NULL,
    total_amount DECIMAL(12,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (address_id) REFERENCES addresses(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_orders_status_date ON orders(status, order_date);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_address ON orders(address_id);

-- ------------------------------------------------------
-- 8) ORDER_DETAILS (chi tiết đơn)
-- ------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_details (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    book_id INT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_orderdetails_order ON order_details(order_id);
CREATE INDEX idx_orderdetails_book ON order_details(book_id);

-- ------------------------------------------------------
-- 9) PAYMENTS (nâng cao)
-- ------------------------------------------------------
CREATE TABLE IF NOT EXISTS payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    user_id INT NULL,
    payment_method VARCHAR(50) NOT NULL,
    payment_status VARCHAR(30) NOT NULL DEFAULT 'pending',
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'VND',
    gateway_transaction_id VARCHAR(255),
    gateway_response TEXT,
    paid_at DATETIME NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_payments_method_status ON payments(payment_method, payment_status);

-- ------------------------------------------------------
-- 10) TRANSACTIONS (log giao dịch/nhật ký)
-- ------------------------------------------------------
CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    product_id INT,
    quantity INT,
    total_price DECIMAL(12,2),
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (product_id) REFERENCES books(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------
-- 11) REVIEWS
-- ------------------------------------------------------
CREATE TABLE IF NOT EXISTS reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    user_id INT NOT NULL,
    rating TINYINT NOT NULL,
    title VARCHAR(255),
    comment TEXT,
    is_approved TINYINT(1) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_rating_range CHECK (rating >= 1 AND rating <= 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_reviews_book ON reviews(book_id);
CREATE INDEX idx_reviews_user ON reviews(user_id);

-- ------------------------------------------------------
-- 12) NOTIFICATIONS
-- ------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    message TEXT NOT NULL,
    is_read TINYINT(1) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------
-- 13) USER_UPDATE_LOGS
-- ------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_update_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    old_username VARCHAR(50),
    new_username VARCHAR(50),
    old_email VARCHAR(100),
    new_email VARCHAR(100),
    old_role VARCHAR(20),
    new_role VARCHAR(20),
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------
-- Index tối ưu bổ sung
-- ------------------------------------------------------
CREATE INDEX idx_books_categoryid ON books(category_id);

-- ======================================================
-- PROCEDURES (login, dashboard stats, reports)
-- ======================================================
DELIMITER $$
CREATE PROCEDURE login_user(IN p_username VARCHAR(50))
BEGIN
    SELECT id, username, role FROM users WHERE username = p_username;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE admin_dashboard_stats()
BEGIN
    SELECT
        (SELECT COALESCE(SUM(total_amount),0) FROM orders WHERE status = 'completed') AS total_revenue,
        (SELECT COUNT(*) FROM orders WHERE status = 'completed') AS total_completed_orders,
        (SELECT COALESCE(SUM(stock),0) FROM books) AS total_stock,
        (SELECT COALESCE(SUM(od.quantity),0)
         FROM order_details od
         JOIN orders o ON o.id = od.order_id
         WHERE o.status = 'completed') AS total_sold_books;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE admin_revenue_by_date()
BEGIN
    SELECT DATE(order_date) AS order_day,
           SUM(total_amount) AS revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY DATE(order_date)
    ORDER BY order_day ASC;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE admin_stock_by_category()
BEGIN
    SELECT c.name AS category, SUM(b.stock) AS total_stock
    FROM books b
    JOIN categories c ON b.category_id = c.id
    GROUP BY c.name;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE sp_GetTopSellingProducts()
BEGIN
    SELECT b.title, SUM(od.quantity) AS sold
    FROM order_details od
    JOIN books b ON b.id = od.book_id
    GROUP BY b.title
    ORDER BY sold DESC
    LIMIT 10;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE sp_GetCustomerCount()
BEGIN
    SELECT COUNT(*) AS total_customers FROM users WHERE role = 'customer';
END$$
DELIMITER ;

-- ======================================================
-- TRIGGERS
--  - kiểm tra category trước khi thêm sách
--  - ngăn stock âm khi cập nhật sách
--  - tạo cart khi user mới
--  - ghi transactions (log) khi insert order_details (không trừ kho)
--  - trừ kho khi payment chuyển sang success (có kiểm tra tồn kho)
--  - hoàn kho khi payment chuyển từ success -> refunded
--  - ghi lịch sử khi update user
-- ======================================================

-- 1) BEFORE INSERT: kiểm tra category tồn tại
DELIMITER $$
CREATE TRIGGER trg_check_category_before_insert
BEFORE INSERT ON books
FOR EACH ROW
BEGIN
    DECLARE v_count INT DEFAULT 0;
    SELECT COUNT(*) INTO v_count FROM categories WHERE id = NEW.category_id;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'category_id does not exist';
    END IF;
END$$
DELIMITER ;

-- 2) BEFORE UPDATE: ngăn stock âm (an toàn)
DELIMITER $$
CREATE TRIGGER trg_prevent_negative_stock
BEFORE UPDATE ON books
FOR EACH ROW
BEGIN
    IF NEW.stock < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'stock cannot be negative';
    END IF;
END$$
DELIMITER ;

-- 3) AFTER INSERT ON users: tự tạo cart cho user mới
DELIMITER $$
CREATE TRIGGER trg_create_cart_after_user_insert
AFTER INSERT ON users
FOR EACH ROW
BEGIN
    -- Tạo cart cho user mới, IGNORE nếu đã có (UNIQUE user_id trong carts)
    INSERT IGNORE INTO carts (user_id, created_at, updated_at) VALUES (NEW.id, NOW(), NOW());
END$$
DELIMITER ;

-- 4) AFTER INSERT ON order_details: ghi transaction (log) — KHÔNG trừ kho ở đây
DELIMITER $$
CREATE TRIGGER trg_log_transaction_after_order_detail
AFTER INSERT ON order_details
FOR EACH ROW
BEGIN
    DECLARE v_user_id INT;
    SELECT user_id INTO v_user_id FROM orders WHERE id = NEW.order_id LIMIT 1;
    INSERT INTO transactions (user_id, product_id, quantity, total_price)
    VALUES (v_user_id, NEW.book_id, NEW.quantity, NEW.price * NEW.quantity);
END$$
DELIMITER ;

-- 5) AFTER UPDATE ON payments: trừ kho khi payment_status -> 'success'
DELIMITER $$
CREATE TRIGGER trg_reduce_stock_after_payment_success
AFTER UPDATE ON payments
FOR EACH ROW
BEGIN
    DECLARE v_insufficient_count INT DEFAULT 0;

    -- Nếu chuyển sang success từ trạng thái khác
    IF NEW.payment_status = 'success' AND OLD.payment_status != 'success' THEN

        -- Kiểm tra tồn kho: có book nào thiếu không?
        SELECT COUNT(*) INTO v_insufficient_count
        FROM order_details od
        JOIN books b ON b.id = od.book_id
        WHERE od.order_id = NEW.order_id AND b.stock < od.quantity;

        IF v_insufficient_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough stock to complete payment';
        END IF;

        -- Nếu đủ, trừ kho
        UPDATE books b
        JOIN order_details od ON b.id = od.book_id
        SET b.stock = b.stock - od.quantity
        WHERE od.order_id = NEW.order_id;
    END IF;
END$$
DELIMITER ;

-- 6) AFTER UPDATE ON payments: hoàn kho nếu chuyển từ success -> refunded
DELIMITER $$
CREATE TRIGGER trg_restore_stock_on_payment_refund
AFTER UPDATE ON payments
FOR EACH ROW
BEGIN
    IF NEW.payment_status = 'refunded' AND OLD.payment_status = 'success' THEN
        UPDATE books b
        JOIN order_details od ON b.id = od.book_id
        SET b.stock = b.stock + od.quantity
        WHERE od.order_id = NEW.order_id;
    END IF;
END$$
DELIMITER ;

-- 7) AFTER UPDATE ON users: ghi lịch sử thay đổi user
DELIMITER $$
CREATE TRIGGER trg_user_update
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    INSERT INTO user_update_logs
    (user_id, old_username, new_username, old_email, new_email, old_role, new_role, updated_at)
    VALUES (OLD.id, OLD.username, NEW.username, OLD.email, NEW.email, OLD.role, NEW.role, NOW());
END$$
DELIMITER ;

-- ======================================================
-- CLEANUP / NOTES
-- ======================================================
/*
  - Logic trừ kho: chỉ trừ khi payment_status chuyển thành 'success' (trigger trg_reduce_stock_after_payment_success).
    Điều này tránh trừ kho khi chỉ có order tạo ra nhưng chưa thanh toán.
  - Nếu muốn trừ kho tại thời điểm tạo order (tùy business), thay đổi trigger tương ứng.
  - Nếu bạn dùng cả trigger trừ kho trên orders.status = 'paid', hãy đảm bảo chỉ 1 trigger thực hiện việc trừ.
  - Cẩn thận chạy script nhiều lần: một số FOREIGN KEY / TRIGGER có thể đã tồn tại -> xóa trước hoặc kiểm tra.
*/

-- ==============================
-- END OF SCRIPT
-- ==============================


INSERT INTO categories (name, description) VALUES
('Sách Kinh tế', 'Sách về kinh tế, quản trị, tài chính, đầu tư và phát triển doanh nghiệp'),
('Sách Công nghệ - CNTT', 'Sách về công nghệ thông tin, lập trình, mạng máy tính, trí tuệ nhân tạo'),
('Sách Kỹ năng sống', 'Những cuốn sách giúp phát triển bản thân, kỹ năng giao tiếp và tư duy tích cực'),
('Văn học Việt Nam', 'Tác phẩm văn học của các tác giả Việt Nam, truyện ngắn, tiểu thuyết'),
('Văn học nước ngoài', 'Tác phẩm văn học kinh điển trên thế giới, dịch từ tiếng Anh, Pháp, Nga, Trung Quốc'),
('Sách Thiếu nhi', 'Sách truyện, tranh, kỹ năng và giáo dục phù hợp cho trẻ nhỏ'),
('Sách Tâm lý - Tình cảm', 'Sách về tâm lý, tình cảm, hôn nhân, gia đình và phát triển cảm xúc'),
('Sách Học thuật - Giáo trình', 'Tài liệu chuyên ngành, giáo trình nghiên cứu và sách học thuật'),
('Sách Tiếng Anh', 'Sách học tiếng Anh, luyện thi TOEIC, IELTS, giao tiếp và ngữ pháp tiếng Anh');

-- 2. Người dùng
INSERT INTO users (username, password, email, role) VALUES
('phat', '$2y$10$edtAAbJ3fZHLRMhlew/u5O047rnNW.tEGUCDPgTe6JVgUbqmJ/gdi', 'phat@example.com', 'customer'),
('admin', '$2y$10$edtAAbJ3fZHLRMhlew/u5O047rnNW.tEGUCDPgTe6JVgUbqmJ/gdi', 'admin@example.com', 'admin'),
('anh', '$2y$10$edtAAbJ3fZHLRMhlew/u5O047rnNW.tEGUCDPgTe6JVgUbqmJ/gdi', 'anh@example.com', 'customer');

-- 3. Sách
INSERT INTO books (category_id, title, author, price, stock, image) VALUES
(1, 'Bí mật tư duy triệu phú', 'T. Harv Eker', 120000, 30, 'bimat.jpg'),
(1, 'Cha giàu cha nghèo', 'Robert Kiyosaki', 150000, 25, 'richdad.jpg'),
(2, 'Lập trình Python cơ bản', 'Nguyễn Văn A', 180000, 40, 'python.jpg'),
(2, 'Trí tuệ nhân tạo và Ứng dụng', 'Lê Minh', 220000, 15, 'ai.jpg', ),
(5, 'English Grammar in Use', 'Raymond Murphy', 250000, 20, 'grammar.jpg', ),
(4, 'Tắt đèn', 'Ngô Tất Tố', 90000, 50, 'tatden.jpg', );

-- 4. Địa chỉ giao hàng
INSERT INTO addresses (user_id, full_name, phone, address_line, ward, district, city, is_default)
VALUES
(1, 'Nguyễn Phát', '0909123456', '123 Đường ABC', 'Phường 1', 'Quận 3', 'TP. HCM', 1),
(3, 'Trần Anh', '0988777666', '45 Lê Lợi', 'Phường 2', 'Quận 5', 'TP. HCM', 1);

-- 5. Đơn hàng
INSERT INTO orders (user_id, address_id, total_amount, status)
VALUES
(1, 1, 300000, 'pending'),
(3, 2, 440000, 'pending');

-- 6. Chi tiết đơn hàng
INSERT INTO order_details (order_id, book_id, quantity, price) VALUES
(1, 1, 1, 120000),
(1, 2, 1, 150000),
(2, 3, 2, 180000),
(2, 5, 1, 250000);

-- 7. Thanh toán
INSERT INTO payments (order_id, user_id, payment_method, payment_status, amount)
VALUES
(1, 1, 'vnpay', 'success', 270000),
(2, 3, 'momo', 'pending', 440000);