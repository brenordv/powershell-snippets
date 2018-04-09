<#  
.SYNOPSIS  
    Extracts lines that contains a specific string.
.DESCRIPTION  
    This script will read every line of a file and extract the ones containing a specific string.
.NOTES  
    File Name  : extract_lines.ps1
    Author     : Breno RdV @ Raccoon Ninja    
.LINK  
    http://raccoon.ninja
#>

$in_file = "big_logfile.txt" # Log file that will be read.
$out_file = "file_with_extractedlines.txt" # File will receive the extracted lines.
$search_for = "ERROR" # Text that we're searching for in the lines.
$line_num = 0 # Number of the line begin read.
$lines_found = 0 # Quantity of lines found.

$log_lines = Get-Content $in_file # Var holding the lines of the log file.

foreach ($line in $log_lines) { 
    $line_num++    
    if ($line.Contains($search_for)) {
        $lines_found++
        Write-Host "Text '$search_for' found in line $line_num..."
        $line | out-file -FilePath $out_file -Append
    }
}

Write-Host "Found $lines_found lines..."
