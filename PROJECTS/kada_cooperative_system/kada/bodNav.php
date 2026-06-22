<?php include 'db_connect.php'; ?>
<?php include 'bodSession.php'; ?>
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
        /* Adjusted for better fit */
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
        /* Ensures alignment with sidebar width */
        height: auto;
        margin-bottom: 10px;
        /* Space between logo and title */
    }

    .navbar-title {
        font-size: 0.75rem;
        /* Adjusted for readability */
        font-weight: 500;
        text-align: center;
        color: #f1faee;
        line-height: 1.4;
        max-width: 180px;
        /* Matches the logo's width */
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
        transition: margin-left 0.3s ease-in-out;
        padding: 20px;
    }

    .content.expanded {
        margin-left: 20px;
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

    .text-primary {
        color: #1d3557 !important;
        transition: all 0.3s ease;
    }

    .card-body {
        padding: 2rem;
    }

    .card-header {
        background-color: #f8f9fa;
        border-bottom: 1px solid #dee2e6;
        padding: 15px 20px;
    }

    .card {
        border: none;
        border-radius: 10px;
    }
    .card-title {
        color: #1d3557;
        border-bottom: 2px solid #457b9d;
        padding-bottom: 10px;
        margin-bottom: 20px;
    }

    .table thead th {
        background-color:rgb(39, 74, 123);
        color: white;
        border-bottom: 2px solid #457b9d;
    }

    .table-hover tbody tr:hover {
        background-color: rgba(69, 123, 157, 0.1);
    }

    .btn-info {
        background-color:rgb(49, 153, 219);
        border-color: #457b9d;
    }

    .btn-info:hover {
        background-color: #1d3557;
        border-color: #1d3557;
    }

    .btn-lg {
        padding: 0.75rem 1.5rem;
        font-size: 1.1rem;
        border-radius: 0.5rem;
        transition: all 0.3s ease;
    }

    .btn-outline-danger {
        color: #dc3545;
        border-color: #dc3545;
    }

    .btn-outline-danger:hover {
        color: #fff;
        background-color: #dc3545;
        border-color: #dc3545;
        box-shadow: 0 4px 8px rgba(220, 53, 69, 0.3);
    }

    .btn-outline-success {
        color: #28a745;
        border-color: #28a745;
    }

    .btn-outline-success:hover {
        color: #fff;
        background-color: #28a745;
        border-color: #28a745;
        box-shadow: 0 4px 8px rgba(40, 167, 69, 0.3);
    }

    .btn-lg:focus {
        outline: none;
        box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
    }


    .btn-outline-primary {
        color: #457b9d;
        border-color: #457b9d;
    }
    .btn-outline-primary:hover {
        background-color: #457b9d;
        color: white;
    }

</style>
<button id="toggleNav">
    <i class="fas fa-chevron-left"></i>
</button>
<div class="navbar">
    <a class="navbar-brand" href="#">
        <img src="img/logo.png" alt="KKK Logo" style="width: 100%; max-width: 200px; height: auto;">
        <div class="navbar-title">Kooperasi Kakitangan <br> KADA Kelantan Berhad</div>
    </a>
    <a href="bodDashboard.php"><i class="fas fa-tachometer-alt"></i>Papan Pemuka</a>
    <a href="bodApproveLoanList.php"><i class="fas fa-hand-holding-usd"></i>Luluskan Permohonan Pembiayaan</a>
    <a href="bodApproveMembershipList.php"><i class="fas fa-users"></i>Luluskan Permohonan Keahlian</a>
    <a href="bodMembershipWithdrawalList.php"><i class="fas fa-user-minus"></i>Luluskan Permohonan Berhenti Keahlian</a>
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