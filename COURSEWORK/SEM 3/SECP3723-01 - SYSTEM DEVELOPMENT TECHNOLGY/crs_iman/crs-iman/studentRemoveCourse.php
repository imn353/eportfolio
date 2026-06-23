<?php
include 'studentSession.php';
include 'dbconnect.php';

$c_code = $_GET['c_code'] ?? '';
$student_id = $_SESSION['u_matric'];


if (empty($c_code)) {
    echo "<script>alert('Invalid course selection.'); window.history.back();</script>";
    exit;
}


$sql = "DELETE FROM tb_registration WHERE r_course = ? AND r_student = ?";
$stmt = mysqli_prepare($con, $sql);
mysqli_stmt_bind_param($stmt, "ss", $c_code, $student_id);

if (mysqli_stmt_execute($stmt)) {
    echo "<script>alert('Successfully removed course!'); window.location.href='studentViewCourse.php';</script>";
} else {
    echo "<script>alert('Failed to remove course. Please try again.'); window.history.back();</script>";
}


mysqli_stmt_close($stmt);
mysqli_close($con);
?>
