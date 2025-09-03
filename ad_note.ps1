# Define the Distinguished Name (DN) of the user object
$UserDN = "LDAP://CN=Jane Doe,OU=Sales,DC=example,DC=com"

# Create an ADSI object for the user
try {
    $ADUser = [ADSI]$UserDN
} catch {
    Write-Host "Error connecting to AD object: $($_.Exception.Message)"
    exit
}

# Update the DisplayName and Department attributes
$ADUser.Properties["displayName"].Value = "Jane A. Doe"
$ADUser.Properties["department"].Value = "Marketing"

# Commit the changes to Active Directory
try {
    $ADUser.SetInfo()
    Write-Host "User attributes updated successfully."
} catch {
    Write-Host "Error updating user attributes: $($_.Exception.Message)"
}
