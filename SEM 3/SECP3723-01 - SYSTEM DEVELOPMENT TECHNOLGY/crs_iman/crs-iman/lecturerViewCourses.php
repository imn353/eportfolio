<?php
include 'lecturerNav.php';

$u_matric = $_SESSION['u_matric'];


$sql = "SELECT * FROM tb_course WHERE c_lect = ?";
$stmt = mysqli_prepare($con, $sql);
mysqli_stmt_bind_param($stmt, "s", $u_matric);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);
?>

<div class="container">
    <div class="mt-5">
        <h2>Assigned Courses</h2>
    </div>
    <div class="mt-4">
        <table class="table">
            <thead>
                <tr>
                    <th scope="col">No.</th>
                    <th scope="col">Course Code</th>
                    <th scope="col">Course Name</th>
                    <th scope="col">Credit</th>
                    <th scope="col">Students</th>
                    <th scope="col"></th>
                </tr>
            </thead>
            <tbody>
                <?php $i = 1;
                while ($row = mysqli_fetch_array($result)): ?>
                    <tr>
                        <td><?php echo $i; ?></td>
                        <td><?php echo htmlspecialchars($row['c_code']); ?></td>
                        <td><?php echo htmlspecialchars($row['c_name']); ?></td>
                        <td><?php echo htmlspecialchars($row['c_credit']); ?></td>
                        <?php
                        // Use prepared statement for student count query
                        $query_count = "SELECT COUNT(r_student) AS student_count FROM tb_registration WHERE r_course = ?";
                        $stmt_count = mysqli_prepare($con, $query_count);
                        mysqli_stmt_bind_param($stmt_count, "s", $row['c_code']);
                        mysqli_stmt_execute($stmt_count);
                        $result_count = mysqli_stmt_get_result($stmt_count);
                        $row_count = mysqli_fetch_assoc($result_count);
                        ?>
                        <td><?php echo htmlspecialchars($row_count['student_count']) . '/' . htmlspecialchars($row['c_max_student']); ?></td>
                        <td>
                            <a href="lecturerViewCourseDetail.php?c_code=<?php echo urlencode($row['c_code']); ?>" class="btn btn-primary">Details</a>
                            <a href="lecturerViewRegisteredStudent.php?c_code=<?php echo urlencode($row['c_code']); ?>" class="btn btn-primary">Students</a>
                        </td>
                    </tr>
                <?php $i++;
                endwhile; ?>
            </tbody>
        </table>
    </div>
</div>
