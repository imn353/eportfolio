<?php include 'clerkNav.php';

if (isset($_GET['member_id']) and isset($_GET['loan_id'])) {
    $memberId = $_GET['member_id'];
    $loanApplicationId = $_GET['loan_id'];
}

$memberId = mysqli_real_escape_string($con, $memberId);
$loanApplicationsql = "SELECT * FROM tb_loan_application WHERE la_member_id = '$memberId';";
$loanApplicationResult = mysqli_query($con, $loanApplicationsql);
$loanApplicationRow = mysqli_fetch_array($loanApplicationResult);

$sql_payment_history = "SELECT l_id, l_payment, l_paid_month, l_app_id FROM tb_loan_payment WHERE l_member_id = '$memberId' AND l_app_id = '$loanApplicationId';";
$result_payment = mysqli_query($con, $sql_payment_history);

?>

<div class="content">
    <div class="container">
        <br>
        <h2>Kemaskini</h2>
        <br>
        <form action="clerkUpdateLoan.php?memberId=<?php echo $memberId; ?>&loanAppId=<?php echo $loanApplicationId; ?>" method="POST">
            <div>
                <label for="paymentMonth" class="text-dark">Tarikh Bayaran:</label>
                <input type="month" id="paymentMonth" name="paymentMonth" required>
            </div>
            <div class="row">
                <div class="col">
                    <label for="currentCharityFund" class="text-dark mt-4"> Jumlah Dibayar:</label>
                    <?php echo $loanApplicationRow['la_paid']; ?>
                </div>
                <div class="col">
                    <label for="currentCharityFund" class="text-dark col mt-4"> Jumlah Dibayar Selepas Kemaskini:</label>
                    <?php echo $loanApplicationRow['la_paid'] + $loanApplicationRow['la_monthly_payment']; ?>
                </div>
            </div>
            <div class="row">
                <div class="col">
                    <label for="currentFixedSavings" class="text-dark col mt-4"> Baki Pinjaman:</label>
                    <?php echo $loanApplicationRow['la_balance']; ?>
                </div>
                <div class="col">
                    <label for="currentFixedSavings" class="text-dark col mt-4"> Baki Pinjaman Selepas Kemaskini:</label>
                    <?php echo $loanApplicationRow['la_balance'] - $loanApplicationRow['la_monthly_payment']; ?>
                </div>
            </div>
            <div>
                <label for="paymentMethod" class="form-label mt-4">Kaedah Pembayaran</label>
                <select class="form-select" id="paymentMethod" name="paymentMethod">
                    <option>Bayaran Kaunter</option>
                    <option>Potongan Gaji</option>
                </select>
            </div>
            <div>
                <label for="remarks" class="form-label mt-4">Catatan</label>
                <textarea class="form-control" id="remarks" name="remarks" rows="3"></textarea>
            </div>
            <div class="form-group mb-4 mt-4">
                <a href="clerkViewMemberLoan.php?id=<?php echo $memberId; ?>" class="btn btn-secondary">Kembali</a>
                <input type="submit" name="submit" class="btn btn-primary" value="Kemaskini">
            </div>
        </form>
    </div>


    <div class="container">
        <div>
            <table class="table">
                <thead>
                    <br>
                    <br>
                    <tr class="table-active">
                        <th scope="col">ID Pembayaran Pinjaman</th>
                        <th scope="col">Bayaran(RM)</th>
                        <th scope="col">Bulan Dibayar</th>
                        <th scope="col"></th>
                    </tr>
                </thead>
                <tbody>
                    <?php
                    while ($loan_payment = mysqli_fetch_array($result_payment)) {
                        echo '<tr class ="primary">';
                        echo '<td>' . $loan_payment['l_id'] . '</td>';
                        echo '<td>' . $loan_payment['l_payment'] . '</td>';
                        echo '<td>' . $loan_payment['l_paid_month'] . '</td>';
                        echo '</tr>';
                    }
                    mysqli_close($con);
                    ?>
                </tbody>
            </table>
        </div>
    </div>
</div>