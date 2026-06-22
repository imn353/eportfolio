<?php  
session_start();

// Connect to DB
include ('db_connect.php');

// Retrieve data from form
$fuid = $_POST['id'];
$fpwd = $_POST['pwd'];

// SQL Retrieve operation to get user data from DB (without comparing password)
$sql = "SELECT * FROM tb_user WHERE u_id = ?";

$stmt = mysqli_prepare($con, $sql);
mysqli_stmt_bind_param($stmt, "s", $fuid);

// Execute the prepared statement
mysqli_stmt_execute($stmt);

// Get the result
$result = mysqli_stmt_get_result($stmt);

// Retrieve data
$row = mysqli_fetch_array($result);

// Check if the user exists
if ($row && $row['u_id'] == $fuid) {
    // Verify the entered password against the hashed password from the database
    if (password_verify($fpwd, $row['u_password'])) {
        // Rule-based AI login
        if ($row['u_role'] == 1) { // Check user type
            // Set member session
            $_SESSION['u_member_id'] = session_id();
            $_SESSION['id'] = $fuid;
            mysqli_close($con);
            echo '<script>
                alert("Log masuk berjaya!");
                window.location.href = "memberDashboard.php";
                </script>';
        }
        if ($row['u_role'] == 2) { // Check user type
            // Set Board of Directors session
            $_SESSION['u_bod_id'] = session_id();
            $_SESSION['id'] = $fuid;
            mysqli_close($con);
            echo '<script>
                alert("Log masuk berjaya!");
                window.location.href = "bodDashboard.php";
                </script>';
        }
        if ($row['u_role'] == 3) { // Check user type
            // Set Clerk session
            $_SESSION['u_clerk_id'] = session_id();
            $_SESSION['id'] = $fuid;
            mysqli_close($con);
            echo '<script>
                alert("Log masuk berjaya!");
                window.location.href = "clerkDashboard.php";
                </script>';
        }
    } else {
        // Incorrect password
        echo '<script>
            alert("Kata laluan tidak sah. Sila cuba semula.");
            window.location.href = "index.php";
            </script>';
    }
} else {
    // User not found
    echo '<script>
        alert("Pengguna tidak dijumpai. Sila pastikan No ID yang dimasukkan sah.");
        window.location.href = "index.php";
        </script>';
}

// Close the database connection
mysqli_stmt_close($stmt);
mysqli_close($con);
?>
