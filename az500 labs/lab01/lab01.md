Senior Admins group with Joseph Price
Junior Admins group with Isabel Garcia
Service Desk group with Dylan Williams - Virtual Machine Contributor Role

az ad user create --display-name "Dylan Williams" --password "placeholderpass!111" --user-principal-name "Dylan.Williams@Andriuslab.onmicrosoft.com"

az ad group create --display-name "Senior Admins"

![alt text](image.png)
![alt text](image-1.png)

$user = az ad user show --id "Dylan.Williams@Andriuslab.onmicrosoft.com" --query id --output tsv
az ad group member add --group "Service Desk" --member-id $user

![alt text](image-2.png)

az group create --location uksouth --name TestScopeRG

az role definition list --name "Virtual Machine Contributor" --query "[].name"

az role assignment create --assignee "4486b84a-ebe6-4550-b858-e96fe8362f85" --role "9980e02c-c2be-4d73-94e8-173b1dc7cf3c" --scope "/subscriptions/f840b6f5-6a35-4434-9323-89c7b8722b47/resourceGroups/TestScopeRG"

![alt text](image-3.png)



