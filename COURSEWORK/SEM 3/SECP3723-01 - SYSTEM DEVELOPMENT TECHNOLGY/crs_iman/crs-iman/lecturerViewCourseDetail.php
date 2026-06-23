<?php
include 'lecturerNav.php';



if (!isset($_GET['c_code']) || empty($_GET['c_code'])) {
    echo "<script>alert('Invalid course selection.'); window.location.href='lecturerViewCourses.php';</script>";
    exit;
}

$c_code = mysqli_real_escape_string($con, $_GET['c_code']); 


$sql = "SELECT * FROM tb_course WHERE c_code = '$c_code'";
$result = mysqli_query($con, $sql);

if (!$result || mysqli_num_rows($result) == 0) {
    echo "<script>alert('Course not found.'); window.location.href='lecturerViewCourses.php';</script>";
    exit;
}

$row = mysqli_fetch_assoc($result);
?>

<div class="container">
    <h1 class="mt-5">Course Detail</h1>

    <h3 class="mt-4"><?php echo htmlspecialchars($row['c_code']) . ' - ' . htmlspecialchars($row['c_name']); ?></h3>
    <h5 class="mt-3">Course Description:</h5>
    <p><?php echo nl2br(htmlspecialchars($row['c_desc'] ?? 'No description available.')); ?></p>

    <a href="lecturerViewCourses.php" class="btn btn-secondary">Back</a>
</div>

</body>
</html>
