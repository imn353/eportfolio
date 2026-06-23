<?php
include 'adminNav.php';

$sql = "SELECT tb_registration.r_student, tb_user.u_matric, tb_user.u_name, tb_course.c_code, tb_course.c_name, tb_registration.r_status, tb_status.status_desc FROM tb_registration LEFT JOIN tb_user ON tb_registration.r_student = tb_user.u_matric LEFT JOIN tb_course ON tb_registration.r_course = tb_course.c_code LEFT JOIN tb_status ON tb_registration.r_status = tb_status.status_id WHERE tb_registration.r_status = 1";

$stmt = mysqli_prepare($con, $sql);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);
mysqli_stmt_close($stmt);
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
                    <th scope="col">Course Code</th>
                    <th scope="col">Course Name</th>
                    <th scope="col">Status</th>
                    <th scope="col"></th>
                </tr>
            </thead>
            <tbody>
                <?php $i = 1;
                while ($row = mysqli_fetch_assoc($result)): ?>
                    <tr>
                        <td><?php echo $i; ?></td>
                        <td><?php echo htmlspecialchars($row['u_matric']); ?></td>
                        <td><?php echo htmlspecialchars($row['u_name']); ?></td>
                        <td><?php echo htmlspecialchars($row['c_code']); ?></td>
                        <td><?php echo htmlspecialchars($row['c_name']); ?></td>
                        <td><?php echo htmlspecialchars($row['status_desc']); ?></td>
                        <td>
                            <a href="adminApproveRegistration.php?u_matric=<?php echo urlencode($row['u_matric']); ?>&c_code=<?php echo urlencode($row['c_code']); ?>" class="btn btn-success">Approve</a>
                            <a href="adminRejectRegistration.php?u_matric=<?php echo urlencode($row['u_matric']); ?>&c_code=<?php echo urlencode($row['c_code']); ?>" class="btn btn-danger">Reject</a>
                        </td>
                    </tr>
                <?php $i++;
                endwhile; ?>
            </tbody>
        </table>
    </div>
</div>
