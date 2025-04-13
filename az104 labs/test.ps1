Install-WindowsFeature -name Web-Server -IncludeManagementTools
Remove-item \'C:\\inetpub\\wwwroot\\iisstart.htm\'
Add-Content -Path \'C:\\inetpub\\wwwroot\\iisstart.htm\' -Value $(\'Hello World from \' + $env:computername)
New-Item -Path \'c:\\inetpub\\wwwroot\' -Name \'image\' -Itemtype \'Directory\'
New-Item -Path \'c:\\inetpub\\wwwroot\\image\\\' -Name \'iisstart.htm\' -ItemType \'file\'
Add-Content -Path \'C:\\inetpub\\wwwroot\\image\\iisstart.htm\' -Value $(\'Image from: \' + $env:computername)
New-Item -Path \'c:\\inetpub\\wwwroot\' -Name \'video\' -Itemtype \'Directory\'
New-Item -Path \'c:\\inetpub\\wwwroot\\video\\\' -Name \'iisstart.htm\' -ItemType \'file\'
Add-Content -Path \'C:\\inetpub\\wwwroot\\video\\iisstart.htm\' -Value $(\'Video from: \' + $env:computername)