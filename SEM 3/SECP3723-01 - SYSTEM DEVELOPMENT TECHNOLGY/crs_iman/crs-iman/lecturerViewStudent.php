<?php
include 'lecturerNav.php';


$sql = "SELECT u_matric, u_name, u_email FROM tb_user WHERE u_utype = ?";
$stmt = mysqli_prepare($con, $sql);
$user_type = 1; 
mysqli_stmt_bind_param($stmt, "i", $user_type);
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
                    <th scope="col"></th>
                </tr>
            </thead>
            <tbody>
                <?php $i = 1;
                while ($row = mysqli_fetch_array($result)): ?>
                    <tr>
                        <td><?php echo $i; ?></td>
                        <td><?php echo htmlspecialchars($row['u_matric']); ?></td>
                        <td><?php echo htmlspecialchars($row['u_name']); ?></td>
                        <td>
                            <a href="lecturerViewStudentDetail.php?u_matric=<?php echo urlencode($row['u_matric']); ?>" class="btn btn-primary">View</a>
                        </td>
                    </tr>
                <?php $i++;
                endwhile; ?>
            </tbody>
        </table>
    </div>
</div>
