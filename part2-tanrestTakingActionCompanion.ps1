############ Companion Snippets ############
 
## Create a PSCustomObject to preserve and work with data


$exampleObject = [PSCustomObject]@{
	actionObject = $null
	action       = $null
}

## Create a validated action object and store it within the actionObject property of $exampleObject

$exampleObject.actionObject = New-TaniumActionObject `
	-Name "API Series - Taking Action - $($(Get-Date).ToString("yyyyMMdd"))" `
	-Package 'Custom Tagging - Add Tags' `
	-Parameters @{key='$1';value=$(-join ($(Get-Date).ToString("yyyyMMdd"),'-TakingActionAPISeries'))} `
	-Filter @(`
		@{sensor='Windows OS Type';operator='contains';value='workstation'},`
		@{sensor='Is Virtual';operator='contains';value='yes'}) `
	-ActionGroup 'All Windows Workstations' `
	-Expiration 600

 
## Submit the constructed action object via TanREST and capture the returned data in the action property

$exampleObject.action = New-TaniumAction -Data $exampleObject.actionObject

## Get information about the current state of the submitted action via TanREST

Get-TaniumCoreAction -ID $exampleObject.action.id
