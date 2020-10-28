-- Indexes
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
CREATE NONCLUSTERED INDEX [Name_Includes] ON [dbo].[Badges]
(
	[Name] ASC
)
INCLUDE ( 	[UserId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
