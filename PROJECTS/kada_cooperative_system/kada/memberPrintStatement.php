<?php
ob_start(); 

include 'memberSession.php';
include 'db_connect.php';
require_once 'vendor/autoload.php';

$fuid = $_SESSION['id'];

$sql = "SELECT * FROM tb_member WHERE mem_id = '$fuid'";
$result = mysqli_query($con, $sql);
$member = mysqli_fetch_array($result);

$sql_loan = "
    SELECT tb_loan.loan_name, 
           SUM(tb_loan_application.la_balance) AS la_balance
    FROM tb_loan
    LEFT JOIN tb_loan_application
    ON tb_loan.loan_id = tb_loan_application.la_type
    AND tb_loan_application.la_member_id = $fuid
    GROUP BY tb_loan.loan_id, tb_loan.loan_name
    ORDER BY tb_loan.loan_id;
";
$result_loan = mysqli_query($con, $sql_loan);

$date = date("d-m-Y");

class FinancialStatement extends TCPDF {
    public function Header() {
        $logoWidth = 40;
        $logoHeight = 20;
        $textStartX = 15 + $logoWidth + 5;
        $textWidth = 125;

        $this->Image('img/logo.png', 15, 10, $logoWidth, $logoHeight, "PNG");
        $this->SetXY($textStartX, 10);
        $this->SetFont('helvetica', 'B', 14);
        $this->Cell($textWidth, 6, 'KOPERASI KAKITANGAN KADA KELANTAN', 0, 1, 'C');

        $this->SetFont('helvetica', '', 12);
        $this->SetX($textStartX);
        $this->Cell($textWidth, 6, 'D/A Lembaga Kemajuan Pertanian Kemubu', 0, 1, 'C');
        $this->SetX($textStartX);
        $this->Cell($textWidth, 6, 'P/S 127, 15710 Kota Bharu, Kelantan', 0, 1, 'C');
        $this->SetX($textStartX);
        $this->Cell($textWidth, 6, 'Tel: 09-7447088', 0, 1, 'C');

        $this->Ln(5);
        $this->SetLineWidth(0.5);
        $this->Line(15, $this->GetY(), 195, $this->GetY());
        $this->Ln(10);
    }

    public function Footer() {
        $this->SetY(-15);
        $this->SetFont('helvetica', 'I', 8);
        $this->Cell(0, 10, 'Page ' . $this->getAliasNumPage() . '/' . $this->getAliasNbPages(), 0, 0, 'C');
    }
}

$pdf = new FinancialStatement();
$pdf->SetCreator(PDF_CREATOR);
$pdf->SetAuthor('KOPERASI KAKITANGAN KADA KELANTAN');
$pdf->SetTitle('Penyata Pembiayaan');
$pdf->SetMargins(15, 40, 15);
$pdf->SetAutoPageBreak(true, 20);
$pdf->AddPage();
$pdf->Ln(5);

$pdf->SetFont('helvetica', 'B', 12);
$pdf->Cell(0, 10, 'PENYATA KEWANGAN AHLI KOPERASI BERTARIKH ' . date('d/m/Y', strtotime($date)), 0, 1, 'C');
$pdf->Ln(10);

$pdf->SetFont('helvetica', 'B', 12);
$pdf->Cell(0, 10, 'NAMA: ' . strtoupper($member['mem_name']), 0, 1, 'L');
$pdf->Cell(0, 10, 'NO K/P: ' . $member['mem_ic'], 0, 1, 'L');
$pdf->Cell(0, 10, 'NO PF: ' . $member['mem_pf'], 0, 1, 'L');
$pdf->Ln(5);

// Table Styling
$column1Width = 90;
$column2Width = 90;
$cellHeight = 10;

$pdf->SetFont('helvetica', 'B', 12);
$pdf->Cell(0, 10, 'MAKLUMAT SAHAM AHLI', 0, 1, 'L');

$pdf->SetFont('helvetica', '', 12);
$pdf->SetFillColor(220, 220, 220);
$pdf->Cell($column1Width, $cellHeight, 'Jenis Saham', 1, 0, 'C', 1);
$pdf->Cell($column2Width, $cellHeight, 'Jumlah (RM)', 1, 1, 'C', 1);

$shares = [
    'Modal Syer' => $member['mem_modal_share'],
    'Modal Yuran' => $member['mem_modal_fee'],
    'Simpanan Tetap' => $member['mem_fixed_saving'],
    'Tabung Anggota' => $member['mem_charity_fund'],
    'Simpanan Anggota' => $member['mem_saving'],
];

foreach ($shares as $label => $value) {
    $pdf->Cell($column1Width, $cellHeight, $label, 1, 0);
    $pdf->Cell($column2Width, $cellHeight, number_format($value, 2), 1, 1, 'R');
}

$pdf->Ln(5);

$pdf->SetFont('helvetica', 'B', 12);
$pdf->Cell(0, 10, 'MAKLUMAT PEMBIAYAAN AHLI', 0, 1, 'L');

$pdf->SetFont('helvetica', '', 12);
$pdf->SetFillColor(220, 220, 220);
$pdf->Cell($column1Width, $cellHeight, 'Jenis Pembiayaan', 1, 0, 'C', 1);
$pdf->Cell($column2Width, $cellHeight, 'Baki Pembiayaan (RM)', 1, 1, 'C', 1);

while ($loan = mysqli_fetch_assoc($result_loan)) {
    $pdf->Cell($column1Width, $cellHeight, htmlspecialchars($loan['loan_name']), 1, 0);
    $pdf->Cell($column2Width, $cellHeight, number_format($loan['la_balance'], 2), 1, 1, 'R');
}

ob_end_clean();
$pdf->Output('PENYATA_KEWANGAN.PDF', 'I');
?>
