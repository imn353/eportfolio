<?php
include('db_connect.php');

if (isset($_GET['id']) && isset($_GET['type'])) {
    
    $id = $_GET['id'];
    $type = $_GET['type'];

    if ($type == 'employer') {
        $query = "SELECT la_employer_sign AS signature FROM tb_loan_application WHERE la_id = ?";
        $stmt = mysqli_prepare($con, $query);
        mysqli_stmt_bind_param($stmt, 'i', $id); 
    } elseif ($type == 'guarantor') {
        if (isset($_GET['application_id'])) {
            $application_id = $_GET['application_id'];
            
            $query = "SELECT g_signature AS signature FROM tb_guarantor WHERE g_ic = ? AND g_application_id = ?";
            $stmt = mysqli_prepare($con, $query);
            mysqli_stmt_bind_param($stmt, 'si', $id, $application_id); 
        } else {
            die("Missing application_id for guarantor.");
        }
    } else {
        die("Invalid signature type.");
    }

    mysqli_stmt_execute($stmt);
    $result = mysqli_stmt_get_result($stmt);

    if ($row = mysqli_fetch_assoc($result)) {
        $pdf_data = $row['signature'];

        // Output the PDF data
        header('Content-Type: application/pdf');
        header('Content-Disposition: inline; filename="signature_' . $id . '.pdf"');
        echo $pdf_data;
    } else {
        echo "No signature found for the requested ID and application.";
    }
} else {
    echo "Invalid request.";
}
?>
