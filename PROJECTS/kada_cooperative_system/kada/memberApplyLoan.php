<?php
include('memberNav.php');

$memberId = $_SESSION['id'];

$modalsharequery = "SELECT mem_modal_share FROM tb_member WHERE mem_id = '$memberId'";
$modalshareresult = mysqli_query($con, $modalsharequery);
$modalsharerow = mysqli_fetch_assoc($modalshareresult);

?>
<div class="content">
    <div class="container-fluid">
        <h2 class="section-title mt-4 mb-4">Borang Pembiayaan Anggota</h2>
        <form action="memberApplyLoanProcess.php" method="POST" enctype="multipart/form-data">
            <div class="form-card">
                <h4 class="mb-4">Butir-Butir Pembiayaan</h4>
                <div class="mb-3">
                    <label for="la_type" class="form-label">Jenis Pembiayaan</label>
                    <select class="form-select" id="la_type" name="la_type" required>
                        <option value="">Pilih Jenis Pembiayaan</option>
                        <?php
                        $loanQuery = "SELECT * FROM tb_loan";
                        $loanResult = mysqli_query($con, $loanQuery);
                        while ($row = mysqli_fetch_array($loanResult)) {
                            echo "<option value='" . $row['loan_id'] . "' data-rate='" . $row['loan_rate'] . "' data-min='" . $row['loan_min'] . "' data-max='" . $row['loan_max'] . "' min-modal-share='" . $row['loan_min_modal_share'] . "'>" . $row['loan_name'] . "</option>";
                        }
                        ?>
                    </select>
                    <small id="loanDetails" class="form-text text-muted"></small>
                </div>

                <div class="mb-3">
                    <label for="la_amount" class="form-label">Amaun Pembiayaan (RM)</label>
                    <input type="number" class="form-control" id="la_amount" name="la_amount" placeholder="Masukkan amaun pembiayaan" required>
                </div>
                <div class="mb-3">
                    <label for="la_duration" class="form-label">Tempoh Pembiayaan (Bulan)</label>
                    <select class="form-select" id="la_duration" name="la_duration" required>
                        <option value="">Pilih Tempoh Pembiayaan</option>
                        <?php
                        $durationQuery = "SELECT * FROM tb_duration";
                        $durationResult = mysqli_query($con, $durationQuery);
                        while ($row = mysqli_fetch_array($durationResult)) {
                            echo "<option value='" . $row['d_year'] . "' data-year='" . $row['d_year'] . "'>" . $row['d_month'] . " Bulan</option>";
                        }
                        ?>
                    </select>
                </div>
                <div class="mb-3">
                    <label for="la_payment" class="form-label">Jumlah Pembiayaan (RM)</label>
                    <input type="text" class="form-control" id="la_payment" name="la_payment" placeholder="Jumlah Pembiayaan Selepas Ditambah Faedah" readonly>
                </div>
                <div class="mb-3">
                    <label for="la_monthly" class="form-label">Ansuran Bulanan (RM)</label>
                    <input type="text" class="form-control" id="la_monthly" name="la_monthly" placeholder="Ansuran Bulanan" readonly>
                </div>
                <div class="mb-3">
                    <label for="la_employer_sign" class="form-label">Borang Pengesahan Majikan (PDF)</label>
                    <input type="file" class="form-control" id="la_employer_sign" name="la_employer_sign" accept="application/pdf" required>
                    <small class="form-text text-muted">Maksimum Saiz Fail: 1 MB.</small>
                    <div id="fileError1" style="color: red; display: none;">SAIZ FAIL YANG DIMUAT NAIK MESTILAH DIBAWAH 1 MB.</div>
                </div>
            </div>

            <div class="form-card">
                <h4 class="mt-4">Butir-Butir Penjamin</h4>
                <div class="row">
                    <div class="col-md-6">
                        <h5>Penjamin 1</h5>
                        <div class="mb-3">
                            <label for="g1_ic" class="form-label">No. KP</label>
                            <input type="text" class="form-control" id="g1_ic" name="g1_ic" placeholder="Masukkan no. KP penjamin 1" required>
                        </div>
                        <div class="mb-3">
                            <label for="g1_name" class="form-label">Nama</label>
                            <input type="text" class="form-control" id="g1_name" name="g1_name" placeholder="Masukkan name penjamin 1" required>
                        </div>
                        <div class="mb-3">
                            <label for="g1_pf" class="form-label">No. PF</label>
                            <input type="number" class="form-control" id="g1_pf" name="g1_pf" placeholder="Masukkan no. PF penjamin 1" required>
                        </div>
                        <div class="mb-3">
                            <label for="g1_staff_id" class="form-label">No. Anggota</label>
                            <input type="number" class="form-control" id="g1_staff_id" name="g1_staff_id" placeholder="Masukkan no. anggota penjamin 1" required>
                        </div>
                        <div class="mb-3">
                            <label for="g1_signature" class="form-label">Borang Tandatangan Penjamin (PDF)</label>
                            <input type="file" class="form-control" id="g1_signature" name="g1_signature" accept="application/pdf" required>
                            <small class="form-text text-muted">Maksimum Saiz Fail: 1 MB.</small>
                            <div id="fileError2" style="color: red; display: none;">SAIZ FAIL YANG DIMUAT NAIK MESTILAH DIBAWAH 1 MB.</div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <h5>Penjamin 2</h5>
                        <div class="mb-3">
                            <label for="g2_ic" class="form-label">No. KP</label>
                            <input type="text" class="form-control" id="g2_ic" name="g2_ic" placeholder="Masukkan no. KP penjamin 2" required>
                        </div>
                        <div class="mb-3">
                            <label for="g2_name" class="form-label">Nama</label>
                            <input type="text" class="form-control" id="g2_name" name="g2_name" placeholder="Masukkan name penjamin 2" required>
                        </div>
                        <div class="mb-3">
                            <label for="g2_pf" class="form-label">No. PF</label>
                            <input type="number" class="form-control" id="g2_pf" name="g2_pf" placeholder="Masukkan no. PF penjamin 2" required>
                        </div>
                        <div class="mb-3">
                            <label for="g2_staff_id" class="form-label">No. Anggota</label>
                            <input type="number" class="form-control" id="g2_staff_id" name="g2_staff_id" placeholder="Masukkan no. anggota penjamin 2" required>
                        </div>
                        <div class="mb-3">
                            <label for="g2_signature" class="form-label">Borang Tandatangan Penjamin (PDF)</label>
                            <input type="file" class="form-control" id="g2_signature" name="g2_signature" accept="application/pdf" required>
                            <small class="form-text text-muted">Maksimum Saiz Fail: 1 MB.</small>
                            <div id="fileError3" style="color: red; display: none;">SAIZ FAIL YANG DIMUAT NAIK MESTILAH DIBAWAH 1 MB.</div>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <button type="submit" class="btn btn-primary">Hantar Permohonan</button>
                    </div>
                </div>
            </div>
        </form>
    </div>
</div>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        const modalShare = <?php echo $modalsharerow['mem_modal_share']; ?>;
        const submitButton = document.querySelector('button[type="submit"]');
        const loanTypeSelect = document.getElementById('la_type');
        const loanAmountInput = document.getElementById('la_amount');
        const loanDurationSelect = document.getElementById('la_duration');
        const monthlyPaymentInput = document.getElementById('la_monthly');
        const totalPaymentInput = document.getElementById('la_payment');
        const loanDetailsText = document.getElementById('loanDetails');

        function updateLoanDetails() {
            const selectedLoanOption = loanTypeSelect.options[loanTypeSelect.selectedIndex];
            const minAmount = parseFloat(selectedLoanOption.getAttribute('data-min')) || 0;
            const maxAmount = parseFloat(selectedLoanOption.getAttribute('data-max')) || 0;
            const MinModalShare = parseFloat(selectedLoanOption.getAttribute('min-modal-share')) || 0;
            loanDetailsText.textContent = `Minimum Pembiayaan: RM ${minAmount.toFixed(2)}, Maksimum Pembiayaan: RM ${maxAmount.toFixed(2)}, Minumum Modal Syer yang Diperlukan: RM ${MinModalShare.toFixed(2)}`;

            if (modalShare < MinModalShare) {
                alert(`Pastikan modal syer anda melebihi ${MinModalShare} untuk teruskan permohonan pembiayaan.`);
                submitButton.disabled = true;
            } else {
                submitButton.disabled = false;
            }
        }

        function calculateMonthlyPayment() {
            const loanAmount = parseFloat(loanAmountInput.value) || 0;
            const selectedDurationOption = loanDurationSelect.options[loanDurationSelect.selectedIndex];
            const durationYear = parseInt(selectedDurationOption.getAttribute('data-year')) || 0;
            const selectedLoanOption = loanTypeSelect.options[loanTypeSelect.selectedIndex];
            const rate = parseFloat(selectedLoanOption.getAttribute('data-rate')) / 100 || 0;
            const minAmount = parseFloat(selectedLoanOption.getAttribute('data-min')) || 0;
            const maxAmount = parseFloat(selectedLoanOption.getAttribute('data-max')) || Infinity;

            if (loanAmount < minAmount || loanAmount > maxAmount) {
                monthlyPaymentInput.value = '-';
                totalPaymentInput.value = '-';
                return;
            }

            if (loanAmount > 0 && durationYear > 0 && rate > 0) {

                const totalProfit = loanAmount * rate * durationYear;
                const totalPayment = loanAmount + totalProfit;
                const monthlyPayment = totalPayment / (durationYear * 12);

                totalPaymentInput.value = totalPayment.toFixed(2);
                monthlyPaymentInput.value = monthlyPayment.toFixed(2);
            } else {
                totalPaymentInput.value = '';
                monthlyPaymentInput.value = '';
            }
        }

        function validateFileSize(inputId, errorId, maxSizeMB) {
            document.getElementById(inputId).addEventListener("change", function() {
                const file = this.files[0];
                const maxSizeInBytes = maxSizeMB * 1024 * 1024;

                if (file && file.size > maxSizeInBytes) {
                    document.getElementById(errorId).style.display = "block";
                    this.value = "";
                } else {
                    document.getElementById(errorId).style.display = "none";
                }
            });
        }

        function validateGuarantors() {
            const g1_ic = document.getElementById('g1_ic').value;
            const g1_staff_id = document.getElementById('g1_staff_id').value;
            const g1_pf = document.getElementById('g1_pf').value;
            
            const g2_ic = document.getElementById('g2_ic').value;
            const g2_staff_id = document.getElementById('g2_staff_id').value;
            const g2_pf = document.getElementById('g2_pf').value;

            if (g1_ic === g2_ic) {
                alert('Nombor KP untuk penjamin tidak boleh sama.');
                return false;
            }
            
            if (g1_pf === g2_pf) {
                alert('Nombor PF untuk penjamin tidak boleh sama.');
                return false;
            }

            if (g1_staff_id === g2_staff_id) {
                alert('Nombor Anggota untuk penjamin tidak boleh sama.');
                return false;
            }

            return true;
        }

        const form = document.querySelector('form');
        form.addEventListener('submit', function(event) {
            if (!validateGuarantors()) {
                event.preventDefault();
            }
        });

        loanAmountInput.addEventListener('input', calculateMonthlyPayment);
        loanDurationSelect.addEventListener('change', calculateMonthlyPayment);
        loanTypeSelect.addEventListener('change', () => {
            updateLoanDetails();
            calculateMonthlyPayment();
        });

        updateLoanDetails();
        validateFileSize("la_employer_sign", "fileError1", 1);
        validateFileSize("g1_signature", "fileError2", 1);
        validateFileSize("g2_signature", "fileError3", 1);
    });
</script>
</body>

</html>