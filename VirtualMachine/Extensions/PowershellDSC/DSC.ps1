Configuration VMConfig {

    Import-DscResource -ModuleName PsDesiredStateConfiguration

    Node 'localhost' {

        File TempFolder {
            Type = "Directory"
            DestinationPath = "c:\support"
            Ensure = "Present"
        }

        File CreateSMBFiledropFolder
        {
            DestinationPath = 'f:\Filedrop'
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn = '[Script]InitializeDiskDrives'
        }

        File CreateSMBTempFolder
        {
            DestinationPath = 'f:\temp'
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn = '[Script]InitializeDiskDrives'
        }

        Script ASPEnvironmentVariable {
            TestScript = {
                $e=$env:COMPUTERNAME
                if($e.Substring(4,1) -like "d" -or $e.Substring(4,1) -like "x"){([System.Environment]::GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT", "Machine") -like "dev")}
                if($e.Substring(4,1) -like "q" -or $e.Substring(4,1) -like "s"){([System.Environment]::GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT", "Machine") -like "test")}
                if($e.Substring(4,1) -like "p"){([System.Environment]::GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT", "Machine") -like "prod")}
            }
            SetScript = {
                $e=$env:COMPUTERNAME
                if($e.Substring(4,1) -like "d" -or $e.Substring(4,1) -like "x"){[System.Environment]::SetEnvironmentVariable("ASPNETCORE_ENVIRONMENT","dev", "Machine")}
                if($e.Substring(4,1) -like "q" -or $e.Substring(4,1) -like "s"){[System.Environment]::SetEnvironmentVariable("ASPNETCORE_ENVIRONMENT","test", "Machine")}
                if($e.Substring(4,1) -like "p"){[System.Environment]::SetEnvironmentVariable("ASPNETCORE_ENVIRONMENT","prod", "Machine")}

            }
            GetScript = {@{Result = "ASPEnvironmentVariable"}}
        }

        Script AddLocalGroupMember {
            TestScript = {
               ((Get-LocalGroupMember -Group "IIS_IUSRS" | ?{$_.name -like "DomainName\svcName"}) -ne $null)
            }
            SetScript = {
                Add-LocalGroupMember -Group "IIS_IUSRS" -Member "PHIBRED\CSNAPsvc"
            }
            GetScript = {@{Result = "AddLocalGroupMember"}}
        }

        Script AddTFSGroupMember {
            TestScript = {
               ((Get-LocalGroupMember -Group "IIS_IUSRS" | ?{$_.name -like "DomainName\tfsName"}) -ne $null)
            }
            SetScript = {
                Add-LocalGroupMember -Group "IIS_IUSRS" -Member "DomainName\tfsbuild"
            }
            GetScript = {@{Result = "AddTFSGroupMember"}}
        }

        Script InitializeDiskDrives {
            TestScript = {
                ((get-disk).PartitionStyle -notcontains 'Raw')
            }
            SetScript = {
                $disks = get-disk | where partitionstyle -eq 'raw' | sort number
                $letters= 70..89 | ForEach-Object { [char]$_ }
                $count = 0
                foreach ($disk in $disks){
                $driveletter = $letters[$count].ToString()
                $disk |
                Initialize-Disk -PartitionStyle GPT -PassThru |
                New-Partition -UseMaximumSize -DriveLetter $driveletter |
                Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data" -Confirm:$false -Force
                $count++
                }
            }
            GetScript = {@{Result = "InitializeDiskDrives"}}
        }

        Script InitializeSMBTempShare {
            TestScript = {
                Test-Path "\\$env:computername\temp"
            }
            SetScript = {
                New-SmbShare -Name "temp" -Path "F:\temp" -FullAccess "BUILTIN\Administrators", "NT Authority\SYSTEM", "BUILTIN\IIS_IUSRS"
            }
            GetScript = {@{Result = "InitializeSMBTempShare"}}
            DependsOn = '[File]CreateSMBTempFolder'
        }

        Script InitializeSMBFiledropShare {
            TestScript = {
                Test-Path "\\$env:computername\filedrop"
            }
            SetScript = {
                New-SmbShare -Name "Filedrop" -Path "F:\Filedrop" -FullAccess "BUILTIN\Administrators", "NT Authority\SYSTEM"
            }
            GetScript = {@{Result = "InitializeSMBFiledropShare"}}
            DependsOn = '[File]CreateSMBFiledropFolder'
        }

        Script GrantSMBFiledropShareAccess {
            TestScript = {
                ((Get-SmbShareAccess -Name 'Filedrop').AccountName -contains 'BUILTIN\IIS_IUSRS')
            }
            SetScript = {
                Grant-SmbShareAccess -Name 'Filedrop' -AccountName "BUILTIN\IIS_IUSRS" -AccessRight Full -Force
            }
            GetScript = {@{Result = "GrantSMBFiledropShareAccess"}}
            DependsOn = '[Script]InitializeSMBFiledropShare'
        }

        Script GrantSMBtempShareAccess {
            TestScript = {
                ((Get-SmbShareAccess -Name 'temp').AccountName -contains 'BUILTIN\IIS_IUSRS')
            }
            SetScript = {
                Grant-SmbShareAccess -Name 'temp' -AccountName "BUILTIN\IIS_IUSRS" -AccessRight Full -Force
            }
            GetScript = {@{Result = "GrantSMBtempShareAccess"}}
            DependsOn = '[Script]InitializeSMBTempShare'
        }
        
        Script DownloadDotnetHosting {
            TestScript = {
                Test-Path "c:\support\dotnet-hosting-5.0.5-win.exe"
            }
            SetScript = {
                $source = "https://download.visualstudio.microsoft.com/download/pr/c80056cc-e6e9-4c57-9973-3167ef6e3c28/6bc80fa159c10a1be63cf1e4d13fcbbc/dotnet-hosting-5.0.5-win.exe"
                $dest = "c:\support\dotnet-hosting-5.0.5-win.exe"
                Invoke-WebRequest $source -OutFile $dest
            }
            GetScript = {@{Result = "DownloadDotnetHosting"}}
        }

        WindowsFeature WebServer
        {
            Ensure = 'Present'
            Name = 'Web-Server'
        }

        Package InstallDotnetHosting
        {
            Ensure = 'Present'
            Name = 'Microsoft .NET Host - 5.0.5 (x64)'
            ProductId = 'C258244B-F999-4CEC-B86C-085AB582275A'
            Arguments = '/quiet /install /norestart'
            Path = 'C:\support\dotnet-hosting-5.0.5-win.exe'
        }

        Environment Dotnet
        {
            Name = 'Path'
            Ensure = 'Present'
            Value = 'C:\Program Files\dotnet\;'
            Path = $true
            DependsOn = '[Package]InstallDotnetHosting'
        }
    }

}
