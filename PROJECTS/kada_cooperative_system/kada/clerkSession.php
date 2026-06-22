<?php

if(!session_id()){

    session_start();
}

if(!isset($_SESSION['u_clerk_id'])) {

    header("location:index.php");
}

?>