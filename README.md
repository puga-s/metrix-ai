# metrix-ai

Software Development Lifecycle (SDLC) ticket data and code commit log to help analyze, benchmark and identify optimization opportunities in the process.

Use the scripts in the sub-folder PowerShell to pull data from Jira and Git.
Note: Only metadata of git commit logs are used, not the source code.

The following section describes the data needed for the analysis, in case of not using the powershell scripts.

A) Ticket metadata from SDLC project management tool (Jira, Azure DevOps, Asana, Pivotal Tracker, etc.), extracted in CSV or JSON format.

Filter: Past 2 years; Include data from all projects/products, both software dev and support tickets (Eg: service desk projects in JIRA)

1. Ticket - Data elements: IssueType [Epic|Story|Bug|...], ParentType, IssueKey, ParentKey, Project, Sprint, Release, Status, Summary, Assignee, Reporter, Created, Updated, TimeEstimate, TimeSpent, StoryPointsEstimate, Priority, Resolution, ResolutionDate

2. Ticket Assignment History - Data elements: HistoryId, IssueKey, UpdatedAt, FromAssignee, ToAssignee

3. Ticket Status History - Data elements: HistoryId, IssueKey, UpdatedAt, FromStatus, ToStatus

4. Ticket Work Log - Data elements: WorklogId, IssueKey, Created, Updated, Started, Author, UpdateAuthor, TimeSpentSeconds

B) Code commit metadata from source code repository system (like GitHub, GitLab, etc.), extracted in CSV or JSON format.

Filter: Past 2 years; Include data from all repositories

5. GIT Log - Data elements: CommitHash, Repository, Author, Committer, Timestamp, Subject, NumberOfFiles, TotalChangedLines, AddedLines, DeletedLines
