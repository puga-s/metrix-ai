# metrix-ai
Raw data of SDLC and code check-ins to help analyze, benchmark and identify optimization opportunities in the process, and coaching opportunities for teams and code contributors.

A) Ticket metadata from Software Development Lifecycle (SDLC) project management tool like JIRA, extracted in CSV or excel format.

Filter: Past 2 years; Include data from all projects/products, both development and support (Eg: service desk projects in JIRA)

1. Ticket - Data elements: IssueType [Epic|Story|Bug|...], ParentType, IssueKey (Identifier), ParentKey, Project, Sprint, Release, Status, Summary, Assignee, Reporter, Created, Updated, TimeEstimate, TimeSpent, StoryPointsEstimate, Priority, Resolution, ResolutionDate

2. Ticket Assignment History - Data elements: IssueKey, UpdatedAt, FromAssignee, ToAssignee

3. Ticket Status History - Data elements: IssueKey, UpdatedAt, FromStatus, ToStatus

4. Ticket Work Log - Data elements: IssueKey, Created, Updated, Started, Author, UpdateAuthor, TimeSpentSeconds

B) Code check-in metadata from repository system like GitHub, extracted in CSV or excel format.

Filter: Past 2 years; Include data from all repositories

1. GIT Log - Data elements: CommitHash, Repository, Author, Committer, Timestamp, Subject, NumberOfFiles, NumberOfLines, AddedLines, DeletedLines
