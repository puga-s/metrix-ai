# `jira.ps1`

## Usage

```
NAME
    jira.ps1
    
SYNOPSIS
    Capture JIRA metrics
    
    
SYNTAX
    jira.ps1 [-ApiUrl] <String> [-Username] <String> [-Password] <String> [[-Projects] <String>] [-Since] <String> [[-ExtraFields] <String>] [-OutputFormat] <String> [<CommonParameters>]
    
    
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
        
    -Password <String>
        JIRA Password (Required)
        
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
        
    -OutputFormat <String>
        Output format (JSON or CSV) (Optional, Default: JSON)
        
        Required?                    true
        Position?                    7
        Default value                JSON
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216). 
    
INPUTS
    
OUTPUTS
    
    
RELATED LINKS
```

## Sample

```shell
$ pwsh jira.ps1 -ApiUrl "https://<company>.atlassian.net" \
    -Username "<jira.user.login>" \
    -Password "<jira.user.password>" \
    -Project "project_1,project_2" \
    -Since "2020-01-01" \
    -OutputFormat "JSON" \
    -Verbose
```
