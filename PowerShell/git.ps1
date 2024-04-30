<#
	.SYNOPSIS
		Capture Git Commit metrics
	
	.DESCRIPTION
		This script captures Git Commit metrics and generates reports in either JSON or CSV format.
	
	.PARAMETER CloneRoot
		Git clone root (e.g., user@host:root_path) (Required)
	
	.PARAMETER Repositories
		Git repositories (comma separated) (Required)
    
    .PARAMETER Since
        Only search commits after a certain date (yyyy-MM-dd) (Required)
    
    .PARAMETER IssueKeyPattern
        Issue key pattern in regular expression format (e.g., "JIRA-xxx") (Optional)
        
    .PARAMETER OutputFormat
        Output format (JSON or CSV) (Optional, Default: JSON)

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String] $CloneRoot,
    [Parameter(Mandatory = $true)]
    [string] $Repositories,
    [Parameter(Mandatory = $true)]
    [string] $Since,
    [Parameter(Mandatory = $false)]
    [string] $IssueKeyPattern = $null,
    [Parameter(Mandatory = $true)]
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

    function Set-RepoWorkingDirectory {
        [CmdletBinding()]
        param (
            $CloneRoot,
            $Repositories
        )

        process {
            $Repositories | ForEach-Object {
                $repo = $_
                $cloneUrl = "$($CloneRoot)/$($repo)"
                if (!(Test-Path -Path "./$($repo)")) {
                    Write-Verbose "Clone repository $($cloneUrl)"
                    git clone --mirror "$($cloneUrl)"
                }
                else {
                    Write-Verbose "Update repository $($repo)"
                    try {
                        Push-Location "./$($repo)"
                        if ($IsWindows) {
                            git fetch --all --prune
                        } else {
                            git fetch --all --prune > /dev/null 2>&1
                        }
                    }
                    finally {
                        Pop-Location
                    }
                }
            }
        }
    }

    function Get-GitCommitMetrics {
        [CmdletBinding()]
        param (
            $Repositories,
            $Since,
            $IssueKeyPattern
        )

        process {
            $commitReport = @()
            $issueKeyReport = @()

            if ($null -ne $IssueKeyPattern -and "" -ne $IssueKeyPattern) {
                [System.Text.RegularExpressions.RegexOptions] $opt = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
                [System.Text.RegularExpressions.RegexOptions] $opt += [System.Text.RegularExpressions.RegexOptions]::Compiled
        
                $regex = [System.Text.RegularExpressions.Regex]::new($IssueKeyPattern, $opt)
            }
            else {
                $regex = $null
            }

            $Repositories | ForEach-Object {
                $repo = $_
                Write-Verbose "Processing repository $($repo)"
                try {
                    Push-Location "./$($repo)"

                    $commitLog = (git --no-pager log --all "--since=$($Since)" --no-merges --pretty=format:"%H%x09%an%x09%cn%x09%aI%x09%s")
                    $commitLog | ForEach-Object { 
                        $items = $_.Split("`t")
                        $author = "$($items[1])"
                        $subject = ("$($items[4])" -Replace "'", "")
                        if ($null -ne $regex) {
                            $issueKeys = @($regex.Matches($subject) | ForEach-Object { $_.Groups[1].Value })
                        }
                        else {
                            $issueKeys = @()
                        }
                        
                        $issueKeys | ForEach-Object {
                            $issueKeyReport += [PSCustomObject]@{
                                Id         = "$($repo)-$($items[0])"
                                Repository = "$($repo)"
                                CommitHash = "$($items[0])"
                                Author     = "$($author)"
                                Committer  = "$($items[2])"
                                IssueKey   = "$($_)"
                            }
                        }

                        $commitReport += [pscustomobject]@{
                            Id           = "$($repo)-$($items[0])"
                            CommitHash   = "$($items[0])"
                            Repository   = "$($repo)"
                            Author       = "$($author)"
                            Committer    = "$($items[2])"
                            Time         = (Format-DateTimeOffset -Date "$($items[3])") 
                            Subject      = $subject
                            Files        = 0
                            Lines        = 0
                            AddedLines   = 0
                            DeletedLines = 0
                        }
                    }

                    $commitLog = (git --no-pager log --all "--since=$($Since)" --no-merges --shortstat)
                    $commitId = ""
                    $commitLog | Select-String -Pattern "^(commit|.*files? changed)" `
                    | ForEach-Object {
                        if ($_ -match '^commit') {
                            $commitId = ($_ -Replace '^commit\s+(\S+).*$', '$1')
                        }
                        else {
                            $files = ($_ -Replace '^\D+(\d+)\D+files? changed.*$', '$1')
                            $insertions = 0
                            if ($_ -match 'insertion') {
                                $insertions = [int] ($_ -Replace '^.*files? changed\D+(\d+)\D+insertion.*$', '$1')
                            }
                            $deletions = 0
                            if ($_ -match 'deletion') {
                                $deletions = [int] ($_ -Replace '^.*\D+(\d+)\D+deletion.*$', '$1')
                            }
                            $id = "$($repo)-$commitId"
                            $record = ($commitReport | Where-Object { $_.Id -eq $id } | Select-Object -First 1)
                            if ($null -ne $record) {
                                $record.Files = [int] "$($files)"
                                $record.Lines = [int] "$($insertions + $deletions)"
                                $record.AddedLines = [int] "$($insertions)"
                                $record.DeletedLines = [int] "$($deletions)"
                            }
                            else {
                                Write-Verbose "WARN: $($id) not found"
                            }
                        }
                    }
                }
                finally {
                    Pop-Location
                }
            }

            $commitReport, $issueKeyReport
        }
    }

    #----------------[ Main ]----------------

    $fileSuffix = (Get-Date -Format "yyyyMMddHHmmss")

    $repos = $Repositories -split ',' | ForEach-Object { $_.Trim() }

    Set-RepoWorkingDirectory -CloneRoot $CloneRoot -Repositories $repos

    $commitReport, $issueKeyReport = Get-GitCommitMetrics -Repositories $repos -Since $Since -IssueKeyPattern $IssueKeyPattern

    switch ($OutputFormat) {
        "JSON" {
            $commitReport | ConvertTo-Json | Out-File -FilePath "git_commit_$($fileSuffix).json"
            if ($null -ne $IssueKeyPattern -and "" -ne $IssueKeyPattern) {
                $issueKeyReport | ConvertTo-Json | Out-File -FilePath "git_issuekey_$($fileSuffix).json"
            }
        }
        "CSV" {
            $commitReport | Export-Csv -Path "git_commit_$($fileSuffix).csv" -NoTypeInformation
            if ($null -ne $IssueKeyPattern -and "" -ne $IssueKeyPattern) {
                $issueKeyReport | Export-Csv -Path "git_issuekey_$($fileSuffix).csv" -NoTypeInformation
            }
        }
    }
}