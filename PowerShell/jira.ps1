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

    function Get-JiraTicket {
        [CmdletBinding()]
        param (
            $ApiUrl,
            $AuthHeader,
            $Projects,
            $Since,
            $Fields,
            $ExtraFields
        )
        process {
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

            $fieldList = ($null -eq $ExtraFields ? $Fields : ($Fields += $ExtraFields -split ",")) -join ","

            $startAt = 0
            $maxResults = 100
    
            $report = @()
            $tickets = @()

            do {
                
                $url = "$($ApiUrl)/rest/api/2/search?startAt=$($startAt)&maxResults=$($maxResults)&jql=$($jql)&fields=$($fieldList)"
                
                Write-Verbose "Retrieve next batch tickets from $($url)"
                
                $response = Invoke-RestMethod $url -Method 'GET' -Headers $headers
    
                $startAt = $response.startAt + $response.maxResults
    
                if ($startAt -lt $response.total) {
                    $moreResult = $true
                }
                else {
                    $moreResult = $false
                }
    
                $response.issues | ForEach-Object {
                    $item = $_
                    $tickets += [PSCustomObject]@{
                        IssueKey = $item.key
                        Url      = $item.self
                    }
                    $properties = [ordered]@{
                        IssueType      = $_.fields.issuetype.name
                        IssueKey       = $_.key
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
                    if ($null -ne $ExtraFields -and $ExtraFields -notmatch "") {
                        $ExtraFields | ForEach-Object {
                            $properties[$_] = $item.fields.$_
                        }
                    }

                    $report += New-Object PSObject -Property $properties
                }
    
            } while ($moreResult -eq $true)

            $report, $tickets
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
            $Since
        )
        process {
            $dateTime = [System.DateTime]::Parse($Since)
            $utcDateTime = [System.TimeZoneInfo]::ConvertTimeToUtc($dateTime)
            $sinceUtm = [System.DateTimeOffset]::new($utcDateTime).ToUnixTimeMilliseconds()
    
            $aggregatedWorklogs = @()

            $lastPage = $false
            $nextPage = [string] $null
            do {
                $updatedWorklogIds = Get-UpdatedWorklogIds -ApiUrl $ApiUrl -AuthHeader $AuthHeader -Since $sinceUtm -NextPage $nextPage
                $lastPage = $updatedWorklogIds.LastPage
                $nextPage = $updatedWorklogIds.NextPage
                $workLogs = Get-Worklogs -ApiUrl $ApiUrl -AuthHeader $AuthHeader -UpdatedWorkLogIds $updatedWorklogIds.Ids
                
                $aggregatedWorklogs += $workLogs
        
            } while ( $lastPage -eq $false)

            $aggregatedWorklogs
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

    $fileSuffix = (Get-Date -Format "yyyyMMddHHmmss")

    $authHeader = Get-BasicAuthHeader -Username $Username -ApiToken $ApiToken

    $ticketReport, $tickets = Get-JiraTicket -ApiUrl $ApiUrl -AuthHeader $authHeader -Projects $Projects -Since $Since -Fields $fixedFields -ExtraFields $ExtraFields

    $assigneeReport, $statusReport, $relatedReport = Get-JiraMetrics -AuthHeader $authHeader -Tickets $tickets

    $worklogReport = Get-WorklogMetrics -ApiUrl $ApiUrl -AuthHeader $authHeader -Since $Since

    switch ($OutputFormat) {
        "JSON" {
            $ticketReport | ConvertTo-Json | Out-File -FilePath "jira_ticket_$($fileSuffix).json"
            $assigneeReport | ConvertTo-Json | Out-File -FilePath "jira_assignee_$($fileSuffix).json"
            $statusReport | ConvertTo-Json | Out-File -FilePath "jira_status_$($fileSuffix).json"
            $relatedReport | ConvertTo-Json | Out-File -FilePath "jira_related_$($fileSuffix).json"
            $worklogReport | ConvertTo-Json | Out-File -FilePath "jira_worklog_$($fileSuffix).json"
        }
        "CSV" {
            $ticketReport | Export-Csv -Path "jira_ticket_$($fileSuffix).csv" -NoTypeInformation
            $assigneeReport | Export-Csv -Path "jira_assignee_$($fileSuffix).csv" -NoTypeInformation
            $statusReport | Export-Csv -Path "jira_status_$($fileSuffix).csv" -NoTypeInformation
            $relatedReport | Export-Csv -Path "jira_related_$($fileSuffix).csv" -NoTypeInformation
            $worklogReport | Export-Csv -Path "jira_worklog_$($fileSuffix).csv" -NoTypeInformation
        }
    }
}