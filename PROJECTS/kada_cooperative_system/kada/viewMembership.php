<?php
include 'clerkNav.php';

$query = "SELECT m_app_id, m_ic, m_pf, m_name, m_appdate, app_desc FROM tb_membership
          LEFT JOIN tb_appstatus ON tb_membership.m_appstatus = tb_appstatus.app_id";
$result = $con->query($query);

$memberships = $result->fetch_all(MYSQLI_ASSOC);

$columnNames = [
    'm_app_id' => 'ID Permohonan',
    'm_ic' => 'Nombor IC',
    'm_pf' => 'Nombor PF',
    'm_name' => 'Nama',
    'm_appdate' => 'Tarikh Permohonan',
    'app_desc' => 'Status'
];

?>
<div class="content">
    <div class="container-fluid mt-4">
        <h2>Senarai Pemohonan Keahlian</h2>
        <div class="table-container">
            <table class="table table-striped table-bordered">
                <thead>
                    <tr>
                        <?php
                        if (!empty($memberships)) {
                            foreach (array_keys($memberships[0]) as $column) {
                                echo "<th>" . htmlspecialchars($columnNames[$column]) . "</th>";
                            }
                        } else {
                            echo "<th>Tiada data tersedia</th>";
                        }
                        ?>
                    </tr>
                </thead>
                <tbody>
                    <?php
                    if (!empty($memberships)) {
                        foreach ($memberships as $membership) {
                            echo "<tr>";
                            foreach ($membership as $value) {
                                echo "<td>" . htmlspecialchars($value) . "</td>";
                            }
                            echo "</tr>";
                        }
                    } else {
                        echo "<tr><td colspan='100%'>Tiada keahlian ditemui.</td></tr>";
                    }
                    ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
</body>

</html>