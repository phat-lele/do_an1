<?php
// process_order.php
require_once 'db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: admin_orders.php');
    exit;
}

$order_id = isset($_POST['order_id']) ? (int)$_POST['order_id'] : 0;
$action = isset($_POST['action']) ? $_POST['action'] : '';

if ($order_id <= 0 || !in_array($action, ['complete', 'cancel'])) {
    header('Location: admin_orders.php?msg=' . urlencode('Yêu cầu không hợp lệ.'));
    exit;
}

$conn->begin_transaction();

try {
    // Lấy trạng thái hiện tại
    $stmt = $conn->prepare("SELECT status FROM orders WHERE id = ?");
    $stmt->bind_param("i", $order_id);
    $stmt->execute();
    $rs = $stmt->get_result();
    $order = $rs->fetch_assoc();

    if (!$order) {
        throw new Exception("Không tìm thấy đơn #$order_id");
    }
    $currentStatus = $order['status'];

    // Lấy list item
    $stmt2 = $conn->prepare("SELECT book_id, SUM(quantity) AS qty FROM order_details WHERE order_id = ? GROUP BY book_id");
    $stmt2->bind_param("i", $order_id);
    $stmt2->execute();
    $items = $stmt2->get_result();

    if ($action === 'complete') {
        if ($currentStatus === 'completed') {
            throw new Exception("Đơn đã ở trạng thái 'completed'.");
        }

        // Kiểm tra tồn kho
        while ($it = $items->fetch_assoc()) {
            $check = $conn->prepare("SELECT stock FROM books WHERE id = ?");
            $check->bind_param("i", $it['book_id']);
            $check->execute();
            $stock_rs = $check->get_result()->fetch_assoc();
            $stock = (int)$stock_rs['stock'];

            if ($stock < (int)$it['qty']) {
                throw new Exception("Sách ID {$it['book_id']} không đủ hàng (Cần {$it['qty']} - Còn {$stock}).");
            }
        }

        // Trừ kho
        $items->data_seek(0);
        while ($it = $items->fetch_assoc()) {
            $upd = $conn->prepare("UPDATE books SET stock = stock - ? WHERE id = ?");
            $upd->bind_param("ii", $it['qty'], $it['book_id']);
            $upd->execute();
        }

        // Update trạng thái đơn
        $u = $conn->prepare("UPDATE orders SET status = 'completed' WHERE id = ?");
        $u->bind_param("i", $order_id);
        $u->execute();

    } else if ($action === 'cancel') {
        if ($currentStatus === 'cancelled') {
            throw new Exception("Đơn đã ở trạng thái 'cancelled'.");
        }

        // Nếu đơn đã completed => trả kho lại
        if ($currentStatus === 'completed') {
            $items->data_seek(0);
            while ($it = $items->fetch_assoc()) {
                $upd = $conn->prepare("UPDATE books SET stock = stock + ? WHERE id = ?");
                $upd->bind_param("ii", $it['qty'], $it['book_id']);
                $upd->execute();
            }
        }

        // Update trạng thái đơn
        $u = $conn->prepare("UPDATE orders SET status = 'cancelled' WHERE id = ?");
        $u->bind_param("i", $order_id);
        $u->execute();
    }

    $conn->commit();
    header('Location: admin_orders.php?msg=' . urlencode("Cập nhật đơn #$order_id thành công."));
    exit;

} catch (Exception $e) {
    $conn->rollback();
    header('Location: admin_orders.php?msg=' . urlencode("Lỗi: " . $e->getMessage()));
    exit;
}
