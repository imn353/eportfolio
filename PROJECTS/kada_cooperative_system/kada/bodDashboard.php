<?php
include 'bodNav.php';

$pendingLoanCount = $con->query("SELECT COUNT(*) FROM tb_loan_application WHERE la_status = 1")->fetch_row()[0];
$pendingMembershipCount = $con->query("SELECT COUNT(*) FROM tb_membership WHERE m_appstatus = 1")->fetch_row()[0];
$totalMemberCount = $con->query("SELECT COUNT(*) FROM tb_member")->fetch_row()[0];
?>


<div class="content">
	<div class="container-fluid">
		<div class="row g-4">
			<div class="col-md-4">
				<div class="stats-card">
					<h5>Permohonan Pembiayaan Tertunda</h5>
					<h2><?php echo $pendingLoanCount; ?></h2>
				</div>
			</div>
			<div class="col-md-4">
				<div class="stats-card">
					<h5>Permohonan Keahlian Tertunda</h5>
					<h2><?php echo $pendingMembershipCount; ?></h2>
				</div>
			</div>
			<div class="col-md-4">
				<div class="stats-card">
					<h5>Jumlah Ahli</h5>
					<h2><?php echo $totalMemberCount; ?></h2>
				</div>
			</div>
		</div>
		<div class="row g-4 mt-4">
			<div class="col">
				<div class="card mb-4">
					<div class="card-body">
						<h4>Tindakan Pantas</h4>
						<div class="row g-3">
							<div class="col-md-4">
								<a href="bodApproveLoanList.php" class="btn btn-primary w-100">
									<i class="fas fa-hand-holding-usd me-2"></i>Luluskan Pembiayaan
								</a>
							</div>
							<div class="col-md-4">
								<a href="bodApproveMembershipList.php" class="btn btn-success w-100">
									<i class="fas fa-users me-2"></i>Luluskan Keahlian
								</a>
							</div>
							<div class="col-md-4">
								<a href="bodMembershipWithdrawalList.php" class="btn btn-warning w-100">
									<i class="fas fa-user-minus me-2"></i>Luluskan Berhenti Keahlian
								</a>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

	</div>
</div>

</body>

</html>