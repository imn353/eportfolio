<?php include 'clerkNav.php';

if (isset($_GET['id'])) {
    $id = $_GET['id'];
}

$id = mysqli_real_escape_string($con, $id);
$loanApplicationsql = "SELECT * FROM tb_loan_application 
                        LEFT JOIN tb_loan ON tb_loan_application.la_type = tb_loan.loan_id
                        WHERE la_member_id = '$id' AND la_status = 4;";
$loanApplicationResult = mysqli_query($con, $loanApplicationsql);

?>
<br>
<div class="content">
    <div class="container">
        <h2>Senarai Pembiayaan Ahli</h2>
        <br>
        <div>
            <table class="table">
                <thead>
                    <tr class="table-active">
                        <th scope="col">ID Pembiayaan</th>
                        <th scope="col">Nama Pembiayaan</th>
                        <th scope="col">Jumlah Diminta</th>
                        <th scope="col">Jumlah Selepas Faedah</th>
                        <th scope="col">Baki Jumlah</th>
                        <th scope="col">Jumlah Dibayar</th>
                        <th scope="col">Bayaran Bulanan</th>
                        <th scope="col"></th>
                    </tr>
                </thead>
                <tbody>
                    <?php
                    while ($loanApplicationRow = mysqli_fetch_array($loanApplicationResult)) {
                        echo '<tr class ="primary">';
                        echo '<td>' . $loanApplicationRow['la_id'] . '</td>';
                        echo '<td>' . $loanApplicationRow['loan_name'] . '</td>';
                        echo '<td>' . $loanApplicationRow['la_amount'] . '</td>';
                        echo '<td>' . $loanApplicationRow['la_amount_after_interest'] . '</td>';
                        echo '<td>' . $loanApplicationRow['la_balance'] . '</td>';
                        echo '<td>' . $loanApplicationRow['la_paid'] . '</td>';
                        echo '<td>' . $loanApplicationRow['la_monthly_payment'] . '</td>';
                        echo '<td>';
                        echo '<a href="clerkViewLoan.php?member_id=' . $id . '&loan_id=' . $loanApplicationRow['la_id'] . '" class="btn btn-primary">Lihat</a>';
                        echo '</td>';
                        echo '</tr>';
                    }
                    mysqli_close($con);
                    ?>
                </tbody>
            </table>
        </div>
        <div class="mt-4">
            <a href="clerkEditLoan.php" class="btn btn-secondary">Kembali</a>
        </div>
    </div>
</div>