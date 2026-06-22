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
                <h1 class="card-title text-center mb-0">Memeriksa Permohonan Ahli</h1>
            </div>
            <div class="card-body px-5 py-4">
                <form method="GET" action="reapplyMembership.php" class="needs-validation" novalidate>
                    <div class="section-personal-info mb-4">
                        <h2 class="section-title mb-3">Memeriksa Maklumat Peribadi</h2>
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label for="number_staff" class="form-label">Nombor Kakitangan</label>
                                <input type="text" class="form-control" id="number_staff" name="fnostaff" placeholder="cth: 12345" required>
                                <div class="invalid-feedback">Sila masukkan nombor kakitangan.</div>
                            </div>
                        </div>
                    </div>
                    <div class="row mt-4">
                        <div class="col-md-4">
                            <a href="index.php" class="btn btn-secondary w-100"><i class="bi bi-arrow-left"></i> Ke Login</a>
                        </div>
                        <div class="col-md-4">
                            <button type="submit" class="btn btn-primary w-100">Seterusnya <i class="bi bi-arrow-right"></i></button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</body>

</html>