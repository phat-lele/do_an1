<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BookStore - Trang Bán Sách</title>
    <style>
        /* Reset và font */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Arial', sans-serif;
            background-color: #f4f4f4;
            color: #333;
            line-height: 1.6;
        }

        /* Navbar */
        .navbar {
            background-color: #007bff;
            padding: 1rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            position: sticky;
            top: 0;
            z-index: 100;
        }
        .navbar .logo {
            font-size: 1.5rem;
            font-weight: bold;
            color: white;
        }
        .navbar ul {
            list-style: none;
            display: flex;
            gap: 1rem;
        }
        .navbar ul li {
            position: relative;
        }
        .navbar ul li a {
            color: white;
            text-decoration: none;
            padding: 0.5rem 1rem;
            border-radius: 5px;
            transition: background-color 0.3s;
        }
        .navbar ul li a:hover {
            background-color: #0056b3;
        }
        .dropdown {
            position: relative;
        }
        .dropdown-content {
            display: none;
            position: absolute;
            background-color: white;
            min-width: 160px;
            box-shadow: 0 8px 16px rgba(0,0,0,0.2);
            z-index: 1;
            border-radius: 5px;
        }
        .dropdown:hover .dropdown-content {
            display: block;
        }
        .dropdown-content a {
            color: #333;
            padding: 12px 16px;
            text-decoration: none;
            display: block;
        }
        .dropdown-content a:hover {
            background-color: #f1f1f1;
        }
        .search-bar {
            display: flex;
            align-items: center;
        }
        .search-bar input {
            padding: 0.5rem;
            border: none;
            border-radius: 5px 0 0 5px;
            width: 200px;
        }
        .search-bar button {
            padding: 0.5rem;
            background-color: #0056b3;
            color: white;
            border: none;
            border-radius: 0 5px 5px 0;
            cursor: pointer;
            transition: background-color 0.3s;
        }
        .search-bar button:hover {
            background-color: #003d82;
        }

        /* Main content */
        .container {
            max-width: 1200px;
            margin: 2rem auto;
            padding: 0 1rem;
        }
        .hero {
            background-color: #e9ecef;
            padding: 2rem;
            text-align: center;
            border-radius: 10px;
            margin-bottom: 2rem;
        }
        .hero h1 {
            margin-bottom: 1rem;
        }
        .books-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 1.5rem;
        }
        .book-card {
            background-color: white;
            border-radius: 10px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            overflow: hidden;
            transition: transform 0.3s, box-shadow 0.3s;
        }
        .book-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 16px rgba(0,0,0,0.2);
        }
        .book-card img {
            width: 100%;
            height: 200px;
            object-fit: cover;
        }
        .book-card .content {
            padding: 1rem;
        }
        .book-card h3 {
            margin-bottom: 0.5rem;
        }
        .book-card p {
            color: #007bff;
            font-weight: bold;
            margin-bottom: 1rem;
        }
        .book-card button {
            background-color: #28a745;
            color: white;
            border: none;
            padding: 0.5rem 1rem;
            border-radius: 5px;
            cursor: pointer;
            width: 100%;
            transition: background-color 0.3s;
        }
        .book-card button:hover {
            background-color: #218838;
        }

        /* Footer */
        footer {
            background-color: #007bff;
            color: white;
            text-align: center;
            padding: 1rem;
            margin-top: 2rem;
        }

        /* Responsive */
        @media (max-width: 768px) {
            .navbar ul {
                flex-direction: column;
                gap: 0.5rem;
            }
            .search-bar input {
                width: 150px;
            }
        }
    </style>
</head>
<body>
    <!-- Navbar -->
    <nav class="navbar">
        <div class="logo">BookStore</div>
        <ul>
            <li><a href="#home">Trang chủ</a></li>
            <li class="dropdown">
                <a href="#categories">Phân loại</a>
                <div class="dropdown-content">
                    <a href="#fiction">Tiểu thuyết</a>
                    <a href="#non-fiction">Phi tiểu thuyết</a>
                    <a href="#education">Giáo dục</a>
                </div>
            </li>
            <li class="search-bar">
                <input type="text" id="search" placeholder="Tìm kiếm sách...">
                <button onclick="searchBooks()">Tìm</button>
            </li>
            <li><a href="login.php">Đăng nhập</a></li>
            <li><a href="register.php">Đăng ký</a></li>
        </ul>
    </nav>

    <!-- Main Content -->
    <div class="container">
        <section id="home" class="hero">
            <h1>Chào mừng đến với BookStore</h1>
            <p>Khám phá hàng ngàn cuốn sách với giá tốt nhất!</p>
        </section>

        <section class="books-grid" id="books">
            <!-- Sách mẫu với hình ảnh thực -->
            <div class="book-card">
                <img src="https://images.unsplash.com/photo-1544947950-fa07a98d237f?ixlib=rb-4.0.3&auto=format&fit=crop&w=250&h=200&q=80" alt="Tiểu thuyết A">
                <div class="content">
                    <h3>Tiểu thuyết A</h3>
                    <p>Giá: 100.000 VND</p>
                    <button>Mua ngay</button>
                </div>
            </div>
            <div class="book-card">
                <img src="https://images.unsplash.com/photo-1589998059171-988d887df646?ixlib=rb-4.0.3&auto=format&fit=crop&w=250&h=200&q=80" alt="Sách Khoa học">
                <div class="content">
                    <h3>Sách Khoa học</h3>
                    <p>Giá: 150.000 VND</p>
                    <button>Mua ngay</button>
                </div>
            </div>
            <div class="book-card">
                <img src="https://images.unsplash.com/photo-1512820790803-83ca734da794?ixlib=rb-4.0.3&auto=format&fit=crop&w=250&h=200&q=80" alt="Truyện tranh">
                <div class="content">
                    <h3>Truyện tranh</h3>
                    <p>Giá: 80.000 VND</p>
                    <button>Mua ngay</button>
                </div>
            </div>
            <div class="book-card">
                <img src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=250&h=200&q=80" alt="Sách Giáo dục">
                <div class="content">
                    <h3>Sách Giáo dục</h3>
                    <p>Giá: 120.000 VND</p>
                    <button>Mua ngay</button>
                </div>
            </div>
            <!-- Thêm sách khác nếu cần -->
        </section>
    </div>

    <!-- Footer -->
    <footer>
        <p>&copy; 2023 BookStore. Tất cả quyền được bảo lưu.</p>
    </footer>

    <script>
        // Hàm tìm kiếm sách
        function searchBooks() {
            const query = document.getElementById('search').value.toLowerCase();
            const books = document.querySelectorAll('.book-card');
            books.forEach(book => {
                const title = book.querySelector('h3').textContent.toLowerCase();
                if (title.includes(query)) {
                    book.style.display = 'block';
                } else {
                    book.style.display = 'none';
                }
            });
        }
    </script>
</body>
</html>
