if($(((get-date).ToUniversalTime().AddHours(1)).Month).ToString().Length -eq 1){$month="0$(((get-date).ToUniversalTime().AddHours(1)).Month)"}
else{$month="$(((get-date).ToUniversalTime().AddHours(1)).Month)"}
if($(((get-date).ToUniversalTime().AddHours(1)).Day).ToString().Length -eq 1){$day="0$(((get-date).ToUniversalTime().AddHours(1)).Day)"}
else{$day="$(((get-date).ToUniversalTime().AddHours(1)).Day)"}
if($(((get-date).ToUniversalTime().AddHours(1)).Hour).ToString().Length -eq 1){$hour="0$(((get-date).ToUniversalTime().AddHours(1)).Hour)"}
else{$hour="$(((get-date).ToUniversalTime().AddHours(1)).Hour)"}
if($(((get-date).ToUniversalTime().AddHours(1)).Minute).ToString().Length -eq 1){$minute="0$(((get-date).ToUniversalTime().AddHours(1)).Minute)"}
else{$minute="$(((get-date).ToUniversalTime().AddHours(1)).Minute)"}
if($(((get-date).ToUniversalTime().AddHours(1)).Second).ToString().Length -eq 1){$second="0$(((get-date).ToUniversalTime().AddHours(1)).Second)"}
else{$second="$(((get-date).ToUniversalTime().AddHours(1)).Second)"}
$OneHourAhead="$(((get-date).ToUniversalTime().AddHours(1)).Year)-$($month)-$($day)T$($hour):$($minute):$($second)Z"
$OneHourAhead

Write-Host "##vso[task.setvariable variable=plusOneHour;isOutput=true]$OneHourAhead"
