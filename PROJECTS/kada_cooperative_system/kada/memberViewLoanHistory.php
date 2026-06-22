<?php
include 'memberNav.php';

$fuid = $_SESSION['id'];

$sql = "SELECT tb_loan_application.la_id, tb_loan_application.la_amount, tb_loan.loan_name, tb_appstatus.app_desc FROM tb_loan_application
    LEFT JOIN tb_loan ON tb_loan.loan_id = tb_loan_application.la_type
    LEFT JOIN tb_appstatus ON tb_appstatus.app_id = tb_loan_application.la_status
    WHERE tb_loan_application.la_member_id = '$fuid';";

$result = mysqli_query($con, $sql);

?>

<div class="content">
    <div class="container-fluid">
        <h2 class="section-title mt-4 mb-4">Sejarah Pembiayaan</h2>
        <div>
            <table class="table">
                <thead>
                    <tr class="table-active">
                        <th scope="col">ID Pembiayaan</th>
                        <th scope="col">Nama Pembiayaan</th>
                        <th scope="col">Jumlah Diminta</th>
                        <th scope="col">Status</th>
                        <th scope="col"></th>
                    </tr>
                </thead>
                <tbody>
                    <?php
                    while ($loanApplicationRow = mysqli_fetch_array($result)) {
                        echo '<tr class ="primary">';
                        echo '<td>' . $loanApplicationRow['la_id'] . '</td>';
                        echo '<td>' . $loanApplicationRow['loan_name'] . '</td>';
                        echo '<td>' . $loanApplicationRow['la_amount'] . '</td>';
                        echo '<td>' . $loanApplicationRow['app_desc'] . '</td>';
                        echo '<td>';
                        echo '<a href="memberViewLoan.php?&loan_id=' . $loanApplicationRow['la_id'] . '" class="btn btn-primary">Semak</a>';

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