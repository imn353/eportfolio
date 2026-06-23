<?php
include 'studentNav.php';


if (!isset($_SESSION['u_matric'])) {
    echo "<script>alert('User not logged in. Redirecting to login page.');</script>";
    echo "<script>window.location.href='login.php';</script>";
    exit();
}

$student_id = $_SESSION['u_matric'];

// Fetch user details
$sql1 = "SELECT * FROM tb_user WHERE u_matric = ?";
$stmt1 = mysqli_prepare($con, $sql1);
mysqli_stmt_bind_param($stmt1, "s", $student_id);
mysqli_stmt_execute($stmt1);
$result1 = mysqli_stmt_get_result($stmt1);
$row = mysqli_fetch_assoc($result1);

if (!$row) {
    echo "<script>alert('User not found.');</script>";
    exit();
}

$name = $row['u_name'];
$email = $row['u_email'];
$hashedPassword = $row['u_pwd']; 


if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['submit'])) {

    $editEmail = trim($_POST['editEmail']);
    $currentPassword = $_POST['currentPassword'] ?? null;
    $newPassword = $_POST['newPassword'] ?? null;
    $confirmPassword = $_POST['confirmPassword'] ?? null;

    if (!empty($currentPassword) && !empty($newPassword) && !empty($confirmPassword)) {
        
        if (password_verify($currentPassword, $hashedPassword)) {
            if ($newPassword === $confirmPassword) {
                $hashedNewPwd = password_hash($newPassword, PASSWORD_DEFAULT);

                
                $sql3 = "UPDATE tb_user SET u_email = ?, u_pwd = ? WHERE u_matric = ?";
                $stmt3 = mysqli_prepare($con, $sql3);
                mysqli_stmt_bind_param($stmt3, "sss", $editEmail, $hashedNewPwd, $student_id);
                $result3 = mysqli_stmt_execute($stmt3);

                if ($result3) {
                    echo "<script>alert('Successfully Updated');</script>";
                    echo "<script>window.location.href='studentEditProfile.php';</script>";
                    exit();
                } else {
                    echo "<script>alert('Failed to update. Please try again.');</script>";
                }
            } else {
                echo "<script>alert('New password and confirm password do not match.');</script>";
            }
        } else {
            echo "<script>alert('Current password is incorrect.');</script>";
        }
    } else {
        
        $sql4 = "UPDATE tb_user SET u_email = ? WHERE u_matric = ?";
        $stmt4 = mysqli_prepare($con, $sql4);
        mysqli_stmt_bind_param($stmt4, "ss", $editEmail, $student_id);
        $result4 = mysqli_stmt_execute($stmt4);

        if ($result4) {
            echo "<script>alert('Email successfully updated');</script>";
            echo "<script>window.location.href='studentEditProfile.php';</script>";
            exit();
        } else {
            echo "<script>alert('Failed to update email. Please try again.');</script>";
        }
    }
}
?>

<div class="container">
    <h2 class="mt-5">Student Profile</h2>
    <form method="post" class = "mb-5">
        <div>
            <fieldset disabled="">
                <label class="form-label mt-4">UTMID</label>
                <input class="form-control" type="text" placeholder="<?php echo $student_id; ?>" disabled="">
            </fieldset>
        </div>
        <div>
            <fieldset disabled="">
                <label class="form-label mt-4">Name</label>
                <input class="form-control" type="text" placeholder="<?php echo $name; ?>" disabled="">
            </fieldset>
        </div>
        <div>
            <label class="form-label mt-4">Email</label>
            <input type="text" class="form-control" id="editEmail" name="editEmail" placeholder="Enter email" value="<?php echo $email; ?>">
        </div>
        <div>
            <label class="form-label mt-4">Current Password</label>
            <input type="password" class="form-control" id="currentPassword" name="currentPassword" placeholder="Enter current password" value="">
        </div>
        <div>
            <label class="form-label mt-4">New Password</label>
            <input type="password" class="form-control" id="newPassword" name="newPassword" placeholder="Enter new password" value="">
        </div>
        <div>
            <label class="form-label mt-4">Confirm Password</label>
            <input type="password" class="form-control" id="confirmPassword" name="confirmPassword" placeholder="Confirm password" value="">
        </div>
        <button type="submit" class="btn btn-primary mt-4" name="submit">Update</button>
    </form>
</div>
</body>
</html>