<?php
include 'dbconnect.php';
include 'htmlHead.php';
include 'lecturerSession.php';
?>
<nav class="navbar navbar-expand-lg bg-primary" data-bs-theme="dark">
  <div class="container">
    <a class="navbar-brand" href="lecturerViewCourses.php">Course Registration System</a>
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarColor01" aria-controls="navbarColor01" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="navbarColor01">
      <ul class="navbar-nav me-auto">
        <li class="nav-item">
          <a class="nav-link active" href="lecturerViewCourses.php">Assigned Course</a>
        </li>
        <li class="nav-item">
          <a class="nav-link active" href="lecturerViewStudent.php">Student List</a>
        </li>
        <li class="nav-item">
          <a class="nav-link active" href="logoutProcess.php">Logout</a>
        </li>
      </ul>
    </div>
  </div>
</nav>