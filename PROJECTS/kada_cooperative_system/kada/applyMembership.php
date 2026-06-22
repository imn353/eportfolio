<?php
include 'indexNav.php';

?>

<style>
    body {
        min-height: 100vh;
        display: flex;
        flex-direction: column;
    }

    .content {
        flex: 1 0 auto;
    }

    .btn-primary {
        background-color: #007bff;
        border-color: #007bff;
    }

    .btn-primary:hover {
        background-color: #0056b3;
        border-color: #0056b3;
    }

    .text-primary {
        color: #1d3557 !important;
        transition: all 0.3s ease;
    }

    .text-primary:hover {
        color: #457b9d !important;
        text-decoration: underline;
    }

    .card {
        box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    }

    .card-header {
        background: linear-gradient(135deg, #1d3557, #457b9d);
        color: white;
        font-weight: 600;
    }

    .form-label {
        font-weight: bold;
    }

    .form-control:focus {
        border-color: #80bdff;
        box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, .25);
    }
</style>

<body class="bg-light"><br><br><br><br>
    <div class="container py-3">
        <title>Makluamat Peribadi</title>
        <div class="card shadow">
            <div class="card-header bg-primary text-white py-2">
                <h1 class="card-title text-center mb-0">Permohonan Keahlian</h1>
            </div>
            <div class="card-body px-5 py-4">
                <p class="text-muted text-end mb-2">
                    <small>Nota: Semua Bahagian Yang Mempunyai Tanda * Adalah Wajib</small>
                </p>
                <form method="POST" action="applyMembershipFamily.php" class="needs-validation" novalidate>
                    <div class="section-personal-info mb-4">
                        <h2 class="section-title mb-3">Maklumat Peribadi</h2>
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label for="number_staff" class="form-label">Nombor Kakitangan *</label>
                                <input type="text" class="form-control" id="number_staff" name="fnostaff" placeholder="cth: 12345" required>
                                <div class="invalid-feedback">Sila masukkan nombor kakitangan.</div>
                            </div>
                            <div class="col-md-4">
                                <label for="inputValid" class="form-label">Nombor Kad Pengenalan *</label>
                                <input type="text" class="form-control" id="inputValid" name="fic" pattern="^\d{12}$" placeholder="cth: 123456789012" required>
                                <div class="invalid-feedback">Sila masukkan 12 digit nombor kad pengenalan.</div>
                            </div>
                            <div class="col-md-4">
                                <label for="priority_number" class="form-label">Nombor pf *</label>
                                <input type="text" class="form-control" id="priority_number" name="fnopf" placeholder="cth: 2000" required>
                                <div class="invalid-feedback">Sila masukkan nombor pf.</div>
                            </div>
                        </div>

                        <div class="row g-3 mt-3">
                            <div class="col-md-6">
                                <label for="employee_name" class="form-label">Nama *</label>
                                <input type="text" class="form-control" id="employee_name" name="fname" placeholder="Nama Penuh" required>
                                <div class="invalid-feedback">Sila masukkan nama anda.</div>
                            </div>
                            <div class="col-md-6">
                                <label for="exampleSelect1" class="form-label">Taraf Perkahwinan *</label>
                                <select class="form-select" name="fstatus" id="exampleSelect1" required>
                                    <option value="">Pilih Taraf Perkahwinan</option>
                                    <option>Belum Berkahwin</option>
                                    <option>Sudah Berkahwin</option>
                                    <option>Duda/Janda</option>
                                </select>
                                <div class="invalid-feedback">Sila pilih taraf perkahwinan.</div>
                            </div>
                        </div>
                        <div>
                            <label for="exampleTextarea" class="form-label mt-4">Alamat Rumah</label>
                            <textarea class="form-control" name="fhaddr" id="exampleTextarea" rows="2" required></textarea>
                        </div>
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label for="postcode" class="form-label mt-4">Poskod Rumah *</label>
                                <input type="text" class="form-control" id="postcode" name="fhpostcode" placeholder="cth: 80000" required>
                                <div class="invalid-feedback">Sila masukkan poskod rumah.</div>
                            </div>
                            <div class="col-md-6">
                                <label for="state" class="form-label mt-4">Negeri (Rumah) *</label>
                                <select class="form-select" name="fhstate" required id="state">
                                    <option value="">Pilih Negeri</option>
                                    <?php
                                    $sql = "SELECT * FROM tb_state";
                                    $result = mysqli_query($con, $sql);
                                    while ($row = mysqli_fetch_array($result)) {
                                        echo "<option value = '" . $row['state_id'] . "'>" . $row['state_name'] . "</option>";
                                    }
                                    ?>
                                </select>
                                <div class="invalid-feedback">Sila pilih negeri.</div>
                            </div>
                        </div>
                        <div class="row g-3 mt-3">
                            <div class="col-md-4">
                                <div class="border rounded p-3 h-100">
                                    <label class="form-label fw-bold">Jantina *</label>
                                    <div class="d-flex flex-column">
                                        <div class="form-check mb-2">
                                            <input class="form-check-input" name="fgender" type="radio" id="male" value="L" required>
                                            <label class="form-check-label" for="male">Lelaki</label>
                                        </div>
                                        <div class="form-check">
                                            <input class="form-check-input" name="fgender" type="radio" id="female" value="P" required>
                                            <label class="form-check-label" for="female">Perempuan</label>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="col-md-4">
                                <div class="border rounded p-3 h-100">
                                    <label class="form-label fw-bold">Agama *</label>
                                    <div class="d-flex flex-column">
                                        <div class="form-check mb-2">
                                            <input class="form-check-input" name="freligion" type="radio" id="rel1" value="Islam" required>
                                            <label class="form-check-label" for="rel1">Islam</label>
                                        </div>
                                        <div class="form-check mb-2">
                                            <input class="form-check-input" name="freligion" type="radio" id="rel2" value="Christianity">
                                            <label class="form-check-label" for="rel2">Christian</label>
                                        </div>
                                        <div class="form-check mb-2">
                                            <input class="form-check-input" name="freligion" type="radio" id="rel3" value="Buddhism">
                                            <label class="form-check-label" for="rel3">Buddha</label>
                                        </div>
                                        <div class="form-check">
                                            <input class="form-check-input" name="freligion" type="radio" id="rel4" value="Other">
                                            <label class="form-check-label" for="rel4">Lain - lain</label>
                                        </div>
                                        <div id="otherReligionInput" class="mt-2" style="display: none;">
                                            <input type="text" id="otherReligion" class="form-control" placeholder="Sila Nyatakan">
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="col-md-4">
                                <div class="border rounded p-3 h-100">
                                    <label class="form-label fw-bold">Bangsa *</label>
                                    <div class="d-flex flex-column">
                                        <div class="form-check mb-2">
                                            <input class="form-check-input" name="frace" type="radio" id="race1" value="Melayu" required>
                                            <label class="form-check-label" for="race1">Melayu</label>
                                        </div>
                                        <div class="form-check mb-2">
                                            <input class="form-check-input" name="frace" type="radio" id="race2" value="Cina">
                                            <label class="form-check-label" for="race2">Cina</label>
                                        </div>
                                        <div class="form-check mb-2">
                                            <input class="form-check-input" name="frace" type="radio" id="race3" value="India">
                                            <label class="form-check-label" for="race3">India</label>
                                        </div>
                                        <div class="form-check">
                                            <input class="form-check-input" name="frace" type="radio" id="race7" value="Other">
                                            <label class="form-check-label" for="race7">Lain - lain</label>
                                        </div>
                                        <div id="otherRaceInput" class="mt-2" style="display: none;">
                                            <input type="text" id="otherRace" name="otherRaceText" class="form-control" placeholder="Sila Nyatakan">
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="row g-3 mt-4">
                            <div class="col-md-6">
                                <label for="floatingEmail" class="form-label">Alamat Emel *</label>
                                <div class="input-group">
                                    <input type="email" class="form-control" name="femail" id="floatingEmail" placeholder="name@example.com" required>
                                </div>
                                <div class="form-text text-muted">
                                    Contoh: nama@gmail.com
                                </div>
                            </div>
                            <div class="col-md-6">
                                <label for="floatingPassword" class="form-label">Katalaluan *</label>
                                <div class="input-group">
                                    <input type="password" class="form-control" name="fpass" id="floatingPassword" placeholder="Password" required>
                                    <button class="btn btn-outline-secondary" type="button" id="togglePassword">
                                        <i class="bi bi-eye"></i>
                                    </button>
                                </div>
                                <div class="form-text text-muted">
                                    Gunakan kombinasi huruf, nombor, dan simbol untuk katalaluan yang kuat.
                                </div>
                            </div>
                        </div>
                        <div class="row g-3 mt-3">
                            <div class="col-md-6">
                                <label for="floatingConfirmPassword" class="form-label">Sahkan Katalaluan *</label>
                                <div class="input-group">
                                    <input type="password" class="form-control" name="fconfirmpass" id="floatingConfirmPassword" placeholder="Confirm Password" required>
                                    <button class="btn btn-outline-secondary" type="button" id="toggleConfirmPassword">
                                        <i class="bi bi-eye"></i>
                                    </button>
                                </div>
                                <div class="invalid-feedback">
                                    Katalaluan tidak sepadan.
                                </div>
                            </div>
                        </div>
                        <div class="row g-3 mt-4">
                            <div class="col-md-6">
                                <label for="position" class="form-label">Jawatan *</label>
                                <input type="text" class="form-control" name="fposi" id="position" placeholder="Masukkan jawatan" required>
                            </div>
                            <div class="col-md-6">
                                <label for="position1" class="form-label">Gred Jawatan *</label>
                                <input type="text" class="form-control" name="fgradeposi" id="position1" placeholder="Masukkan gred jawatan" required>
                            </div>
                        </div>

                        <div class="row g-3 mt-3">
                            <div class="col-md-12">
                                <label for="exampleTextarea" class="form-label">Alamat Pejabat *</label>
                                <textarea class="form-control" name="foaddr" id="exampleTextarea" rows="2" required></textarea>
                            </div>
                        </div>

                        <div class="row g-3 mt-3">
                            <div class="col-md-6">
                                <label for="postcode" class="form-label">Poskod Pejabat *</label>
                                <input type="text" class="form-control" name="fopostcode" id="postcode" placeholder="cth: 80000" required>
                            </div>
                            <div class="col-md-6">
                                <label for="state" class="form-label">Negeri (Pejabat) *</label>
                                <select class="form-select" name="fostate" id="state" required>
                                    <option value="">Pilih Negeri</option>
                                    <?php
                                    $sql = "SELECT * FROM tb_state";
                                    $result = mysqli_query($con, $sql);
                                    while ($row = mysqli_fetch_array($result)) {
                                        echo "<option value = '" . $row['state_id'] . "'>" . $row['state_name'] . "</option>";
                                    }
                                    ?>
                                </select>
                            </div>
                        </div>

                        <div class="row g-3 mt-3">
                            <div class="col-md-4">
                                <label for="faxno" class="form-label">Nombor Fax</label>
                                <input type="text" class="form-control" name="fnofax" id="faxno" placeholder="cth: 0123456789">
                                <small class="form-text text-muted">Letak " - " jika tiada</small>
                            </div>
                            <div class="col-md-4">
                                <label for="nophone" class="form-label">Nombor Telefon *</label>
                                <input type="text" class="form-control" name="fnotel" id="nophone" placeholder="cth: 0123456789" required>
                            </div>
                            <div class="col-md-4">
                                <label for="nohouse" class="form-label">Nombor Telefon Rumah</label>
                                <input type="text" class="form-control" name="fnohouse" id="nohouse" placeholder="cth: 0123456789">
                                <small class="form-text text-muted">Letak " - " jika tiada</small>
                            </div>
                        </div>

                        <div class="row g-3 mt-3">
                            <div class="col-md-6">
                                <label for="salary" class="form-label">Gaji Bulanan *</label>
                                <div class="input-group">
                                    <span class="input-group-text">RM</span>
                                    <input type="text" class="form-control" name="fsalary" id="salary" placeholder="Masukkan gaji bulanan" required>
                                </div>
                            </div>
                        </div>

                        <div class="row g-3 mt-3">
                            <div class="col-md-6">
                                <label for="bank" class="form-label">Nama Bank *</label>
                                <select class="form-select" name="fbank" id="bank" required>
                                    <option value="">Pilih Bank</option>
                                    <?php
                                    $sql = "SELECT * FROM tb_bank";
                                    $result = mysqli_query($con, $sql);
                                    while ($row = mysqli_fetch_array($result)) {
                                        echo "<option value = '" . $row['bank_id'] . "'>" . $row['bank_name'] . "</option>";
                                    }
                                    ?>
                                </select>
                            </div>
                            <div class="col-md-6">
                                <label for="acc" class="form-label">Nombor Bank Akaun *</label>
                                <input type="text" class="form-control" name="fnoacc" id="acc" placeholder="Masukkan nombor akaun bank" required>
                            </div>
                        </div>


                        <div class="row mt-4">
                            <div class="col-md-4">
                                <a href="index.php" class="btn btn-secondary w-100"><i class="bi bi-arrow-left"></i> Ke Login</a>
                            </div>
                            <div class="col-md-4">
                                <button type="reset" class="btn btn-warning w-100"><i class="bi bi-arrow-counterclockwise"></i> Reset</button>
                            </div>
                            <div class="col-md-4">
                                <button type="submit" class="btn btn-primary w-100">Seterusnya <i class="bi bi-arrow-right"></i></button>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const passwordInput = document.getElementById('floatingPassword');
            const confirmPasswordInput = document.getElementById('floatingConfirmPassword');
            const togglePassword = document.getElementById('togglePassword');
            const toggleConfirmPassword = document.getElementById('toggleConfirmPassword');
            const form = document.querySelector('form');


            function togglePasswordVisibility(inputField, toggleButton) {
                const type = inputField.getAttribute('type') === 'password' ? 'text' : 'password';
                inputField.setAttribute('type', type);
                toggleButton.innerHTML = type === 'password' ? '<i class="bi bi-eye"></i>' : '<i class="bi bi-eye-slash"></i>';
            }

            togglePassword.addEventListener('click', () => togglePasswordVisibility(passwordInput, togglePassword));
            toggleConfirmPassword.addEventListener('click', () => togglePasswordVisibility(confirmPasswordInput, toggleConfirmPassword));


            function checkPasswordMatch() {
                if (passwordInput.value !== confirmPasswordInput.value) {
                    confirmPasswordInput.setCustomValidity("Passwords do not match");
                } else {
                    confirmPasswordInput.setCustomValidity('');
                }
            }

            passwordInput.addEventListener('input', checkPasswordMatch);
            confirmPasswordInput.addEventListener('input', checkPasswordMatch);


            form.addEventListener('submit', function(event) {
                if (!form.checkValidity()) {
                    event.preventDefault();
                    event.stopPropagation();
                }
                form.classList.add('was-validated');
            });

 
            function validateInput(input) {
                const pattern = /^\d{12}$/;
                input.classList.toggle("is-valid", pattern.test(input.value));
                input.classList.toggle("is-invalid", !pattern.test(input.value));
            }

            const icInput = document.getElementById('inputValid');
            icInput.addEventListener('input', () => validateInput(icInput));


            function setupOtherInput(name, otherId, otherInputId, otherRadioId) {
                const radios = document.querySelectorAll(`input[name="${name}"]`);
                const otherInput = document.getElementById(otherId);
                const otherTextInput = document.getElementById(otherInputId);
                const otherRadio = document.getElementById(otherRadioId);

                radios.forEach(radio => {
                    radio.addEventListener('change', function() {
                        const isOther = this.value === 'Other';
                        otherInput.style.display = isOther ? 'block' : 'none';
                        otherTextInput.required = isOther;
                        if (!isOther) otherTextInput.value = '';
                    });
                });

                otherTextInput.addEventListener('input', function() {
                    otherRadio.value = this.value;
                });
            }

            setupOtherInput('freligion', 'otherReligionInput', 'otherReligion', 'rel4');
            setupOtherInput('frace', 'otherRaceInput', 'otherRace', 'race7');
        });
    </script>

</body>

</html>