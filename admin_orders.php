<?php
// admin_orders.php
require_once 'db.php';

// Lấy thông báo (nếu có)
$msg = isset($_GET['msg']) ? htmlspecialchars($_GET['msg']) : '';

// Lấy danh sách đơn kèm tên user và tổng số item
$sql = "
    SELECT o.id, u.username, o.total_amount, o.status, o.order_date,
           (SELECT COUNT(*) FROM order_details od WHERE od.order_id = o.id) AS item_count
    FROM orders o
    JOIN users u ON o.user_id = u.id
    ORDER BY o.order_date DESC, o.id DESC
";

$orders = [];
$stmt = $conn->query($sql);

if ($stmt && $stmt->num_rows > 0) {
    $orders = $stmt->fetch_all(MYSQLI_ASSOC);
}

?>
<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <title>Admin - Orders</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container py-4">
  <h2>Quản lý đơn hàng</h2>
  <?php if($msg): ?>
    <div class="alert alert-info"><?php echo $msg; ?></div>
  <?php endif; ?>

  <table class="table table-striped table-bordered">
    <thead>
      <tr>
        <th>Order ID</th>
        <th>Người đặt</th>
        <th>Số mặt hàng</th>
        <th>Tổng tiền</th>
        <th>Trạng thái</th>
        <th>Ngày đặt</th>
        <th>Hành động</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach($orders as $o): ?>
      <tr>
        <td><?php echo $o['id']; ?></td>
        <td><?php echo htmlspecialchars($o['username']); ?></td>
        <td><?php echo $o['item_count']; ?></td>
        <td><?php echo number_format($o['total_amount']); ?></td>
        <td>
          <?php
            $st = $o['status'];
            $badge = $st === 'completed' ? 'success' : ($st === 'cancelled' ? 'danger' : 'warning');
          ?>
          <span class="badge bg-<?php echo $badge; ?>"><?php echo htmlspecialchars($st); ?></span>
        </td>
        <td><?php echo $o['order_date']; ?></td>
        <td>
          <a href="admin_order_details.php?order_id=<?php echo $o['id']; ?>" class="btn btn-sm btn-primary">Xem</a>

          <!-- Nếu chưa hoàn thành thì có thể hoàn thành -->
          <?php if($o['status'] !== 'completed'): ?>
            <form style="display:inline" method="post" action="process_order.php">
              <input type="hidden" name="order_id" value="<?php echo $o['id']; ?>">
              <input type="hidden" name="action" value="complete">
              <button type="submit" class="btn btn-sm btn-success" onclick="return confirm('Xác nhận hoàn thành đơn #<?php echo $o['id']; ?>?')">Hoàn thành</button>
            </form>
          <?php endif; ?>

          <!-- Nếu chưa bị hủy thì có thể hủy (nếu đang completed -> sẽ trả kho lại) -->
          <?php if($o['status'] !== 'cancelled'): ?>
            <form style="display:inline" method="post" action="process_order.php">
              <input type="hidden" name="order_id" value="<?php echo $o['id']; ?>">
              <input type="hidden" name="action" value="cancel">
              <button type="submit" class="btn btn-sm btn-danger" onclick="return confirm('Xác nhận hủy đơn #<?php echo $o['id']; ?>?')">Hủy</button>
            </form>
          <?php endif; ?>
        </td>
      </tr>
      <?php endforeach; ?>
    </tbody>
  </table>
</div>
</body>
</html>
