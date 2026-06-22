<?php
include('memberSession.php');
include('db_connect.php');

if ($_SERVER["REQUEST_METHOD"] == "POST") {

    $la_type = $_POST['la_type'];
    $la_amount = $_POST['la_amount'];
    $la_duration = $_POST['la_duration'];
    $la_monthly_payment = $_POST['la_monthly'];
    $la_total_payment = $_POST['la_payment'];
    $la_employer_sign = file_get_contents($_FILES['la_employer_sign']['tmp_name']);
    $la_member_id = $_SESSION['id'];

    // Guarantor 1 details
    $g1_ic = $_POST['g1_ic'];
    $g1_name = $_POST['g1_name'];
    $g1_pf = $_POST['g1_pf'];
    $g1_staff_id = $_POST['g1_staff_id'];
    $g1_signature = file_get_contents($_FILES['g1_signature']['tmp_name']);

    // Guarantor 2 details
    $g2_ic = $_POST['g2_ic'];
    $g2_name = $_POST['g2_name'];
    $g2_pf = $_POST['g2_pf'];
    $g2_staff_id = $_POST['g2_staff_id'];
    $g2_signature = file_get_contents($_FILES['g2_signature']['tmp_name']);


    $query = "INSERT INTO tb_loan_application (la_type, la_amount, la_duration, la_monthly_payment, la_amount_after_interest, la_member_id, la_employer_sign) 
                  VALUES (?, ?, ?, ?, ?, ?, ?)";
    $stmt = mysqli_prepare($con, $query);

    mysqli_stmt_bind_param($stmt, "ididdib", $la_type, $la_amount, $la_duration, $la_monthly_payment, $la_total_payment, $la_member_id, $la_employer_sign);
    mysqli_stmt_send_long_data($stmt, 6, $la_employer_sign);
    mysqli_stmt_execute($stmt);

    // Get auto increment in query
    $application_id = mysqli_insert_id($con);

    // Guarantor 1 details
    $query1 = "INSERT INTO tb_guarantor (g_ic, g_name, g_pf, g_signature, g_staff_id, g_application_id) 
                           VALUES (?, ?, ?, ?, ?, ?)";
    $stmt1 = mysqli_prepare($con, $query1);

    // Guarantor 2 details
    $query2 = "INSERT INTO tb_guarantor (g_ic, g_name, g_pf, g_signature, g_staff_id, g_application_id) 
                           VALUES (?, ?, ?, ?, ?, ?)";
    $stmt2 = mysqli_prepare($con, $query2);

    mysqli_stmt_bind_param($stmt1, "ssibii", $g1_ic, $g1_name, $g1_pf, $g1_signature, $g1_staff_id, $application_id);
    mysqli_stmt_send_long_data($stmt1, 3, $g1_signature);
    mysqli_stmt_execute($stmt1);

    mysqli_stmt_bind_param($stmt2, "ssibii", $g2_ic, $g2_name, $g2_pf, $g2_signature, $g2_staff_id, $application_id);
    mysqli_stmt_send_long_data($stmt2, 3, $g2_signature);
    mysqli_stmt_execute($stmt2);

    echo "<script>
    alert('Borang Pembiayaan Anggota Berjaya Dihantar!');
    window.location.href = 'memberDashboard.php';
    </script>";
    
    mysqli_stmt_close($stmt1);
    mysqli_stmt_close($stmt2);
    mysqli_stmt_close($stmt);
    mysqli_close($con);
} else {
    echo "<script>
        alert('Invalid request.');
        window.history.back();
    </script>";
}
