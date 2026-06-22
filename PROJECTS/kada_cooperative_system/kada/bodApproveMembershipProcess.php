<?php
include 'bodSession.php';
include 'db_connect.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'vendor/autoload.php'; 

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
        $nostaff = $_POST['no_staff'];
        $action = $_POST['action'];
        $uid = $_SESSION['id'];
        $membership_id = $_POST['membership_id'];

        if ($nostaff > 0 && ($action == 'approve' || $action == 'reject')) {
                $sql2 = "SELECT m_password, m_email, m_name FROM tb_membership
            WHERE m_app_id = $membership_id";

                $result2 = mysqli_query($con, $sql2);
                $row2 = mysqli_fetch_array($result2);

                $pass = $row2['m_password'];
                $email = $row2['m_email'];
                $name = $row2['m_name'];

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

                if ($action == 'approve') {
                        $query = "UPDATE tb_membership 
                                  SET m_appstatus = 2, m_bod_id = $uid, m_approval_timestamp = CURRENT_TIMESTAMP()
                                  WHERE m_app_id = $membership_id";
                        $query2 = "UPDATE tb_member 
                                   SET mem_join_date = CURRENT_TIMESTAMP(), mem_quit_date = NULL, mem_membership_status = 6
                                   WHERE mem_id = $nostaff";

                        mysqli_query($con, $query);
                        mysqli_query($con, $query2);

                        $sql = "INSERT INTO tb_user (u_id, u_password, u_role)
                                VALUES ('$nostaff', '$pass', 1)";

                        mysqli_query($con, $sql);

                        // Content
                        $mail->isHTML(true);
                        $mail->Subject = 'Keputusan Permohonan Keahlian';
                        $mail->Body = "
                        <h2>Assalamualaikum wbt / Salam Sejahtera, $name</h2>
                        <p>Tahniah! Permohonan keahlian anda telah berjaya diluluskan.</p>";

                        $mail->send();

                        echo '<script>
                alert("Pemohon ' . $nostaff . ' Telah Diluluskan");
                window.location.replace("bodApproveMembershipList.php");
                        </script>';
                } else {
                        $checkquery = "SELECT mem_id FROM tb_member WHERE mem_id = $nostaff AND mem_membership_status = 10";
                        $result = mysqli_query($con, $checkquery);
                        $row = mysqli_fetch_array($result);

                        $query = "UPDATE tb_membership 
                      SET m_appstatus = 3, m_bod_id = $uid, m_approval_timestamp = CURRENT_TIMESTAMP()
                      WHERE m_app_id = $membership_id";
                        mysqli_query($con, $query);

                        if (!isset($row['mem_id'])) {
                                $sql = "DELETE FROM tb_member WHERE mem_id = $nostaff";
                                mysqli_query($con, $sql);
                        }

                        $mail->isHTML(true);
                        $mail->Subject = 'Keputusan Permohonan Keahlian';
                        $mail->Body = "
                        <h2>Assalamualaikum wbt / Salam Sejahtera, $name</h2>
                        <p>Maaf! Permohonan keahlian anda gagal diluluskan.</p>";

                        $mail->send();

                        echo '<script>
                alert("Pemohon ' . $nostaff . ' Telah Ditolak");
                window.location.replace("bodApproveMembershipList.php");
            </script>';
                }
        }
} else {
        echo "<script>
            alert('Permintaan tidak sah.');
            window.history.back();
        </script>";
}
?>
