<?php
include 'db_connect.php';
include 'clerkSession.php';
require_once 'vendor/autoload.php';

$reportData = [];
$reportTypeTemplate = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get the selected report type (monthly or yearly)
    $reportType = $_POST['reportType'];
    $monthInput = isset($_POST['month']) ? $_POST['month'] : null;
    $yearInput = isset($_POST['year']) ? $_POST['year'] : null;

    if ($monthInput) {
        $month = date('m', strtotime($monthInput)); // Extracts the month as MM
        $year = date('Y', strtotime($monthInput)); // Extracts the year as YYYY
        $reportTypeTemplate = 'monthly'; 
    } else {
        $month = null;
        $year = $yearInput; // If year is provided independently (yearly report)
        $reportTypeTemplate = 'yearly'; 
    }

    // Initialize an array to store the results
    $reportData = [
        'totalMembers' => 0,
        'totalLoanApplications' => 0,
        'totalMemberApplications' => 0,
        'totalLoanPayments' => 0,
        'totalFeePayments' => 0,
        'totalApprovedLoanAmounts' => 0,
    ];

    if ($reportType == 'monthly' && $month && $year) {
        $lastDay = date("Y-m-t", strtotime("$year-$month-01"));
        $queries = [
            'totalMembers' => "SELECT COUNT(mem_id) AS TotalMember FROM tb_member WHERE DATE(mem_join_date) <= '$lastDay' AND mem_membership_status = 6 OR mem_membership_status = 7;",
            'totalLoanApplications' => "SELECT COUNT(la_id) AS totalLoanApplication FROM tb_loan_application 
                                        WHERE MONTH(la_timestamp) = '$month' AND YEAR(la_timestamp) = '$year';",
            'totalMemberApplications' => "SELECT COUNT(m_app_id) AS totalMemberApplication FROM tb_membership 
                                          WHERE MONTH(m_appdate) = '$month' AND YEAR(m_appdate) = '$year';",
            'totalLoanPayments' => "SELECT ROUND(SUM(l_payment), 2) AS totalPayment FROM tb_loan_payment 
                                    WHERE MONTH(l_paid_month) = '$month' AND YEAR(l_paid_month) = '$year';",
            'totalFeePayments' => "SELECT ROUND(SUM(fee_entry), 2) AS totalFee FROM tb_fee_payment 
                                   WHERE MONTH(fee_month) = '$month' AND YEAR(fee_month) = '$year';",
            'totalApprovedLoanAmounts' => "SELECT SUM(la_amount) AS total_approved_loans FROM tb_loan_application WHERE MONTH(la_timestamp) = '$month' AND YEAR(la_timestamp) = '$year' AND la_status = 4",

            'totalMemberWithdrawals' => "SELECT COUNT(mw_id) AS total_member_withdrawals FROM tb_member_withdrawal WHERE DATE(mw_approval_date) <= '$lastDay' AND mw_status = 2;",
        ];
    } elseif ($reportType == 'yearly' && $year) {
        $endOfYear = "$year-12-31";
        $queries = [
            'totalMembers' => "SELECT COUNT(mem_id) AS TotalMember FROM tb_member WHERE DATE(mem_join_date) <= '$endOfYear' AND mem_membership_status = 6 OR mem_membership_status = 7;;",
            'totalLoanApplications' => "SELECT COUNT(la_id) AS totalLoanApplication FROM tb_loan_application 
                                        WHERE YEAR(la_timestamp) = '$year';",
            'totalMemberApplications' => "SELECT COUNT(m_app_id) AS totalMemberApplication FROM tb_membership 
                                          WHERE YEAR(m_appdate) = '$year';",
            'totalLoanPayments' => "SELECT ROUND(SUM(l_payment), 2) AS totalPayment FROM tb_loan_payment 
                                    WHERE YEAR(l_paid_month) = '$year';",
            'totalFeePayments' => "SELECT ROUND(SUM(fee_entry), 2) AS totalFee FROM tb_fee_payment 
                                   WHERE YEAR(fee_month) = '$year';",
            'totalApprovedLoanAmounts' => "SELECT SUM(la_amount) AS total_approved_loans FROM tb_loan_application WHERE YEAR(la_timestamp) = '$year' AND la_status = 4",

            'totalMemberWithdrawals' => "SELECT COUNT(mw_id) AS total_member_withdrawals FROM tb_member_withdrawal WHERE YEAR(mw_approval_date) <= '$year' AND mw_status = 2;",
        ];
    } else {
        echo 'Invalid input.';
        exit();
    }

    // Execute all queries 
    foreach ($queries as $key => $query) {
        $result = mysqli_query($con, $query);
        if ($result && ($row = mysqli_fetch_assoc($result))) {
            $reportData[$key] = $row[array_key_first($row)];
        }
    }

    class FinancialStatement extends TCPDF {
        // Header
        public function Header() {
            $logoWidth = 40; 
            $logoHeight = 20; 
            $textStartX = 10 + $logoWidth + 5; 
            $textWidth = 150; 
    
            $this->Image('img/logo.png', 10, 10, $logoWidth, $logoHeight, "PNG");
    
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
            $this->Line(10, $this->GetY(), 200, $this->GetY());
    
            $this->Ln(10);
        }
    
        // Footer
        public function Footer() {
            $this->SetY(-15);
            $this->SetFont('helvetica', 'I', 8);
            $this->Cell(0, 10, 'Page ' . $this->getAliasNumPage() . '/' . $this->getAliasNbPages(), 0, 0, 'C');
        }
    }
    
    // Create new PDF
    $pdf = new FinancialStatement();
    $pdf->SetCreator(PDF_CREATOR);
    $pdf->SetAuthor('KOPERASI KAKITANGAN KADA KELANTAN');
    $pdf->SetTitle('Penyata Pembiayaan');
    $pdf->SetMargins(10, 40, 10);
    $pdf->SetAutoPageBreak(true, 20);
    
    $pdf->AddPage();
    $pdf->Ln(5);
    $pdf->SetFont('helvetica', 'B', 12);
    
    if ($reportType == 'monthly' && $month && $year) {
        $pdf->Cell(0, 10, 'LAPORAN BULAN ' . strtoupper(date('F Y', strtotime("$year-$month-01"))), 0, 1, 'C');
    } elseif ($reportType == 'yearly' && $year) {
        $pdf->Cell(0, 10, 'LAPORAN TAHUN ' . $year, 0, 1, 'C');
    }
    
    $pdf->Ln(10);
    
    // Membership Information Table
    $pdf->SetFont('helvetica', 'B', 14);
    $pdf->Cell(0, 10, 'Maklumat Keahlian', 0, 1, 'L');
    $pdf->SetFont('helvetica', '', 12);
    $pdf->SetFillColor(220, 220, 220);
    
    $pdf->Cell(80, 10, 'Maklumat', 1, 0, 'C', 1);
    $pdf->Cell(110, 10, 'Butiran', 1, 1, 'C', 1);
    
    $pdf->Cell(80, 10, 'Jumlah Ahli Aktif', 1, 0);
    $pdf->Cell(110, 10, number_format($reportData['totalMembers']), 1, 1, 'R');
    
    $pdf->Cell(80, 10, 'Jumlah Permohonan Ahli', 1, 0);
    $pdf->Cell(110, 10, number_format($reportData['totalMemberApplications']), 1, 1, 'R');

    $pdf->Cell(80, 10, 'Jumlah Ahli Berhenti', 1, 0);
    $pdf->Cell(110, 10, number_format($reportData['totalMemberWithdrawals']), 1, 1, 'R');
    
    $pdf->Ln(5);
    
    // Loan Information Table
    $pdf->SetFont('helvetica', 'B', 14);
    $pdf->Cell(0, 10, 'Maklumat Pembiayaan', 0, 1, 'L');
    $pdf->SetFont('helvetica', '', 12);
    $pdf->SetFillColor(220, 220, 220);
    
    $pdf->Cell(80, 10, 'Maklumat', 1, 0, 'C', 1);
    $pdf->Cell(110, 10, 'Butiran', 1, 1, 'C', 1);
    
    $pdf->Cell(80, 10, 'Jumlah Permohonan Pembiayaan', 1, 0);
    $pdf->Cell(110, 10, number_format($reportData['totalLoanApplications']), 1, 1, 'R');
    
    $pdf->Cell(80, 10, 'Jumlah Pembiayaan Yang Diluluskan', 1, 0);
    $pdf->Cell(110, 10, number_format($reportData['totalApprovedLoanAmounts']), 1, 1, 'R');
    
    $pdf->Cell(80, 10, 'Jumlah Bayaran Balik Pembiayaan', 1, 0);
    $pdf->Cell(110, 10, number_format($reportData['totalLoanPayments'], 2), 1, 1, 'R');

    
    $pdf->Ln(5);
    
    // Fee Payment Information Table
    $pdf->SetFont('helvetica', 'B', 14);
    $pdf->Cell(0, 10, 'Maklumat Bayaran Yuran', 0, 1, 'L');
    $pdf->SetFont('helvetica', '', 12);
    $pdf->SetFillColor(220, 220, 220);
    
    $pdf->Cell(80, 10, 'Maklumat', 1, 0, 'C', 1);
    $pdf->Cell(110, 10, 'Butiran', 1, 1, 'C', 1);
    
    $pdf->Cell(80, 10, 'Jumlah Fee Masuk', 1, 0);
    $pdf->Cell(110, 10, number_format($reportData['totalFeePayments'], 2), 1, 1, 'R');
    
    $pdf->Output('PENYATA_PEMBIAYAAN.PDF', 'I');
    
    mysqli_close($con);
}
?>

