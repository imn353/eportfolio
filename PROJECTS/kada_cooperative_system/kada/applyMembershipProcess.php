<?php
include('db_connect.php');

// Function to sanitize
function sanitizeInput($input)
{
    global $con;
    return mysqli_real_escape_string($con, trim($input));
}

$memberData = [
    'fnostaff' => sanitizeInput($_POST['fnostaff']),
    'fic' => sanitizeInput($_POST['fic']),
    'fnopf' => sanitizeInput($_POST['fnopf']),
    'fname' => sanitizeInput($_POST['fname']),
    'fstatus' => sanitizeInput($_POST['fstatus']),
    'fhaddr' => sanitizeInput($_POST['fhaddr']),
    'fhpostcode' => sanitizeInput($_POST['fhpostcode']),
    'fhstate' => sanitizeInput($_POST['fhstate']),
    'fgender' => sanitizeInput($_POST['fgender']),
    'freligion' => sanitizeInput($_POST['freligion']),
    'frace' => sanitizeInput($_POST['frace']),
    'femail' => sanitizeInput($_POST['femail']),
    'fpass' => $_POST['fpass'],
    'fposi' => sanitizeInput($_POST['fposi']),
    'fgradeposi' => sanitizeInput($_POST['fgradeposi']),
    'foaddr' => sanitizeInput($_POST['foaddr']),
    'fopostcode' => sanitizeInput($_POST['fopostcode']),
    'fostate' => sanitizeInput($_POST['fostate']),
    'fnofax' => sanitizeInput($_POST['fnofax']),
    'fnotel' => sanitizeInput($_POST['fnotel']),
    'fnohouse' => sanitizeInput($_POST['fnohouse']),
    'fsalary' => sanitizeInput($_POST['fsalary']),
    'fbank' => sanitizeInput($_POST['fbank']),
    'fnoacc' => sanitizeInput($_POST['fnoacc']),
    'entryfee' => sanitizeInput($_POST['entryfee']),
    'share' => sanitizeInput($_POST['share']),
    'modalfee' => sanitizeInput($_POST['modalfee']),
    'depo' => sanitizeInput($_POST['depo']),
    'charity' => sanitizeInput($_POST['charity']),
    'saving' => sanitizeInput($_POST['saving'])
];

function getBirthDateFromIC($icNumber) {  

    // Extract year, month, and day from the IC number
    $year = intval(substr($icNumber, 0, 2));  
    $month = intval(substr($icNumber, 2, 2)); 
    $day = intval(substr($icNumber, 4, 2));  

    // Determine the full birth year
    $currentYear = intval(date("Y")); 
    $currentCentury = intval(substr($currentYear, 0, 2)) * 100; 

    $fullYear = ($year <= ($currentYear % 100)) ? ($currentCentury + $year) : ($currentCentury - 100 + $year);

    // Return the birth date in the format YYYY-MM-DD
    return sprintf("%04d-%02d-%02d", $fullYear, $month, $day);
}

$fbirthdate = getBirthDateFromIC($memberData['fic']);


// Process family member data
$familyMembers = [];
if (isset($_POST['name']) && is_array($_POST['name'])) {
    $count = count($_POST['name']);
    for ($i = 0; $i < $count; $i++) {
        if (!empty($_POST['name'][$i]) && !empty($_POST['ic'][$i]) && !empty($_POST['relationship'][$i])) {
            $familyMembers[] = [
                'name' => sanitizeInput($_POST['name'][$i]),
                'ic' => sanitizeInput($_POST['ic'][$i]),
                'relationship' => sanitizeInput($_POST['relationship'][$i])
            ];
        }
    }
}

// Check application status
$query = "SELECT m_appstatus FROM tb_membership WHERE m_nostaff = '{$memberData['fnostaff']}' ORDER BY m_appdate DESC;";

$result = mysqli_query($con, $query);
$row = mysqli_fetch_assoc($result);

if ($row && ($row['m_appstatus'] == 1 || $row['m_appstatus'] == 2)) {
    echo '<script>
        alert("Permohonan anda tidak dapat diproses. Status mesti ditolak atau belum memohon.");
        window.location.replace("index.php");
        </script>';
    exit;
}

// Hash the password
$hashedPassword = password_hash($memberData['fpass'], PASSWORD_DEFAULT);

$sql1 = "INSERT INTO tb_membership (
    m_nostaff, m_ic, m_pf, m_name, m_birthdate, m_status, m_address, m_postcode, m_state, m_gender, m_religion, 
    m_race, m_email, m_password, m_position, m_position_grade, m_office_address, m_office_postcode, m_office_state, m_fax, 
    m_tel, m_tel_house, m_salary, m_bank, m_bank_no, m_entryfee, m_fee_modalfee, m_fee_modalshare, m_fee_deposit, m_fee_charity, m_fee_fixedsaving
) VALUES (
    '{$memberData['fnostaff']}', '{$memberData['fic']}', '{$memberData['fnopf']}', '{$memberData['fname']}', '$fbirthdate',
    '{$memberData['fstatus']}', '{$memberData['fhaddr']}', '{$memberData['fhpostcode']}', '{$memberData['fhstate']}', 
    '{$memberData['fgender']}', '{$memberData['freligion']}', '{$memberData['frace']}', '{$memberData['femail']}', 
    '$hashedPassword', '{$memberData['fposi']}', '{$memberData['fgradeposi']}', '{$memberData['foaddr']}', 
    '{$memberData['fopostcode']}', '{$memberData['fostate']}', '{$memberData['fnofax']}', '{$memberData['fnotel']}', 
    '{$memberData['fnohouse']}', '{$memberData['fsalary']}', '{$memberData['fbank']}', '{$memberData['fnoacc']}', {$memberData['entryfee']},
    '{$memberData['modalfee']}', '{$memberData['share']}', '{$memberData['depo']}', '{$memberData['charity']}', '{$memberData['saving']}'  
)";


if (mysqli_query($con, $sql1)) {
    $app_id = mysqli_insert_id($con);

    $sql2 = "INSERT INTO tb_member (
            mem_id, mem_ic, mem_pf, mem_name, mem_birthdate, mem_status, mem_address, mem_postcode, mem_state, mem_gender, mem_religion, 
            mem_race, mem_email, mem_password, mem_position, mem_position_grade, mem_office_address, mem_office_postcode, mem_office_state, mem_fax, 
            mem_tel, mem_tel_house, mem_salary, mem_bank, mem_bank_no, mem_fee_modal_share, mem_fee_modal_fee, mem_fee_fixed_saving, mem_fee_charity_fund, mem_fee_saving, mem_application_id
        ) VALUES (
            '{$memberData['fnostaff']}', '{$memberData['fic']}', '{$memberData['fnopf']}', '{$memberData['fname']}', '$fbirthdate',
            '{$memberData['fstatus']}', '{$memberData['fhaddr']}', '{$memberData['fhpostcode']}', '{$memberData['fhstate']}', 
            '{$memberData['fgender']}', '{$memberData['freligion']}', '{$memberData['frace']}', '{$memberData['femail']}', 
            '$hashedPassword', '{$memberData['fposi']}', '{$memberData['fgradeposi']}', '{$memberData['foaddr']}', 
            '{$memberData['fopostcode']}', '{$memberData['fostate']}', '{$memberData['fnofax']}', '{$memberData['fnotel']}', 
            '{$memberData['fnohouse']}', '{$memberData['fsalary']}', '{$memberData['fbank']}', '{$memberData['fnoacc']}',
            '{$memberData['share']}', '{$memberData['modalfee']}', '{$memberData['saving']}', '{$memberData['charity']}', '{$memberData['depo']}', '$app_id'
        )";

    if (mysqli_query($con, $sql2)) {
        $familyInsertSuccess = true;
        if (!empty($familyMembers)) {
            foreach ($familyMembers as $family) {
                $name = mysqli_real_escape_string($con, $family['name']);
                $ic = mysqli_real_escape_string($con, $family['ic']);
                $relationship = mysqli_real_escape_string($con, $family['relationship']);

                $sql = "INSERT INTO tb_family (f_name, f_ic, f_relationship, f_member_id)
                                VALUES ('$name', '$ic', '$relationship', '{$memberData['fnostaff']}')";

                if (!mysqli_query($con, $sql)) {
                    $familyInsertSuccess = false;
                    break;
                }
            }
        }
        if ($familyInsertSuccess) {
            echo '<script>
                    alert("Permohonan Berjaya Dihantar. Sila Tunggu Kelulusan");
                    window.location.replace("index.php");
                    </script>';
        } else {
            echo '<script>
                    alert("Permohonan Berjaya Dihantar, tetapi terdapat masalah dengan maklumat keluarga. Sila hubungi admin.");
                    window.location.replace("index.php");
                    </script>';
        }
    } else {
        echo "Error: " . $sql2 . "<br>" . mysqli_error($con);
    }
} else {
    echo "Error: " . $sql1 . "<br>" . mysqli_error($con);
}

mysqli_close($con);
