<?php
include 'clerkNav.php';

$memberCount = $con->query("SELECT COUNT(*) FROM tb_member")->fetch_row()[0];
$loanCount = $con->query("SELECT COUNT(*) FROM tb_loan_application")->fetch_row()[0];
$membershipCount = $con->query("SELECT COUNT(*) FROM tb_membership")->fetch_row()[0];

// Get the current year and available years for selection
$currentYear = date('Y');
$yearQuery = "SELECT DISTINCT YEAR(mem_join_date) AS year FROM tb_member ORDER BY year DESC";
$yearResult = $con->query($yearQuery);
$availableYears = [];
while ($row = $yearResult->fetch_assoc()) {
	$availableYears[] = $row['year'];
}

// Get the selected year (default to current year if not set)
$selectedYear = isset($_GET['year']) ? intval($_GET['year']) : $currentYear;

// Fetch membership growth data for the selected year
$membershipGrowthQuery = "SELECT DATE_FORMAT(mem_join_date, '%Y-%m') AS month, COUNT(*) AS count 
                          FROM tb_member 
                          WHERE YEAR(mem_join_date) = ?
                          GROUP BY month 
                          ORDER BY month";
						  
$stmt = $con->prepare($membershipGrowthQuery);
$stmt->bind_param("i", $selectedYear);
$stmt->execute();
$membershipGrowthResult = $stmt->get_result();
$labels = [];
$data = [];
while ($row = $membershipGrowthResult->fetch_assoc()) {
	$labels[] = date('M', strtotime($row['month']));
	$data[] = $row['count'];
}
$stmt->close();

?>

<div class="content">
	<div class="container-fluid">
		<div class="row g-4">
			<div class="col-md-4">
				<div class="stats-card">
					<h5>Jumlah Ahli</h5>
					<h2><?php echo $memberCount; ?></h2>
				</div>
			</div>
			<div class="col-md-4">
				<div class="stats-card">
					<h5>Jumlah Permohonan Keahliaan</h5>
					<h2><?php echo $membershipCount; ?></h2>
				</div>
			</div>
			<div class="col-md-4">
				<div class="stats-card">
					<h5>Jumlah Permohonan Pembiayaan</h5>
					<h2><?php echo $loanCount; ?></h2>
				</div>
			</div>
		</div>

		<div class="row g-4 mt-4">
			<div class="col-lg-8">
				<div class="card mb-4">
					<div class="card-body">
						<h4>Tindakan Pantas</h4>
						<div class="row g-3">
							<div class="col-md-4">
								<a href="updatePolicy.php" class="btn btn-primary w-100">
									<i class="fas fa-file-alt me-2"></i>Kemaskini Polisi
								</a>
							</div>
							<div class="col-md-4">
								<a href="viewLoan.php" class="btn btn-info w-100">
									<i class="fas fa-hand-holding-usd me-2"></i>Senarai Permohonan Pembiayaan
								</a>
							</div>
							<div class="col-md-4">
								<a href="viewMembership.php" class="btn btn-success w-100">
									<i class="fas fa-users me-2"></i>Senarai Permohonan Keahliaan
								</a>
							</div>
						</div>
					</div>
				</div>

			</div>
			<div class="col-lg-4">
				<div class="card">
					<div class="card-body">
						<h4>Pertumbuhan Keahlian</h4>
						<form id="yearForm" class="mb-3">
							<select name="year" id="yearSelect" class="form-select" onchange="this.form.submit()">
								<?php foreach ($availableYears as $year): ?>
									<option value="<?php echo $year; ?>" <?php echo $year == $selectedYear ? 'selected' : ''; ?>>
										<?php echo $year; ?>
									</option>
								<?php endforeach; ?>
							</select>
						</form>
						<div class="chart-container">
							<canvas id="membershipChart"></canvas>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>

<script>
	var ctx = document.getElementById('membershipChart').getContext('2d');
	var chart = new Chart(ctx, {
		type: 'line',
		data: {
			labels: <?php echo json_encode($labels); ?>,
			datasets: [{
				label: 'Membership (<?php echo $selectedYear; ?>)',
				data: <?php echo json_encode($data); ?>,
				backgroundColor: 'rgba(23, 162, 184, 0.2)',
				borderColor: 'rgba(23, 162, 184, 1)',
				borderWidth: 2,
				tension: 0.4,
				fill: true
			}]
		},
		options: {
			responsive: true,
			maintainAspectRatio: false,
			plugins: {
				legend: {
					display: true,
					position: 'top'
				}
			},
			scales: {
				y: {
					beginAtZero: true,
					ticks: {
						precision: 0
					}
				}
			}
		}
	});
</script>

</body>

</html>