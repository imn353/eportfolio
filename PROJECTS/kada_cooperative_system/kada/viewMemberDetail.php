<?php
include 'db_connect.php';
include 'clerkNav.php';

if (isset($_GET['mem_id'])) {
    $mem_id = $_GET['mem_id'];

    $query = "SELECT *,
              state1.state_name AS state1_name,
              state2.state_name AS state2_name
              FROM tb_member 
              LEFT JOIN tb_state AS state1 ON tb_member.mem_state = state1.state_id
              LEFT JOIN tb_state AS state2 ON tb_member.mem_office_state = state2.state_id
              LEFT JOIN tb_bank ON tb_member.mem_bank = tb_bank.bank_id
              WHERE mem_id = ?";

    $stmt = $con->prepare($query);
    $stmt->bind_param("i", $mem_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result->fetch_assoc();
?>
    <style>
        .card-header {
            background-color: #1d3557;
            color: #fff;
        }
    </style>

    <div class="content">
        <div class="container-fluid">
            <div class="row mb-4">
                <div class="col-12">
                    <h2 class="text"><i class="fas fa-user-circle mr-3"></i>  Butiran Pemohon, <?php echo $row['mem_name']; ?> !!</h2>
                </div>
            </div>

            <div class="card shadow mb-4">
                <div class="card-header">
                    <h3 class="card-title">Maklumat Peribadi</h3>
                </div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-md-6">
                            <p><strong>Nombor Staf:</strong> <?php echo $row['mem_id']; ?></p>
                            <p><strong>Nombor IC:</strong> <?php echo $row['mem_ic']; ?></p>
                            <p><strong>Nombor Keutamaan:</strong> <?php echo $row['mem_pf']; ?></p>
                            <p><strong>Nama:</strong> <?php echo $row['mem_name']; ?></p>
                            <p><strong>Tarikh Lahir:</strong> <?php echo $row['mem_birthdate']; ?></p>
                            <p><strong>Status Perkahwinan:</strong> <?php echo $row['mem_status']; ?></p>
                        </div>
                        <div class="col-md-6">
                            <p><strong>Jantina:</strong> <?php echo $row['mem_gender']; ?></p>
                            <p><strong>Agama:</strong> <?php echo $row['mem_religion']; ?></p>
                            <p><strong>Bangsa:</strong> <?php echo $row['mem_race']; ?></p>
                            <p><strong>Emel:</strong> <?php echo $row['mem_email']; ?></p>
                            <p><strong>No. Telefon:</strong> <?php echo $row['mem_tel']; ?></p>
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
                            <p><?php echo $row['state1_name']; ?></p>
                        </div>
                        <div class="col-md-6">
                            <h5>Alamat Pejabat</h5>
                            <p><?php echo $row['mem_office_address']; ?></p>
                            <p><?php echo $row['mem_office_postcode']; ?></p>
                            <p><?php echo $row['state2_name']; ?></p>
                            <p><strong>No. Faks:</strong> <?php echo $row['mem_fax']; ?></p>
                        </div>
                    </div>
                </div>
            </div>

            <div class="card shadow mb-4">
                <div class="card-header">
                    <h3 class="card-title">Maklumat Pekerjaan</h3>
                </div>
                <div class="card-body">
                    <p><strong>Jawatan:</strong> <?php echo $row['mem_position']; ?></p>
                    <p><strong>Gred Jawatan:</strong> <?php echo $row['mem_position_grade']; ?></p>
                    <p><strong>Gaji Bulanan:</strong> RM <?php echo number_format($row['mem_salary'], 2); ?></p>
                    <p><strong>Bank:</strong> <?php echo $row['bank_name']; ?></p>
                    <p><strong>Nombor Akaun Bank:</strong> <?php echo $row['mem_bank_no']; ?></p>
                </div>
            </div>
            <div class="card shadow mb-4">
                <div class="card-header">
                    <h3 class="card-title">Maklumat Pembayaran Bulanan</h3>
                </div>
                <div class="card-body">
                    <p><strong>Yuran Modal Syer:</strong> RM  <?php echo $row['mem_fee_modal_share']; ?></p>
                    <p><strong>Modal Yuran:</strong> RM  <?php echo $row['mem_fee_modal_fee']; ?></p>
                    <p><strong>Simpanan Tetap:</strong> RM <?php echo number_format($row['mem_fee_fixed_saving'], 2); ?></p>
                    <p><strong>Sumbangan Tabung Kebajikan (Al-Abrar):</strong> RM <?php echo $row['mem_fee_charity_fund']; ?></p>
                    <p><strong>Wang Deposit Anggota:</strong> RM  <?php echo $row['mem_fee_saving']; ?></p>
                </div>
            </div>

            <a href='viewMember.php' class='btn btn btn-secondary mb-4'><i class="fas fa-arrow-left mr-2"></i>Kembali ke Senarai Ahli</a>
        </div>
    </div>
    </div>

<?php
} else {
    echo "<p class='alert alert-danger'>ID keahlian tidak sah.</p>";
}
?>
</body>

</html>