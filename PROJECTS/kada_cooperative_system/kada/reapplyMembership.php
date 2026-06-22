<?php
include 'indexNav.php';

$no_staff = $_GET['fnostaff'];

$sql = "SELECT *,
        state1.state_name AS state1_name,
        state2.state_name AS state2_name,
        state1.state_id AS stateid1,
        state2.state_id AS stateid2
        FROM tb_member 
        LEFT JOIN tb_state AS state1 ON tb_member.mem_state = state1.state_id
        LEFT JOIN tb_state AS state2 ON tb_member.mem_office_state = state2.state_id
        LEFT JOIN tb_bank ON tb_member.mem_bank = tb_bank.bank_id
        WHERE mem_id = '$no_staff'";

$result = mysqli_query($con, $sql);
$row = mysqli_fetch_array($result);

if ($row['mem_id'] == "") {
    echo "<script>alert('Nombor Kakitangan yang anda masukkan tiada dalam sistem !!!');";
    die("window.history.go(-1);</script>");
}

if ($row['mem_membership_status'] != 10) {
    echo "<script>alert('Anda sudah mempunyai akaun yang aktif !!!');";
    die("window.history.go(-1);</script>");
}

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
                <form method="POST" action="reapplyMembershipFamily.php" class="needs-validation" novalidate>
                    <div class="section-personal-info mb-4">
                        <h2 class="section-title mb-3">Maklumat Peribadi</h2>
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label for="number_staff" class="form-label">Nombor Kakitangan</label>
                                <input type="text" class="form-control" id="number_staff" name="fnostaff" value="<?php echo $no_staff; ?>" readonly required>
                            </div>
                            <div class="col-md-4">
                                <label for="inputValid" class="form-label">Nombor Kad Pengenalan</label>
                                <input type="text" class="form-control" id="inputValid" name="fic" pattern="^\d{12}$" value="<?php echo $row['mem_ic']; ?>" readonly required>
                            </div>
                            <div class="col-md-4">
                                <label for="priority_number" class="form-label">Nombor pf</label>
                                <input type="text" class="form-control" id="priority_number" name="fnopf" value="<?php echo $row['mem_pf']; ?>" readonly required>
                            </div>
                        </div>

                        <div class="row g-3 mt-3">
                            <div class="col-md-6">
                                <label for="employee_name" class="form-label">Nama</label>
                                <input type="text" class="form-control" id="employee_name" name="fname" value="<?php echo $row['mem_name']; ?>" readonly required>
                            </div>
                            <div class="col-md-6">
                                <label for="exampleSelect1" class="form-label">Taraf Perkahwinan *</label>
                                <select class="form-select" name="fstatus" id="exampleSelect1" required>
                                    <option><?php echo $row['mem_status']; ?></option>
                                    <option>Belum Berkahwin</option>
                                    <option>Sudah Berkahwin</option>
                                    <option>Duda/Janda</option>
                                </select>
                                <div class="invalid-feedback">Sila pilih taraf perkahwinan.</div>
                            </div>
                        </div>
                        <div>
                            <label for="exampleTextarea" class="form-label mt-4">Alamat Rumah *</label>
                            <textarea class="form-control" name="fhaddr" id="exampleTextarea" rows="2" required><?php echo $row['mem_address']; ?></textarea>
                        </div>
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label for="postcode" class="form-label mt-4">Poskod Rumah *</label>
                                <input type="text" class="form-control" id="postcode" name="fhpostcode" value="<?php echo $row['mem_postcode']; ?>" required>
                            </div>
                            <div class="col-md-6">
                                <label for="state" class="form-label mt-4">Negeri (Rumah) *</label>
                                <select class="form-select" name="fhstate" required id="state">
                                    <option value="<?php echo $row['stateid1']; ?>"><?php echo $row['state1_name']; ?></option>
                                    <?php
                                    $sql = "SELECT * FROM tb_state";
                                    $result = mysqli_query($con, $sql);
                                    while ($row1 = mysqli_fetch_array($result)) {
                                        echo "<option value = '" . $row1['state_id'] . "'>" . $row1['state_name'] . "</option>";
                                    }
                                    ?>
                                </select>
                                <div class="invalid-feedback">Sila pilih negeri.</div>
                            </div>
                        </div>
                        <div class="row g-3 mt-3">
                            <div class="col-md-4">
                                <div class="border rounded p-3 h-100">
                                    <label class="form-label fw-bold">Jantina</label>
                                    <div class="d-flex flex-column">
                                        <div class="form-check mb-2">
                                            <input class="form-check-input" type="radio" id="male" value="L" <?php echo ($row['mem_gender'] == 'L') ? 'checked' : ''; ?> disabled>
                                            <label class="form-check-label" for="male">Lelaki</label>
                                        </div>
                                        <div class="form-check">
                                            <input class="form-check-input" type="radio" id="female" value="P" <?php echo ($row['mem_gender'] == 'P') ? 'checked' : ''; ?> disabled>
                                            <label class="form-check-label" for="female">Perempuan</label>
                                        </div>
                                    </div>
                                    <input type="hidden" name="fgender" value="<?php echo $row['mem_gender']; ?>">
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="border rounded p-3 h-100">
                                    <label class="form-label fw-bold">Agama</label>
                                    <input type="text" class="form-control mt-2" id="religion" name="freligion" value="<?php echo $row['mem_religion']; ?>" readonly required>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="border rounded p-3 h-100">
                                    <label class="form-label fw-bold">Bangsa</label>
                                    <input type="text" class="form-control mt-2" id="race" name="frace" value="<?php echo $row['mem_race']; ?>" readonly required>
                                </div>
                            </div>
                            <div class="row g-3 mt-4">
                                <div class="col-md-6">
                                    <label for="email" class="form-label mt-4">Alamat Emel *</label>
                                    <input type="text" class="form-control" id="email" name="femail" value="<?php echo $row['mem_email']; ?>" required>
                                </div>
                            </div>
                            <div class="row g-3 mt-4">
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
                                    <textarea class="form-control" name="foaddr" id="exampleTextarea" rows="2" required><?php echo $row['mem_office_address']; ?></textarea>
                                </div>
                            </div>

                            <div class="row g-3 mt-3">
                                <div class="col-md-6">
                                    <label for="postcode" class="form-label">Poskod Pejabat *</label>
                                    <input type="text" class="form-control" name="fopostcode" id="postcode" value="<?php echo $row['mem_office_postcode']; ?>" required>
                                </div>
                                <div class="col-md-6">
                                    <label for="state" class="form-label">Negeri (Pejabat) *</label>
                                    <select class="form-select" name="fostate" id="state" required>
                                        <option value="<?php echo $row['stateid2']; ?>"><?php echo $row['state2_name']; ?></option>
                                        <?php
                                        $sql = "SELECT * FROM tb_state";
                                        $result = mysqli_query($con, $sql);
                                        while ($row2 = mysqli_fetch_array($result)) {
                                            echo "<option value = '" . $row2['state_id'] . "'>" . $row2['state_name'] . "</option>";
                                        }
                                        ?>
                                    </select>
                                </div>
                            </div>

                            <div class="row g-3 mt-3">
                                <div class="col-md-4">
                                    <label for="faxno" class="form-label">Nombor Fax</label>
                                    <input type="text" class="form-control" name="fnofax" id="faxno" value="<?php echo $row['mem_fax']; ?>">
                                    <small class="form-text text-muted">Letak " - " jika tiada</small>
                                </div>
                                <div class="col-md-4">
                                    <label for="nophone" class="form-label">Nombor Telefon *</label>
                                    <input type="text" class="form-control" name="fnotel" id="nophone" value="<?php echo $row['mem_tel']; ?>" required>
                                </div>
                                <div class="col-md-4">
                                    <label for="nohouse" class="form-label">Nombor Telefon Rumah</label>
                                    <input type="text" class="form-control" name="fnohouse" id="nohouse" value="<?php echo $row['mem_tel_house']; ?>">
                                    <small class="form-text text-muted">Letak " - " jika tiada</small>
                                </div>
                            </div>

                            <div class="row g-3 mt-3">
                                <div class="col-md-6">
                                    <label for="salary" class="form-label">Gaji Bulanan *</label>
                                    <div class="input-group">
                                        <span class="input-group-text">RM</span>
                                        <input type="text" class="form-control" name="fsalary" id="salary" value="<?php echo $row['mem_salary']; ?>" required>
                                    </div>
                                </div>
                            </div>

                            <div class="row g-3 mt-3">
                                <div class="col-md-6">
                                    <label for="bank" class="form-label">Nama Bank *</label>
                                    <select class="form-select" name="fbank" id="bank" required>
                                        <option value="<?php echo $row['bank_id']; ?>"><?php echo $row['bank_name']; ?></option>
                                        <?php
                                        $sql = "SELECT * FROM tb_bank";
                                        $result = mysqli_query($con, $sql);
                                        while ($row3 = mysqli_fetch_array($result)) {
                                            echo "<option value = '" . $row3['bank_id'] . "'>" . $row3['bank_name'] . "</option>";
                                        }
                                        ?>
                                    </select>
                                </div>
                                <div class="col-md-6">
                                    <label for="acc" class="form-label">Nombor Bank Akaun *</label>
                                    <input type="text" class="form-control" name="fnoacc" id="acc" value="<?php echo $row['mem_bank_no']; ?>" required>
                                </div>
                            </div>
                            <div class="row mt-4">
                                <div class="col-md-4">
                                    <a href="reapplyMembershipChecking.php" class="btn btn-secondary w-100"><i class="bi bi-arrow-left"></i> Ke Pemeriksaan Ahli</a>
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

            // Password confirmation check
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
        });
    </script>

</body>

</html>