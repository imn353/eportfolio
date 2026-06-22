<?php
include 'dbconnect.php';
include 'studentSession.php';

$student_id = $_SESSION['u_matric'];
$c_code = $_GET['c_code'] ?? '';


if (empty($c_code)) {
    echo "<script>alert('Invalid course selection.'); window.history.back();</script>";
    exit;
}


$query = "SELECT c_max_student FROM tb_course WHERE c_code = ?";
$stmt = mysqli_prepare($con, $query);
mysqli_stmt_bind_param($stmt, "s", $c_code);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);
$row = mysqli_fetch_assoc($result);


if (!$row) {
    echo "<script>alert('Course not found.'); window.history.back();</script>";
    exit;
}

$max_students = $row['c_max_student'];


$query_count = "SELECT COUNT(r_student) AS student_count FROM tb_registration WHERE r_course = ?";
$stmt_count = mysqli_prepare($con, $query_count);
mysqli_stmt_bind_param($stmt_count, "s", $c_code);
mysqli_stmt_execute($stmt_count);
$result_count = mysqli_stmt_get_result($stmt_count);
$row_count = mysqli_fetch_assoc($result_count);
$current_students = $row_count['student_count'];

// Check if the student is already registered for the course
$check_query = "SELECT * FROM tb_registration WHERE r_student = ? AND r_course = ?";
$stmt_check = mysqli_prepare($con, $check_query);
mysqli_stmt_bind_param($stmt_check, "ss", $student_id, $c_code);
mysqli_stmt_execute($stmt_check);
$result_check = mysqli_stmt_get_result($stmt_check);

if (mysqli_num_rows($result_check) > 0) {
    echo "<script>alert('You are already registered for this course.'); window.location.href='studentRegisterCourse.php';</script>";
    exit;
}


$status = ($current_students < $max_students) ? 2 : 1;


$sql = "INSERT INTO tb_registration (r_student, r_course, r_status) VALUES (?, ?, ?)";
$stmt_insert = mysqli_prepare($con, $sql);
mysqli_stmt_bind_param($stmt_insert, "ssi", $student_id, $c_code, $status);

if (mysqli_stmt_execute($stmt_insert)) {
    $message = ($status == 2) ? "Course registered successfully!" : "Course is full. Waiting for admin approval!";
    echo "<script>alert('$message'); window.location.href='studentRegisterCourse.php';</script>";
} else {
    echo "<script>alert('Error registering course.'); window.history.back();</script>";
}


mysqli_stmt_close($stmt);
mysqli_stmt_close($stmt_count);
mysqli_stmt_close($stmt_check);
mysqli_stmt_close($stmt_insert);
mysqli_close($con);
?>
