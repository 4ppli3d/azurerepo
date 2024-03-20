param (
    [Parameter(Mandatory=$true)]
    [string]$InputCsvPath

    [Parameter(Mandatory=$true)]
    [string]$OutputCsvPathAndFileName
)

# Connect to Microsoft Graph
# Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All"

# Import a CSV file
$data = Import-Csv -Path $InputCsvPath

# Get the 'id' column
$idColumn = $data.id

# Create an empty array to store the results
$results = @()

# Iterate over the group IDs to get Members of the groups
foreach ($id in $idColumn) {
    # Get the group members
    $members = Get-MgGroupMember -GroupId $id

    # Iterate over the members
    foreach ($member in $members) {

        # Group IDs to Group Name
        $groupName = Get-MgGroup -GroupId $id

        # Member IDs to Member Name
        $memberName = Get-MgUser -UserId $member.Id

        # Add the member to the results
        $results += New-Object PSObject -Property @{
            'GroupName' = $groupName.DisplayName
            'GroupId' = $id
            'MemberName' = $memberName.DisplayName
            'MemberId' = $member.Id
        }
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path $OutputCsvPathAndFileName -NoTypeInformation