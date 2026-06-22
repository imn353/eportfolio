<?php

include 'clerkNav.php';
?>


<div class="content">
    <div class="container mt-4">
        <h2 class="mb-4 text-center">Kemaskini Polisi Pinjaman</h2>
        <div class="row">
            <div class="col-md-6 mb-4">
                <form action="editLoanProcess.php" method="POST" onsubmit="return validateForm()" class="bg-light p-4 rounded shadow">
                    <div class="mb-3">
                        <label for="loan_name" class="form-label">Pilih Jenis Pinjaman:</label>
                        <select name="loan_name" id="loan_name" class="form-select" required>
                            <option value="">Pilih Jenis Pinjaman</option>
                            <?php
                            $sql = "SELECT * FROM tb_loan";
                            $result = mysqli_query($con, $sql);

                            while ($row = mysqli_fetch_array($result)) {
                                echo "<option value='" . $row['loan_name'] . "'>" . $row['loan_name'] . "</option>";
                            }
                            ?>
                        </select>
                    </div>

                    <div class="mb-3">
                        <label for="interest_rate" class="form-label">Faedah (%):</label>
                        <input type="number" step="0.1" name="interest_rate" id="interest_rate" class="form-control" required>
                    </div>

                    <div class="mb-3">
                        <label for="max_loan_amount" class="form-label">Maksimum Amaun Pinjaman (RM):</label>
                        <input type="number" name="max_loan_amount" id="max_loan_amount" class="form-control" required>
                    </div>

                    <div class="mb-3">
                        <label for="min_loan_amount" class="form-label">Min Amaun Pinjaman (RM):</label>
                        <input type="number" name="min_loan_amount" id="min_loan_amount" class="form-control" required>
                    </div>

                    <div class="mb-3">
                        <label for="processing_fee" class="form-label">Modah Syer (RM):</label>
                        <input type="number" name="processing_fee" id="processing_fee" class="form-control" required>
                    </div>

                    <button type="submit" class="btn btn-primary w-100">Kemaskini Polisi Pinjaman</button>
                </form>
            </div>
            <div class="col-md-6">
                <div class="table-responsive">
                    <table class="table table-hover table-striped bg-white rounded shadow">
                        <thead class="table-primary">
                            <tr>
                                <th>Jenis Pinjaman</th>
                                <th>Faedah (%)</th>
                                <th>Maks. Amaun (RM)</th>
                                <th>Min. Amaun (RM)</th>
                                <th>Modah Syer (RM)</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php
                            $query = "SELECT loan_name, loan_rate, loan_max, loan_min, loan_modal_share FROM tb_loan";
                            $result = mysqli_query($con, $sql);

                            if ($result && mysqli_num_rows($result) > 0) {
                                while ($row = mysqli_fetch_assoc($result)) {

                                    $loanName = $row['loan_name'] ?? 'N/A';
                                    $loanRate = $row['loan_rate'] ?? 0;
                                    $loanMax = $row['loan_max'] ?? 0;
                                    $loanMin = $row['loan_min'] ?? 0;
                                    $loanModalShare = $row['loan_min_modal_share'] ?? 0;

                                    echo "<tr>";
                                    echo "<td>" . htmlspecialchars($loanName) . "</td>";
                                    echo "<td>" . number_format($loanRate, 2) . "%</td>";
                                    echo "<td>" . number_format($loanMax) . "</td>";
                                    echo "<td>" . number_format($loanMin) . "</td>";
                                    echo "<td>" . number_format($loanModalShare) . "</td>";
                                    echo "</tr>";
                                }
                            } else {
                                echo "<tr><td colspan='5' style='color: red;'>No data found.</td></tr>";
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
    function validateForm() {
        const interestRate = parseFloat(document.getElementById('interest_rate').value);
        const maxLoanAmount = parseFloat(document.getElementById('max_loan_amount').value);
        const minLoanAmount = parseFloat(document.getElementById('min_loan_amount').value);

        if (interestRate > 10) {
            alert('Interest rate must not exceed 10%.');
            return false;
        }

        if (minLoanAmount >= maxLoanAmount) {
            alert('Minimum loan amount must be less than the maximum loan amount.');
            return false;
        }

        return true;
    }
</script>

</body>

</html>