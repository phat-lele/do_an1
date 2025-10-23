<?php
session_start();
require_once "db.php";

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';
    $role = 'customer'; // mặc định khách hàng

    if ($username === '' || $email === '' || $password === '') {
        $error = "Vui lòng điền đầy đủ thông tin!";
    } else {
        // kiểm tra username/email đã tồn tại chưa
        $stmt = $conn->prepare("SELECT id FROM users WHERE username=? OR email=? LIMIT 1");
        $stmt->bind_param("ss", $username, $email);
        $stmt->execute();
        $stmt->store_result();

        if ($stmt->num_rows > 0) {
            $error = "Username hoặc email đã tồn tại!";
        } else {
            // hash mật khẩu
            $hashedPassword = password_hash($password, PASSWORD_BCRYPT);

            // insert vào DB
            $insert = $conn->prepare("INSERT INTO users (username, password, email, role) VALUES (?, ?, ?, ?)");
            $insert->bind_param("ssss", $username, $hashedPassword, $email, $role);

            if ($insert->execute()) {
                // Lưu thông báo flash và chuyển sang login.php
                $_SESSION['success'] = "Đăng ký thành công! Bạn có thể đăng nhập.";
                header("Location: login.php");
                exit;
            } else {
                $error = "Lỗi khi tạo tài khoản!";
            }
        }
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Register - Bookstore</title>
</head>
<body>
    <h2>Đăng ký</h2>
    <?php if ($error) echo "<p style='color:red;'>$error</p>"; ?>
    <form method="post" action="">
        <label>Username:</label><br>
        <input type="text" name="username" required><br><br>

        <label>Email:</label><br>
        <input type="email" name="email" required><br><br>

        <label>Password:</label><br>
        <input type="password" name="password" required><br><br>

        <button type="submit">Đăng ký</button>
    </form>
</body>
</html>
