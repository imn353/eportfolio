<?php include 'db_connect.php'; ?>
<?php include 'clerkSession.php'; ?>
<?php include 'layout.php'; ?>

<style>
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
        padding: 8px 15px;
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

    .content {
        margin-left: 260px;
        transition: margin-left 0.3s ease-in-out;
        padding: 20px;
    }

    .content.expanded {
        margin-left: 20px;
    }

    #toggleNav {
        position: fixed;
        left: 260px;
        top: 20px;
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

    .stats-card {
        background-color: #fff;
        border-radius: 10px;
        box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        text-align: center;
        padding: 20px;
    }

    .chart-container {
        height: 300px;
    }

    .table-container {
        margin-top: 20px;
    }

    .table th {
        background-color: #457b9d;
        color: white;
    }

    .form-label {
        font-weight: bold;
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
<div class="no-print">
    <button id="toggleNav" >
        <i class="fas fa-chevron-left"></i>
    </button>
    <div class="navbar no-print">
        <a class="navbar-brand" href="#">
            <img src="img/logo.png" alt="KKK Logo" style="width: 100%; max-width: 200px; height: auto;">
            <div class="navbar-title">Kooperasi Kakitangan <br> KADA Kelantan Berhad</div>
        </a>
        <a href="clerkDashboard.php"><i class="fas fa-tachometer-alt"></i>Papan Pemuka</a>
        <a href="viewMember.php"><i class="fas fa-address-book"></i>Senarai Ahli</a>
        <a href="viewMembership.php"><i class="fas fa-users"></i>Senarai Permohonan Keahlian</a>
        <a href="viewLoan.php"><i class="fas fa-hand-holding-usd"></i>Senarai Permohonan Pembiayaan</a>
        <a href="updatePolicy.php"><i class="fas fa-file-alt"></i>Kemaskini Polisi</a>
        <a href="clerkEditShare.php"><i class="fas fa-chart-pie"></i>Kemaskini Saham</a>
        <a href="clerkEditLoan.php"><i class="fas fa-money-bill-wave"></i>Kemaskini Bayaran Pembiayaan</a>
        <a href="clerkGenerateReport.php"><i class="fas fas fa-chart-bar"></i>Penjanaan Laporan</a>
        <a href="logoutProcess.php" class="mt-auto"><i class="fas fa-sign-out-alt"></i>Log Keluar</a>
    </div>
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