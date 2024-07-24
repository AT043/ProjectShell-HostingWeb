<?php
session_start();

// Check if admin is logged in
if (!isset($_SESSION['admin_loggedin']) || $_SESSION['admin_loggedin'] !== true) {
    header("Location: index.php");
    exit();
}

// Database credentials
$host = "localhost";
$user = "root";
$password = "admine123";
$dbname = "naohosting";

// Create connection
$conn = new mysqli($host, $user, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Handle delete request
if (isset($_POST['delete'])) {
    //$user_id = $conn->real_escape_string($_POST['id']);
    $username = $conn->real_escape_string(trim($_POST['username']));
    $sql = "DELETE FROM nao_user WHERE username='$username'";
    $conn->query($sql);
}

// Fetch user data
$sql = "SELECT id, username, email, tgl_regis FROM nao_user";
$result = $conn->query($sql);

$users = [];
while ($row = $result->fetch_assoc()) {
    $users[] = $row;
}

$conn->close();
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Page</title>
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
            width: 90%;
            max-width: 1200px;
            background-color: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 10px;
            border: 1px solid #ccc;
            text-align: left;
        }
        th {
            background-color: #007BFF;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .actions {
            text-align: center;
        }
        button {
            padding: 5px 10px;
            border: none;
            border-radius: 5px;
            background-color: #d9534f;
            color: white;
            cursor: pointer;
        }
        button:hover {
            background-color: #c9302c;
        }
        .filter {
            margin-bottom: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Admin Page</h1>
        <div class="filter">
            <label for="rows">Show rows: </label>
            <select id="rows" onchange="filterRows()">
                <option value="5">5</option>
                <option value="10">10</option>
                <option value="all">All</option>
            </select>
        </div>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Username</th>
                    <th>Email</th>
                    <th>Registration Date</th>
                    <th class="actions">Actions</th>
                </tr>
            </thead>
            <tbody id="userTable">
                <?php foreach ($users as $user): ?>
                    <tr>
                        <td><?= htmlspecialchars($user['id']) ?></td>
                        <td><?= htmlspecialchars($user['username']) ?></td>
                        <td><?= htmlspecialchars($user['email']) ?></td>
                        <td><?= htmlspecialchars($user['tgl_regis']) ?></td>
                        <td class="actions">
                            <form action="" method="post" style="display:inline;">
                                <input type="hidden" name="username" value="<?= htmlspecialchars($user['username']) ?>">
                                <button type="submit" name="delete">Delete</button>
                            </form>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <script>
        function filterRows() {
            const rows = document.getElementById('rows').value;
            const table = document.getElementById('userTable');
            const tr = table.getElementsByTagName('tr');
            for (let i = 0; i < tr.length; i++) {
                tr[i].style.display = '';
                if (rows !== 'all' && i >= rows) {
                    tr[i].style.display = 'none';
                }
            }
        }
        // Initialize the filter to show 5 rows by default
        filterRows();
    </script>
</body>
</html>
