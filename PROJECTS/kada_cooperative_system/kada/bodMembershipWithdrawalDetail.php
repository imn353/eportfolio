<?php
include('bodNav.php');

if (isset($_GET['withdrawal_id'])) {
    $withdrawal_id = $_GET['withdrawal_id'];
} else {
    $withdrawal_id = 0;
}

if ($withdrawal_id > 0) {
    $query = "SELECT mw_member_id, mem_ic, mem_pf, mem_name, mw_application_date, mem_address, mem_postcode, state_name, mem_gender, mem_religion, mem_race, mem_email, mem_tel, mw_reason
          FROM tb_member_withdrawal
          LEFT JOIN tb_member ON tb_member_withdrawal.mw_member_id = tb_member.mem_id
          LEFT JOIN tb_state ON tb_member.mem_state = tb_state.state_id
          WHERE mw_id = $withdrawal_id AND mw_status = 1";

    $result = mysqli_query($con, $query);
    $row = mysqli_fetch_array($result);
?>

    <div class="content">
        <div class="container-fluid">
            <div class="row mb-4">
                <div class="col-12">
                    <h2 class="text-primary"><i class="fas fa-user-circle mr-3"></i>Maklumat Pemohon #<?php echo $withdrawal_id; ?></h2>
                </div>
            </div>

            <div class="card shadow mb-4">
                <div class="card-header">
                    <h3 class="card-title">Maklumat Peribadi</h3>
                </div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-md-6">
                            <p><strong>No Anggota:</strong> <?php echo $row['mw_member_id']; ?></p>
                            <p><strong>No KP:</strong> <?php echo $row['mem_ic']; ?></p>
                            <p><strong>No PF:</strong> <?php echo $row['mem_pf']; ?></p>
                            <p><strong>Nama:</strong> <?php echo $row['mem_name']; ?></p>
                        </div>
                        <div class="col-md-6">
                            <p><strong>Jantina:</strong> <?php echo $row['mem_gender']; ?></p>
                            <p><strong>Agama:</strong> <?php echo $row['mem_religion']; ?></p>
                            <p><strong>Bangsa:</strong> <?php echo $row['mem_race']; ?></p>
                            <p><strong>Emel:</strong> <?php echo $row['mem_email']; ?></p>
                            <p><strong>No Telefon Bimbit:</strong> <?php echo $row['mem_tel']; ?></p>
                            <p><strong>Tarikh Permohonan:</strong> <?php echo date('d M Y', strtotime($row['mw_application_date'])); ?></p>
                        </div>
                    </div>
                </div>
            </div>

            <div class="card shadow mb-4">
                <div class="card-header">
                    <h3 class="card-title">Maklumat Alamat</h3>
                </div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-md-6">
                            <h5>Alamat Rumah</h5>
                            <p><?php echo $row['mem_address']; ?></p>
                            <p><?php echo $row['mem_postcode']; ?></p>
                            <p><?php echo $row['state_name']; ?></p>
                        </div>
                    </div>
                </div>
            </div>

            <div class="card shadow mb-4">
                <div class="card-header">
                    <h3 class="card-title">Sebab</h3>
                </div>
                <div class="card-body">
                    <p><?php echo $row['mw_reason']; ?></p>
                </div>
            </div>

            <div class="card shadow mb-4">
                <div class="card-header">
                    <h3 class="card-title">Keputusan</h3>
                </div>
                <div class="card-body">
                    <form action='bodMembershipWithdrawalApproval.php' method='POST'>
                        <input type='hidden' name='withdrawal_id' value='<?php echo $withdrawal_id; ?>'>
                        <input type='hidden' name='no_staff' value='<?php echo $row['mw_member_id']; ?>'>
                        <button type='submit' name='action' value='reject' class='btn btn-danger btn-lg mr-3'>Tidak Diluluskan</button>
                        <button type='submit' name='action' value='approve' class='btn btn-success btn-lg'>Luluskan</button>
                    </form>
                </div>
            </div>

            <a href='bodMembershipWithdrawalList.php' class='btn btn btn-secondary mb-4'><i class="fas fa-arrow-left mr-2"></i>Kembali ke Senarai Berhenti</a>
        </div>
    </div>

<?php
} else {
    echo "<div class='content'><p class='text-center'>Invalid application ID.</p></div>";
}

?>

</body>

</html>