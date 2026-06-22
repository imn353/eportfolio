<?php
include('memberNav.php');

$memberId = $_SESSION['id'];

$query = "SELECT mw_status FROM tb_member_withdrawal WHERE mw_member_id = '$memberId' ORDER BY mw_application_date DESC LIMIT 1";

$result = mysqli_query($con, $query);
$row = mysqli_fetch_assoc($result);

if (isset($_POST['reason'])) {
    if ($row && ($row['mw_status'] == 1)) {
        echo '<script>
            alert("Permohonan anda tidak dapat diproses. Status mesti ditolak atau belum memohon.");
            window.location.replace("memberDashboard.php");
            </script>';
    } else {
        $reason = $_POST['reason'];

        $sql = "INSERT INTO tb_member_withdrawal (mw_member_id, mw_reason) VALUES ('$memberId', '$reason')";
        $result = mysqli_query($con, $sql);

        if ($result) {
            echo "<script>alert('Permohonan berjaya dihantar!');
        window.location.replace('memberDashboard.php');
        </script>";
        } else {
            echo "<script>alert('Permohonan gagal dihantar!');
        window.location.replace('memberDashboard.php');
        </script>";
        }
    }
}

?>

<div class="content">
    <div class="container-fluid">
        <h2 class="section-title mt-4 mb-4">Permohonan Berhenti Menjadi Anggota</h2>
        <form action="#" method="POST">
            <div class="form-card">
                <h4 class="mb-4">Sebab Berhenti Menjadi Anggota</h4>
                <div class="mb-3">
                    <label for="reason" class="form-label">Sila nyatakan sebab-sebab mahu berhenti</label>
                    <textarea class="form-control" name="reason" id="reason" rows="5" required></textarea>
                </div>
                <div class="col-md-4">
                    <button type="submit" class="btn btn-primary">Hantar Permohonan</button>
                </div>
            </div>
        </form>
    </div>
</div>

</body>

</html>