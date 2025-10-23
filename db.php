<?php
$host = "localhost";
$username = "root";   // Tài khoản mặc định của XAMPP
$password = "";       // Mặc định để trống
$database = "bookstore";

$conn = new mysqli($host, $username, $password, $database);

// Kiểm tra kết nối
if ($conn->connect_error) {
    die("Kết nối thất bại: " . $conn->connect_error);
} else {
    // echo "Kết nối thành công!";
}
?>
