<?php include 'db_connect.php'; ?>
<?php include 'memberSession.php'; ?>
<?php include 'layout.php'; ?>

<style>
    body {
        background-color: #f8f9fa;
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    }

    .navbar {
        width: 240px;
        position: fixed;
        height: 100%;
        background: linear-gradient(135deg, #1d3557, #457b9d);
        color: white;
        padding: 20px 15px;
        box-shadow: 2px 0 10px rgba(0, 0, 0, 0.1);
        display: flex;
        flex-direction: column;
        align-items: center;
        transition: transform 0.3s ease-in-out;
    }

    .navbar.collapsed {
        transform: translateX(-240px);
    }

    .navbar-brand {
        font-weight: bold;
        font-size: 1.2rem;
        margin-bottom: 20px;
        display: flex;
        flex-direction: column;
        align-items: center;
        color: #f1faee;
        text-transform: uppercase;
        letter-spacing: 2px;
        border-bottom: 2px solid rgba(255, 255, 255, 0.3);
        padding-bottom: 10px;
    }

    .navbar-brand img {
        width: 100%;
        max-width: 180px;
        height: auto;
        margin-bottom: 10px;
    }

    .navbar-title {
        font-size: 0.75rem;
        font-weight: 500;
        text-align: center;
        color: #f1faee;
        line-height: 1.4;
        max-width: 180px;
        word-wrap: break-word;
    }

    .navbar a {
        color: white;
        text-decoration: none;
        display: flex;
        align-items: center;
        padding: 12px 15px;
        margin: 8px 0;
        font-size: 0.7rem;
        font-weight: 500;
        border-radius: 8px;
        transition: background 0.3s ease, transform 0.2s ease;
        width: 100%;
    }

    .navbar a:hover {
        background-color: rgba(255, 255, 255, 0.2);
        transform: translateX(10px);
        box-shadow: 2px 2px 8px rgba(0, 0, 0, 0.1);
    }

    .navbar a i {
        margin-right: 12px;
        font-size: 1.2rem;
    }

    #toggleNav {
        position: fixed;
        left: 250px;
        top: 5px;
        z-index: 1000;
        background-color: #1d3557;
        color: white;
        border: none;
        padding: 10px;
        cursor: pointer;
        transition: left 0.3s ease-in-out, transform 0.3s ease-in-out;
        border-radius: 50%;
        width: 40px;
        height: 40px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    #toggleNav.collapsed {
        left: 20px;
        transform: rotate(180deg);
    }

    .content {
        margin-left: 260px;
        padding: 20px;
        transition: margin-left 0.3s ease-in-out;
    }

    .content.expanded {
        margin-left: 20px;
    }

    .stats-card {
        background-color: #fff;
        border-radius: 15px;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
        transition: transform 0.3s ease, box-shadow 0.3s ease;
        overflow: hidden;
    }

    .stats-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 6px 25px rgba(0, 0, 0, 0.15);
    }

    .stats-card h5 {
        color: #1d3557;
        font-weight: 600;
        margin-bottom: 10px;
    }

    .stats-card h2 {
        color: #457b9d;
        font-weight: 700;
    }

    .section-title {
        color: #1d3557;
        font-weight: 700;
        margin-bottom: 30px;
        position: relative;
        padding-bottom: 10px;
    }

    .section-title::after {
        content: '';
        position: absolute;
        left: 0;
        bottom: 0;
        width: 50px;
        height: 3px;
        background-color: #457b9d;
    }


    .form-card {
        background-color: #fff;
        border-radius: 15px;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
        padding: 30px;
        margin-bottom: 30px;
    }

    .btn-primary {
        background-color: #457b9d;
        border-color: #457b9d;
    }

    .btn-primary:hover {
        background-color: #1d3557;
        border-color: #1d3557;
    }
</style>

<button id="toggleNav">
    <i class="fas fa-chevron-left"></i>
</button>
<div class="navbar">
    <a class="navbar-brand" href="memberDashboard.php">
        <img src="img/logo.png" alt="KKK Logo" style="width: 100%; max-width: 200px; height: auto;">
        <div class="navbar-title">Kooperasi Kakitangan <br> KADA Kelantan Berhad</div>
    </a>
    <a href="memberDashboard.php"><i class="fas fa-tachometer-alt"></i>Papan Pemuka</a>
    <a href="memberApplyLoan.php"><i class="fas fa-hand-holding-usd"></i>Permohonan Pembiayaan</a>
    <a href="memberViewLoanHistory.php"><i class="fas fa-history"></i>Sejarah Pembiayaan</a>
    <a href="memberWithdraw.php"><i class="fas fa-door-open"></i>Permohonan Berhenti Ahli</a>
    <a href="logoutProcess.php" class="mt-auto"><i class="fas fa-sign-out-alt"></i>Log Keluar</a>
</div>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        const navbar = document.querySelector('.navbar');
        const content = document.querySelector('.content');
        const toggleBtn = document.getElementById('toggleNav');

        toggleBtn.addEventListener('click', function() {
            navbar.classList.toggle('collapsed');
            content.classList.toggle('expanded');
            toggleBtn.classList.toggle('collapsed');
        });
    });
</script>