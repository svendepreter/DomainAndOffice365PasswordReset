$encPassword=Read-Host -Prompt "Enter the encrypted password"
$encKey=(1..16)
$encString=ConvertTo-SecureString -String $encPassword -Key $encKey
[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($encString))
