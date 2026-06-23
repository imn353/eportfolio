<?php
include 'adminSessionSession.php';
include 'dbconnect.php';

$student_id = $_GET['u_matric'];
$c_code = $_GET['c_code'];

$sql = "UPDATE tb_registration SET r_status = 3 WHERE r_student = ? AND r_course = ?";
$stmt = mysqli_prepare($con, $sql);
mysqli_stmt_bind_param($stmt, "ss", $student_id, $c_code);
$result = mysqli_stmt_execute($stmt);
mysqli_stmt_close($stmt);

if($result){
    echo "<script>alert('Successfully Rejected')</script>";
    echo "<script>window.location.href='adminManageRegistration.php'</script>";
}else{
    echo "<script>alert('Failed to Reject')</script>";
}
?>