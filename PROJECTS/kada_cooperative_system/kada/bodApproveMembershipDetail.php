<?php
include 'bodNav.php';

if (isset($_GET['membership_id'])) {
    $membership_id = $_GET['membership_id'];
} else {
    $membership_id = 0;
}

if ($membership_id > 0) {
    $sql = "SELECT *,
            state1.state_name AS state1_name,
            state2.state_name AS state2_name
            FROM tb_membership
            LEFT JOIN tb_state AS state1 ON tb_membership.m_state = state1.state_id
            LEFT JOIN tb_state AS state2 ON tb_membership.m_office_state = state2.state_id
            LEFT JOIN tb_bank ON tb_membership.m_bank = tb_bank.bank_id
            LEFT JOIN tb_appstatus ON tb_membership.m_appstatus = tb_appstatus.app_id
            WHERE m_app_id = $membership_id";

    $result = mysqli_query($con, $sql);
    if (!$result) {
        die("Query gagal: " . mysqli_error($con));
    }
    $row = mysqli_fetch_array($result);
?>

    <div class="content">
        <div class="container-fluid">
            <div class="row mb-4">
                <div class="col-12">
                    <h2 class="text-primary"><i class="fas fa-user-circle mr-3"></i>Butiran Pemohon #<?php echo $membership_id; ?></h2>
                </div>
            </div>

            <div class="card shadow mb-4">
                <div class="card-header">
                    <h3 class="card-title">Maklumat Peribadi</h3>
                </div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-md-6">
                            <p><strong>Nombor Staf:</strong> <?php echo $row['m_nostaff']; ?></p>
                            <p><strong>Nombor IC:</strong> <?php echo $row['m_ic']; ?></p>
                            <p><strong>Nombor Keutamaan:</strong> <?php echo $row['m_pf']; ?></p>
                            <p><strong>Nama:</strong> <?php echo $row['m_name']; ?></p>
                            <p><strong>Status Perkahwinan:</strong> <?php echo $row['m_status']; ?></p>
                        </div>
                        <div class="col-md-6">
                            <p><strong>Jantina:</strong> <?php echo $row['m_gender']; ?></p>
                            <p><strong>Agama:</strong> <?php echo $row['m_religion']; ?></p>
                            <p><strong>Bangsa:</strong> <?php echo $row['m_race']; ?></p>
                            <p><strong>Email:</strong> <?php echo $row['m_email']; ?></p>
                            <p><strong>No. Telefon:</strong> <?php echo $row['m_tel']; ?></p>
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
                            <p><?php echo $row['m_address']; ?></p>
                            <p><?php echo $row['m_postcode']; ?></p>
                            <p><?php echo $row['state1_name']; ?></p>
                        </div>
                        <div class="col-md-6">
                            <h5>Alamat Pejabat</h5>
                            <p><?php echo $row['m_office_address']; ?></p>
                            <p><?php echo $row['m_office_postcode']; ?></p>
                            <p><?php echo $row['state2_name']; ?></p>
                            <p><strong>Faks:</strong> <?php echo $row['m_fax']; ?></p>
                        </div>
                    </div>
                </div>
            </div>

            <div class="card shadow mb-4">
                <div class="card-header">
                    <h3 class="card-title">Maklumat Pekerjaan</h3>
                </div>
                <div class="card-body">
                    <p><strong>Jawatan:</strong> <?php echo $row['m_position']; ?></p>
                    <p><strong>Gred Jawatan:</strong> <?php echo $row['m_position_grade']; ?></p>
                    <p><strong>Gaji Bulanan:</strong> RM <?php echo number_format($row['m_salary'], 2); ?></p>
                    <p><strong>Bank:</strong> <?php echo $row['bank_name']; ?></p>
                    <p><strong>Nombor Akaun Bank:</strong> <?php echo $row['m_bank_no']; ?></p>
                    <p><strong>Tarikh Permohonan:</strong> <?php echo date('d M Y', strtotime($row['m_appdate'])); ?></p>
                </div>
            </div>

            <?php
            $nostaff = $row['m_nostaff'];
            $sql = "SELECT * FROM tb_family WHERE f_member_id = $nostaff";
            $result = mysqli_query($con, $sql);
            $i = 1;

            if (mysqli_num_rows($result) > 0) {
                while ($row = mysqli_fetch_array($result)) {
            ?>
                    <div class="card shadow mb-4">
                        <div class="card-header">
                            <h3 class="card-title">Ahli Keluarga <?php echo $i; ?></h3>
                        </div>
                        <div class="card-body">
                            <p><strong>Nama:</strong> <?php echo $row['f_name']; ?></p>
                            <p><strong>Nombor IC:</strong> <?php echo $row['f_ic']; ?></p>
                            <p><strong>Hubungan:</strong> <?php echo $row['f_relationship']; ?></p>
                        </div>
                    </div>
            <?php
                    $i++;
                }
            } else {
                echo "<p class='alert alert-info'>Tiada ahli keluarga ditemui untuk pemohon ini.</p>";
            }
            ?>

            <div class="card shadow mb-4">
                <div class="card-header">
                    <h3 class="card-title">Keputusan</h3>
                </div>
                <div class="card-body">
                    <form action='bodApproveMembershipProcess.php' method='POST'>
                        <input type='hidden' name='membership_id' value='<?php echo $membership_id; ?>'>
                        <input type='hidden' name='no_staff' value='<?php echo $nostaff; ?>'>
                        <button type='submit' name='action' value='reject' class='btn btn-danger btn-lg mr-3'>Tolak</button>
                        <button type='submit' name='action' value='approve' class='btn btn-success btn-lg'>Lulus</button>
                    </form>
                </div>
            </div>

            <a href='bodApproveMembershipList.php' class='btn btn btn-secondary mb-4'><i class="fas fa-arrow-left mr-2"></i>Kembali ke Senarai Ahli</a>
        </div>
    </div>

<?php
} else {
    echo "<p class='alert alert-danger'>ID keahlian tidak sah.</p>";
}
?>
</body>

</html>