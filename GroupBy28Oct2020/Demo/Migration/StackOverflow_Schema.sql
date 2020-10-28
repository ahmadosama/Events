/******** DMA Schema Migration Deployment Script      Script Date: 10/23/2020 3:59:00 AM ********/

/****** Object:  Table [dbo].[Posts]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Posts]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Posts](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[AcceptedAnswerId] [int] NULL,
	[AnswerCount] [int] NULL,
	[Body] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ClosedDate] [datetime] NULL,
	[CommentCount] [int] NULL,
	[CommunityOwnedDate] [datetime] NULL,
	[CreationDate] [datetime] NOT NULL,
	[FavoriteCount] [int] NULL,
	[LastActivityDate] [datetime] NOT NULL,
	[LastEditDate] [datetime] NULL,
	[LastEditorDisplayName] [nvarchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[LastEditorUserId] [int] NULL,
	[OwnerUserId] [int] NULL,
	[ParentId] [int] NULL,
	[PostTypeId] [int] NOT NULL,
	[Score] [int] NOT NULL,
	[Tags] [nvarchar](150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Title] [nvarchar](250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ViewCount] [int] NOT NULL,
 CONSTRAINT [PK_Posts__Id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
END
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Posts]') AND name = N'AcceptedAnswerId_Includes')
CREATE NONCLUSTERED INDEX [AcceptedAnswerId_Includes] ON [dbo].[Posts]
(
	[AcceptedAnswerId] ASC
)
INCLUDE ( 	[OwnerUserId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Posts]') AND name = N'ClosedDate_CommunityOwnedDate_PostTypeId_Includes')
CREATE NONCLUSTERED INDEX [ClosedDate_CommunityOwnedDate_PostTypeId_Includes] ON [dbo].[Posts]
(
	[ClosedDate] ASC,
	[CommunityOwnedDate] ASC,
	[PostTypeId] ASC
)
INCLUDE ( 	[OwnerUserId],
	[Score]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Posts]') AND name = N'OwnerUserId_PostTypeId')
CREATE NONCLUSTERED INDEX [OwnerUserId_PostTypeId] ON [dbo].[Posts]
(
	[OwnerUserId] ASC,
	[PostTypeId] ASC
)
INCLUDE ( 	[AcceptedAnswerId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
/****** Object:  StoredProcedure [dbo].[GetAcceptedAnsPercentage]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetAcceptedAnsPercentage]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[GetAcceptedAnsPercentage] AS' 
END
GO


ALTER   proc [dbo].[GetAcceptedAnsPercentage]
@UserId int
AS
SET NOCOUNT ON
SELECT 
    (CAST(Count(a.Id) AS float) / (SELECT Count(*) FROM Posts WHERE OwnerUserId = @UserId AND PostTypeId = 2) * 100) AS AcceptedPercentage
into #tmp
FROM
    Posts q
  INNER JOIN
    Posts a ON q.AcceptedAnswerId = a.Id
WHERE
    a.OwnerUserId = @UserId
  AND
    a.PostTypeId = 2


GO
/****** Object:  Table [dbo].[userstats]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[userstats]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[userstats](
	[Accepted Answers] [int] NULL,
	[Scored Answers] [int] NULL,
	[Unscored Answers] [int] NULL,
	[Percentage Unscored] [numeric](17, 6) NULL
)
END
GO
/****** Object:  StoredProcedure [dbo].[GetAnswerStatsByUser]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetAnswerStatsByUser]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[GetAnswerStatsByUser] AS' 
END
GO



ALTER   proc [dbo].[GetAnswerStatsByUser]
@UserId int
AS
SET NOCOUNT ON

insert into userstats
select
    count(a.Id) as [Accepted Answers],
    sum(case when a.Score = 0 then 0 else 1 end) as [Scored Answers],  
    sum(case when a.Score = 0 then 1 else 0 end) as [Unscored Answers],
    sum(CASE WHEN a.Score = 0 then 1 else 0 end)*1000 / count(a.Id) / 10.0 as [Percentage Unscored]
from
    Posts q
  inner join
    Posts a
  on a.Id = q.AcceptedAnswerId
where
      a.CommunityOwnedDate is null
  and a.OwnerUserId = @UserId
  and q.OwnerUserId != @UserId
  and a.postTypeId = 2

GO
/****** Object:  Table [dbo].[Votes]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Votes]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Votes](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[PostId] [int] NOT NULL,
	[UserId] [int] NULL,
	[BountyAmount] [int] NULL,
	[VoteTypeId] [int] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Votes__Id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
END
GO
/****** Object:  StoredProcedure [dbo].[GetMostControversialPost]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetMostControversialPost]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[GetMostControversialPost] AS' 
END
GO


ALTER   proc [dbo].[GetMostControversialPost]
AS
set nocount on 

--declare @VoteStats table (PostId int, up int, down int) 

select 
    PostId, 
    up = sum(case when VoteTypeId = 2 then 1 else 0 end), 
    down = sum(case when VoteTypeId = 3 then 1 else 0 end)
into #VoteStats
from Votes
where VoteTypeId in (2,3)
group by PostId

select top 1 p.id as [Post Link] , up, down into #tmp from #VoteStats 
join Posts p on PostId = p.Id
where down > (up * 0.5) and p.CommunityOwnedDate is null and p.ClosedDate is null
order by up desc

GO
/****** Object:  Table [dbo].[Users]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Users](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[AboutMe] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Age] [int] NULL,
	[CreationDate] [datetime] NOT NULL,
	[DisplayName] [nvarchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DownVotes] [int] NOT NULL,
	[EmailHash] [nvarchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[LastAccessDate] [datetime] NOT NULL,
	[Location] [nvarchar](100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Reputation] [int] NOT NULL,
	[UpVotes] [int] NOT NULL,
	[Views] [int] NOT NULL,
	[WebsiteUrl] [nvarchar](200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AccountId] [int] NULL,
 CONSTRAINT [PK_Users_Id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
END
GO
/****** Object:  StoredProcedure [dbo].[GetTop500Answers]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetTop500Answers]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[GetTop500Answers] AS' 
END
GO


ALTER   proc [dbo].[GetTop500Answers]
AS
SELECT 
    TOP 500
    Users.Id as [User Link],
    Count(Posts.Id) AS Answers,
    CAST(AVG(CAST(Score AS float)) as numeric(6,2)) AS [Average Answer Score]
into #tmp
FROM
    Posts
  INNER JOIN
    Users ON Users.Id = OwnerUserId
WHERE 
    PostTypeId = 2 and CommunityOwnedDate is null and ClosedDate is null
GROUP BY
    Users.Id, DisplayName
HAVING
    Count(Posts.Id) > 10
ORDER BY
    [Average Answer Score] DESC

GO
/****** Object:  Table [dbo].[editors]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[editors]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[editors](
	[User Link] [int] IDENTITY(1,1) NOT NULL,
	[QuestionEdits] [int] NULL,
	[AnswerEdits] [int] NULL,
	[TotalEdits] [int] NULL
)
END
GO
/****** Object:  StoredProcedure [dbo].[GetTop50ProfilicEditors]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetTop50ProfilicEditors]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[GetTop50ProfilicEditors] AS' 
END
GO


ALTER   proc [dbo].[GetTop50ProfilicEditors]
AS


SET NOCOUNT ON
insert into editors
SELECT TOP 10
    --Id AS [User Link],
    (
        SELECT COUNT(*) FROM Posts
        WHERE
            PostTypeId = 1 AND
            LastEditorUserId = Users.Id AND
            OwnerUserId != Users.Id
    ) AS QuestionEdits,
    (
        SELECT COUNT(*) FROM Posts
        WHERE
            PostTypeId = 2 AND
            LastEditorUserId = Users.Id AND
            OwnerUserId != Users.Id
    ) AS AnswerEdits,
    (
        SELECT COUNT(*) FROM Posts
        WHERE
            LastEditorUserId = Users.Id AND
            OwnerUserId != Users.Id
    ) AS TotalEdits
    
	FROM Users
    ORDER BY TotalEdits DESC

GO
/****** Object:  Table [dbo].[popularquestions]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[popularquestions]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[popularquestions](
	[User Link] [int] NOT NULL,
	[Popular Questions] [int] NULL,
	[Total Questions] [int] NULL,
	[Ratio] [float] NULL
)
END
GO
/****** Object:  Table [dbo].[Badges]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Badges]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Badges](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[UserId] [int] NOT NULL,
	[Date] [datetime] NOT NULL,
 CONSTRAINT [PK_Badges__Id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
END
GO
SET ANSI_PADDING ON

GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Badges]') AND name = N'Name_Includes')
CREATE NONCLUSTERED INDEX [Name_Includes] ON [dbo].[Badges]
(
	[Name] ASC
)
INCLUDE ( 	[UserId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
/****** Object:  StoredProcedure [dbo].[GetUsersByPopularQuestions]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetUsersByPopularQuestions]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[GetUsersByPopularQuestions] AS' 
END
GO


ALTER   proc [dbo].[GetUsersByPopularQuestions]
AS
set nocount on
insert into popularquestions
select top 10
  Users.Id as [User Link],
  BadgeCount as [Popular Questions],
  QuestionCount as [Total Questions],
  CONVERT(float, BadgeCount)/QuestionCount as [Ratio]
from Users
inner join (
  -- Popular Question badges for each user
  select top(60)
    UserId,
    count(Id) as BadgeCount
  from Badges
  where Name = 'Popular Question'
  group by UserId
) as Pop on Users.Id = Pop.UserId
inner join (
  -- Questions by each user
  select
    OwnerUserId,
    count(Id) as QuestionCount
  from posts
  where PostTypeId = 1
  group by OwnerUserId
) as Q on Users.Id = Q.OwnerUserId
where BadgeCount >= 10
order by [Ratio] desc;

GO
/****** Object:  StoredProcedure [dbo].[InsertUsers]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InsertUsers]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[InsertUsers] AS' 
END
GO


ALTER proc [dbo].[InsertUsers]
AS
SET NOCOUNT ON
DECLARE @i int = 1
WHILE(@i<=100)
BEGIN
INSERT INTO [dbo].[Users]
           ([AboutMe]
           ,[Age]
           ,[CreationDate]
           ,[DisplayName]
           ,[DownVotes]
           ,[EmailHash]
           ,[LastAccessDate]
           ,[Location]
           ,[Reputation]
           ,[UpVotes]
           ,[Views]
           ,[WebsiteUrl]
           ,[AccountId])
     VALUES
           (SUBSTRING(CAST(NEWID() as VARCHAR(1000)),2,10)
           ,CAST(RAND()*100 as int)
           ,GetDate()
           ,SUBSTRING(CAST(NEWID() as VARCHAR(1000)),3,10)
           ,CAST(RAND()*10 as int)
           ,NULL
           ,GetDate()-(rand()*10)
           ,SUBSTRING(CAST(NEWID() as VARCHAR(1000)),3,16)
           ,CAST(RAND()*100000 as int)
           ,CAST(RAND()*100 as int)
           ,CAST(RAND()*100000 as int)
           ,'http://somewebsite.com'
           ,CAST(RAND()*10 as int)
		   )

SET @i=@i+1
END

GO
/****** Object:  StoredProcedure [dbo].[InsertVotes]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InsertVotes]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[InsertVotes] AS' 
END
GO


ALTER proc [dbo].[InsertVotes]
AS
SET NOCOUNT ON
DECLARE @i int = 1
WHILE(@i<=100)
BEGIN
INSERT INTO [dbo].[Votes]
           ([PostId]
           ,[UserId]
           ,[BountyAmount]
           ,[VoteTypeId]
           ,[CreationDate])
     VALUES
           (CAST(RAND()*10000 AS INT)
           ,NULL
           ,NULL
           ,2
           ,GETDATE()
		   )
SET @i=@i+1
END


GO
/****** Object:  StoredProcedure [dbo].[StressTest]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[StressTest]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[StressTest] AS' 
END
GO


ALTER   PROC [dbo].[StressTest]
AS
SET NOCOUNT ON
DECLARE @id INT = CAST((RAND()*10) AS INT)%10

IF(@id = 0)
Execute InsertUsers

IF(@id = 1)
Execute InsertVotes

IF(@id = 2 OR @id=5)
Execute GetAnswerStatsByUser @UserId=1

--IF(@id = 3)
--Execute GetMostControversialPost

IF(@id = 4)
Execute GetTop500Answers

--IF(@id = 5)
--Execute GetTop50ProfilicEditors

IF(@id = 6)
Execute GetUsersByPopularQuestions

IF(@id = 7)
Execute GetAcceptedAnsPercentage @UserId=1

GO
/****** Object:  StoredProcedure [dbo].[DropIndexes]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DropIndexes]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[DropIndexes] AS' 
END
GO



ALTER PROCEDURE [dbo].[DropIndexes] 
  @SchemaName NVARCHAR(255) = 'dbo', @TableName NVARCHAR(255) = NULL AS
BEGIN
SET NOCOUNT ON

CREATE TABLE #commands (ID INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, Command NVARCHAR(2000));
DECLARE @CurrentCommand NVARCHAR(2000);

INSERT INTO #commands (Command)
SELECT 'DROP INDEX [' + i.name + '] ON [' + SCHEMA_NAME(t.schema_id) + '].[' + t.name + ']'
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
WHERE i.type = 2
AND SCHEMA_NAME(t.schema_id) = COALESCE(@SchemaName, SCHEMA_NAME(t.schema_id))
AND t.name = COALESCE(@TableName, t.name);

INSERT INTO #commands (Command)
SELECT 'DROP STATISTICS ' + SCHEMA_NAME(t.schema_id) + '.'  + OBJECT_NAME(s.object_id) + '.' + s.name
FROM sys.stats AS s
INNER JOIN sys.tables AS t ON s.object_id = t.object_id
WHERE NOT EXISTS (SELECT * FROM sys.indexes AS i WHERE i.name = s.name) 
AND SCHEMA_NAME(t.schema_id) = COALESCE(@SchemaName, SCHEMA_NAME(t.schema_id))
AND t.name = COALESCE(@TableName, t.name)
AND OBJECT_NAME(s.object_id) NOT LIKE 'sys%';
DECLARE result_cursor CURSOR FOR
SELECT Command FROM #commands

OPEN result_cursor
FETCH NEXT FROM result_cursor into @CurrentCommand
WHILE @@FETCH_STATUS = 0
BEGIN 
        
        PRINT @CurrentCommand;
	EXEC(@CurrentCommand);

FETCH NEXT FROM result_cursor into @CurrentCommand
END
--end loop

--clean up
CLOSE result_cursor
DEALLOCATE result_cursor
END

GO
/****** Object:  Table [dbo].[Comments]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Comments]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Comments](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[PostId] [int] NOT NULL,
	[Score] [int] NULL,
	[Text] [nvarchar](700) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[UserId] [int] NULL,
 CONSTRAINT [PK_Comments__Id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
END
GO
/****** Object:  Table [dbo].[LinkTypes]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LinkTypes]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[LinkTypes](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Type] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_LinkTypes__Id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
END
GO
/****** Object:  Table [dbo].[PostLinks]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PostLinks]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PostLinks](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[PostId] [int] NOT NULL,
	[RelatedPostId] [int] NOT NULL,
	[LinkTypeId] [int] NOT NULL,
 CONSTRAINT [PK_PostLinks__Id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
END
GO
/****** Object:  Table [dbo].[PostTypes]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PostTypes]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PostTypes](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Type] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_PostTypes__Id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
END
GO
/****** Object:  Table [dbo].[VoteTypes]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[VoteTypes]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[VoteTypes](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_VoteType__Id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
END
GO
/****** Object:  Table [dbo].[test]    Script Date: 10/23/2020 3:59:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[test]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[test](
	[col1] [int] NULL
)
END
GO

