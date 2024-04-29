# `jira.ps1`

## Usage

```

NAME
    /Users/yafeiliu/Projects/OptiCloudPros/metrix-ai/PowerShell/jira.ps1
    
SYNOPSIS
    Capture JIRA metrics
    
    
SYNTAX
    /Users/yafeiliu/Projects/OptiCloudPros/metrix-ai/PowerShell/jira.ps1 [-ApiUrl] <String> [-Username] <String> [-ApiToken] <String> [[-Projects] <String>] [-Since] <String> [[-ExtraFields] <String>] [[-OutputFormat] <String>] [<CommonParameters>]
    
    
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
    
REMARKS
    To see the examples, type: "Get-Help /Users/yafeiliu/Projects/OptiCloudPros/metrix-ai/PowerShell/jira.ps1 -Examples"
    For more information, type: "Get-Help /Users/yafeiliu/Projects/OptiCloudPros/metrix-ai/PowerShell/jira.ps1 -Detailed"
    For technical information, type: "Get-Help /Users/yafeiliu/Projects/OptiCloudPros/metrix-ai/PowerShell/jira.ps1 -Full"
```

## Sample

### Linux & Mac

```shell
$ pwsh jira.ps1 -ApiUrl "https://<company>.atlassian.net" \
    -Username "<jira.user.login>" \
    -ApiToken "<jira.user.api.token>" \
    -Project "project_1,project_2" \
    -Since "2020-01-01" \
    -OutputFormat "JSON" \
    -Verbose
```

### Windows

```shell
.\jira.ps1 -ApiUrl "https://<company>.atlassian.net" `
    -Username "<jira.user.login>" `
    -ApiToken "<jira.user.api.token>" `
    -Project "project_1,project_2" `
    -Since "2020-01-01" `
    -OutputFormat "JSON" `
    -Verbose
```