# `git.ps1`

## Prerequisite

Minimal read-only access to Git repositories is required.

## Usage

```
NAME
    git.ps1
    
SYNOPSIS
    Capture Git Commit metrics
    
    
SYNTAX
    git.ps1 [-CloneRoot] <String> [-Repositories] <String> [-Since] <String> [[-IssueKeyPattern] <String>] [-OutputFormat] <String> [<CommonParameters>]
    
    
DESCRIPTION
    This script captures Git Commit metrics and generates reports in either JSON or CSV format.
    

PARAMETERS
    -CloneRoot <String>
        Git clone root (e.g., user@host:root_path) (Required)
        
        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Repositories <String>
        Git repositories (comma separated) (Required)
        
        Required?                    true
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Since <String>
        Only search commits after a certain date (yyyy-MM-dd) (Required)
        
        Required?                    true
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -IssueKeyPattern <String>
        Issue key pattern in regular expression format (e.g., "JIRA-xxx") (Optional)
        
        Required?                    false
        Position?                    4
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -OutputFormat <String>
        Output format (JSON or CSV) (Optional, Default: JSON)
        
        Required?                    true
        Position?                    5
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

### Linux & Mac

If JIRA ticket(s) is referenced in the commit message:

```shell
$ pwsh git.ps1 -CloneRoot "git@<git repo host>" \
    -Repositories "repo_1.git,repo_2.git" \
    -Since "2020-01-01" \
    -IssueKeyPattern "(JIRA-\d+)" \
    -OutputFormat "JSON" \
    -Verbose
```

If JIRA ticket(s) is not referenced in the commit message:

```shell
$ pwsh git.ps1 -CloneRoot "git@<git repo host>" \
    -Repositories "repo_1.git,repo_2.git" \
    -Since "2020-01-01" \
    -OutputFormat "JSON" \
    -Verbose
```

### Windows

If JIRA ticket(s) is referenced in the commit message:

```shell
.\git.ps1 -CloneRoot "git@<git repo host>" `
    -Repositories "repo_1.git,repo_2.git" `
    -Since "2020-01-01" `
    -IssueKeyPattern "(JIRA-\d+)" `
    -OutputFormat "JSON" `
    -Verbose
```

If JIRA ticket(s) is not referenced in the commit message:

```shell
.\git.ps1 -CloneRoot "git@<git repo host>" `
    -Repositories "repo_1.git,repo_2.git" `
    -Since "2020-01-01" `
    -OutputFormat "JSON" `
    -Verbose
```
