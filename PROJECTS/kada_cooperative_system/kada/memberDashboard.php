<?php include 'memberNav.php';

$fuid = $_SESSION['id'];

$sql = "SELECT * FROM tb_member WHERE mem_id = '$fuid'";
$result = mysqli_query($con, $sql);
$row = mysqli_fetch_array($result);

$sql_loan = "SELECT tb_loan.loan_name, SUM(tb_loan_application.la_balance) AS la_balance
    FROM tb_loan
    LEFT JOIN tb_loan_application ON tb_loan.loan_id = tb_loan_application.la_type AND tb_loan_application.la_member_id = $fuid
    GROUP BY tb_loan.loan_id, tb_loan.loan_name
    ORDER BY tb_loan.loan_id;";
    
$result_loan = mysqli_query($con, $sql_loan);

?>
<div class="content">
    <div class="container-fluid">
        <div class="d-flex justify-content-between align-items-center">
            <h2 class="section-title mt-4 mb-4">Maklumat Saham</h2>
            <a href="memberPrintStatement.php" class="btn btn-primary">Cetak Penyata</a>
        </div>
        <div class="row g-4">
            <div class="col-md-4 col-lg-3">
                <div class="stats-card p-4">
                    <h5><i class="fas fa-coins me-2"></i>Modal Syer</h5>
                    <h2>RM <?php echo number_format($row['mem_modal_share'], 2); ?></h2>
                </div>
            </div>
            <div class="col-md-4 col-lg-3">
                <div class="stats-card p-4">
                    <h5><i class="fas fa-money-bill-wave me-2"></i>Modal Yuran</h5>
                    <h2>RM <?php echo number_format($row['mem_modal_fee'], 2); ?></h2>
                </div>
            </div>
            <div class="col-md-4 col-lg-3">
                <div class="stats-card p-4">
                    <h5><i class="fas fa-piggy-bank me-2"></i>Simpanan Tetap</h5>
                    <h2>RM <?php echo number_format($row['mem_fixed_saving'], 2); ?></h2>
                </div>
            </div>
            <div class="col-md-4 col-lg-3">
                <div class="stats-card p-4">
                    <h5><i class="fas fa-hand-holding-heart me-2"></i>Tabung Anggota</h5>
                    <h2>RM <?php echo number_format($row['mem_charity_fund'], 2); ?></h2>
                </div>
            </div>
            <div class="col-md-4 col-lg-3">
                <div class="stats-card p-4">
                    <h5><i class="fas fa-wallet me-2"></i>Simpanan Anggota</h5>
                    <h2>RM <?php echo number_format($row['mem_saving'], 2); ?></h2>
                </div>
            </div>
        </div>

        <h2 class="section-title mt-5 mb-4">Maklumat Pembiayaan</h2>
        <div class="row g-4">
            <?php while ($row_loan = mysqli_fetch_assoc($result_loan)): ?>
                <div class="col-md-4 col-lg-3">
                    <div class="stats-card p-4">
                        <h5><i class="fas fa-file-invoice-dollar me-2"></i><?php echo htmlspecialchars($row_loan['loan_name']); ?></h5>
                        <h2>RM <?php echo number_format($row_loan['la_balance'], 2); ?></h2>
                    </div>
                </div>
            <?php endwhile; ?>
        </div>
    </div>
</div>

</body>
</html>