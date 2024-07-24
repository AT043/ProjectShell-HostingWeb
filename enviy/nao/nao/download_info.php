<?php
session_start();

// Check if download content is set
// Cek apakah barang yg dikirim masih oke, setelah dipastikan aman.. gas!
if (isset($_SESSION['download_content'])) {
    $content = $_SESSION['download_content'];
    $filename = "user_info.txt";

    // Send headers to initiate file download
    // buat download filenye
    header('Content-Type: text/plain');
    header('Content-Disposition: attachment; filename="' . $filename . '"');
    header('Content-Length: ' . strlen($content));

    // Tampilkan konten download
    echo $content;
    exit();
} else {
    echo "User belum terdaftar! Silahkan daftar di http://nao.net.";
}
?>
