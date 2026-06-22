<?php
include 'clerkNav.php';

$query = "SELECT mem_id, mem_ic, mem_pf, mem_name, mem_position, mem_join_date FROM tb_member";
$result = $con->query($query);

$members = [];
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $members[] = $row;
    }
}

$columnNames = [
    'mem_id' => 'ID Staf',
    'mem_ic' => 'Nombor IC',
    'mem_pf' => 'Nombor PF',
    'mem_name' => 'Nama',
    'mem_position' => 'Jawatan',
    'mem_join_date' => 'Tarikh Sertai'
];
?>

<div class="content">
    <div class="container-fluid mt-4">
        <h2>Senarai Ahli</h2>
        <div class="table-container">
            <table class="table table-striped table-bordered">
                <thead>
                    <tr>
                        <?php

                        if (!empty($members)) {
                            foreach (array_keys($members[0]) as $column) {
                                echo "<th>" . htmlspecialchars($columnNames[$column]) . "</th>";
                            }
                            echo "<th>Tindakan</th>"; 
                        } else {
                            echo "<th>Tiada data tersedia</th>";
                        }
                        ?>
                    </tr>
                </thead>
                <tbody>
                    <?php

                    if (!empty($members)) {
                        foreach ($members as $member) {
                            echo "<tr>";
                            foreach ($member as $key => $value) {
                                echo "<td>" . htmlspecialchars($value) . "</td>";
                            }

                            echo "<td>
                                <form action='viewMemberDetail.php' method='get'>
                                    <input type='hidden' name='mem_id' value='" . htmlspecialchars($member['mem_id']) . "'>
                                    <button type='submit' class='btn btn-primary btn-sm'>Lihat Butiran</button>
                                </form>
                            </td>";
                            echo "</tr>";
                        }
                    } else {
                        echo "<tr><td colspan='100%' class='text-center'>Tiada senarai ahli.</td></tr>";
                    }
                    ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
</body>

</html>