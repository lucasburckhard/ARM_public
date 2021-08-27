I've included an example Desired State Configuration file and I will likely be adding more to it later.  Currently this state file will download and install dotnet hosting framework; then it will initialize any disk drives that have been added; finally it will create a shared folder in the F: drive (this will need to be changed if you haven't added any disk drives, change it to the C: drive.)
</br>
</br>
Follow these general build/release steps
1) add a Powershell step in your build definition that runs the Create-DSCzip.ps1 script file and this will output a DSC.zip file that will be used in the next step
2) add an Azure File Copy step in your release definition that copies the DSC.zip file to a storage account that lives in the same resource group as your virtual machine
3) add a step in your release definition that will deploy the ARM template.  !!! Remember to update the SignedExpiry parameter.  (bonus points if you pass in a (UTC + 1) day value automatically in your release definition).
