<?php
include 'db_connect.php';
include 'clerkSession.php';
if (isset($_GET['id'])) {
    $id = $_GET['id'];
}

$clerkid = $_SESSION['id'];

if (isset($_POST['paymentMonth'])) {
    $fee_month = date('Y-m-01', strtotime($_POST['paymentMonth']));
    $fee_modalshare = $_POST['shareModal'];
    $fee_modalfee = $_POST['modalFee'];
    $fee_fixed_saving = $_POST['fixedSavings'];
    $fee_charity = $_POST['charityFund'];
    $fee_savings = $_POST['savings'];
    $fee_entry = $_POST['entryFee'];
    $fee_others = $_POST['others'];
    $fee_remarks = $_POST['remarks'];
    $fee_payment_method = $_POST['paymentMethod'];
    
    $sql_fee_payment = "INSERT INTO tb_fee_payment (fee_entry, fee_modalshare, fee_modalfee, fee_savings, fee_charity, fee_fixed_saving, fee_other, fee_payment_method, fee_remarks, fee_month, fee_member_id, fee_clerk_id)
                           VALUES ('$fee_entry', '$fee_modalshare', '$fee_modalfee', '$fee_savings', '$fee_charity', '$fee_fixed_saving', '$fee_others', '$fee_payment_method', '$fee_remarks', '$fee_month', '$id', '$clerkid')";
    mysqli_query($con, $sql_fee_payment);

    $id = mysqli_real_escape_string($con, $id);
    $membersql = "SELECT * FROM tb_member WHERE mem_id = '$id';";
    $memberResult = mysqli_query($con, $membersql);
    $memberRow = mysqli_fetch_array($memberResult);

    $mem_modal_share = $memberRow['mem_modal_share'] + $fee_modalshare;
    $mem_modal_fee = $memberRow['mem_modal_fee'] + $fee_modalfee;
    $mem_fixed_saving = $memberRow['mem_fixed_saving'] + $fee_fixed_saving;
    $mem_charity = $memberRow['mem_charity_fund'] + $fee_charity;
    $mem_saving = $memberRow['mem_saving'] + $fee_savings;

    $updatemembersql = "UPDATE tb_member
                            SET mem_modal_share = '$mem_modal_share',
                            mem_modal_fee = '$mem_modal_fee',
                            mem_fixed_saving = '$mem_fixed_saving',
                            mem_charity_fund = '$mem_charity',
                            mem_saving = '$mem_saving'
                            WHERE mem_id = '$id';";

    mysqli_query($con, $updatemembersql);
    echo '<script>alert("Update successful")
		window.location.href = "clerkEditShare.php"
		</script>';
} else {
    echo '<script>alert("Update failed")
		window.location.href = "clerkViewShare.php?id=$id;"
		</script>';
}
?>

