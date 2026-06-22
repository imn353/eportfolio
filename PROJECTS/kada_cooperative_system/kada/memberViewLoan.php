<?php
include 'memberNav.php';

$fuid = $_SESSION['id'];
$loan_id = $_GET['loan_id'];

$loan_payment = "SELECT l_id, l_payment, l_paid_month FROM tb_loan_payment WHERE l_member_id = '$fuid' AND l_app_id = '$loan_id';";
$result = mysqli_query($con, $loan_payment);
?>

<div class="content">
    <div class="container-fluid">
        <h2 class="section-title mt-4 mb-4">Sejarah Pembiayaan</h2>
        <br>
        <div>
            <table class="table">
                <thead>
                    <tr class="table-active">
                        <th scope="col">ID Bayaran</th>
                        <th scope="col">Jumlah Bayaran</th>
                        <th scope="col">Bulan Bayaran</th>
                        <th scope="col"></th>
                    </tr>
                </thead>
                <tbody>
                    <?php
                    while ($row = mysqli_fetch_array($result)) {
                        echo '<tr class ="primary">';
                        echo '<td>' . $row['l_id'] . '</td>';
                        echo '<td>' . $row['l_payment'] . '</td>';
                        echo '<td>' . $row['l_paid_month'] . '</td>';
                        echo '<td>';
                        echo '<a href="memberPrintLoanStatement.php?loan_id=' . $loan_id . '&payment=' . $row['l_id'] . '" class="btn btn-primary">Cetak Penyata</a>';
                        echo '</td>';
                        echo '</tr>';
                    }
                    mysqli_close($con);
                    ?>
                </tbody>
            </table>
        </div>
    </div>
</div>