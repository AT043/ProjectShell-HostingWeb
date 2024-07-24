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
		echo "Username atau email telah digunakan, silahkan gunakan yang lain..";
    } else {
        // Generate password
        $password = generatePassword();
        
        //Get tanggal submit
        $tgl_regis = date('Y-m-d H:i:s');

        // Insert data ke database
        $sql = "INSERT INTO nao_user (username, email, password, tgl_regis) VALUES ('$username', '$email', '$password', '$tgl_regis')";

        if ($conn->query($sql) === TRUE) {
			session_start();
            
            $_SESSION['username'] = $username;
            $_SESSION['password'] = $password;
            $_SESSION['email'] = $email;
            $_SESSION['form_submitted'] = true;
            
            header("Location: registered.php");
            exit();
        
        } else {
            echo " <p>Something wrong...</p>";
        }
    }
}
// Tutup koneksi ke database
$conn->close();
?>
