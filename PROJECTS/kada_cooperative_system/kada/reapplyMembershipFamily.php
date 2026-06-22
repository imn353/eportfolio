<?php
include 'indexNav.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $fnostaff = htmlspecialchars($_POST['fnostaff']);
    $fic = htmlspecialchars($_POST['fic']);
    $fnopf = htmlspecialchars($_POST['fnopf']);
    $fname = htmlspecialchars($_POST['fname']);
    $fstatus = htmlspecialchars($_POST['fstatus']);
    $fhaddr = htmlspecialchars($_POST['fhaddr']);
    $fhpostcode = htmlspecialchars($_POST['fhpostcode']);
    $fhstate = htmlspecialchars($_POST['fhstate']);
    $fgender = htmlspecialchars($_POST['fgender']);
    $freligion = htmlspecialchars($_POST['freligion']);
    $frace = htmlspecialchars($_POST['frace']);
    $femail = htmlspecialchars($_POST['femail']);
    $fpass = htmlspecialchars($_POST['fpass']);
    $fposi = htmlspecialchars($_POST['fposi']);
    $fgradeposi = htmlspecialchars($_POST['fgradeposi']);
    $foaddr = htmlspecialchars($_POST['foaddr']);
    $fopostcode = htmlspecialchars($_POST['fopostcode']);
    $fostate = htmlspecialchars($_POST['fostate']);
    $fnofax = htmlspecialchars($_POST['fnofax']);
    $fnotel = htmlspecialchars($_POST['fnotel']);
    $fnohouse = htmlspecialchars($_POST['fnohouse']);
    $fsalary = htmlspecialchars($_POST['fsalary']);
    $fbank = htmlspecialchars($_POST['fbank']);
    $fnoacc = htmlspecialchars($_POST['fnoacc']);
} else {
    die("Tiada maklumat daripada muka surat 1.");
}

$family_sql = "SELECT * FROM tb_family WHERE f_member_id = '$fnostaff'";
$family_result = mysqli_query($con, $family_sql);
$family_data = [];
while ($family_row = mysqli_fetch_assoc($family_result)) {
    $family_data[] = $family_row;
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

    .btn-danger {
        background-color: #dc3545;
        border-color: #dc3545;
    }

    .btn-danger:hover {
        background-color: #bb2d3b;
        border-color: #b02a37;
    }

    .family-form {
        transition: all 0.3s ease;
    }

    .family-form:hover {
        box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15);
    }
</style>

<div class="container py-5"> <br><br><br>
    <div class="card shadow">
        <title>Makluamat Keluarga</title>
        <div class="card-header bg-primary text-white py-3">
            <h2 class="card-title text-center mb-0">Permohonan Keahlian</h2>
        </div>
        <div class="card-body p-4">
            <h2 class="section-title mb-3">Maklumat Keluarga</h2>
            <form method="POST" action="reapplyMembershipCharity.php" class="needs-validation" novalidate>
                <input type="hidden" name="fnostaff" value="<?php echo htmlspecialchars($_POST['fnostaff']); ?>">
                <input type="hidden" name="fic" value="<?php echo htmlspecialchars($_POST['fic']); ?>">
                <input type="hidden" name="fnopf" value="<?php echo htmlspecialchars($_POST['fnopf']); ?>">
                <input type="hidden" name="fname" value="<?php echo htmlspecialchars($_POST['fname']); ?>">
                <input type="hidden" name="fstatus" value="<?php echo htmlspecialchars($_POST['fstatus']); ?>">
                <input type="hidden" name="fhaddr" value="<?php echo htmlspecialchars($_POST['fhaddr']); ?>">
                <input type="hidden" name="fhpostcode" value="<?php echo htmlspecialchars($_POST['fhpostcode']); ?>">
                <input type="hidden" name="fhstate" value="<?php echo htmlspecialchars($_POST['fhstate']); ?>">
                <input type="hidden" name="fgender" value="<?php echo htmlspecialchars($_POST['fgender']); ?>">
                <input type="hidden" name="freligion" value="<?php echo htmlspecialchars($_POST['freligion']); ?>">
                <input type="hidden" name="frace" value="<?php echo htmlspecialchars($_POST['frace']); ?>">
                <input type="hidden" name="femail" value="<?php echo htmlspecialchars($_POST['femail']); ?>">
                <input type="hidden" name="fpass" value="<?php echo htmlspecialchars($_POST['fpass']); ?>">
                <input type="hidden" name="fposi" value="<?php echo htmlspecialchars($_POST['fposi']); ?>">
                <input type="hidden" name="fgradeposi" value="<?php echo htmlspecialchars($_POST['fgradeposi']); ?>">
                <input type="hidden" name="foaddr" value="<?php echo htmlspecialchars($_POST['foaddr']); ?>">
                <input type="hidden" name="fopostcode" value="<?php echo htmlspecialchars($_POST['fopostcode']); ?>">
                <input type="hidden" name="fostate" value="<?php echo htmlspecialchars($_POST['fostate']); ?>">
                <input type="hidden" name="fnofax" value="<?php echo htmlspecialchars($_POST['fnofax']); ?>">
                <input type="hidden" name="fnotel" value="<?php echo htmlspecialchars($_POST['fnotel']); ?>">
                <input type="hidden" name="fnohouse" value="<?php echo htmlspecialchars($_POST['fnohouse']); ?>">
                <input type="hidden" name="fsalary" value="<?php echo htmlspecialchars($_POST['fsalary']); ?>">
                <input type="hidden" name="fbank" value="<?php echo htmlspecialchars($_POST['fbank']); ?>">
                <input type="hidden" name="fnoacc" value="<?php echo htmlspecialchars($_POST['fnoacc']); ?>">
                <?php
                $previous_data = [
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
                foreach ($previous_data as $field) {
                    echo '<input type="hidden" name="' . $field . '" value="' . htmlspecialchars($_POST[$field] ?? '') . '">';
                }
                ?>

                <div id="familyFormsContainer">
                    <?php foreach ($family_data as $index => $family_member): ?>
                        <div class="family-form mb-4 p-3 border rounded bg-light">
                            <h4 class="mb-3">Ahli Keluarga <?php echo $index + 1; ?></h4>
                            <div class="row g-3">
                                <div class="col-md-6">
                                    <label for="name<?php echo $index; ?>" class="form-label">Nama</label>
                                    <input type="text" class="form-control" id="name<?php echo $index; ?>" name="name[]" value="<?php echo htmlspecialchars($family_member['f_name']); ?>" required>
                                    <div class="invalid-feedback">Sila masukkan nama.</div>
                                </div>
                                <div class="col-md-6">
                                    <label for="ic<?php echo $index; ?>" class="form-label">No. Kad Pengenalan</label>
                                    <input type="text" class="form-control" id="ic<?php echo $index; ?>" name="ic[]" value="<?php echo htmlspecialchars($family_member['f_ic']); ?>" required pattern="[0-9]{12}" maxlength="12">
                                    <div class="invalid-feedback">Sila masukkan 12 digit nombor IC tanpa sengkang atau jarak.</div>
                                </div>
                            </div>
                            <div class="row g-3 mt-2">
                                <div class="col-md-6">
                                    <label for="relationship<?php echo $index; ?>" class="form-label">Hubungan</label>
                                    <select class="form-select" id="relationship<?php echo $index; ?>" name="relationship[]" required>
                                        <option value="">Pilih Hubungan</option>
                                        <option value="Bapa" <?php echo ($family_member['f_relationship'] == 'Bapa') ? 'selected' : ''; ?>>Bapa</option>
                                        <option value="Ibu" <?php echo ($family_member['f_relationship'] == 'Ibu') ? 'selected' : ''; ?>>Ibu</option>
                                        <option value="Adik-beradik" <?php echo ($family_member['f_relationship'] == 'Adik-beradik') ? 'selected' : ''; ?>>Adik-beradik</option>
                                        <option value="Anak" <?php echo ($family_member['f_relationship'] == 'Anak') ? 'selected' : ''; ?>>Anak</option>
                                    </select>
                                    <div class="invalid-feedback">Sila pilih hubungan.</div>
                                </div>
                                <div class="col-md-10 mt-5 d-flex align-items-end">
                                    <button type="button" class="btn btn-danger" onclick="removeFamilyForm(this)">
                                        <i class="bi bi-trash me-2"></i>Buang
                                    </button>
                                </div>
                            </div>
                            <input type="hidden" name="family_id[]" value="<?php echo htmlspecialchars($family_member['f_id']); ?>">
                        </div>
                    <?php endforeach; ?>
                </div>
                <div class="mb-4">
                    <button type="button" class="btn btn-secondary" onclick="addFamilyForm()">
                        <i class="bi bi-plus-circle me-2"></i>Tambah Ahli Keluarga
                    </button>
                </div>

                <div class="d-grid gap-2 d-md-flex justify-content-md-end">
                    <button type="submit" class="btn btn-primary" onclick="return validateForm()">
                        Seterusnya <i class="bi bi-arrow-right"></i>
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
    let familyFormCount = <?php echo count($family_data); ?>;

    function addFamilyForm() {
        const container = document.getElementById('familyFormsContainer');
        const formIndex = familyFormCount++;

        const formDiv = document.createElement('div');
        formDiv.className = 'family-form mb-4 p-3 border rounded bg-light';

        formDiv.innerHTML = `
        <h4 class="mb-3">Ahli Keluarga ${formIndex + 1}</h4>
        <div class="row g-3">
            <div class="col-md-6">
                <label for="name${formIndex}" class="form-label">Nama</label>
                <input type="text" class="form-control" id="name${formIndex}" name="name[]" placeholder="Masukkan Nama" required>
                <div class="invalid-feedback">Sila masukkan nama.</div>
            </div>
            <div class="col-md-6">
                <label for="ic${formIndex}" class="form-label">No. Kad Pengenalan</label>
                <input type="text" class="form-control" id="ic${formIndex}" name="ic[]" placeholder="Masukkan IC (12 digit)" required pattern="[0-9]{12}" maxlength="12">
                <div class="invalid-feedback">Sila masukkan 12 digit nombor IC tanpa sengkang atau jarak.</div>
            </div>
        </div>
        <div class="row g-3 mt-2">
            <div class="col-md-6">
                <label for="relationship${formIndex}" class="form-label">Hubungan</label>
                <select class="form-select" id="relationship${formIndex}" name="relationship[]" required>
                    <option value="">Pilih Hubungan</option>
                    <option value="Bapa">Bapa</option>
                    <option value="Ibu">Ibu</option>
                    <option value="Adik-beradik">Adik-beradik</option>
                    <option value="Anak">Anak</option>
                </select>
                <div class="invalid-feedback">Sila pilih hubungan.</div>
            </div>
            <div class="col-md-10 mt-5 d-flex align-items-end">
                <button type="button" class="btn btn-danger" onclick="removeFamilyForm(this)">
                    <i class="bi bi-trash me-2"></i>Buang
                </button>
            </div>
        </div>
    `;

        container.appendChild(formDiv);

        formDiv.innerHTML += '<input type="hidden" name="family_id[]" value="">';
    }

    function removeFamilyForm(button) {
        const formDiv = button.closest('.family-form');
        formDiv.remove();
        updateFamilyFormTitles();
        familyFormCount--;
    }

    function updateFamilyFormTitles() {
        const forms = document.querySelectorAll('.family-form');
        forms.forEach((form, index) => {
            const title = form.querySelector('h4');
            title.textContent = `Ahli Keluarga ${index + 1}`;
        });
    }

    function validateForm() {
        const form = document.querySelector('form');
        if (!form.checkValidity()) {
            event.preventDefault();
            event.stopPropagation();
        }
        form.classList.add('was-validated');

        // Check if any family members were added
        if (familyFormCount === 0) {
            if (!confirm('Anda belum menambah ahli keluarga. Adakah anda pasti ingin menghantar borang tanpa maklumat keluarga?')) {
                return false;
            }
        }

        // Check for duplicate ICs
        const icInputs = document.querySelectorAll('input[name="ic[]"]');
        const icValues = Array.from(icInputs).map(input => input.value);
        const uniqueICs = new Set(icValues);

        if (icValues.length !== uniqueICs.size) {
            alert('Terdapat nombor IC yang sama. Sila pastikan semua nombor IC adalah unik.');
            return false;
        }

        return true;
    }

    document.addEventListener('input', function(e) {
        if (e.target && e.target.name === 'ic[]') {
            const icInput = e.target;
            const icValue = icInput.value.replace(/\D/g, ''); // Remove non-digit characters
            icInput.value = icValue; 

            if (icValue.length !== 12) {
                icInput.setCustomValidity('Sila masukkan 12 digit nombor IC.');
            } else {
                icInput.setCustomValidity('');
            }
        }
    });


</script>
<?php

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $icNumbers = $_POST['ic'] ?? [];
    $uniqueICs = array_unique($icNumbers);

    if (count($icNumbers) !== count($uniqueICs)) {
        echo "<script>
            alert('Terdapat nombor IC yang sama. Sila pastikan semua nombor IC adalah unik.');
            window.history.back();
        </script>";
        exit;
    }
}
?>

</body>

</html>