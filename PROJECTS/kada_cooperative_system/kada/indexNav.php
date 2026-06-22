<?php
include 'layout.php';
include 'db_connect.php';
?>

<style>
    .header {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        background: linear-gradient(135deg, #1d3557, #457b9d);
        z-index: 1000;
        padding: 15px 0;
    }

    .header-content {
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .header-brand {
        font-size: 1.4rem;
        font-weight: 600;
        color: #f1faee;
        display: flex;
        align-items: center;
        text-decoration: none;
    }

    .header-brand img {
        height: 50px;
        width: auto;
        margin-right: 15px;
    }

    .header-info {
        color: #f1faee;
        font-size: 1rem;
    }
</style>

<header class="header">
    <div class="container">
        <div class="header-content">
            <a class="header-brand" href="index.php">
                <img src="img/logo.png" alt="Logo" style="background-color: transparent;">
                Koperasi Kakitangan KADA Kelantan Berhad
            </a>
        </div>
    </div>
</header>
