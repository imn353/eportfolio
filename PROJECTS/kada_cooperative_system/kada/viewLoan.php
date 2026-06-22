<?php

include 'clerkNav.php';

$query = "SELECT la_id, loan_name, la_amount, la_duration, la_monthly_payment, la_balance, la_paid, la_amount_after_interest, la_timestamp, app_desc, la_bod_id, la_member_id FROM tb_loan_application
          LEFT JOIN tb_appstatus ON tb_loan_application.la_status = tb_appstatus.app_id
          LEFT JOIN tb_loan ON tb_loan_application.la_type = tb_loan.loan_id";

$result = $con->query($query);

$loans = $result->fetch_all(MYSQLI_ASSOC);

$columnNames = [
    'la_id' => 'ID',
    'loan_name' => 'Jenis Pinjaman',
    'la_amount' => 'Jumlah',
    'la_duration' => 'Tempoh (Tahun)',
    'la_monthly_payment' => 'Bayaran Bulanan (RM)',
    'la_balance' => 'Baki (RM)',
    'la_paid' => 'Dibayar (RM)',
    'la_amount_after_interest' => 'Jumlah Keseluruhan (RM)',
    'la_timestamp' => 'Tarikh Permohonan',
    'app_desc' => 'Status',
    'la_bod_id' => 'ID BOD Pengesah',
    'la_member_id' => 'ID Ahli'
];

?>
<div class="content">
    <div class="container-fluid mt-4">
        <h2>Senarai Pemohon Pinjaman</h2>
        <div class="table-container">
            <table class="table table-striped table-bordered">
                <thead>
                    <tr>
                        <?php
                        if (!empty($loans)) {
                            foreach (array_keys($loans[0]) as $column) {
                                echo "<th>" . htmlspecialchars($columnNames[$column]) . "</th>";
                            }
                        } else {
                            echo "<th>Tiada data tersedia</th>";
                        }
                        ?>
                    </tr>
                </thead>
                <tbody>
                    <?php
                    if (!empty($loans)) {
                        foreach ($loans as $loan) {
                            echo "<tr>";
                            foreach ($loan as $value) {
                                echo "<td>" . htmlspecialchars($value) . "</td>";
                            }
                            echo "</tr>";
                        }
                    } else {
                        echo "<tr><td colspan='100%'>Tiada permohonan pinjaman ditemui.</td></tr>";
                    }
                    ?>
                </tbody>
            </table>
        </div>
    </div>

    </body>

    </html>
