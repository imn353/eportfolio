<?php

//Set DB Parameter
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "db_kada";

//Connect DB
$con = mysqli_connect($servername, $username, $password, $dbname);

//Connection Check (individual project)
if (!$con)
{
	die("Failed to connect to MySQL" . mysqli_connect_error());
}

?>