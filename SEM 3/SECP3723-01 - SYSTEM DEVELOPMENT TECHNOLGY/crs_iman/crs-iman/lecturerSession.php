<?php

if(!session_id()){

    session_start();
}

if(!isset($_SESSION['u_matric'])) {

    header("location:index.php");
    
}elseif($_SESSION['u_utype'] != 2){

    header("location:index.php");
}

?>