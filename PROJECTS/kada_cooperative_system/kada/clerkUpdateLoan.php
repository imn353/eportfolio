<?php
include ('db_connect.php');
include ('clerkSession.php');

if (isset($_GET['memberId']) && isset($_GET['loanAppId'])) {
    $memberId = $_GET['memberId'];
    $loanApplicationId = $_GET['loanAppId'];
}

$clerkid = $_SESSION['id'];

if (isset($_POST['paymentMonth'])) {
    $fee_month = date('Y-m-01', strtotime($_POST['paymentMonth']));
    $fee_payment_method = $_POST['paymentMethod'];
    $fee_remarks = $_POST['remarks'];

    $sql_loan_fee = "SELECT * FROM tb_loan_application WHERE la_id = '$loanApplicationId' AND la_status = 4 ;";
    $result = mysqli_query($con, $sql_loan_fee);
    $row = mysqli_fetch_array($result);

    $loan_balance = $row['la_balance'] - $row['la_monthly_payment'];
    $loan_paid = $row['la_paid'] + $row['la_monthly_payment'];
    if ($loan_balance < 1){
      $loan_balance = 0;
      $sql_update_loan = "UPDATE tb_loan_application
                        SET la_balance = '$loan_balance',
                        la_paid = '$loan_paid',
                        la_status = 5
                        WHERE la_id = '$loanApplicationId';";
    }
    else{
      $sql_update_loan = "UPDATE tb_loan_application
                        SET la_balance = '$loan_balance',
                        la_paid = '$loan_paid'
                        WHERE la_id = '$loanApplicationId';";
    }
  
    mysqli_query($con, $sql_update_loan);

    $sql_fee_payment = "INSERT INTO tb_loan_payment (l_payment, l_paid_month, l_payment_method, l_remarks, l_member_id, l_app_id, l_clerk_id)
                        VALUES ('{$row['la_monthly_payment']}', '$fee_month', '$fee_payment_method', '$fee_remarks', '$memberId', '$loanApplicationId', '$clerkid');";
    mysqli_query($con, $sql_fee_payment);

    echo "<script>
            alert('Update successful');
            window.location.href = 'clerkViewMemberLoan.php?id={$memberId}';
          </script>";
} else {
    echo "<script>
            alert('Update failed');
            window.location.href = 'clerkViewMemberLoan.php?id={$memberId}';
          </script>";
}
?>
