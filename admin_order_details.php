<?php
// admin_order_details.php
require_once 'db.php';

$order_id = isset($_GET['order_id']) ? (int)$_GET['order_id'] : 0;
if($order_id <= 0){
    echo "Order ID không hợp lệ.";
    exit;
}

// Lấy thông tin order + user
$sqlOrder = "
    SELECT o.*, u.username 
    FROM orders o 
    JOIN users u ON o.user_id = u.id 
    WHERE o.id = $order_id
";
$resultOrder = $conn->query($sqlOrder);
$order = $resultOrder->fetch_assoc();

if(!$order){
    echo "Không tìm thấy đơn hàng #$order_id";
    exit;
}

// Lấy chi tiết order
$sqlItems = "
    SELECT od.*, b.title, b.author
    FROM order_details od
    JOIN books b ON od.book_id = b.id
    WHERE od.order_id = $order_id
";
$resultItems = $conn->query($sqlItems);
?>
<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <title>Chi tiết đơn #<?php echo $order_id; ?></title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-white">
<div class="container py-4">
  <h3>Chi tiết đơn hàng #<?php echo $order_id; ?></h3>
  <p><strong>Người đặt:</strong> <?php echo htmlspecialchars($order['username']); ?> | 
     <strong>Trạng thái:</strong> <?php echo htmlspecialchars($order['status']); ?></p>

  <table class="table table-sm table-bordered">
    <thead>
      <tr>
        <th>#</th>
        <th>Sách</th>
        <th>Tác giả</th>
        <th>Số lượng</th>
        <th>Giá (1)</th>
        <th>Tổng</th>
      </tr>
    </thead>
    <tbody>
      <?php $i=1; $sum=0; while($it = $resultItems->fetch_assoc()): ?>
      <tr>
        <td><?php echo $i++; ?></td>
        <td><?php echo htmlspecialchars($it['title']); ?></td>
        <td><?php echo htmlspecialchars($it['author']); ?></td>
        <td><?php echo $it['quantity']; ?></td>
        <td><?php echo number_format($it['price']); ?></td>
        <td><?php echo number_format($it['price'] * $it['quantity']); ?></td>
      </tr>
      <?php $sum += $it['price'] * $it['quantity']; endwhile; ?>
    </tbody>
    <tfoot>
      <tr>
        <th colspan="5" class="text-end">Tổng đơn</th>
        <th><?php echo number_format($sum); ?></th>
      </tr>
    </tfoot>
  </table>

  <a href="admin_orders.php" class="btn btn-secondary">Quay lại danh sách</a>
</div>
</body>
</html>
