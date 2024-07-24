<?php
session_start();

// Cek sesi user apakah ada
if (!isset($_SESSION['username']) || !isset($_SESSION['password']) || !isset($_SESSION['email'])) {
    echo "UPs.. Anda belum terdaftar.. silahkan daftar di http://nao.net";
    exit();
}

$username = $_SESSION['username'];
$password = $_SESSION['password'];

// Informasi share hosting yang ditampilkan di website ini
$subdomain = "http://$username.nao.net";
$ftp = "http://file.nao.net";
$ftp_host = "192.168.97.73";
$pma = "http://pma.nao.net";

// Informasi akun user baru
$content = "Website Subdomain: $subdomain\n";
$content = "FTP File Manager: $ftp\n";
$content .= "FTP Host: $ftp_host\n";
$content .= "FTP Username: $username\n";
$content .= "FTP Password: $password\n";
$content .= "phpMyAdmin: $pma\n";
$content .= "phpMyAdmin Username: $username\n";
$content .= "phpMyAdmin Password: $password\n";

// Store the content in a session variable for download
// Simpan content di variabel session untuk mendownload data ini kemudian.
$_SESSION['download_content'] = $content;
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Informasi Hosting</title>
    <style>
        body, html {
            height: 100%;
            margin: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            font-family: Arial, sans-serif;
            background-color: #f0f0f0;
        }
        .container {
            background-color: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        .container h1 {
            margin-bottom: 20px;
        }
        .container p {
            margin: 10px 0;
        }
        .container a {
            display: inline-block;
            margin-top: 20px;
            padding: 10px 20px;
            background-color: #007BFF;
            color: white;
            text-decoration: none;
            border-radius: 5px;
        }
        .container a:hover {
            background-color: #0056b3;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>User Information</h1>
        <p>Website Subdomain: <a href="<?= $subdomain ?>" target="_blank"><?= $subdomain ?></a></p>
        <p>FTP File Manager: <a href="<?= $ftp ?>" target="_blank"><?= $ftp ?></a></p>
        <p>FTP Host: <?= $ftp_host ?></p>
        <p>FTP Username: <?= $username ?></p>
        <p>FTP Password: <?= $password ?></p>
        <p>phpMyAdmin: <a href="<?= $pma ?>" target="_blank"><?= $pma ?></a></p>
        <p>phpMyAdmin Username: <?= $username ?></p>
        <p>phpMyAdmin Password: <?= $password ?></p>
        <a href="download_info.php">Download Info</a>
    </div>
</body>
</html>
