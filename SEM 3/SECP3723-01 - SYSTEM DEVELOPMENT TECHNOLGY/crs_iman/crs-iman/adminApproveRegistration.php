<?php
include 'dbconnect.php';
include 'clerkSession.php';

$student = $_GET['u_matric']; 
$c_code = $_GET['c_code'];

$sql = "UPDATE tb_registration SET r_status = 2 WHERE r_student = ? AND r_course = ?";
$stmt = mysqli_prepare($con, $sql);

if ($stmt) {
    mysqli_stmt_bind_param($stmt, "ss", $student, $c_code);
    $result = mysqli_stmt_execute($stmt);
    mysqli_stmt_close($stmt);
} else {
    $result = false;
}

$sql_course = "UPDATE tb_course SET c_max_student = c_max_student + 1 WHERE c_code = ?";
$stmt_course = mysqli_prepare($con, $sql_course);

if ($stmt_course) {
    mysqli_stmt_bind_param($stmt_course, "s", $c_code);
    $result_course = mysqli_stmt_execute($stmt_course);
    mysqli_stmt_close($stmt_course);
} else {
    $result_course = false;
}

if ($result && $result_course) {
    echo "<script>alert('Successfully Approved'); window.location.href='adminManageRegistration.php';</script>";
} else {
    echo "<script>alert('Failed to Approve'); window.location.href='adminManageRegistration.php';</script>";
}
?>