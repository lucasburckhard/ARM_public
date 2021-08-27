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
                New-SmbShare -Name "temp" -Path "F:\temp" -FullAccess "BUILTIN\Administrators", "NT Authority\SYSTEM"
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
