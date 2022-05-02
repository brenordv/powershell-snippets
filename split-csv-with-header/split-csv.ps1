# Those are the script parameters and must be the first line of code of the script.
param([string]$file,[int]$maxLines)

function Save-SplitCsv {
    param(
        [System.Collections.Generic.List[string]]$lines,
        [string]$header,
        [string]$fileLocation,
        [string]$baseFilename,
        [int]$filesExported
    )
        $lines.Insert(0, $header)
        $filename = $fileLocation + "\" + $baseFilename + "--" + "{0:0000}" -f $filesExported
        $filename = $filename + ".csv"
        $lines | Set-Content -Path $filename -Encoding UTF8
        $filesExported += 1

    return $filesExported
}

function Split-Csv
{
    param([string]$file,[int]$maxLines)
    <#
        .SYNOPSIS
        Splits a CSV file into multiple, smaller files, replicating the header.

        .DESCRIPTION
        Splits a large CSV file into smaller ones. All files will have headers and will be written using
        UTF-8 encoding. No validation of any kind is made in the procress.
        To reiterate: The source file must use UTF8 and must have headers.

        .PARAMETER file
        Path for the source file.

        .PARAMETER maxLines
        Max number of lines for each split file. Remembering that header counts as a line.

        .OUTPUTS
        Will save n files, depending on the size of the source file and maxLines value.

        .EXAMPLE
        .\split-csv.ps1 -file c:\\temp\\big-csv.csv -maxLine 25000

        .LINK
        https://raccoon.nina

        .LINK
        https://github.com/brenordv/powershell-snippets/blob/master/split-csv-with-header/split-csv.ps1
     #>
    $sw = [system.diagnostics.stopwatch]::StartNew()
    Write-Host "Split starting for:" $file

    $totalLines = 0
    $header = ""
    $actualMaxLines = $maxLines - 1
    $lines =  new-object 'System.Collections.Generic.List[string]'
    $filesExported = 0
    $fileLocation = [System.IO.Path]::GetDirectoryName($file)
    $baseFilename = [System.IO.Path]::GetFileNameWithoutExtension($file)

    $content = Get-Content -Path $file -Encoding UTF8

    foreach($line in $content) {
        $totalLines += 1

        if ($totalLines -eq 1) {
            $header = $line;
            continue;
        }

        if ($lines.Count -ne $actualMaxLines) {
            $lines.Add($line)
            continue
        }
        $filesExported = Save-SplitCsv -lines $lines -fileLocation $fileLocation -baseFilename $baseFilename -filesExported $filesExported -header $header
        $lines.Clear()
    }

    if ($lines.Count -gt 0) {
        $filesExported = Save-SplitCsv -lines $lines -fileLocation $fileLocation -baseFilename $baseFilename -filesExported $filesExported -header $header
        $lines.Clear()
    }

    $sw.Stop()
    Write-Host "All done!"
    Write-Host "Lines Read:" $totalLines
    Write-Host "Lines per file:" $maxLines
    Write-Host "Total generated files:" $filesExported
    Write-Host "Elapsed Time:" $sw.Elapsed
    Write-Host "Estimated:" ([math]::Round(($totalLines / $sw.Elapsed.TotalSeconds), 2)) "lines/second"
}

#$file = "Z:\dti\vale_notebooks_public\notebook_input_data_files\arcadis\Arcadis_ValeECOS_SE_HIST2021_12_21.csv"
#$maxLines = 2500
Split-Csv -file $file -maxLines $maxLines