# Title: Password reset script
#
# Author: 	Sven De Preter
# Version: 	1.0
#
# Description:
#	This script will allow you to reset the Domain users password, as well as the office 365 password
#	It should be run as an account with administrative privileges
# 	The script will gather and verify information first, and ask for a password reset confirmation prior to changing the password
#	Also, the user will be asked if they want to share their password with us or not. The pw-file is stored in c:\tmp\pw.txt
#
# Requirements:
# - Windows management framework 4.0
# - Remote Server Administration Tools (Enable AD Powershell features using add programs/roles & features)
# - Microsoft Online Services Sign-in Assistant for IT Professonals RTW
# - Windows Azure Active Directory Module for Windows Powershell (64-bit version)
# More info: https://technet.microsoft.com/en-us/library/dn975125.aspx


# Get all needed information



$domainUser=Read-Host -Prompt "Enter the Domain Account (login)" 

$domainUserPassword=Read-Host -Prompt "Enter the NEW password" -AsSecureString 
$domainUserPasswordConfirm=Read-Host -Prompt "Enter the NEW password again" -AsSecureString

# Check if password and confirmation are equal, else exit
$dup_txt=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($domainUserPassword))
$dupc_txt=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($domainUserPasswordConfirm))
if ($dup_txt -ceq $dupc_txt)
{
	Write-Host "Passwords match"
}
else
{
	Write-Warning "Passwords don't match. Exiting"
	Exit
	
}


#check if domain user is found, else exit
if (Get-ADUser -Filter {samAccountName -eq $domainUser})
{
	Get-ADUser -Identity $domainUser | ft
	Write-Host "Domain user found"
}
else
{ 
	Write-warning "Domain user not found. Exiting!"
	Exit
}

$office365Login=Read-Host -Prompt "Enter the Office365 Account"
$office365AdminCredentials = Get-Credential -Message "Enter the Office365 Administrative User"

# check if the office administrator is a valid account
try
{
	Connect-MsolService -Credential $office365AdminCredentials -ErrorAction Stop
}
catch {
	Write-Warning  "Error. Could not connect to MS Online service becasue $_ .Exiting" 
	exit

}
	
# check if the office user is valid

try
{
$user=Get-MsolUser -UserPrincipalName $office365Login -ErrorAction stop
$user | ft
}
catch
{
	Write-warning "Office 365 User not found! "
	Write-Warning "Reason: $_"
	Write-Warning "Exiting"
	exit
}

# when we get here, all is verified and we can start the password reset
$confTitle="Are you sure ?"
$confMess="Do you really want to reset the userpassword for domain user: $domainuser and office365 user: $office365Login"
$confYes=New-Object system.Management.Automation.Host.ChoiceDescription "&Yes", "I want to reset the password"
$confNo=New-Object system.Management.Automation.Host.ChoiceDescription "&No","I don't want to reset the password"
$confOptions=[System.Management.Automation.Host.ChoiceDescription[]]($confYes,$confNo)
$confResult=$Host.UI.PromptForChoice($confTitle,$confMess,$confOptions,0)
switch( $confResult)
{
	0 {
		Write-Host "Resetting password ..."
		try{
			#Set-ADAccountPassword -Reset -NewPassword $domainUserPassword -Identity $domainUser
			Write-Host "Password for user $domainuser successfully reset"
		}
		catch{
			Write-Warning "Something went wrong while resetting the AD Password: $_"
			Exit
		}
		
		try	{
			#Set-MsolUserPassword -UserPrincipalName $office365Login -NewPassword $dup_txt -ForceChangePassword $false
			Write-Host "Password for office365 user $Office365Login successfully reset"
		}
		catch{
			Write-Warning "Something went wrong resetting the Office365 Password :$_"
			Exit
		}
		}
	1 {
		Write-Warning "User chose not to reset the password! Exiting"
		Exit
		}
}


$dateOfReset=Get-Date
$encKey=(1..16)
$encPass=$domainUserPassword
$encPassword=ConvertFrom-SecureString -SecureString $encPass -Key $encKey

$dateOfReset,$domainUser,$office365Login,$dup_txt,$encPassword,"Shared" -join ';' | Out-File -FilePath "c:\tmp\pw.txt" -Append 




# disconnect Session
try
{
	Get-PSSession |Remove-PSSession -ErrorAction Stop
}
catch
{
	Write-Warning "Error. Could not remove session because $_"
}
