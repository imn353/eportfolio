<?php
include('db_connect.php');

if ($_SERVER['REQUEST_METHOD'] == 'POST') {

    $loan_name = $_POST['loan_name'];
    $interest_rate = $_POST['interest_rate'];
    $max_loan_amount = $_POST['max_loan_amount'];
    $min_loan_amount = $_POST['min_loan_amount'];
    $processing_fee = $_POST['processing_fee'];

    $sql = "UPDATE tb_loan SET loan_rate = ?, loan_max = ?, loan_min = ?, loan_min_modal_share = ? WHERE loan_name = ?";
    $stmt = $con->prepare($sql);
    $stmt->bind_param("dddis", $interest_rate, $max_loan_amount, $min_loan_amount, $processing_fee, $loan_name);

    if ($stmt->execute()) {
        echo
        "<script>
            alert('Butiran pinjaman berjaya dikemas kini!');
            window.location.href = 'updatePolicy.php';
          </script>";
    } else {
        echo "Error updating loan details: " . $con->error;
    }

    $stmt->close();
}

$con->close();
?>
