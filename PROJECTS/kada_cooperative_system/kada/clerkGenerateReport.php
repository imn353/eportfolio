<?php
include 'clerkNav.php';
?>

<body>
    <div class="content">
        <div class="container mt-5">
            <h2>Penjanaan Laporan</h2>
            <form method="POST" action="clerkDownloadReport.php">
                <div class="mb-3">
                    <label for="reportType" class="form-label">Pilih Jenis Laporan</label>
                    <select class="form-select" id="reportType" name="reportType" required>
                        <option value="">Pilih...</option>
                        <option value="monthly">Laporan Bulanan</option>
                        <option value="yearly">Laporan Tahunan</option>
                    </select>
                </div>

                <div class="mb-3" id="monthInput" style="display: none;">
                    <label for="month" class="form-label">Pilih Bulan</label>
                    <input type="month" class="form-control" id="month" name="month">
                </div>

                <div class="mb-3" id="yearInput" style="display: none;">
                    <label for="year" class="form-label">Pilih Tahun</label>
                    <input type="number" class="form-control" id="year" name="year" min="2000" max="2099">
                </div>

                <button type="submit" class="btn btn-primary">Jana Laporan</button>
            </form>
        </div>
    </div>

    <script>

        document.getElementById('reportType').addEventListener('change', function() {
            const reportType = this.value;
            const monthInput = document.getElementById('monthInput');
            const yearInput = document.getElementById('yearInput');

            if (reportType === 'monthly') {
                monthInput.style.display = 'block';
                yearInput.style.display = 'none';
                document.getElementById('month').required = true;
                document.getElementById('year').required = false;
            } else if (reportType === 'yearly') {
                monthInput.style.display = 'none';
                yearInput.style.display = 'block';
                document.getElementById('month').required = false;
                document.getElementById('year').required = true;
            } else {
                monthInput.style.display = 'none';
                yearInput.style.display = 'none';
                document.getElementById('month').required = false;
                document.getElementById('year').required = false;
            }
        });
    </script>
</body>

</html>