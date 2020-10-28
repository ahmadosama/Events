USE [StackOverflow2010]
GO

/****** Object:  StoredProcedure [dbo].[StressTest]    Script Date: 10/22/2020 9:53:15 AM ******/
DROP PROCEDURE [dbo].[StressTest]
GO

/****** Object:  StoredProcedure [dbo].[InsertVotes]    Script Date: 10/22/2020 9:53:15 AM ******/
DROP PROCEDURE [dbo].[InsertVotes]
GO

/****** Object:  StoredProcedure [dbo].[InsertUsers]    Script Date: 10/22/2020 9:53:15 AM ******/
DROP PROCEDURE [dbo].[InsertUsers]
GO

/****** Object:  StoredProcedure [dbo].[GetUsersByPopularQuestions]    Script Date: 10/22/2020 9:53:15 AM ******/
DROP PROCEDURE [dbo].[GetUsersByPopularQuestions]
GO

/****** Object:  StoredProcedure [dbo].[GetTop50ProfilicEditors]    Script Date: 10/22/2020 9:53:15 AM ******/
DROP PROCEDURE [dbo].[GetTop50ProfilicEditors]
GO

/****** Object:  StoredProcedure [dbo].[GetTop500Answers]    Script Date: 10/22/2020 9:53:15 AM ******/
DROP PROCEDURE [dbo].[GetTop500Answers]
GO

/****** Object:  StoredProcedure [dbo].[GetMostControversialPost]    Script Date: 10/22/2020 9:53:15 AM ******/
DROP PROCEDURE [dbo].[GetMostControversialPost]
GO

/****** Object:  StoredProcedure [dbo].[GetAnswerStatsByUser]    Script Date: 10/22/2020 9:53:15 AM ******/
DROP PROCEDURE [dbo].[GetAnswerStatsByUser]
GO

/****** Object:  StoredProcedure [dbo].[GetAcceptedAnsPercentage]    Script Date: 10/22/2020 9:53:15 AM ******/
DROP PROCEDURE [dbo].[GetAcceptedAnsPercentage]
GO

/****** Object:  StoredProcedure [dbo].[GetAcceptedAnsPercentage]    Script Date: 10/22/2020 9:53:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   proc [dbo].[GetAcceptedAnsPercentage]
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

/****** Object:  StoredProcedure [dbo].[GetAnswerStatsByUser]    Script Date: 10/22/2020 9:53:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE   proc [dbo].[GetAnswerStatsByUser]
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

/****** Object:  StoredProcedure [dbo].[GetMostControversialPost]    Script Date: 10/22/2020 9:53:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   proc [dbo].[GetMostControversialPost]
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

/****** Object:  StoredProcedure [dbo].[GetTop500Answers]    Script Date: 10/22/2020 9:53:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   proc [dbo].[GetTop500Answers]
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

/****** Object:  StoredProcedure [dbo].[GetTop50ProfilicEditors]    Script Date: 10/22/2020 9:53:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   proc [dbo].[GetTop50ProfilicEditors]
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

/****** Object:  StoredProcedure [dbo].[GetUsersByPopularQuestions]    Script Date: 10/22/2020 9:53:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   proc [dbo].[GetUsersByPopularQuestions]
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

/****** Object:  StoredProcedure [dbo].[InsertUsers]    Script Date: 10/22/2020 9:53:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[InsertUsers]
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

/****** Object:  StoredProcedure [dbo].[InsertVotes]    Script Date: 10/22/2020 9:53:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[InsertVotes]
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

/****** Object:  StoredProcedure [dbo].[StressTest]    Script Date: 10/22/2020 9:53:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROC [dbo].[StressTest]
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

CREATE proc [dbo].[GetUsers]
AS
select * from somedb.dbo.users
EXECUTE xp_cmdshell 'C:\'
GO