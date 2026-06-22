<?php
include 'studentNav.php';


$search = '';
$semester = '';
$student_id = $_SESSION['u_matric'] ?? ''; 

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!empty($_POST['semester'])) {
        $semester = mysqli_real_escape_string($con, $_POST['semester']);
    }
    if (!empty($_POST['search'])) {
        $search = mysqli_real_escape_string($con, $_POST['search']);
    }
}

$result = false;
if (!empty($semester)) {
    
    $sql = "SELECT 
                tb_course.c_code, 
                tb_course.c_name, 
                tb_course.c_credit 
            FROM tb_course 
            LEFT JOIN tb_registration 
            ON tb_course.c_code = tb_registration.r_course
            WHERE tb_course.c_sem = ? 
            AND tb_registration.r_student = ?";

    $stmt = mysqli_prepare($con, $sql);
    mysqli_stmt_bind_param($stmt, "ss", $semester, $student_id);
    mysqli_stmt_execute($stmt);
    $result = mysqli_stmt_get_result($stmt);
}
?>

<div class="container">
    <form method="POST">
        <div class="mt-5">
            <h2>Registered Courses</h2>
        </div>
        <div>
            <label class="form-label mt-4">Semester</label>
            <select class="form-select" id="semester" name="semester" required>
                <option value="">Pick a semester</option>
                <?php
                $sql2 = "SELECT * FROM tb_semester";
                $option = mysqli_query($con, $sql2);
                while ($row2 = mysqli_fetch_array($option)) {
                    echo "<option value='" . $row2['s_id'] . "'" . ($semester == $row2['s_id'] ? " selected" : "") . ">" . $row2['s_desc'] . "</option>";
                }
                ?>
            </select>
        </div>
        <div class="modal-footer mt-3">
            <input type="submit" name="submit" value="Submit" class="btn btn-primary">
        </div>
    </form>

    <?php if (!empty($semester)): ?>
        <form method="POST" class="mt-3">
            <input type="hidden" name="semester" value="<?php echo htmlspecialchars($semester); ?>">
        </form>
    <?php endif; ?>

    <?php if ($result && mysqli_num_rows($result) > 0): ?>
        <div class="mt-4">
            <table class="table">
                <thead>
                    <tr>
                        <th scope="col">No.</th>
                        <th scope="col">Course Code</th>
                        <th scope="col">Course Name</th>
                        <th scope="col">Credit</th>
                        <th scope="col">Action</th>
                    </tr>
                </thead>
                <tbody>
                    <?php $i = 1;
                    while ($row = mysqli_fetch_assoc($result)): ?>
                        <tr>
                            <td><?php echo $i; ?></td>
                            <td><?php echo htmlspecialchars($row['c_code']); ?></td>
                            <td><?php echo htmlspecialchars($row['c_name']); ?></td>
                            <td><?php echo htmlspecialchars($row['c_credit']); ?></td>
                            <td>
                                <a href="studentRemoveCourse.php?c_code=<?php echo urlencode($row['c_code']); ?>" class="btn btn-danger">Remove</a>
                            </td>
                        </tr>
                    <?php $i++;
                    endwhile; ?>
                </tbody>
            </table>
        </div>
    <?php else: ?>
        <div class="alert alert-danger mt-4 text-center">No registered courses found for the selected semester.</div>
    <?php endif; ?>
</div>
</body>
</html>
