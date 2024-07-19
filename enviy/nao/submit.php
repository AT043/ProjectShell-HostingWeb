<?php
// Database credentials
$host = "localhost";
$user = "root";
$password = "admine123";
$dbname = "naohosting";

// Buat koneksi ke database
$conn = new mysqli($host, $user, $password, $dbname);

// Cek koneksi
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Fungsi generate password random untuk user
function generatePassword($length = 9) {
    $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $charactersLength = strlen($characters);
    $randomString = '';
    for ($i = 0; $i < $length; $i++) {
        $randomString .= $characters[rand(0, $charactersLength - 1)];
    }
    return $randomString;
}

// Cek apakah form sudah disubmit (klik tombol submit)
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Get form data
    $email = $conn->real_escape_string($_POST['email']);
    $username = $conn->real_escape_string($_POST['username']);

    //	Cek apakah username atau email telah digunakan sebelumnya
    $sql = "SELECT * FROM nao_user WHERE username='$username' OR email='$email'";
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        // Username dan Email telah digunakan
        echo "Username or email already used. Please choose a different username or email.";
		echo "Username atau email telah digunakan, silahkan gunakan yang lain.."
    } else {
        // Generate password
        $password = generatePassword();

        // Insert data ke database
        $sql = "INSERT INTO nao_user (username, email, password) VALUES ('$username', '$email', '$password')";

        if ($conn->query($sql) === TRUE) {
            echo "New record created successfully. Your password is: $password";
        } else {
            echo "Error: " . $sql . "<br>" . $conn->error;
        }
    }
}
// Tutup koneksi ke database
$conn->close();
?>
