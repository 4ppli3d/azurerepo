param (
    [Parameter(Mandatory=$true)]
    [string]$CsvPath

    [Parameter(Mandatory=$true)]
    [string]$OutputCsvPathAndFileName
)

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All"

# Import a CSV file
$data = Import-Csv -Path $CsvPath

# Get the 'id' column
$idColumn = $data.id

# Create an empty array to store the results
$results = @()

# Iterate over the group IDs
foreach ($id in $idColumn) {
    # Get the group owners
    $owners = Get-MgGroupOwner -GroupId $id

    # Iterate over the owners
    foreach ($owner in $owners) {

        # Group IDs to Group Name
        $groupName = Get-MgGroup -GroupId $id

        # Owner IDs to Owner Name
        $ownerName = Get-MgUser -UserId $owner.Id

        # Add the owner to the results
        $results += New-Object PSObject -Property @{
            'GroupName' = $groupName.DisplayName
            'GroupId' = $id
            'OwnerName' = $ownerName.DisplayName
            'OwnerId' = $owner.Id
        }
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path $OutputCsvPathAndFileName -NoTypeInformation