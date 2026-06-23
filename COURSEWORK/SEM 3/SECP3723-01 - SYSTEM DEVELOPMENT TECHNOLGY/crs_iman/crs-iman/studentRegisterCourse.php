<?php
include 'studentNav.php';

$search = '';
$semester = '';


if ($_SERVER['REQUEST_METHOD'] == 'POST') {
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
                tb_course.c_credit, 
                tb_course.c_max_student, 
                tb_course.c_lect,
                tb_user.u_name,
                tb_course.c_sem,
                tb_semester.s_desc
            FROM tb_course 
            LEFT JOIN tb_user ON tb_user.u_matric = tb_course.c_lect
            LEFT JOIN tb_semester ON tb_semester.s_id = tb_course.c_sem
            WHERE tb_course.c_sem = ?";

    
    if (!empty($search)) {
        $sql .= " AND (tb_course.c_code LIKE ? OR tb_course.c_name LIKE ?)";
    }

    $stmt = mysqli_prepare($con, $sql);

    if (!empty($search)) {
        $search_param = "%$search%";
        mysqli_stmt_bind_param($stmt, "sss", $semester, $search_param, $search_param);
    } else {
        mysqli_stmt_bind_param($stmt, "s", $semester);
    }

    mysqli_stmt_execute($stmt);
    $result = mysqli_stmt_get_result($stmt);
}
?>

<div class="container">
    <form method="POST">
        <div class="mt-5">
            <h2>Course Registration</h2>
        </div>
        <div>
            <label class="form-label mt-4">Semester</label>
            <select class="form-select" id="semester" name="semester" required>
                <option value="">Pick a semester</option>
                <?php
                $sql2 = "SELECT * FROM tb_semester";
                $option = mysqli_query($con, $sql2);
                while ($row2 = mysqli_fetch_array($option)) {
                    echo "<option value='" . htmlspecialchars($row2['s_id']) . "'" . 
                         ($semester == $row2['s_id'] ? " selected" : "") . ">" . 
                         htmlspecialchars($row2['s_desc']) . "</option>";
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
            <div class="input-group">
                <input type="text" class="form-control" name="search" placeholder="Search course..." value="<?php echo htmlspecialchars($search); ?>">
                <button type="submit" class="btn btn-secondary" name="submit">Search</button>
            </div>
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
                        <th scope="col">Capacity</th>
                        <th scope="col">Semester</th>
                        <th scope="col">Lecturer</th>
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
                            
                            $query_count = "SELECT COUNT(r_student) AS student_count FROM tb_registration WHERE r_course = ?";
                            $stmt_count = mysqli_prepare($con, $query_count);
                            mysqli_stmt_bind_param($stmt_count, "s", $row['c_code']);
                            mysqli_stmt_execute($stmt_count);
                            $result_count = mysqli_stmt_get_result($stmt_count);
                            $row_count = mysqli_fetch_assoc($result_count);
                            ?>
                            <td><?php echo htmlspecialchars($row_count['student_count']) . '/' . htmlspecialchars($row['c_max_student']); ?></td>
                            <td><?php echo htmlspecialchars($row['s_desc']); ?></td>
                            <td><?php echo htmlspecialchars($row['u_name']); ?></td>
                            <td>
                                <a href="studentRegisterCourseProcess.php?c_code=<?php echo urlencode($row['c_code']); ?>" class="btn btn-primary">Register</a>
                            </td>
                        </tr>
                    <?php $i++;
                    endwhile; ?>
                </tbody>
            </table>
        </div>
    <?php elseif (isset($_POST['submit']) && !empty($semester)): ?>
        <p class="text-danger mt-4">No courses available for the selected semester.</p>
    <?php endif; ?>
</div>
</body>
</html>
