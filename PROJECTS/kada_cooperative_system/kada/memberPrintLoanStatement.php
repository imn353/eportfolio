<?php
include 'memberSession.php';
include 'db_connect.php';

$fuid = $_SESSION['id'];
$loanPaymentID = $_GET['payment'];


$sql = "SELECT tb_loan_payment.l_id, tb_loan_payment.l_payment, tb_loan_payment.l_paid_month, tb_loan_payment.l_payment_method, tb_loan_payment.l_remarks, tb_loan_payment.l_app_id, tb_loan.loan_name, tb_loan_payment.l_payment_date 
        FROM tb_loan_application 
        LEFT JOIN tb_loan_payment ON tb_loan_payment.l_app_id = tb_loan_application.la_id 
        LEFT JOIN tb_loan ON tb_loan.loan_id = tb_loan_application.la_type 
        WHERE tb_loan_payment.l_id = '$loanPaymentID';";

$result = mysqli_query($con, $sql);
$row = mysqli_fetch_assoc($result);


$remarks = $row['l_remarks'];

if($remarks == ''){
    $remarks = 'Tiada';
}
        
require_once 'vendor/autoload.php'; // Composer's autoloader

class FinancialStatement extends TCPDF {
    // Header
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

    // Footer
    public function Footer() {
        $this->SetY(-15);
        $this->SetFont('helvetica', 'I', 8);
        $this->Cell(0, 10, 'Page ' . $this->getAliasNumPage() . '/' . $this->getAliasNbPages(), 0, 0, 'C');
    }
}

// Create a new PDF
$pdf = new FinancialStatement();
$pdf->SetCreator(PDF_CREATOR);
$pdf->SetAuthor('KOPERASI KAKITANGAN KADA KELANTAN');
$pdf->SetTitle('Penyata Pembiayaan');
$pdf->SetMargins(15, 40, 15); 
$pdf->SetAutoPageBreak(true, 20); 

$pdf->AddPage();
$pdf->Ln(5);
$pdf->SetFont('helvetica', 'B', 12);
$pdf->Cell(0, 10, 'BAYARAN PEMBIAYAAN UNTUK BULAN ' . date('m/Y', strtotime($row['l_paid_month'])), 0, 1, 'C');
$pdf->Ln(10);

$pdf->SetFont('helvetica', '', 12);
$pdf->SetFillColor(220, 220, 220); 
$pdf->Cell(50, 10, 'Maklumat', 1, 0, 'C', 1);
$pdf->Cell(0, 10, 'Butiran', 1, 1, 'C', 1);
$pdf->Cell(50, 10, 'No. Pembiayaan ', 1);
$pdf->Cell(0, 10, $row['l_app_id'] , 1, 1);
$pdf->Cell(50, 10, 'Jenis Pembiayaan', 1);
$pdf->Cell(0, 10, $row['loan_name'], 1, 1);
$pdf->Cell(50, 10, 'No. Bayaran ', 1);
$pdf->Cell(0, 10, $row['l_id'] , 1, 1);
$pdf->Cell(50, 10, 'Jumlah Bayaran', 1);
$pdf->Cell(0, 10, $row['l_payment'], 1, 1);
$pdf->Cell(50, 10, 'Tarikh Bayaran', 1);
$pdf->Cell(0, 10, date('d/m/Y', strtotime($row['l_payment_date'])), 1, 1);
$pdf->Cell(50, 10, 'Kaedah Pembayaran', 1);
$pdf->Cell(0, 10, $row['l_payment_method'], 1, 1);
$pdf->Cell(50, 10, 'Butiran Pembayaran', 1);
$pdf->Cell(0, 10, $remarks, 1, 1);

$pdf->Output('PENYATA_PEMBIAYAAN.PDF', 'I'); 
?>
