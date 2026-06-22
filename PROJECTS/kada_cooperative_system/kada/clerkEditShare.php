<?php include 'clerkNav.php';

$sql = 'SELECT * from tb_member;';

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
                    <th scope="col">No Staff</th>
                    <th scope="col">Modah Syer</th>
                    <th scope="col">Modal Yuran</th>
                    <th scope="col">Simpanan Tetap</th>
                    <th scope="col">Tabung Anggota</th>
                    <th scope="col">Simpanan Anggota</th>
                    <th scope="col"></th>
                </tr>
            </thead>
            <tbody>
                <?php
                while ($row = mysqli_fetch_array($result)) {
                    echo '<tr>';
                    echo '<td>' . $row['mem_id'] . '</td>';
                    echo '<td>' . $row['mem_modal_share'] . '</td>';
                    echo '<td>' . $row['mem_modal_fee'] . '</td>';
                    echo '<td>' . $row['mem_fixed_saving'] . '</td>';
                    echo '<td>' . $row['mem_charity_fund'] . '</td>';
                    echo '<td>' . $row['mem_saving'] . '</td>';
                    echo '<td>';
                    echo '<a href = clerkViewShare.php?id=' . $row['mem_id'] . "' class = 'btn btn-primary'> Kemaskini </a>";
                    echo '</td>';
                    echo '</tr>';
                }
                mysqli_close($con);
                ?>
            </tbody>
        </table>
    </div>
</div>