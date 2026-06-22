<?php
include('bodNav.php');

if (isset($_GET['application_id'])) {
    $application_id = $_GET['application_id'];
} else {
    $application_id = 0;
}

if ($application_id > 0) {
    $query = "SELECT la_member_id, mem_name, mem_ic, mem_email, loan_name, la_amount, la_amount_after_interest, d_year, d_month, la_monthly_payment, la_employer_sign FROM tb_loan_application
    LEFT JOIN tb_member ON tb_loan_application.la_member_id = tb_member.mem_id
    LEFT JOIN tb_duration ON tb_loan_application.la_duration = tb_duration.d_year
    LEFT JOIN tb_appstatus ON tb_loan_application.la_status = tb_appstatus.app_id
    LEFT JOIN tb_loan ON tb_loan_application.la_type = tb_loan.loan_id
    WHERE la_id = '$application_id'";

    $result = mysqli_query($con, $query);
    
    if ($row = mysqli_fetch_assoc($result)) {
        echo "<div class='content'>";
        echo "<div class='container'>";
        echo "<h2 class=\"text-primary\"><i class=\"fas fa-user-circle mr-3\"></i>Butiran Permohonan #" . $application_id . "</h2>";
        echo "<div class='card shadow-sm mb-4'>";
        echo "<div class='card-body'>";
        echo "<h3 class='card-title'>Butiran Pinjaman</h3>";
        echo "<div class='row'>";
        echo "<div class='col-md-6'>";
        echo "<p><strong>ID Ahli:</strong> " . $row['la_member_id'] . "</p>";
        echo "<p><strong>Nama Ahli:</strong> " . $row['mem_name'] . "</p>";
        echo "<p><strong>Nombor IC:</strong> " . $row['mem_ic'] . "</p>";
        echo "<p><strong>Email:</strong> " . $row['mem_email'] . "</p>";
        echo "</div>";
        echo "<div class='col-md-6'>";
        echo "<p><strong>Jenis Pinjaman:</strong> " . $row['loan_name'] . "</p>";
        echo "<p><strong>Jumlah Pinjaman:</strong> RM" . number_format($row['la_amount'], 2) . "</p>";
        echo "<p><strong>Jumlah Pinjaman Selepas Faedah:</strong> RM" . number_format($row['la_amount_after_interest'], 2) . "</p>";
        echo "<p><strong>Tempoh Pinjaman:</strong> " . $row['d_year'] . " tahun / " . $row['d_month'] . " bulan</p>";
        echo "<p><strong>Bayaran Bulanan:</strong> RM" . number_format($row['la_monthly_payment'], 2) . "</p>";
        echo "</div>";
        echo "</div>";

        // Reusable download link
        if (!empty($row['la_employer_sign'])) {
            echo "<p><strong>Tandatangan Majikan:</strong> 
                <a href='downloadSignature.php?id=" . $application_id . "&type=employer' target='_blank' class='btn btn-sm btn-outline-primary'><i class='fas fa-download'></i> Muat Turun Tandatangan</a>
                </p>";
        } else {
            echo "<p><strong>Tandatangan Majikan:</strong> Tidak Tersedia</p>";
        }
        echo "</div></div>";

        $guarantor_query = "SELECT * FROM tb_guarantor WHERE g_application_id = ?";
        $guarantor_stmt = mysqli_prepare($con, $guarantor_query);
        mysqli_stmt_bind_param($guarantor_stmt, 'i', $application_id);
        mysqli_stmt_execute($guarantor_stmt);
        $guarantor_result = mysqli_stmt_get_result($guarantor_stmt);

        echo "<div class='card shadow-sm mb-4'>";
        echo "<div class='card-body'>";
        echo "<h3 class='card-title'>Butiran Penjamin</h3>";
        if (mysqli_num_rows($guarantor_result) > 0) {
            while ($guarantor = mysqli_fetch_assoc($guarantor_result)) {
                echo "<div class='mb-3'>";
                echo "<p><strong>Nama Penjamin:</strong> " . $guarantor['g_name'] . "</p>";
                echo "<p><strong>Nombor IC:</strong> " . $guarantor['g_ic'] . "</p>";
                echo "<p><strong>Nombor PF:</strong> " . $guarantor['g_pf'] . "</p>";
                echo "<p><strong>Nombor Staf:</strong> " . $guarantor['g_staff_id'] . "</p>";

                if (!empty($guarantor['g_signature'])) {
                    echo "<p><strong>Tandatangan Penjamin:</strong> 
                        <a href='downloadSignature.php?id=" . $guarantor['g_ic'] . "&type=guarantor&application_id=" . $application_id . "' target='_blank' class='btn btn-sm btn-outline-primary'><i class='fas fa-download'></i> Muat Turun Tandatangan</a>
                        </p>";
                } else {
                    echo "<p><strong>Tandatangan Penjamin:</strong> Tidak Tersedia</p>";
                }
                echo "</div>";
                echo "<hr>";
            }
        } else {
            echo "<p>Tiada butiran penjamin tersedia.</p>";
        }
        echo "</div></div>";

        echo "<form action='bodApproveLoanProcess.php' method='POST' class='mb-3'>";
        echo "<input type='hidden' name='application_id' value='" . $application_id . "'>";
        echo "<button type='submit' name='action' value='Approve' class='btn btn-success me-2' onclick='return confirm(\"Adakah anda pasti ingin meluluskan permohonan pinjaman ini?\");'><i class='fas fa-check'></i> Luluskan</button>";
        echo "<button type='submit' name='action' value='Reject' class='btn btn-danger' onclick='return confirm(\"Adakah anda pasti ingin menolak permohonan pinjaman ini?\");'><i class='fas fa-times'></i> Tolak</button>";
        echo "</form>";
        echo "<button onclick='history.back()' class='btn btn-secondary'><i class='fas fa-arrow-left'></i> Kembali</button>";
        echo "</div></div>";
    } else {
        echo "<div class='content'><p class='text-center'>ID permohonan tidak sah.</p></div>";
    }
} else {
    echo "<div class='content'><p class='text-center'>Tiada ID permohonan disediakan.</p></div>";
}

?>

</body>
</html>
