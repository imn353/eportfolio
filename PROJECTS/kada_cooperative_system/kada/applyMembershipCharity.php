<?php

include 'indexNav.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Retrieve data from Page 2
    $data = [];
    $fields = [
        'fnostaff',
        'fic',
        'fnopf',
        'fname',
        'fstatus',
        'fhaddr',
        'fhpostcode',
        'fhstate',
        'fgender',
        'freligion',
        'frace',
        'femail',
        'fpass',
        'fposi',
        'fgradeposi',
        'foaddr',
        'fopostcode',
        'fostate',
        'fnofax',
        'fnotel',
        'fnohouse',
        'fsalary',
        'fbank',
        'fnoacc'
    ];

    
    $minModalFee = 35;
    
    $ModalSyer = 50;
    $deposit = 20;
    $charity = 5;
    $fixedSaving = 5;
    $entryFee = 50;

    foreach ($fields as $field) {
        $data[$field] = htmlspecialchars($_POST[$field] ?? '');
    }

    // Retrieve family data
    $familyData = [];
    if (isset($_POST['name']) && is_array($_POST['name'])) {
        foreach ($_POST['name'] as $index => $name) {
            $familyData[] = [
                'name' => htmlspecialchars($name),
                'ic' => htmlspecialchars($_POST['ic'][$index] ?? ''),
                'relationship' => htmlspecialchars($_POST['relationship'][$index] ?? '')
            ];
        }
    }
} else {
    die("No data received from Page 2.");
}
?>
<style>
    body {
        background-color: #f8f9fa;
    }

    .card {
        border: none;
        border-radius: 15px;
    }

    .card-header {
        background: linear-gradient(135deg, #1d3557, #457b9d);
        border-radius: 15px 15px 0 0;
        color: white;
        font-weight: 600;
    }

    .btn-primary {
        background-color: #0d6efd;
        border-color: #0d6efd;
    }

    .btn-primary:hover {
        background-color: #0b5ed7;
        border-color: #0a58ca;
    }
</style>

<body>
    <div class="container py-5"> <br><br><br>
        <div class="card shadow">
            <div class="card-header">
                <h2 class="text-center mb-0">Permohonan Keahlian</h2>
            </div>
            <div class="card-body">
                <form method="POST" action="applyMembershipProcess.php">

                    <?php foreach ($data as $key => $value): ?>
                        <input type="hidden" name="<?php echo $key; ?>" value="<?php echo $value; ?>">
                    <?php endforeach; ?>


                    <?php foreach ($familyData as $index => $family): ?>
                        <input type="hidden" name="name[]" value="<?php echo $family['name']; ?>">
                        <input type="hidden" name="ic[]" value="<?php echo $family['ic']; ?>">
                        <input type="hidden" name="relationship[]" value="<?php echo $family['relationship']; ?>">
                    <?php endforeach; ?>

                    <div class="row g-3 mt-3">
                        <h2 class="section-title mb-3">Yuran & Sumbangan</h2>
                        <div class="col-md-6">
                            <label for="modalfee" class="form-label">Modal Yuran (Min: RM<?php echo $minModalFee; ?>)</label>
                            <div class="input-group">
                                <span class="input-group-text">RM</span>
                                <input type="text" class="form-control" name="modalfee" id="modalfee" required min="<?php echo $minModalFee; ?>" placeholder="Sila Masukkan Modal Yuran">
                            </div>
                        </div>
                        <div class="col-md-6">
                            <label for="share" class="form-label">Modal Syer</label>
                            <div class="input-group">
                                <span class="input-group-text">RM</span>
                                <input type="text" class="form-control" name="share" id="share" value="<?php echo $ModalSyer; ?>" readonly required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <label for="entryfee" class="form-label">Fee Masuk</label>
                            <div class="input-group">
                                <span class="input-group-text">RM</span>
                                <input type="text" class="form-control" name="entryfee" id="entryfee" value="<?php echo $entryFee; ?>" readonly required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <label for="depo" class="form-label">Wang Deposit Anggota</label>
                            <div class="input-group">
                                <span class="input-group-text">RM</span>
                                <input type="text" class="form-control" name="depo" id="depo" value="<?php echo $deposit; ?>" readonly required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <label for="charity" class="form-label">Sumbangan Tabung Kebajikan (Al - Abrar)</label>
                            <div class="input-group">
                                <span class="input-group-text">RM</span>
                                <input type="text" class="form-control" name="charity" id="charity" value="<?php echo $charity; ?>" readonly required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <label for="saving" class="form-label">Simpanan Tetap</label>
                            <div class="input-group">
                                <span class="input-group-text">RM</span>
                                <input type="text" class="form-control" name="saving" id="saving" value="<?php echo $fixedSaving; ?>" readonly required>
                            </div>
                        </div>
                    </div>

                    <div class="form-check mt-3">
                        <input class="form-check-input" type="checkbox" id="agreementCheckbox">
                        <label class="form-check-label" for="agreementCheckbox">
                            Saya Pasti Bahawa Segala Maklumat Yang Saya Masukkan Adalah Benar Dan Akan Memikul Tanggungjawab Jika Maklumat Tersebut Adalah Salah.
                        </label>
                    </div><br><br><br>

                    <div class="d-flex justify-content-center mt-3">
                        <button type="submit" class="btn btn-primary w-25" id="submitButton" disabled>Hantar <i class="fas fa-arrow-right"></i>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const form = document.querySelector('form');
            const numberInputs = form.querySelectorAll('input[type="text"]:not([readonly])');
            const agreementCheckbox = document.getElementById('agreementCheckbox');
            const submitButton = document.getElementById('submitButton');
            const modalFeeInput = document.getElementById('modalfee');

            // Enable submit button when all inputs are filled and agreement checkbox is checked
            agreementCheckbox.addEventListener('change', function() {
                submitButton.disabled = !this.checked;
            });

            numberInputs.forEach(input => {
                input.addEventListener('input', function(e) {
                    if (e.target.value < 0) {
                        e.target.value = 0;
                    }
                });
            });

            form.addEventListener('submit', function(e) {
                e.preventDefault(); // Prevent form from submitting immediately

                let isValid = true;
                numberInputs.forEach(input => {
                    if (isNaN(parseFloat(input.value)) || input.value === '') {
                        isValid = false;
                        input.classList.add('is-invalid');
                    } else {
                        input.classList.remove('is-invalid');
                    }
                });

                // Validate Modal Yuran
                if (parseFloat(modalFeeInput.value) < <?php echo $minModalFee; ?>) {
                    isValid = false;
                    modalFeeInput.classList.add('is-invalid');
                    alert('Modal Yuran mestilah melebihi RM<?php echo $minModalFee; ?>.');
                    return;
                }

                if (!isValid) {
                    alert('Sila masukkan nilai yang sah.');
                    return;
                }


                if (confirm('Pastikan maklumat yang diisi adalah benar.')) {
                    this.submit(); 
                }
            });
        });
    </script>


</body>


</html>