<?php
include 'bodNav.php';

$query = "SELECT mw_id, mw_member_id, mem_pf, mem_name, mw_application_date
          FROM tb_member_withdrawal
          LEFT JOIN tb_member ON tb_member_withdrawal.mw_member_id = tb_member.mem_id
          WHERE mw_status = 1";

$result = mysqli_query($con, $query);
?>

<div class="content">
    <div class="container-fluid">
        <div class="row mb-4">
            <div class="col-md-8"><br>
                <h2 class="text-primary">Senarai Permohonan Berhenti Keahlian</h2>
            </div>
        </div>
        <div class="card shadow">
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table table-hover" id="loanApplicationTable">
                        <thead>
                            <tr>
                                <th>No Permohonan</th>
                                <th>No Anggota</th>
                                <th>No PF</th>
                                <th>Nama</th>
                                <th>Tarikh Permohonan</th>
                                <th>Tindakan</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php
                            while ($row = mysqli_fetch_array($result)) {
                                echo "<tr>";
                                echo "<td>" . $row['mw_id'] . "</td>";
                                echo "<td>" . $row['mw_member_id'] . "</td>";
                                echo "<td>" . $row['mem_pf'] . "</td>";
                                echo "<td>" . $row['mem_name'] . "</td>";
                                echo "<td>" . date('d M Y', strtotime($row['mw_application_date'])) . "</td>";
                                echo "<td>
                                        <a href='bodMembershipWithdrawalDetail.php?withdrawal_id=" . $row['mw_id'] . "' class='btn btn-info btn-sm'><i class='fas fa-info-circle'></i></a>
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
        $('#loanApplicationTable').DataTable({
            responsive: true,
            order: [
                [4, 'desc']
            ], 
            language: {
                search: "<i class='fas fa-search'></i>",
                searchPlaceholder: "Search applications..."
            },
            dom: '<"row"<"col-md-6"l><"col-md-6"f>>rtip'
        });
    });
</script>
</body>

</html>