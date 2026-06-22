<?php
include 'bodNav.php';

$query = "SELECT la.la_id, la.la_member_id, m.mem_name, l.loan_name, la.la_amount, la.la_amount_after_interest, la.la_monthly_payment, d.d_year, d.d_month, la.la_timestamp
FROM tb_loan_application la
LEFT JOIN tb_member m ON la.la_member_id = m.mem_id
LEFT JOIN tb_duration d ON la.la_duration = d.d_year
LEFT JOIN tb_appstatus a ON la.la_status = a.app_id
LEFT JOIN tb_loan l ON la.la_type = l.loan_id
WHERE a.app_desc = 'Dihantar'";

$result = mysqli_query($con, $query);
?>

<div class="content">
    <div class="container-fluid">
        <div class="row mb-4">
            <div class="col-md-8"><br>
                <h2 class="text-primary">Senarai Permohonan Pinjaman</h2>
            </div>
        </div>
        <div class="card shadow">
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover" id="loanApplicationTable">
                        <thead>
                            <tr>
                                <th>ID Permohonan</th>
                                <th>ID Ahli</th>
                                <th>Nama Ahli</th>
                                <th>Jenis Pinjaman</th>
                                <th>Amaun Pembiayaan (RM)</th>
                                <th>Jumlah Pembiayaan (RM)</th>
                                <th>Bayaran Bulanan (RM)</th>
                                <th>Tempoh (Tahun / Bulan)</th>
                                <th>Tarikh Permohonan</th>
                                <th>Tindakan</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php
                            while ($row = mysqli_fetch_array($result)) {
                                echo "<tr>";
                                echo "<td>" . $row['la_id'] . "</td>";
                                echo "<td>" . $row['la_member_id'] . "</td>";
                                echo "<td>" . $row['mem_name'] . "</td>";
                                echo "<td>" . $row['loan_name'] . "</td>";
                                echo "<td>" . number_format($row['la_amount'], 2) . "</td>";
                                echo "<td>" . number_format($row['la_amount_after_interest'], 2) . "</td>";
                                echo "<td>" . number_format($row['la_monthly_payment'], 2) . "</td>";
                                echo "<td>" . $row['d_year'] . " / " . $row['d_month'] . "</td>";
                                echo "<td>" . date('d M Y', strtotime($row['la_timestamp'])) . "</td>";
                                echo "<td>
                                        <a href='bodApproveLoanDetail.php?application_id=" . $row['la_id'] . "' class='btn btn-info btn-sm'><i class='fas fa-info-circle'></i></a>
                                      </td>";
                                echo "</tr>";
                            }
                            ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    $(document).ready(function() {
        $('#loanApplicationTable').DataTable({
            responsive: true,
            order: [
                [8, 'desc']
            ], // Sort by Application Date column in descending order
            language: {
                search: "<i class='fas fa-search'></i>",
                searchPlaceholder: "Cari permohonan..."
            },
            dom: '<"row"<"col-md-6"l><"col-md-6"f>>rtip'
        });
    });
</script>
</body>

</html>