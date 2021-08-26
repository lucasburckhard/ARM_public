There are two important things you need to do before these templates can be applied successfully

1) You will need to have the web app or function app already deployed in your Azure subscription
2) You will need a DNS Record Name (CNAME) that points to the original web app name, i.e. yourAppName.yourDomain.com > https://actualResourceName.azurewebsites.net.  Also, you need a DNS Record Name (TXT) to point that points to the original web app Custom Domain Verification ID; you can get this value by viewing the Custom Domain of your web/function app settings in Azure portal. 
