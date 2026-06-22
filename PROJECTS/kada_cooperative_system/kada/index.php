<?php
include 'layout.php';
include 'db_connect.php';
?>

<style>
    body {
        background: linear-gradient(135deg, #1d3557, #457b9d);
        height: 100vh;
        display: flex;
        justify-content: center;
        align-items: center;
        color: #f1faee;
    }

    .login-card {
        background: rgba(255, 255, 255, 0.9);
        border-radius: 15px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
        overflow: hidden;
        max-width: 400px;
        width: 100%;
        position: relative;
    }

    .login-card .card-header {
        background: linear-gradient(135deg, #1d3557, #457b9d);
        color: white;
        text-align: center;
        padding: 20px 15px;
        position: relative;
        border-bottom: none;
    }

    .login-card .card-header img {
        width: 80px;
        margin-bottom: 10px;
        border-radius: 50%;
        border: 3px solid #a8dadc;
        box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
    }

    .login-card .card-header h5 {
        margin: 0;
        font-weight: 600;
    }

    .login-card .card-body {
        padding: 25px;
        background: #f8f9fa;
    }

    .btn-primary {
        background-color: #1d3557;
        border: none;
        border-radius: 8px;
        padding: 10px;
        font-size: 1rem;
        font-weight: 500;
        transition: all 0.3s ease;
    }

    .btn-primary:hover {
        background-color: #457b9d;
        box-shadow: 0 4px 15px rgba(69, 123, 157, 0.5);
    }

    .text-primary {
        color: #1d3557 !important;
        transition: all 0.3s ease;
    }

    .text-primary:hover {
        color: #457b9d !important;
        text-decoration: underline;
    }

    .text-center a {
        font-size: 0.9rem;
    }
    
    .account-popup {
        display: none;
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-color: rgba(0, 0, 0, 0.5);
        justify-content: center;
        align-items: center;
        z-index: 1000;
    }

    .popup-content {
        background-color: white;
        padding: 30px;
        border-radius: 15px;
        text-align: center;
        max-width: 400px;
        width: 90%;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
        transform: scale(0.9);
        opacity: 0;
        transition: all 0.3s ease;
    }

    .popup-content.active {
        transform: scale(1);
        opacity: 1;
    }

    .popup-content h4 {
        color: #1d3557;
        margin-bottom: 20px;
        font-size: 1.5rem;
    }

    .popup-content .btn {
        display: block;
        width: 100%;
        margin-bottom: 15px;
        padding: 12px;
        font-size: 1rem;
        transition: all 0.3s ease;
    }

    .popup-content .btn:hover {
        transform: translateY(-3px);
        box-shadow: 0 4px 15px rgba(69, 123, 157, 0.5);
    }

    .close-popup {
        position: absolute;
        top: 10px;
        right: 15px;
        font-size: 1.5rem;
        color: #1d3557;
        cursor: pointer;
        transition: all 0.3s ease;
    }

    .close-popup:hover {
        color: #457b9d;
    }
</style>

<div class="login-card">
    <div class="card-header">
        <img src="img/logo.png" alt="KKK Logo">
        <h5>Kooperasi Kakitangan<br>KADA Kelantan Berhad</h5>
    </div>
    <div class="card-body">
        <h3 class="text-center text-dark">Log Masuk</h3>
        <form class="form mt-4" action="loginProcess.php" method="POST">
            <div class="form-group mb-3">
                <label for="id" class="text-dark">No Kakitangan:</label>
                <input type="id" name="id" id="id" class="form-control" placeholder="Masukkan No Kakitangan" required>
            </div>
            <div class="form-group mb-3">
                <label for="password" class="text-dark">Katalaluan:</label>
                <div class="input-group">
                    <input type="password" name="pwd" id="password" class="form-control" placeholder="Masukkan Katalaluan" required>
                    <button class="btn btn-outline-secondary" type="button" id="togglePassword">
                        <i class="bi bi-eye"></i>
                    </button>
                </div>
            </div>
            <div class="form-group mb-4">
                <input type="submit" name="submit" class="btn btn-primary w-100" value="Log Masuk">
            </div>
            <div class="text-center">
                <p class="text-dark">Tiada akaun / Bukan Ahli? <a href="#" id="accountOptions" class="text-primary">Daftar di sini</a></p>
            </div>
        </form>
    </div>
</div>

<div id="accountPopup" class="account-popup">
    <div class="popup-content">
        <span class="close-popup">&times;</span>
        <h4>Pilih Pilihan Anda</h4>
        <a href="reapplyMembershipChecking.php" class="btn btn-primary mb-2">Sudah Ada Akaun Tetapi Tidak Aktif</a>
        <a href="applyMembership.php" class="btn btn-primary">Pengguna Baru</a>
    </div>
</div>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        const passwordInput = document.getElementById('password');
        const togglePassword = document.getElementById('togglePassword');

        togglePassword.addEventListener('click', function() {
            const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
            passwordInput.setAttribute('type', type);
            this.innerHTML = type === 'password' ? '<i class="bi bi-eye"></i>' : '<i class="bi bi-eye-slash"></i>';
        });

        const accountOptions = document.getElementById('accountOptions');
        const accountPopup = document.getElementById('accountPopup');
        const popupContent = accountPopup.querySelector('.popup-content');
        const closePopup = accountPopup.querySelector('.close-popup');

        accountOptions.addEventListener('click', function(e) {
            e.preventDefault();
            accountPopup.style.display = 'flex';
            setTimeout(() => {
                popupContent.classList.add('active');
            }, 10);
        });

        function hidePopup() {
            popupContent.classList.remove('active');
            setTimeout(() => {
                accountPopup.style.display = 'none';
            }, 300);
        }

        accountPopup.addEventListener('click', function(e) {
            if (e.target === this) {
                hidePopup();
            }
        });

        closePopup.addEventListener('click', hidePopup);
    });
</script>

</body>

</html>