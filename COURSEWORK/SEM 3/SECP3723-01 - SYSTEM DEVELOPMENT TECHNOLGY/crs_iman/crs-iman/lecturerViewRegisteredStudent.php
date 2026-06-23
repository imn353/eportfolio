<?php
include 'lecturerNav.php';

if (!isset($_GET['c_code'])) {
    die("Invalid course code.");
}

$c_code = $_GET['c_code'];


$sql = "SELECT tb_registration.r_student, tb_user.u_matric, tb_user.u_name 
        FROM tb_registration
        LEFT JOIN tb_user ON tb_registration.r_student = tb_user.u_matric
        WHERE tb_registration.r_course = ? AND tb_registration.r_status = 2";

$stmt = mysqli_prepare($con, $sql);
mysqli_stmt_bind_param($stmt, "s", $c_code);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);
?>

<div class="container">
    <div class="mt-5">
        <h2>Student List</h2>
    </div>
    <div class="mt-4">
        <table class="table">
            <thead>
                <tr>
                    <th scope="col">No.</th>
                    <th scope="col">Matric Number</th>
                    <th scope="col">Name</th>
                </tr>
            </thead>
            <tbody>
                <?php $i = 1;
                while ($row = mysqli_fetch_array($result)): ?>
                    <tr>
                        <td><?php echo $i; ?></td>
                        <td><?php echo htmlspecialchars($row['u_matric']); ?></td>
                        <td><?php echo htmlspecialchars($row['u_name']); ?></td>
                    </tr>
                <?php $i++;
                endwhile; ?>
            </tbody>
        </table>
        <a href='lecturerViewCourses.php' class='btn btn-secondary'>Back</a>
    </div>
</div>
