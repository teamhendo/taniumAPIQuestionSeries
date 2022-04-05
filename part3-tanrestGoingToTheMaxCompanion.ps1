############ Companion Snippets - Conversing with TanREST Part III: Going to the Max ############

## Set maximum of opportunistic BIOS targeting to 1 (Of 4 potential candidates)

[int]$biosMax = 1

## Create the BIOS custom object that will be utilized throughout the script

$biosObject = [PSCustomObject]@{
	question             = "Get Online from all machines with ( ( Windows OS Type contains windows workstation and Is Virtual equals yes ) and BIOS Version < 090009 )"
	parsed               = $null
	max                  = $biosMax
	id                   = $null
	results              = $null
	resultCount          = $null
	actionObject         = $null
	action               = $null
	actionResult         = $null
}

## Pass question property of $biosObject to parser and retain results in parsed property of $biosObject

$biosObject.parsed = New-TaniumCoreParseQuestion -Data @{text=$biosObject.question}

## Submit Tanium questions upon validating that canonical value of 1

if($biosObject.parsed.from_canonical_text -eq 1) {
	Write-Output 'Gathering number of online assets meeting BIOS targeting logic...'
	
	$biosObject.id = @{ query_text = $biosObject.parsed[0].question_text } | New-TaniumCoreQuestion | Select-Object -ExpandProperty id
}

Write-Output "Sleeping 60 seconds to allow response to BIOS targeting question..."

Start-Sleep -Seconds 60

## Collect question results into the results property of $biosObject

$biosObject.results = Get-TaniumCoreQuestionResult -ID $biosObject.id | Format-TaniumCoreQuestionResults

$biosObject.resultCount = $biosObject.results | Where-Object {$_.Online -eq 'True'} | Select-Object -ExpandProperty Count

Write-Output "The number of online respondents to BIOS targeting logic is $($biosObject.resultCount)."

## Random Sampling Logic

if ([int]$($biosObject.resultCount) -gt $biosObject.max -and $null -ne $biosObject.resultCount) {
	## Determine the maximum percentage of online assets that can be targeted within your defined maximum

	[int]$biosSamplePercentage = ($biosObject.max / $biosObject.resultCount * 100)

	Write-Output "Respondent count of $($biosObject.resultCount) exceeds BIOS targeting maximum of $($biosObject.max).  Sampling percentage set to $biosSamplePercentage."
	
	## Create Action object and leverage the Online Random Sample sensor to limit the numerical scope of the activity

	$biosObject.actionObject = New-TaniumActionObject -Name "Dynamic Deployment Targeting - BIOS Example - $($(Get-Date).ToString("yyyyMMdd"))" `
		-Package 'Custom Tagging - Add Tags' `
		-Parameters @{key='$1';value=$(-join ($(Get-Date).ToString("yyyyMMdd"),'-IPUTarget'))} `
		-Filter @(`
		@{sensor='Windows OS Type';operator='contains';value='workstation'},`
		@{sensor='Is Virtual';operator='contains';value='yes'},`
		@{sensor='BIOS Version';operator='lt';value='090009'}, `
		@{sensor='Online Random Sample';operator='contains';value='True';params=@("$biosSamplePercentage")}) `
		-ActionGroup 'All Windows Workstations' `
		-Expiration 600

	## Pass the assembled Action object to the API to deploy the Custom Tagging - Add Tags package

	$biosObject.action = New-TaniumAction -Data $biosObject.actionObject

	## Sleep while package is deployed

	Start-Sleep -Seconds 300

	## Collect the results of the deployed Action

     $biosObject.actionResult = (Get-TaniumCoreActionResult -WebSession $Session -ID $($biosObject.action.id))
}
else {
	## Notify user that the currently online endpoints fitting the targeting criteria do not exceed defined maximums

	Write-Output "Respondent count of $($biosObject.resultCount) is within BIOS targeting maximum of $($biosObject.max)."
	
	## Create Action object 

	$biosObject.actionObject = New-TaniumActionObject -Name "Dynamic Deployment Targeting - BIOS Example - $($(Get-Date).ToString("yyyyMMdd"))" `
		-Package 'Custom Tagging - Add Tags' `
		-Parameters @{key='$1';value=$(-join ($(Get-Date).ToString("yyyyMMdd"),'-IPUTarget'))} `
		-Filter @(`
			@{sensor='Windows OS Type';operator='contains';value='workstation'},`
			@{sensor='Is Virtual';operator='contains';value='yes'},`
			@{sensor='BIOS Version';operator='lt';value='090009'}) `
		-ActionGroup 'All Windows Workstations' `
		-Expiration 600

	## Pass the assembled Action object to the API to deploy the Custom Tagging - Add Tags package

	$biosObject.action = New-TaniumAction -Data $biosObject.actionObject

	## Sleep while package is deployed

	Start-Sleep -Seconds 300

	## Collect the results of the deployed Action

     $biosObject.actionResult = (Get-TaniumCoreActionResult -WebSession $Session -ID $($biosObject.action.id))
}