$docs = Get-ChildItem C:\users\azlog\AzureActiveDirectoryJson -File

#declare a variable to hold how many messages we're uploading
$messagesUploaded = 0

foreach ($d in $docs) {
   $content = Get-Content -Raw -Path "C:\users\azlog\AzureActiveDirectoryJson\$($d.Name)" | ConvertFrom-Json
   $records = $content.Records
   foreach ($r in $records) {
      $obj = New-Object PSObject
      $obj | Add-Member NoteProperty version "1.1"
      $obj | Add-Member NoteProperty host "Azure.azlog"
      $obj | Add-Member NoteProperty _azureid $r.id
      $obj | Add-Member NoteProperty _tenantId $r.tenantId
      $obj | Add-Member NoteProperty _activity $r.activity
      $obj | Add-Member NoteProperty short_message $r.activity
      $obj | Add-Member NoteProperty _azureEventDate $r.activityDate
      $obj | Add-Member NoteProperty _activityType $r.activityType
      $obj | Add-Member NoteProperty _activityOperationType $r.activityOperationType
      if ($r.actor.UserPrincipalName) { $obj | Add-Member NoteProperty _actor $r.actor.UserPrincipalName }
      for ($i=0; $i -le $r.targets.count; $i++) {
         if ($r.targets[$i].Name) {
            $obj | Add-Member NoteProperty "_target$($i)" $r.targets[$i].Name
         } ElseIf ($r.targets[$i].userPrincipalName) {
            $obj | Add-Member NoteProperty "_target$($i)" $r.targets[$i].userPrincipalName
         }
      }
      #post message to gelf
      $messagesUploaded += 1
      Invoke-RestMethod -Method Post -Uri https://mygelfserver.mydomain.com:12201/gelf -Body (ConvertTo-Json $obj)
   }
   Move-Item "C:\users\azlog\AzureActiveDirectoryJson\$($d.Name)" "C:\users\azlog\AzureActiveDirectoryJson\Archive\"
}

Write-Host "$($messagesUploaded) AzureAD messages uploaded!"

$docs = Get-ChildItem C:\Users\azlog\AzureResourceManagerJson -File

#declare a variable to hold how many messages we're uploading
$messagesUploaded = 0

foreach ($d in $docs) {
   $content = Get-Content -Raw -Path "C:\Users\azlog\AzureResourceManagerJson\$($d.Name)" | ConvertFrom-Json
   $records = $content.Records
   foreach ($r in $records) {
      #skip update user or import records
      $obj = New-Object PSObject
      $obj | Add-Member NoteProperty version "1.1"
      $obj | Add-Member NoteProperty host "Azure.azlog"
      $obj | Add-Member NoteProperty _azureid $r.eventDataId
      $obj | Add-Member NoteProperty _tenantId $r.tenantId
      $obj | Add-Member NoteProperty _subscriptionId $r.subscriptionId
      $obj | Add-Member NoteProperty _activity $r.authorization.action
      $obj | Add-Member NoteProperty _scope $r.authorization.scope
      $obj | Add-Member NoteProperty short_message $r.operationname.localizedvalue
      $obj | Add-Member NoteProperty _azureEventDate $r.eventTimestamp
      $obj | Add-Member NoteProperty _status $r.status.value
      $obj | Add-Member NoteProperty _caller $r.caller
      if ($r.resourceGroupName) { $obj | Add-Member NoteProperty _resourceGroupName $r.resourceGroupName }
      if ($r.httpRequest.clientIpAddress) { $obj | Add-Member NoteProperty _clientIpAddress $r.httpRequest.clientIpAddress }

      #post message to gelf
      $messagesUploaded += 1
      Invoke-RestMethod -Method Post -Uri https://mygelfserver.mydomain.com:12201/gelf -Body (ConvertTo-Json $obj)
   }
   Move-Item "C:\Users\azlog\AzureResourceManagerJson\$($d.Name)" "C:\users\azlog\AzureResourceManagerJson\Archive\"
}

Write-Host "$($messagesUploaded) ARM messages uploaded!"