###########################
#This script can be run on a server that collects forwarded AppLocker Meta 
#events to help perform basic analysis by grouping the events by file path 
#to show if there are any files that are being blocked many times. 
#
#This script can take two arguments with the first specifying the number of 
#previous days worth of events to retrieve and the second specifying the number
#of previous hours worth of events to retrieve.  By default, without any 
#arguments specified, the script will retrieve one day's events.
###########################

Import-Module AppLocker

$daysToGet = 1
$hoursToGet = 0

if($args.Length -ge 1) 
{  
  $daysToGet = $args[0] 
}
if($args.Length -ge 2) 
{ 
  $hoursToGet = $args[1] 
}
$timespan = (get-date) - (new-timespan -Days $daysToGet -Hours $hoursToGet)

Write-Host Retrieving AppLocker events since $timespan
$events = Get-WinEvent -LogName ForwardedEvents | Where {$_.timecreated -ge $timespan -and $_.ProviderName -eq "AppLocker"} 
if($events -eq $Null) {
  Write-Host No AppLocker events found in the requested time range.
  Exit
}
ForEach ($eventRecord in $events) 
{
  $xml = $eventRecord.ToXML()
  #Write-Host $xml
  $xd = [xml] $xml
  $innerEvent = $xd.Event.EventData.Data
  $event = [xml] $innerEvent
  $eventID = $event.Event.System.EventID
  $level = $event.Event.System.Level
  $createdTime = $event.Event.System.TimeCreated.Attributes.GetNamedItem("SystemTime").Value
  $eventRecordID = $event.Event.System.EventRecordID
  $computer = $event.Event.System.Computer
  $policyName = $event.Event.UserData.RuleAndFileData.PolicyName
  $filePath = $event.Event.UserData.RuleAndFileData.FilePath
  $fileHash = $event.Event.UserData.RuleAndFileData.FileHash
  $fqbn = $event.Event.UserData.RuleAndFileData.Fqbn
  $username = $event.Event.UserData.RuleAndFileData.Username.InnerText
  $callingProcess = $event.Event.UserData.RuleAndFileData.CallingProcess.InnerText
  $eventRecord.Message = $filePath
}

Write-Host Showing counts of AppLocker meta events per file path since $timespan
$events | Group-Object Message | Sort-Object Count -Descending | Format-Table Count,Name -AutoSize
