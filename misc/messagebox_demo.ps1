<#
.SYNOPSIS
	Simple messagebox demo.   
.DESCRIPTION
	Shows a messagebox with Yes/No/Cancel option and runs code based on the answer.
.PARAMETER <paramName>
	None.
.EXAMPLE
	Just run this script.
.AUTHOR
	Breno RdV @ Raccoon Ninja
.SITE
	http://raccoon.ninja
#>

$title = "Messagebox Demo"
$message = "Do you like Bacon?"
$answerOptions = "YesNoCancel"
$answerOptions = "YesNoCancel"
$icon = "Warning"

$msgBoxAnswer = [System.Windows.MessageBox]::Show($message, $tile, $answerOptions, $icon)

switch ($msgBoxAnswer) {
	'Yes' {		
		Write-Host "Great! So do I! :)"
	}

	'No' {
		Write-Host "Sad to hear that, but ok."
	}

	'Cancel' {
		Write-Host "Ok. You don't have to answer right now..."
	}
}
