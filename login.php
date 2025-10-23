<?php
session_start();
require_once "db.php";

$error = '';
$success = $_SESSION['success'] ?? '';
unset($_SESSION['success']); // Xóa flash sau khi hiển thị

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $login = trim($_POST['login'] ?? '');
    $password = $_POST['password'] ?? '';

    if ($login === '' || $password === '') {
        $error = "Vui lòng điền đầy đủ thông tin!";
    } else {
        // truy vấn user theo username hoặc email
        $stmt = $conn->prepare("SELECT * FROM users WHERE username=? OR email=? LIMIT 1");
        $stmt->bind_param("ss", $login, $login);
        $stmt->execute();
        $result = $stmt->get_result();
        $user = $result->fetch_assoc();

        if ($user) {
            // so sánh mật khẩu với hash bcrypt
            if (password_verify($password, $user['password'])) {
                $_SESSION['user_id'] = $user['id'];
                $_SESSION['username'] = $user['username'];
                $_SESSION['role'] = $user['role'];

                if ($user['role'] === 'admin') {
                    header("Location: admin_orders.php");
                } else {
                    header("Location: index.php");
                }
                exit;
            } else {
                $error = "Sai mật khẩu!";
            }
        } else {
            $error = "Username hoặc email không tồn tại!";
        }
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Login - Bookstore</title>
</head>
<body>
    <h2>Đăng nhập</h2>

    <?php 
    if ($success) echo "<p style='color:green;'>$success</p>";
    if ($error) echo "<p style='color:red;'>$error</p>"; 
    ?>

    <form method="post" action="">
        <label>Username hoặc Email:</label><br>
        <input type="text" name="login" required><br><br>

        <label>Password:</label><br>
        <input type="password" name="password" required><br><br>

        <button type="submit">Đăng nhập</button>
    </form>
</body>
</html>
