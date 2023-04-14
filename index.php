<?php
// Display per gli errori
ini_set ('display_errors', 1);
ini_set('display_startupt_errors',1);
error_reporting(E_ALL);

require 'vendor/autoload.php'; // Carico il file autoload.php

$servername = "localhost";
$username = "<YOUR_URSERNAME>";
$password = "<YOUR_PASSWORD>"; // Questa coincide anche al nome del proprio database sia per MySQL che per MongoDB;


// Creo la connessione a MySQL
$conn = new mysqli($servername, $username, $password);

// Controllo la connessione
if ($conn->connect_error) {
    die("Connessione fallita a MySQL: " . $conn->connect_error);
}
else{
    print "Connesso a MySql";
}


// Creo la connessione a MongoDb
$m = new MongoDB\Client('mongodb://' . $username . ':' . $password . '@localhost:27017/' . $password);
$db = $m->$password; 
$collection=$db->test;
$result=$collection->find();

foreach ($result as $document) {
    echo $document["Ciao!"] . "\n";
}

echo "Connesso a MongoDb!\n";
?>