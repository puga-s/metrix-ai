# `jira.ps1`

## `-ExtraFields` option

The `-ExtraFields` parameter is utilized for specifying a list of comma-separated field names that you wish to retrieve from JIRA. These field names should be provided in user-friendly format, such as `Story point` instead of their internal, technical identifiers (like `customfield_10000`). 

The search process employs a case-insensitive regular expression method, meaning it will (partial) match any field name that corresponds to the specified input, regardless of its case. For instance, if you enter `store point`, both `Stor Point` and `Estimated Story points` would be considered as matches.

To optimize your data extraction from JIRA, we highly recommend using this `-ExtraFields` option when seeking out _**story point**_ fields or any other custom attributes related to tagging _**production issues**_ and managing _**tech debt**_ or _**maintenance tasks**_. 

## Usage

```
NAME
    jira.ps1
    
SYNOPSIS
    Capture JIRA metrics
    
    
SYNTAX
    jira.ps1 [-ApiUrl] <String> [-Username] <String> [-ApiToken] <String> [[-Projects] <String>] [-Since] <String> [[-ExtraFields] <String>] [[-MaxResultsPerFile] <Int32>] [[-OutputFormat] <String>] [<CommonParameters>]
    
    
DESCRIPTION
    This script captures JIRA metrics and generates reports in either JSON or CSV format.
    

PARAMETERS
    -ApiUrl <String>
        JIRA API URL (Required)
        
        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Username <String>
        JIRA Username (Required)
        
        Required?                    true
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -ApiToken <String>
        JIRA API Token - https://id.atlassian.com/manage-profile/security/api-tokens (Required)
        
        Required?                    true
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Projects <String>
        JIRA Projects, comma separated (Optional)
        
        Required?                    false
        Position?                    4
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Since <String>
        Only search tickets that were created after a certain date (yyyy-MM-dd) (Required)
        
        Required?                    true
        Position?                    5
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -ExtraFields <String>
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
        
        Required?                    false
        Position?                    6
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -MaxResultsPerFile <Int32>
        Maximum number of results per file (jira_ticket_*) (Optional, Default: 1000)
        
        Required?                    false
        Position?                    7
        Default value                1000
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -OutputFormat <String>
        Output format (JSON or CSV) (Optional, Default: JSON)
        
        Required?                    false
        Position?                    8
        Default value                JSON
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216). 
```

## Sample

> **Username** should be the email address.
> 
> **Project** should be the project `Key` (Project → view all projects → Key column)

### Linux & Mac

```shell
$ pwsh jira.ps1 -ApiUrl "https://<company>.atlassian.net" \
    -Username "<jira.user.email>" \
    -ApiToken "<jira.user.api.token>" \
    -Project "project_key_1,project_key_2" \
    -Since "2020-01-01" \
    -OutputFormat "JSON" \
    -Verbose
```

### Windows

```shell
.\jira.ps1 -ApiUrl "https://<company>.atlassian.net" `
    -Username "<jira.user.email>" `
    -ApiToken "<jira.user.api.token>" `
    -Project "project_key_1,project_key_2" `
    -Since "2020-01-01" `
    -OutputFormat "JSON" `
    -Verbose
```

#### Hints
If unable to run Powershell. Check and Set Execution policy accordingly
```shell
Get-ExecutionPolicy -List
Set-ExecutionPolicy Unrestricted
```
