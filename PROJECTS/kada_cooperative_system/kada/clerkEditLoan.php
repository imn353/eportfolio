<?php
include 'clerkNav.php';

$sql = 'SELECT mem_id, mem_name from tb_member;';

$result = mysqli_query($con, $sql);

?>
<br>
<div class="content">
    <div class="container">
        <h2>Senarai Ahli</h2>
        <br>
        <table class="table">
            <thead>
                <tr>
                    <th scope="col">No Staf</th>
                    <th scope="col">Nama</th>
                    <th scope="col">Pembiayaan Aktif</th>
                    <th scope="col"></th>
                </tr>
            </thead>
            <tbody>
                <?php
                while ($row = mysqli_fetch_array($result)) {
                    $sql_count = "SELECT COUNT(la_id) as num_loan FROM tb_loan_application WHERE la_member_id = {$row['mem_id']} AND la_status = 4;";
                    $count_result = mysqli_query($con, $sql_count);
                    $count_row = mysqli_fetch_assoc($count_result);
                    if ($count_row['num_loan'] > 0) {
                        echo '<tr>';
                        echo '<td>' . $row['mem_id'] . '</td>';
                        echo '<td>' . $row['mem_name'] . '</td>';

                        echo '<td>' . $count_row['num_loan'] . '</td>';

                        echo '<td>';
                        echo '<a href="clerkViewMemberLoan.php?id=' . $row['mem_id'] . '" class="btn btn-primary">Lihat</a>';
                        echo '</td>';
                        echo '</tr>';
                    }
                }
                mysqli_close($con);
                ?>
            </tbody>
        </table>
    </div>
</div>