<?php

if(!session_id()){

    session_start();
}

if(!isset($_SESSION['u_member_id'])) {

    header("location:index.php");
}

?>