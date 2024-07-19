<?php
session_start();

// Check if download content is set
if (isset($_SESSION['download_content']) || !isset($_SESSION['form_submitted']) || $_SESSION['form_submitted'] == true || !isset($_SESSION['download_content'])) {
    $content = $_SESSION['download_content'];
    $filename = "user_info.txt";

    // Send headers to initiate file download
    header('Content-Type: text/plain');
    header('Content-Disposition: attachment; filename="' . $filename . '"');
    header('Content-Length: ' . strlen($content));

    // Output the content
    echo $content;
    exit();
} else {
    echo "User belum terdaftar!.";
}
?>
