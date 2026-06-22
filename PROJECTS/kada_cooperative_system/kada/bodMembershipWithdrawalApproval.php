<?php

include 'db_connect.php';
include 'bodSession.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $nostaff = $_POST['no_staff'];
    $action = $_POST['action'];
    $uid = $_SESSION['id'];
    $withdrawal_id = $_POST['withdrawal_id'];

    if ($nostaff > 0 && ($action == 'approve' || $action == 'reject')) {

        if ($action == 'approve') {
            $query = "UPDATE tb_member 
                SET mem_membership_status = 10, mem_quit_date = CURRENT_TIMESTAMP(), mem_modal_share = 0, mem_modal_fee = 0, mem_fixed_saving = 0, mem_charity_fund = 0, mem_saving = 0
                WHERE mem_id = $nostaff";

            $query2 = "UPDATE tb_member_withdrawal
                SET mw_status = 2, mw_bod_id = $uid, mw_approval_date = CURRENT_TIMESTAMP()
                WHERE mw_id = $withdrawal_id";

            $query3 = "UPDATE tb_membership
                SET m_quit_date = CURRENT_TIMESTAMP()
                WHERE m_nostaff = $nostaff AND m_quit_date IS NULL AND m_appstatus = 2";

            mysqli_query($con, $query);
            mysqli_query($con, $query2);
            mysqli_query($con, $query3);

            $sql = "DELETE FROM tb_user WHERE u_id = $nostaff";
            mysqli_query($con, $sql);

            echo "<script>
            alert('Ahli $nostaff Berjaya Diberhentikan!');
            window.location.replace('bodMembershipWithdrawalList.php');
          </script>";
        } else {
            $query = "UPDATE tb_member_withdrawal
                SET mw_status = 3, mw_bod_id = $uid, mw_approval_date = CURRENT_TIMESTAMP()
                WHERE mw_id = $withdrawal_id";
            mysqli_query($con, $query);

            echo "<script>
            alert('Permohonan Berhenti Ahli $nostaff Tidak Berjaya !');
            window.location.replace('bodMembershipWithdrawalList.php');
          </script>";
        }
    } else {
        echo "<script>
            alert('Invalid request.');
            window.history.back();
        </script>";
    }
} else {
    echo "<script>
        alert('Invalid request.');
        window.history.back();
    </script>";
}
