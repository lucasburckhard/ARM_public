####copy the dsc.ps1 file into your documents folder first!
####then change username on line 3 below to reflect the correct path to your folder
cd C:\Users\{username}\Documents
. .\dsc.ps1
VMConfig

Start-DscConfiguration -Path .\VMConfig -Verbose -Wait
