<?php

include 'dbconnect.php';

$id = $_POST['registerId'];
$name = $_POST['registerName'];
$email = $_POST['registerEmail'];
$password = $_POST['registerPassword'];
$confirmPassword = $_POST['confirmPassword'];


if ($password !== $confirmPassword) {
    echo '<script>alert("Passwords do not match. Please try again.");
    window.location.href = "index.php";</script>';
    exit();
}


$hashPassword = password_hash($password, PASSWORD_DEFAULT);

$sql = "INSERT INTO tb_user (u_matric, u_name, u_pwd, u_email, u_utype) 
        VALUES (?, ?, ?, ?, 1)";

$stmt = mysqli_prepare($con, $sql);
if ($stmt) {
    mysqli_stmt_bind_param($stmt, "ssss", $id, $name, $hashPassword, $email);
    $query = mysqli_stmt_execute($stmt);

    if ($query) {
        echo '<script>alert("Registration Successful");
        window.location.href = "index.php";</script>';
    } else {
        echo '<script>alert("Registration failed. Please try again.");
        window.location.href = "index.php";</script>';
    }
    mysqli_stmt_close($stmt);
} else {
    echo '<script>alert("Database error. Please try again later.");
    window.location.href = "index.php";</script>';
}

mysqli_close($con);

?>
