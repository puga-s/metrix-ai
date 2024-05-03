# `jira.ps1`

## Usage

```

NAME
    jira.ps1
    
SYNOPSIS
    Capture JIRA metrics
    
    
SYNTAX
    jira.ps1 [-ApiUrl] <String> [-Username] <String> [-ApiToken] <String> [[-Projects] <String>] [-Since] <String> [[-ExtraFields] <String>] [[-OutputFormat] <String>] [<CommonParameters>]
    
    
DESCRIPTION
    This script captures JIRA metrics and generates reports in either JSON or CSV format.
    

PARAMETERS
    -ApiUrl <String>
        JIRA API URL (Required)
        
    -Username <String>
        JIRA Username (Required)
        
    -ApiToken <String>
        JIRA API Token - https://id.atlassian.com/manage-profile/security/api-tokens (Required)
        
    -Projects <String>
        JIRA Projects, comma separated (Optional)
        
    -Since <String>
        Only search tickets that were created after a certain date (yyyy-MM-dd) (Required)
        
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
        
    -OutputFormat <String>
        Output format (JSON or CSV) (Optional, Default: JSON)
        
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
