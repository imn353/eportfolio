<?php
include('bodSession.php');
include('db_connect.php');

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'vendor/autoload.php'; // Include PHPMailer

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $application_id = $_POST['application_id'];
    $action = $_POST['action'];
    $bod_id = $_SESSION['id'];

    if ($application_id > 0 && ($action == 'Approve' || $action == 'Reject')) {

        $sql2 = "SELECT mem_name, mem_email, loan_name, la_amount FROM tb_loan_application
            LEFT JOIN tb_member ON tb_loan_application.la_member_id = tb_member.mem_id
            LEFT JOIN tb_loan ON tb_loan_application.la_type = tb_loan.loan_id
            WHERE la_id = $application_id";

        $result2 = mysqli_query($con, $sql2);
        $row2 = mysqli_fetch_array($result2);

        $name = $row2['mem_name'];
        $email = $row2['mem_email'];
        $loan_name = $row2['loan_name'];
        $amount = $row2['la_amount'];

        $mail = new PHPMailer(true);
        // Email settings
        $mail->isSMTP();
        $mail->Host = 'smtp.gmail.com'; 
        $mail->SMTPAuth = true;
        $mail->Username = 'kadaofficial01@gmail.com';
        $mail->Password = 'jbap bdbx vjjm nmyl';
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port = 587;

        // Recipients
        $mail->setFrom($email, 'Koperasi KADA');
        $mail->addAddress($email, $name);

        $query_balance = "SELECT la_amount_after_interest FROM tb_loan_application WHERE la_id = $application_id;";
        $result = mysqli_query($con, $query_balance);
        $row = mysqli_fetch_assoc($result);

        if ($action == 'Approve') {
            $new_status = 4;
            $new_balance = $row['la_amount_after_interest'];

            $mail->isHTML(true);
            $mail->Subject = 'Keputusan Permohonan Pembiayaan';
            $mail->Body = "
            <h2>Assalamualaikum wbt / Salam Sejahtera, $name</h2>
            <p>Dengan sukacitanya kami ingin memaklumkan bahawa permohonan pembiayaan anda ($loan_name) telah berjaya diluluskan.</p>
            <p>Jumlah pembiayaan yang diluluskan adalah sebanyak RM $amount.</p>";

            $mail->send();
            
        } else {
            $new_status = 3;
            $new_balance = 0;

            $mail->isHTML(true);
            $mail->Subject = 'Keputusan Permohonan Pembiayaan';
            $mail->Body = "
            <h2>Assalamualaikum wbt / Salam Sejahtera, $name</h2>
            <p>Dengan dukacitanya kami ingin memaklumkan bahawa permohonan pembiayaan anda ($loan_name) telah ditolak.</p>
            <p>Anda boleh menghubungi pihak kami untuk maklumat lanjut.</p>";

            $mail->send();
        }

        $query = "UPDATE tb_loan_application SET la_status = ?, la_bod_id = ?, la_balance = ?, la_approval_timestamp = CURRENT_TIMESTAMP WHERE la_id = ?";
        $stmt = mysqli_prepare($con, $query);
        mysqli_stmt_bind_param($stmt, 'iidi', $new_status, $bod_id, $new_balance, $application_id);

        if (mysqli_stmt_execute($stmt)) {
            if ($action == 'Approve') {
                $message = "Permohonan pinjaman #$application_id telah berjaya diluluskan.";
            } else {
                $message = "Permohonan pinjaman #$application_id telah berjaya ditolak.";
            }
        } else {
            $message = "Gagal memproses permohonan pinjaman. Sila cuba lagi.";
        }
        mysqli_stmt_close($stmt);
    } else {
        $message = "Permintaan tidak sah. Sila cuba lagi.";
    }
} else {
    $message = "Akses tidak dibenarkan.";
}

echo "<script>
    alert('$message');
    window.location.href = 'bodApproveLoanList.php'; // Gantikan dengan halaman yang sesuai
</script>";
exit();
