<?php
include 'adminNav.php';

if (isset($_POST['submit'])) {

    
    $c_code = mysqli_real_escape_string($con, $_POST['code']);
    $c_name = mysqli_real_escape_string($con, $_POST['name']);
    $c_credit = intval($_POST['credit']); 
    $c_max_student = intval($_POST['capacity']); 
    $c_sem = intval($_POST['semester']); 
    $c_lect = mysqli_real_escape_string($con, $_POST['lecturer']);
    $c_desc = mysqli_real_escape_string($con, $_POST['description']);

    
    $sql = "INSERT INTO tb_course (c_code, c_name, c_desc, c_credit, c_max_student, c_sem, c_lect) 
            VALUES (?, ?, ?, ?, ?, ?, ?)";

    
    $stmt = mysqli_prepare($con, $sql);

    if ($stmt) {

        mysqli_stmt_bind_param($stmt, "sssiiss", $c_code, $c_name, $c_desc, $c_credit, $c_max_student, $c_sem, $c_lect);
        
        
        $result = mysqli_stmt_execute($stmt);
        
        if ($result) {
            echo "<script>alert('Successfully Added New Course'); window.location.href='adminViewCourse.php';</script>";
        } else {
            echo "<script>alert('Failed to Add New Course'); window.location.href='adminViewCourse.php';</script>";
        }
        
        
        mysqli_stmt_close($stmt);
    } else {
        echo "<script>alert('Database Error'); window.location.href='adminViewCourse.php';</script>";
    }
}
?>

<div class="container">
    <h2 class="mt-5">Course Details</h2>
    <form method="post">
        <div>
            <label class="form-label mt-4">Code</label>
            <input type="text" class="form-control" id="code" name="code" placeholder="Enter course code" required>
        </div>
        <div>
            <label class="form-label mt-4">Name</label>
            <input type="text" class="form-control" id="name" name="name" placeholder="Enter course name" required>
        </div>
        <div>
            <label for="exampleTextarea" class="form-label mt-4">Description</label>
            <textarea class="form-control" id="description" name="description" rows="5"></textarea>
        </div>
        <div>
            <label class="form-label mt-4">Credit Hour</label>
            <input type="number" class="form-control" id="credit" name="credit" placeholder="Enter credit hour" required>
        </div>
        <div>
            <label class="form-label mt-4">Capacity</label>
            <input type="number" class="form-control" id="capacity" name="capacity" placeholder="Enter capacity" required>
        </div>
        <div>
            <label class="form-label mt-4">Semester</label>
            <select class="form-select" id="semester" name="semester" required>
                <option value="">Choose semester</option>
                <?php
                $sql2 = "SELECT * FROM tb_semester";
                $option = mysqli_query($con, $sql2);
                while ($row2 = mysqli_fetch_array($option)) {
                    echo "<option value='" . htmlspecialchars($row2['s_id']) . "'>" . htmlspecialchars($row2['s_desc']) . "</option>";
                }
                ?>
            </select>
        </div>
        <div>
            <label class="form-label mt-4">Lecturer</label>
            <select class="form-select" id="lecturer" name="lecturer" required>
                <option value="">Choose a lecturer</option>
                <?php
                $sql2 = "SELECT u_matric, u_name FROM tb_user WHERE u_utype = 2";
                $option = mysqli_query($con, $sql2);
                while ($row2 = mysqli_fetch_array($option)) {
                    echo "<option value='" . htmlspecialchars($row2['u_matric']) . "'>" . htmlspecialchars($row2['u_name']) . "</option>";
                }
                ?>
            </select>
        </div>
        <button type="submit" class="btn btn-primary mt-4 mb-4" name="submit">Submit</button>
    </form>
</div>
</body>
</html>
