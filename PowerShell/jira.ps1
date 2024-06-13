<#
	.SYNOPSIS
		Capture JIRA metrics
	
	.DESCRIPTION
		This script captures JIRA metrics and generates reports in either JSON or CSV format.
	
	.PARAMETER ApiUrl
		JIRA API URL (Required) 
	
	.PARAMETER Username
		JIRA Username (Required)

	.PARAMETER ApiToken
		JIRA API Token - https://id.atlassian.com/manage-profile/security/api-tokens (Required)
	
	.PARAMETER Projects
		JIRA Projects, comma separated (Optional) 
    
    .PARAMETER Since
        Only search tickets that were created after a certain date (yyyy-MM-dd) (Required)
    
    .PARAMETER ExtraFields
        In addition to following fields, you can also specify additional fields (comma separated) to be included in the report. (Optional)
        * parent
        * assignee
        * reporter
        * issuetype
        * summary
        * status
        * creator
        * created
        * fixVersions
        * aggregatetimeoriginalestimate
        * aggregatetimespent
        * updated
        * project
        * projectType
        * priority
        * resolution
        * resolutiondate

    .PARAMETER MaxResultsPerFile
        Maximum number of results per file (jira_ticket_*) (Optional, Default: 1000)   

    .PARAMETER OutputFormat
        Output format (JSON or CSV) (Optional, Default: JSON)

#>
[CmdletBinding()]

param (
    [Parameter(Mandatory = $true)]
    [String] $ApiUrl,
    [Parameter(Mandatory = $true)]
    [string] $Username,
    [Parameter(Mandatory = $true)]
    [string] $ApiToken,
    [Parameter(Mandatory = $false)]
    [string] $Projects = $null,
    [Parameter(Mandatory = $true)]
    [string] $Since,
    [Parameter(Mandatory = $false)]
    [string] $ExtraFields = $null,
    [Parameter(Mandatory = $false)]
    [int] $MaxResultsPerFile = 1000,
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV")]
    [string] $OutputFormat = "JSON"
)

process {

    #----------------[ Functions ]------------------

    function Format-DateTimeOffset {
        [CmdletBinding()]
        param (
            $Date
        )

        process {
            $null -eq $Date ? $null : ([System.DateTimeOffset]$Date).ToString("yyyy-MM-ddTHH:mm:ss.fffzzz")
        }
    }

    function Get-BasicAuthHeader {
        param (
            $Username,
            $ApiToken
        )

        process {
            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Username, $ApiToken)))
            return "Basic $base64AuthInfo"
        }
    }

    function Get-CustomFieldMedataData {
        [CmdletBinding()]
        param (
            $ApiUrl,
            $AuthHeader,
            $ExtraFields
        )
        process {
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", $AuthHeader)
    
            $fields = $ExtraFields -split "," | ForEach-Object { $_.Trim() } 

            $metadata = @{}
            $url = "$($ApiUrl)/rest/api/2/field"
            Write-Verbose "Retrieve custom field metadata from $($url)"
            $response = Invoke-RestMethod $url -Method 'GET' -Headers $headers
            $response | ForEach-Object {
                if ($fields -contains $_.id) {
                    $metadata[$_.id] = $_.name
                }
            }

            $metadata
        }
    }

    function Get-JiraTicket {
        [CmdletBinding()]
        param (
            $ApiUrl,
            $AuthHeader,
            $Projects,
            $Since,
            $Fields,
            $ExtraFields,
            $StartAt,
            $MaxResults
        )
        process {

            if ($null -ne $ExtraFields -and $ExtraFields -ne "") {
                $customFieldMetadata = Get-CustomFieldMedataData -ApiUrl $ApiUrl -AuthHeader $AuthHeader -ExtraFields $ExtraFields
            }
            else {
                $customFieldMetadata = $null
            }

            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", $AuthHeader)
    
            $rawJql = ""
            if ($null -ne $Projects -and $Projects -ne "") {
                $projectList = ($Projects.Split(",") | ForEach-Object { $_ -match "\s" ? "`"$($_)`"" : $_ } ) -join ","
                $rawJql = "project in ($($projectList)) and " 
            }

            $rawJql += "created >= $($Since) order by created ASC"
            
            Write-Verbose "rawJql: $($rawJql)"
            
            $jql = [System.Web.HttpUtility]::UrlEncode($rawJql)

            $fieldList = (($null -eq $ExtraFields -and $ExtraFields -ne "") ? $Fields : ($Fields += $ExtraFields -split ",")) -join ","
            
            $report = @()
            $tickets = @()
            $extendedAttribute = @()

            $url = "$($ApiUrl)/rest/api/2/search?startAt=$($StartAt)&maxResults=$($MaxResults)&jql=$($jql)&fields=$($fieldList)"
                
            Write-Verbose "Retrieve next batch tickets from $($url)"
                
            $response = Invoke-RestMethod $url -Method 'GET' -Headers $headers
    
            $local:nextStartAt = $response.startAt + $response.maxResults
    
            if ($startAt -lt $response.total) {
                $local:moreResult = $true
            }
            else {
                $local:moreResult = $false
            }
    
            $response.issues | ForEach-Object {
                $item = $_
                $tickets += [PSCustomObject]@{
                    IssueKey = $item.key
                    Url      = $item.self
                }
                $issueKey = $_.key
                $fields = $_.fields
                $properties = [ordered]@{
                    IssueType      = $_.fields.issuetype.name
                    IssueKey       = $issueKey
                    IssueId        = $_.id
                    ParentKey      = $_.fields.parent.key
                    ParentType     = $_.fields.parent.fields.issuetype.name
                    Release        = ($_.fields.fixVersions | ForEach-Object { $_.name }) -join ","
                    Status         = $_.fields.status.name
                    Summary        = $_.fields.summary
                    Assignee       = $_.fields.assignee.displayName
                    Reporter       = $_.fields.reporter.displayName
                    Created        = (Format-DateTimeOffset -Date $_.fields.created)
                    Updated        = (Format-DateTimeOffset -Date $_.fields.updated)
                    TimeEstimate   = $_.fields.aggregatetimeoriginalestimate
                    TimeSpent      = $_.fields.aggregatetimespent
                    ProjectType    = $_.fields.project.projectTypeKey
                    Project        = $_.fields.project.name
                    Priority       = $_.fields.priority.name
                    Resolution     = $_.fields.resolution.name
                    ResolutionDate = (Format-DateTimeOffset -Date $_.fields.resolutiondate)
                }
                $report += New-Object PSObject -Property $properties

                if ($null -ne $customFieldMetadata) {
                    $customFieldMetadata.GetEnumerator() | ForEach-Object {
                        $value = $fields."$($_.Key)"
                        if ($null -ne $value) {
                            $extendedAttribute += [PSCustomObject]@{
                                IssueKey       = $issueKey
                                AttributeName  = $_.Value
                                AttributeId    = $_.Key
                                AttributeValue = $value.ToString()
                            }
                        }
                        
                    }
                }               
            }

            $report, $extendedAttribute, $tickets, $local:moreResult, $local:nextStartAt
        }
    }

    function Get-JiraMetrics {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string] $AuthHeader,
            [Parameter(Mandatory = $true)]
            [PSCustomObject]$Tickets
        )

        process {

            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", $AuthHeader)

            $assigneeReport = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
            $statusReport = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
            $relatedReport = [System.Collections.Concurrent.ConcurrentBag[object]]::new()

            $dtFormatFuncDef = ${function:Format-DateTimeOffset}.ToString()

            $Tickets | ForEach-Object {
                [PSCustomObject]@{
                    IssueKey = $_.IssueKey
                    Url      = $_.Url
                    Headers  = $headers
                }
            }
            | ForEach-Object -Parallel {
                $assigneeRpt = $using:assigneeReport
                $statusRpt = $using:statusReport
                $relatedRpt = $using:relatedReport
                ${function:Format-DateTimeOffset} = $using:dtFormatFuncDef
                $url = "$($_.Url)?expand=changelog&fields=issuelinks"
                Write-Verbose "Get metrics for $($_.IssueKey) from  $($url)" -Verbose:($using:VerbosePreference -eq 'Continue')
                $response = Invoke-RestMethod $url -Method 'GET' -Headers $_.Headers
                $issueKey = $response.key
                $response.changelog.histories 
                | ForEach-Object { 
                    $created = $_.created
                    $historyId = $_.id
                    $updatedBy = $_.author.displayName
                    $_.items | ForEach-Object { 
                        [pscustomobject]@{
                            historyId  = $historyId
                            created    = $created
                            updatedBy  = $updatedBy
                            field      = $_.field
                            fromString = $_.fromString
                            toString   = $_.toString
                        } 
                    }
                } 
                | ForEach-Object {
                    if ($_.field -eq "assignee") {
                        $assigneeRpt.Add([pscustomobject] @{
                                HistoryId    = $historyId                            
                                IssueKey     = $issueKey
                                UpdatedAt    = (Format-DateTimeOffset -Date $_.created)
                                UpdatedBy    = $updatedBy
                                FromAssignee = $_.fromString
                                ToAssignee   = $_.toString
                            }      )
                    }
                    if ($_.field -eq "status") {
                        $statusRpt.Add([pscustomobject] @{   
                                HistoryId  = $historyId                         
                                IssueKey   = $issueKey
                                UpdatedAt  = (Format-DateTimeOffset -Date $_.created)
                                UpdatedBy  = $updatedBy
                                FromStatus = $_.fromString
                                ToStatus   = $_.toString
                            })      
                    }
                }
                $response.fields.issuelinks 
                | Where-Object { $null -ne $_.outwardIssue }
                | ForEach-Object {
                    $relatedRpt.Add([pscustomobject]@{
                            IssueKey        = $issueKey
                            RelatedIssueKey = $_.outwardIssue.Key
                            RelatedType     = $_.type.name
                        })
                }  
            }

            $assigneeReport, $statusReport, $relatedReport
        }
    }

    function Get-UpdatedWorklogIds {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            $ApiUrl,
            [Parameter(Mandatory = $true)]
            $AuthHeader,
            [Parameter(Mandatory = $false)]
            $Since,
            [Parameter(Mandatory = $false)]
            $NextPage
        )
        process {
            $ids = @()
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", $AuthHeader)
            if ($NextPage) {
                $url = $NextPage
            }
            else {
                $url = "$($ApiUrl)/rest/api/2/worklog/updated?since=$($Since)"
            }
            Write-Verbose "Get IDs of updated worklogs from $($url)"
            $response = Invoke-RestMethod $url -Method 'GET' -Headers $headers
            $response.values | ForEach-Object {
                $id = [int] $_.worklogId
                $ids += $id
            }
    
            @{
                Ids      = $ids
                LastPage = $response.lastPage
                NextPage = $response.nextPage
            }
        }
    }

    function Get-Worklogs {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            $ApiUrl,
            [Parameter(Mandatory = $true)]
            $AuthHeader,
            [Parameter(Mandatory = $true)]
            $UpdatedWorkLogIds
        )
    
        process {
            $worklogs = @()
    
            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Authorization", $AuthHeader)
            $headers.Add("Accept", "application/json")
            $headers.Add("Content-Type", "application/json")
    
            $requestBody = New-Object -TypeName psobject -Property @{ ids = $UpdatedWorkLogIds } | ConvertTo-Json
            
            $worklogIds = ($UpdatedWorkLogIds | ForEach-Object { "$($_)" } ) -join ","
            $url = "$($ApiUrl)/rest/api/2/worklog/list"
            Write-Verbose "Get worklogs ($($worklogIds)) from $($ApiUrl)"
            $response = Invoke-RestMethod $url -Method 'POST' -Headers $headers -Body $requestBody
    
            $response | ForEach-Object {
                $worklogs += [PSCustomObject]@{
                    Author           = $_.author.displayName
                    UpdateAuthor     = $_.updateAuthor.displayName
                    WorklogId        = $_.id
                    IssueId          = $_.issueId
                    Created          = (Format-DateTimeOffset -Date $_.created)
                    Updated          = (Format-DateTimeOffset -Date $_.updated)
                    Started          = (Format-DateTimeOffset -Date $_.started)
                    TimeSpentSeconds = $_.timeSpentSeconds
                }
            }
    
            $worklogs
        }
    }

    function Get-WorklogMetrics {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            $ApiUrl,
            [Parameter(Mandatory = $true)]
            $AuthHeader,
            [Parameter(Mandatory = $true)]
            $Since,
            [string] $NextPage
        )
        process {
            $dateTime = [System.DateTime]::Parse($Since)
            $utcDateTime = [System.TimeZoneInfo]::ConvertTimeToUtc($dateTime)
            $sinceUtm = [System.DateTimeOffset]::new($utcDateTime).ToUnixTimeMilliseconds()
    
            $aggregatedWorklogs = @()

            $lastPage = $false

            $updatedWorklogIds = Get-UpdatedWorklogIds -ApiUrl $ApiUrl -AuthHeader $AuthHeader -Since $sinceUtm -NextPage $NextPage
            $lastPage = $updatedWorklogIds.LastPage
            $nextPage2 = $updatedWorklogIds.NextPage
            $workLogs = Get-Worklogs -ApiUrl $ApiUrl -AuthHeader $AuthHeader -UpdatedWorkLogIds $updatedWorklogIds.Ids
                
            $aggregatedWorklogs += $workLogs

            $aggregatedWorklogs, $lastPage, $nextPage2
        }
    }

    #----------------[ Declarations ]----------------

    $fixedFields = @(
        "parent",
        "assignee",
        "reporter",
        "issuetype",
        "summary",
        "status",
        "creator",
        "created",
        "fixVersions",
        "aggregatetimeoriginalestimate",
        "aggregatetimespent",
        "progress",
        "updated",
        "project",
        "priority",
        "resolution",
        "resolutiondate"
    )

    #----------------[ Main ]----------------


    $authHeader = Get-BasicAuthHeader -Username $Username -ApiToken $ApiToken

    $startAt = 0

    $aggregatedTicketReport = @()
    $aggregatedExtendedAttributeReport = @()
    $aggregatedAssigneeReport = @()
    $aggregatedStatusReport = @()
    $aggregatedRelatedReport = @()

    do {
        $fileSuffix = (Get-Date -Format "yyyyMMddHHmmss")

        $ticketReport, $extendedAttribute, $tickets, $moreResult, $nextStartAt = Get-JiraTicket -ApiUrl $ApiUrl `
            -AuthHeader $authHeader `
            -Projects $Projects `
            -Since $Since `
            -Fields $fixedFields `
            -ExtraFields $ExtraFields `
            -StartAt $startAt `
            -MaxResults $MaxResultsPerFile

        $startAt = $nextStartAt

        $assigneeReport, $statusReport, $relatedReport = Get-JiraMetrics -AuthHeader $authHeader -Tickets $tickets

        $aggregatedTicketReport += $ticketReport
        $aggregatedExtendedAttributeReport += $extendedAttribute
        $aggregatedAssigneeReport += $assigneeReport
        $aggregatedStatusReport += $statusReport
        $aggregatedRelatedReport += $relatedReport

        if ($aggregatedTicketReport.Count -ge $MaxResultsPerFile -or $moreResult -eq $false) {
            switch ($OutputFormat) {
                "JSON" {
                    $aggregatedTicketReport | ConvertTo-Json | Out-File -FilePath "jira_ticket_$($fileSuffix).json"
                    if ($aggregatedExtendedAttributeReport.Count -gt 0) {
                        $aggregatedExtendedAttributeReport | Convertto-Json | Out-File -FilePath "jira_extended_attribute_$($fileSuffix).json"
                    }
                    $aggregatedAssigneeReport | ConvertTo-Json | Out-File -FilePath "jira_assignee_$($fileSuffix).json"
                    $aggregatedStatusReport | ConvertTo-Json | Out-File -FilePath "jira_status_$($fileSuffix).json"
                    $aggregatedRelatedReport | ConvertTo-Json | Out-File -FilePath "jira_related_$($fileSuffix).json"
                }
                "CSV" {
                    $aggregatedTicketReport | Export-Csv -Path "jira_ticket_$($fileSuffix).csv" -NoTypeInformation
                    if ($aggregatedExtendedAttributeReport.Count -gt 0) {
                        $aggregatedExtendedAttributeReport | Export-Csv -Path "jira_extended_attribute_$($fileSuffix).csv" -NoTypeInformation
                    }
                    $aggregatedAssigneeReport | Export-Csv -Path "jira_assignee_$($fileSuffix).csv" -NoTypeInformation
                    $aggregatedStatusReport | Export-Csv -Path "jira_status_$($fileSuffix).csv" -NoTypeInformation
                    $aggregatedRelatedReport | Export-Csv -Path "jira_related_$($fileSuffix).csv" -NoTypeInformation
                }
            }
            $aggregatedTicketReport = @()
            $aggregatedAssigneeReport = @()
            $aggregatedStatusReport = @()
            $aggregatedRelatedReport = @()
        }
        
    } while ($moreResult -eq $true)

    $nextPage = [string] $null
    do {
        $fileSuffix = (Get-Date -Format "yyyyMMddHHmmss")

        $worklogReport, $lastPage, $nextPage2 = Get-WorklogMetrics -ApiUrl $ApiUrl `
            -AuthHeader $authHeader `
            -Since $Since `
            -NextPage $nextPage

        $nextPage = $nextPage2

        switch ($OutputFormat) {
            "JSON" {
                $worklogReport | ConvertTo-Json | Out-File -FilePath "jira_worklog_$($fileSuffix).json"
            }
            "CSV" {
                $worklogReport | Export-Csv -Path "jira_worklog_$($fileSuffix).csv" -NoTypeInformation
            }
        }

    } while ($lastPage -eq $false)
}