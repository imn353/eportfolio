<?php
include 'bodNav.php';

$sql = "SELECT * FROM tb_membership
    LEFT JOIN tb_state AS state1 ON tb_membership.m_state = state1.state_id
    LEFT JOIN tb_state AS state2 ON tb_membership.m_office_state = state2.state_id
    LEFT JOIN tb_bank ON tb_membership.m_bank = tb_bank.bank_id
    LEFT JOIN tb_appstatus ON tb_membership.m_appstatus = tb_appstatus.app_id
    WHERE m_appstatus = '1'";

$result = mysqli_query($con, $sql);
?> 

<div class="content">
    <div class="container-fluid">
    <div class="row mb-4">
        <div class="col-md-8"><br>
        <h2 class="text-primary">Senarai Ahli</h2>
        </div>
    </div>
    <div class="card shadow">
        <div class="card-body">
        <div class="table-responsive">
            <table class="table table-hover" id="memberTable">
            <thead>
                <tr>
                <th>ID Pemohon</th>
                <th>No. Staf</th>
                <th>Nama</th>
                <th>Email</th>
                <th>No. Tel</th>
                <th>Tarikh Permohonan</th>
                <th>Tindakan</th>
                </tr>
            </thead>
            <tbody>
                <?php 
                while($row = mysqli_fetch_array($result)) {
                echo "<tr>";
                echo "<td>".$row['m_app_id']."</td>";
                echo "<td>".$row['m_nostaff']."</td>";
                echo "<td>".$row['m_name']."</td>";
                echo "<td>".$row['m_email']."</td>";
                echo "<td>".$row['m_tel']."</td>";
                echo "<td>".date('d M Y', strtotime($row['m_appdate']))."</td>";
                echo "<td>
                    <a href='bodApproveMembershipDetail.php?membership_id=".$row['m_app_id']."' class='btn btn-info btn-sm mr-2'><i class='fas fa-info-circle'></i></a>
                      </td>";
                echo "</tr>";
                }
                ?>
            </tbody>
            </table>
        </div>
        </div>
    </div>
    </div>
</div>

<script>
$(document).ready(function() {
    $('#memberTable').DataTable({
    responsive: true,
    order: [[5, 'desc']],
    language: {
        search: "<i class='fas fa-search'></i>",
        searchPlaceholder: "Cari ahli..."
    },
    dom: '<"row"<"col-md-6"l><"col-md-6"f>>rtip'
    });
});
</script>

</body>
</html>
