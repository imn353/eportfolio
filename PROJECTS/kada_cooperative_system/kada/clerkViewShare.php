<?php

include 'clerkNav.php';

if (isset($_GET['id'])) {
    $id = $_GET['id'];
}

$id = mysqli_real_escape_string($con, $id);
$membersql = "SELECT * FROM tb_member WHERE mem_id = '$id';";
$memberResult = mysqli_query($con, $membersql);
$memberRow = mysqli_fetch_array($memberResult);

$sql_fee_history = "SELECT * FROM tb_fee_payment WHERE fee_member_id = '$id'
                        ORDER BY fee_month DESC;";

$fee_history_result = mysqli_query($con, $sql_fee_history);

$sql_member_fee = "SELECT mem_fee_modal_share, mem_fee_modal_fee, mem_fee_fixed_saving, mem_fee_charity_fund, mem_fee_saving FROM tb_member WHERE mem_id = '$id';";

?>

<div class="content">
    <div class="container">
        <br>
        <h2>Senarai Ahli</h2>
        <br>
        <form action="clerkUpdateShare.php?id=<?php echo $id; ?>" method="POST">
            <div>
                <label for="paymentMonth" class="text-dark">Tarikh Pembayaran:</label>
                <input type="month" id="paymentMonth" name="paymentMonth" required>
            </div>
            <div>
                <label for="staffNo" class="text-dark mt-4">Nombor Staf:</label>
                <?php echo $memberRow['mem_id']; ?>
            </div>
            <div>
                <label for="paymentMethod" class="form-label mt-4">Kaedah Pembayaran</label>
                <select class="form-select" id="paymentMethod" name="paymentMethod">
                    <option>Pembayaran Kaunter</option>
                    <option>Potongan Gaji</option>
                </select>
            </div>
            <div>
                <label for="entryFee" class="text-dark mt-4"> Yuran Masuk:</label>
                <input type="text" name="entryFee" id="entryFee" class="form-control"
                    placeholder="Masukkan jumlah pembayaran yuran masuk di sini" value = "0" required>
            </div>
            <div>
                <label for="currentShareModal" class="text-dark mt-4"> Modal Saham Semasa:</label>
                <?php echo $memberRow['mem_modal_share']; ?>
                <input type="text" name="shareModal" id="shareModal" class="form-control"
                    placeholder="Masukkan jumlah pembayaran modal saham di sini" value = "<?php echo $memberRow['mem_fee_modal_share'];?>"readonly>
            </div>
            <div>
                <label for="currentModalFee" class="text-dark mt-4"> Yuran Modal Semasa:</label>
                <?php echo $memberRow['mem_modal_fee']; ?>
                <input type="text" name="modalFee" id="modalFee" class="form-control"
                    placeholder="Masukkan jumlah pembayaran yuran modal di sini" value = "<?php echo $memberRow['mem_fee_modal_fee'];?>" readonly>
            </div>
            <div>
                <label for="currentFixedSavings" class="text-dark mt-4"> Simpanan Tetap Semasa:</label>
                <?php echo $memberRow['mem_fixed_saving']; ?>
                <input type="text" name="fixedSavings" id="fixedSavings" class="form-control"
                    placeholder="Masukkan jumlah pembayaran simpanan tetap di sini" value = "<?php echo $memberRow['mem_fee_fixed_saving'];?>" readonly>
            </div>
            <div>
                <label for="currentCharityFund" class="text-dark mt-4"> Dana Kebajikan Semasa:</label>
                <?php echo $memberRow['mem_charity_fund']; ?>
                <input type="text" name="charityFund" id="charityFund" class="form-control"
                    placeholder="Masukkan jumlah pembayaran dana kebajikan di sini" value = "<?php echo $memberRow['mem_fee_charity_fund'];?>" readonly> 
            </div>
            <div>
                <label for="currentSavings" class="text-dark mt-4"> Simpanan Semasa:</label>
                <?php echo $memberRow['mem_saving']; ?>
                <input type="text" name="savings" id="savings" class="form-control"
                    placeholder="Masukkan jumlah pembayaran simpanan di sini" value = "<?php echo $memberRow['mem_fee_saving'];?>" readonly>
            </div>
            <div>
                <label for="remarks" class="form-label mt-4">Catatan</label>
                <textarea class="form-control" id="remarks" name="remarks" rows="3"></textarea>
            </div>
            <div class="form-group mb-4 mt-4">
            <a href='clerkEditShare.php' class='btn btn-secondary'>Kembali</a>
                <input type="submit" name="submit" class="btn btn-primary" value="Kemaskini">
            </div>
        </form>
    </div>

    <div class="container">
        <div>
            <table class="table">
                <thead>
                    <tr class="table-dark">
                        <th scope="col">ID Pembayaran</th>
                        <th scope="col">Yuran Masuk</th>
                        <th scope="col">Modal Saham</th>
                        <th scope="col">Yuran Modal</th>
                        <th scope="col">Simpanan Tetap</th>
                        <th scope="col">Dana Kebajikan</th>
                        <th scope="col">Simpanan</th>
                        <th scope="col">Tahun/Bulan</th>
                        <th scope="col"></th>
                    </tr>
                </thead>
                <tbody>
                    <?php
                    while ($feerow = mysqli_fetch_array($fee_history_result)) {
                        echo '<tr class ="primary">';
                        echo '<td>' . $feerow['fee_id'] . '</td>';
                        echo '<td>' . $feerow['fee_entry'] . '</td>';
                        echo '<td>' . $feerow['fee_modalshare'] . '</td>';
                        echo '<td>' . $feerow['fee_modalfee'] . '</td>';
                        echo '<td>' . $feerow['fee_fixed_saving'] . '</td>';
                        echo '<td>' . $feerow['fee_charity'] . '</td>';
                        echo '<td>' . $feerow['fee_savings'] . '</td>';
                        echo '<td>' . $feerow['fee_month'] . '</td>';
                        echo '</tr>';
                    }
                    mysqli_close($con);
                    ?>
                </tbody>
            </table>
        </div>
    </div>
</div>