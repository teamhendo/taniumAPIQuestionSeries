############ Companion Snippets ############

## Importing TanREST after having extracted TanRest-master.zip to Documents folder

Import-Module "C:\Users\YourUserNameHere\Documents\TanREST-master\TanREST"

## Validating the module import.  There are 467 functions in my version of TanREST; this may vary.

$(Get-Command -Module TanREST).count

## Establishing a TanREST session with Tanium. Drop the -DisableCertificateValidation if you have a valid certificate.

New-TaniumWebSession -credential (Get-Credential) -ServerURI https://yourTaniumServer.com -DisableCertificateValidation

## Create a PSCustomObject to work with.  There are numerous properties that we will need to capture in order to work with and it is simply easier to work with one modular PowerShell object rather than a lot of distinct variables.

$questionObject = [PSCustomObject]@{
	question             = 'Get Online from all machines with ( Is Virtual contains yes and ( Is Windows equals true and Windows OS Type contains workstation ) )'
	parsed               = $null
	id                   = $null
	results              = $null
}

## Pass the question to the Tanium question parser and capture the response in the $questionObject.parsed property

$questionObject.parsed = New-TaniumCoreParseQuestion -Data @{text=$questionObject.question}

## Validate that there is only one interpretation of the defined question, submit that question for evaluation, and capture the question ID in the $questionObject.id property.

if($questionObject.parsed.from_canonical_text -eq 1) 
{
	Write-Output 'Processing Question...'
	
	$questionObject.id = @{ query_text = $questionObject.parsed[0].question_text } | New-TaniumCoreQuestion | Select-Object -ExpandProperty id
}

## Initiate a sleep cycle to allow the client fleet some amount of time to evaluate and respond to the question.

Write-Output "Sleeping 120 seconds"

Start-Sleep -Seconds 120

## Feed the ID of the previously submitted question to the API and capture the results in the $questionObject.results property.

$questionObject.results = Get-TaniumCoreQuestionResult -ID $questionObject.id | Format-TaniumCoreQuestionResults

