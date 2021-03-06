USE [CMDB]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_Json]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[fn_Json](@PersonId INT, @IsRoot INT ) 
RETURNS VARCHAR(MAX)
BEGIN 
    DECLARE @Json NVARCHAR(MAX) = '{}', @Name NVARCHAR(MAX) , @Children                 NVARCHAR(MAX)

    SET @Json =  
    (SELECT p.parent_id, p.id, p.[name], p.CIATTRTYPE_NAME, p.CIATTR_VALUE ,JSON_QUERY(dbo.fn_Json(P.Id, 2) ) AS Children 
    FROM [dbo].[GetCIAttributes] ('CMDB' ,'CI001224' ,0 )  AS P  
    WHERE P.Parent_Id = @PersonId 
    FOR JSON PATH);

    IF(@IsRoot = 1) 
    BEGIN
       SELECT @Name =  p.[name]FROM [dbo].[GetCIAttributes] ('CMDB' ,'CI001224' ,0 ) AS P WHERE P.Id = @PersonId
       SET @Json =   '{"Name":"' + @Name + '","Children":' + CAST(@Json AS NVARCHAR(MAX)) + '}'
       SET @IsRoot = 2
    END

    RETURN @Json 
END 
GO
/****** Object:  UserDefinedFunction [dbo].[fn_Json_aux_v2]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[fn_Json_aux_v2](@PersonId INT) 
RETURNS VARCHAR(MAX)
BEGIN 
    DECLARE @Json NVARCHAR(MAX) = '{}'

    SET @Json =  
    (SELECT t2.CIATTR_ID [id], t3.CIATTRTYPE_TYPE [type], t3.CIATTRTYPE_NAME [name], ISNULL(CASE WHEN LEN(t2.CIATTR_VALUE) = 0 THEN
                             (SELECT        T4.LONGDESCRIPTION
                               FROM            CIATTR_LONGDESCRIPTION T4
                               WHERE        T4.CIATTR_ID = T2.CIATTR_ID) ELSE t2.CIATTR_VALUE END, '-') AS [value]
FROM            CI_V AS t1 LEFT OUTER JOIN
                         CIATTR AS t2 ON t1.CI_ID = t2.CI_ID INNER JOIN
                         CIATTRTYPE AS t3 ON t2.CIATTRTYPE_ID = t3.CIATTRTYPE_ID

						 where t1.CI_ID = @PersonId for json path)

    RETURN @Json 
END 



GO
/****** Object:  UserDefinedFunction [dbo].[fn_Json_v2]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[fn_Json_v2](@PersonId INT, @IsRoot INT ) 
RETURNS VARCHAR(MAX)
BEGIN 
    DECLARE @Json_tmp NVARCHAR(MAX) = '{}', @Json NVARCHAR(MAX) = '{}', @Name NVARCHAR(MAX) , @Children NVARCHAR(MAX), @type_id INT, @citype_type NVARCHAR(10)

    SET @Json =  
    (SELECT p.CHILD_ID id, p.CHILD_NAME name, p.CI_TYPEID [type_id], rtrim(p.CITYPE_TYPE) [ci_type], JSON_QUERY(dbo.fn_Json_aux_v2(P.CHILD_ID)) as Attributes, JSON_QUERY(dbo.fn_Json_v2(P.CHILD_ID, 2) ) AS Children
    FROM ci_v  AS P  
    WHERE P.Parent_Id = @PersonId and p.CITYPE_TYPE='CONF'
    FOR JSON PATH);

    IF(@IsRoot = 1) 
    BEGIN
       SELECT @Name =  p.CHILD_NAME, @type_id = p.CI_TYPEID, @citype_type = p.CITYPE_TYPE FROM ci_v AS P WHERE P.CI_ID = @PersonId
       SET @Json =   '{"id":' + CAST(@PersonId AS VARCHAR)+',"name":"' + @Name + '","type_id":'+ CAST(@Type_Id AS VARCHAR)+',"ci_type":"'+rtrim(@citype_type) +'","Attributes":' + JSON_QUERY(dbo.fn_Json_aux_v2(@PersonId)) + ',"Children":' + CAST(isnull(@Json,'{}') AS NVARCHAR(MAX)) + '}'
	   
       SET @IsRoot = 2
    END

    RETURN (SELECT ISNULL(@Json, '{}') )
END 



GO
/****** Object:  UserDefinedFunction [dbo].[GetChildren]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[GetChildren] 
(
	@parent varchar(50)
)
RETURNS 
@childrenCIs TABLE 
(
	child varchar(50),
	child_name varchar(50),
	parent varchar(50)
)
AS
BEGIN
	exec IncreaceUsability @CI=@parent

	insert into @childrenCIs SELECT [CHILD], [CHILD_NAME], [PARENT] FROM CI_V WHERE (PARENT = @parent) ORDER BY [USABILITY] DESC, [CHILD_NAME]
	
	RETURN 
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetCIAttributes]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Petyo hristov
-- Create date: 12.11.2021
-- Description:	Get Configuration Attributes
-- =============================================
CREATE FUNCTION [dbo].[GetCIAttributes](@CI_ID VARCHAR(50)) 
RETURNS VARCHAR(MAX)
AS
BEGIN
	DECLARE @Json VARCHAR(MAX) ='{}', @Root_Name varchar(50)
	
	IF (SUBSTRING (@CI_ID, 1,2) <> 'RT') 
		BEGIN
			SET @CI_ID = (SELECT SUBSTRING(@CI_ID, 3,100)) 
			SET @CI_ID = (SELECT CASE t1.CIATTRTYPE_TYPE 
									WHEN 2 THEN t1.CIATTRTYPE_SUBCI 
									WHEN 1 THEN 0 ELSE @CI_ID 
								  END 
							FROM [CIATTRTYPE] t1 
							WHERE t1.CIATTRTYPE_ID=@CI_ID)
		END
	ELSE 
			SET @CI_ID = (SELECT SUBSTRING(@CI_ID, 3,100))

	SET @Json = (SELECT [CIATTRTYPE_ID] as [Attribute_ID]
						  ,[CIATTRTYPE_NAME] as [Name]
						  ,[CIATTRTYPE_DESCRIPTION] as Info
						  ,[CIATTRTYPE_ACTVE] As Active
						  ,[CIATTRTYPE_MANDATORY] As Mandatory
						  ,[CIATTRTYPE_IS_MULTIPLE] as Multiple
						  ,CASE [CIATTRTYPE_TYPE] WHEN 1 THEN 'Attribute' WHEN 2 THEN 'SubCI' WHEN 3 THEN 'Ref ID' WHEN 4 THEN 'MAIN Rel' END as [Type]
						  ,isnull(CAST(t1.CIATTRTYPE_SUBCI as VARCHAR(10)), '') as SubCI_ID
						  ,isnull (t2.CITYPE_NAME, '') as SubCI_Name
					  FROM [CMDB].[dbo].[CIATTRTYPE] t1 Left join [CMDB].[dbo].[CITYPE] t2 ON t1.CIATTRTYPE_SUBCI = t2.CITYPE_ID
					  WHERE t1.CIATTRTYPE_CITYPEID = @CI_ID for Json path)

	SET @Json ='{"Root_ID":"'+CAST(@CI_ID AS VARCHAR)+'","Attributes":'+CAST(isnull(@Json,'{}') AS NVARCHAR(MAX)) + '}'


	Return @Json
END

--  commit
GO
/****** Object:  UserDefinedFunction [dbo].[GetMainSubCI]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Petyo.Hristov
-- Create date: 4.10.2021
-- Description:	return subCIs 
-- =============================================
CREATE FUNCTION [dbo].[GetMainSubCI]
(
	@CI varchar(50)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
	DECLARE @Json NVARCHAR(MAX) = '{}'

	SET @Json = (SELECT ISNULL((select t1.CHILD, t1.CHILD_NAME, t1.PARENT, t1.CI_TYPEID from ci_v t1 where (PARENT = @CI) AND CITYPE_TYPE = 'MAIN' order by t1.USABILITY DESC for json path),'{}'))

	RETURN @Json

END
GO
/****** Object:  UserDefinedFunction [dbo].[Test]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[Test] 
(

)
RETURNS nvarchar(50)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ResultVar nvarchar(50)

	-- Add the T-SQL statements to compute the return value here
	SELECT @ResultVar = CITYPE_NAME FROM CITYPE WHERE CITYPE_ID = 22

	-- Return the result of the function
	RETURN @ResultVar

END
GO
/****** Object:  UserDefinedFunction [dbo].[GetAtrributeConf]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[GetAtrributeConf] 
(	
	@CI_ID as int
)
RETURNS TABLE 
AS
RETURN 
(
	WITH T1 AS ( SELECT ISNULL(Parent_id, CI_TYPE + 100000) as CI_ID,
					ID as Attribute_ID,
					CI_Name as Name,
					CIATTRTYPE_ACTVE as Active,
					CIATTRTYPE_MANDATORY as Mandatory,
					CIATTRTYPE_IS_MULTIPLE as Multiple,
					attrib_type as [Type],
					ciattrtype_description as Info,
					CIATTRTYPE_ORDER as [ORDER]
                FROM CIATTRTYPE_V 
            UNION ALL 
            SELECT  0  as CI_ID, 
					CITYPE_ID + 100000 as Attribute_ID, 
					CITYPE_NAME as Name, 
					'true' as Active,
					'true' as Mandatory,
					'false' as Multiple,
					'Base' as [Type],
					CITYPE_DESCRIPTION as Info,
					1 as [ORDER]
				FROM            CITYPE
				WHERE        (CITYPE_TYPE = 'MAIN')	
				
				
				
				
				) 
            SELECT CI_ID, Attribute_ID, Name, Active, Mandatory, Multiple, [Type], Info, [ORDER]
              FROM T1 
        WHERE (CI_ID = @CI_ID)
)
GO
/****** Object:  UserDefinedFunction [dbo].[GetCIAttributes_ToByDeleted]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[GetCIAttributes_ToByDeleted] 
(	
	-- Add the parameters for the function here
	@Tenant as nvarchar(50),
	@CI  as nvarchar(20),
	@CITYPE as bit = 1 
)
RETURNS TABLE 
AS
RETURN 
(

	WITH CIHerarchy AS (SELECT LEVEL=0,
							   CIRELATION_ID, 
							   PARENT_ID, 
							   PARENT_NAME, 
							   CHILD, 
							   CHILD_NAME, 
							   cast(CAST(CHILD_NAME as nvarchar(max)) as varchar(max)) as PathString,
							   CIRELATION_TYPEID, 
							   USABILITY, 
							   CI_TYPEID,  
							   CITYPE_NAME,
							   CI_ID,
							   CI_V.CITYPE_TYPE
						  FROM CI_V
						 WHERE (CHILD = @CI) AND ((CI_V.CITYPE_TYPE = 'MAIN' AND @CITYPE = 1) OR (CI_V.CITYPE_TYPE = 'CONF' AND @CITYPE = 2) OR @CITYPE = 0) AND CI_V.TENANT = @Tenant

						UNION ALL

						SELECT LEVEL=CIHerarchy.LEVEL+1,
							   CI_V.CIRELATION_ID, 
							   CI_V.PARENT_ID, 
							   CI_V.PARENT_NAME, 
							   CI_V.CHILD, 
							   CI_V.CHILD_NAME, 
							   REPLACE(PathString, '>','/') + ' > ' + cast(CI_V.CHILD_NAME as varchar(max)) as PathString,
							   CI_V.CIRELATION_TYPEID, 
							   CI_V.USABILITY, 
							   CI_V.CI_TYPEID,  
							   CI_V.CITYPE_NAME,
							   CI_V.CI_ID,
							   CI_V.CITYPE_TYPE
						  FROM CI_V INNER JOIN CIHerarchy ON CI_V.PARENT = CIHerarchy.CHILD
						 WHERE 1=1 AND ((CI_V.CITYPE_TYPE = 'MAIN' AND @CITYPE = 1) OR (CI_V.CITYPE_TYPE = 'CONF' AND @CITYPE = 2) OR @CITYPE = 0) AND CI_V.TENANT = @Tenant
						 )



		SELECT t1.LEVEL, 
			   t1.PathString,
			   --t1.CI_TYPEID,
			   t1.CITYPE_NAME,
			   t1.PARENT_ID,
			   t1.PARENT_NAME, 
			   t1.CI_ID ID,
			   t1.CHILD_NAME NAME,
			   --t3.CIATTRTYPE_ID, 
			   t2.CIATTR_ID ,
			   t3.CIATTRTYPE_NAME, 
			   ISNULL(CASE WHEN LEN(t2.CIATTR_VALUE) = 0 THEN (SELECT T4.LONGDESCRIPTION FROM CIATTR_LONGDESCRIPTION T4 WHERE T4.CIATTR_ID = T2.CIATTR_ID) ELSE t2.CIATTR_VALUE END,'-') CIATTR_VALUE,
			   t1.CITYPE_TYPE
			   
		  FROM CIHerarchy AS t1 LEFT OUTER JOIN
			   CIATTR AS t2 ON t1.CI_ID = t2.CI_ID INNER JOIN
			   CIATTRTYPE AS t3 ON t2.CIATTRTYPE_ID = t3.CIATTRTYPE_ID
)
GO
/****** Object:  UserDefinedFunction [dbo].[GETRootCITYPE]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[GETRootCITYPE] 
(
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	SELECT	CITYPE_ID, 
			CITYPE_NAME, 
			CITYPE_DESCRIPTION, 
			CITYPE_TYPE,
			(SELECT CASE COUNT(*) WHEN 0 THEN 'No' ELSE 'Yes' END AS Expr1
			   FROM CIATTRTYPE AS t2
			  WHERE (t1.CITYPE_ID = CIATTRTYPE_CITYPEID)) AS ATTRUTES
	  FROM  CITYPE AS t1
)
GO
/****** Object:  StoredProcedure [dbo].[Add_CI]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Petyo Hristov
-- Create date: 25.02.2018
-- Description:	Add CI into CMDB and create 
-- needed herarchy of properties and sub CIs 
-- =============================================
CREATE PROCEDURE [dbo].[Add_CI]
	@Tenant nvarchar(50),
	@CITypeName nvarchar(50),  
	@ParentCI_ID INTEGER = -1,
	@CI_Name nvarchar(50) = '',
	@Use_MandatoryDefinition INTEGER = 0,
	@NEW_CI_ID INTEGER OUTPUT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @Parent_Name nvarchar(200)

	-- Get Parrent Name

	IF @CI_Name = ''
	BEGIN
			--SELECT @Parent_Name = CI_NAME FROM CI WHERE CI_ID = @ParentCI_ID;
			--SET @CI_Name = @Parent_Name + '_' + @CITypeName ;
			SET @CI_Name = @CITypeName ;
	END	

	BEGIN TRY
		BEGIN TRANSACTION;

		DECLARE @Type_ID INT = (SELECT CITYPE_ID FROM dbo.CITYPE WHERE CITYPE_NAME = @CITypeName)

		-- Insert new Software CI
		INSERT INTO [dbo].[CI]
					([CI_NAME]
					,[CI_TYPEID]
					,[CI_STATUSID])
				VALUES
					(@CI_Name
					,@Type_ID
					,2)

		-- Get ID of new record into CI table
		SET @NEW_CI_ID = SCOPE_IDENTITY()

		-- Create relation with parent
		IF @ParentCI_ID > 0
		BEGIN
			INSERT INTO [dbo].[CIRELATION]
						([CIRELATION_CIID]
						,[CIRELATION_TYPEID]
						,[CIRELATION_NAME]
						,[CIRELATION_PARENTID])
					VALUES
						(@NEW_CI_ID
						,6
						,'Relation to ' + @CITypeName
						,@ParentCI_ID)
		END

		-- Greate Propeerties
		DECLARE @CIATTRTYPE_ID INT, @CIATTRTYPE_NAME nvarchar(50), @PRPERTY_CNT int = 0, @SUBCI_cnt int = 0

		DECLARE PROPERTIES CURSOR LOCAL
		FOR
		SELECT CIATTRTYPE_ID, CIATTRTYPE_NAME
		FROM CIATTRTYPE
		WHERE (CIATTRTYPE_TYPE in (1, 3)) 
			AND (CIATTRTYPE_ACTVE = 1) 
			AND (CIATTRTYPE_MANDATORY = 1 OR @Use_MandatoryDefinition = 1) 
			AND (CIATTRTYPE_CITYPEID = @Type_ID)

		OPEN PROPERTIES
		FETCH NEXT FROM PROPERTIES INTO
		@CIATTRTYPE_ID, @CIATTRTYPE_NAME
 
		WHILE @@FETCH_STATUS = 0
		BEGIN
			INSERT INTO [dbo].[CIATTR]
						([CI_ID]
						,[CIATTRTYPE_ID]
						,[CIATTR_VALUE])
					VALUES
						(@NEW_CI_ID
						,@CIATTRTYPE_ID
						,'')
						   				
			SET @PRPERTY_CNT += 1	
					
			FETCH NEXT FROM PROPERTIES INTO
			@CIATTRTYPE_ID, @CIATTRTYPE_NAME
		END
 
		CLOSE PROPERTIES
		DEALLOCATE PROPERTIES

		-- Greate Sub CIs
		DECLARE @CIATTRTYPE_SUBCI INT, @SUBCINAME nvarchar(50), @RetVal int

		DECLARE SUBCI CURSOR LOCAL
		FOR
		SELECT CIATTRTYPE_SUBCI, CIATTRTYPE_NAME
		FROM CIATTRTYPE
		WHERE (CIATTRTYPE_TYPE = 2) AND (CIATTRTYPE_ACTVE = 1) AND (CIATTRTYPE_CITYPEID = @Type_ID)

		OPEN SUBCI
		FETCH NEXT FROM SUBCI INTO
		@CIATTRTYPE_SUBCI, @CIATTRTYPE_NAME
 
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @SUBCINAME = (SELECT CITYPE_NAME FROM CITYPE WHERE CITYPE_ID = @CIATTRTYPE_SUBCI)

			EXEC Add_CI @Tenant = @Tenant, @CITypeName = @SUBCINAME,  @ParentCI_ID = @NEW_CI_ID, @CI_Name = @CIATTRTYPE_NAME, @Use_MandatoryDefinition = @Use_MandatoryDefinition, @NEW_CI_ID = @RetVal OUTPUT
				
			SET @SUBCI_cnt += 1			
						
			FETCH NEXT FROM SUBCI INTO
			@CIATTRTYPE_SUBCI, @CIATTRTYPE_NAME
		END
 
		CLOSE SUBCI
		DEALLOCATE SUBCI

		IF @@TRANCOUNT > 0  
			COMMIT TRANSACTION;  

 		RETURN 0;
	END TRY

	BEGIN CATCH
		BEGIN			
			SELECT  
				ERROR_NUMBER() AS ErrorNumber  
				,ERROR_SEVERITY() AS ErrorSeverity  
				,ERROR_STATE() AS ErrorState  
				,ERROR_PROCEDURE() AS ErrorProcedure  
				,ERROR_LINE() AS ErrorLine  
				,ERROR_MESSAGE() AS ErrorMessage;

			IF @@TRANCOUNT > 0  
					ROLLBACK TRANSACTION; 

			RETURN (@@ERROR)
		END
	END CATCH

	SELECT @PRPERTY_CNT, @SUBCI_cnt
END


commit
GO
/****** Object:  StoredProcedure [dbo].[Add_CI_Test]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Petyo Hristov
-- Create date: 25.02.2018
-- Description:	Add CI into CMDB and create 
-- needed herarchy of properties and sub CIs 
-- =============================================
CREATE PROCEDURE [dbo].[Add_CI_Test]
	@CITypeName nvarchar(50),  
	@ParentCI_ID INTEGER = -1,
	@CI_Name nvarchar(50) = '',
	@Use_MandatoryDefinition INTEGER = 0,
	@NEW_CI_ID INTEGER OUTPUT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @Parent_Name nvarchar(200)

	-- Get Parrent Name

	IF @CI_Name = ''
	BEGIN
			--SELECT @Parent_Name = CI_NAME FROM CI WHERE CI_ID = @ParentCI_ID;
			--SET @CI_Name = @Parent_Name + '_' + @CITypeName ;
			SET @CI_Name = @CITypeName ;
	END	

	BEGIN TRY
		BEGIN TRANSACTION;

		DECLARE @Type_ID INT = (SELECT CITYPE_ID FROM dbo.CITYPE WHERE CITYPE_NAME = @CITypeName)

		-- Insert new Software CI
		INSERT INTO [dbo].[CI]
					([CI_NAME]
					,[CI_TYPEID]
					,[CI_STATUSID])
				VALUES
					(@CI_Name
					,@Type_ID
					,2)

		-- Get ID of new record into CI table
		SET @NEW_CI_ID = SCOPE_IDENTITY()

		-- Create relation with parent
		IF @ParentCI_ID > 0
		BEGIN
			INSERT INTO [dbo].[CIRELATION]
						([CIRELATION_CIID]
						,[CIRELATION_TYPEID]
						,[CIRELATION_NAME]
						,[CIRELATION_PARENTID])
					VALUES
						(@NEW_CI_ID
						,6
						,'Relation to ' + @CITypeName
						,@ParentCI_ID)
		END

		-- Greate Propeerties
		DECLARE 
			@CIATTRTYPE_ID INT, 
			@CIATTRTYPE_NAME nvarchar(50),
			@CIATTRTYPE_TYPE INT, 
			@MULTIPLE INT,
			@PRPERTY_CNT INT = 0, 
			@SUBCI_cnt INT = 0,
			@CIATTRTYPE_SUBCI INT, 
			@SUBCINAME nvarchar(50), 
			@RetVal int,
			@OLD_CI_ID int

		DECLARE PROPERTIES CURSOR LOCAL
		FOR
		SELECT CIATTRTYPE_ID, CIATTRTYPE_NAME, CIATTRTYPE_TYPE, CIATTRTYPE_SUBCI, CIATTRTYPE_IS_MULTIPLE
		FROM CIATTRTYPE
		WHERE (CIATTRTYPE_ACTVE = 1) 
			AND (CIATTRTYPE_MANDATORY = 1 OR @Use_MandatoryDefinition = 1) 
			AND (CIATTRTYPE_CITYPEID = @Type_ID)

		OPEN PROPERTIES
		FETCH NEXT FROM PROPERTIES INTO
		@CIATTRTYPE_ID, @CIATTRTYPE_NAME, @CIATTRTYPE_TYPE, @CIATTRTYPE_SUBCI, @MULTIPLE
 
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @OLD_CI_ID = @NEW_CI_ID

			PRINT  N'Record is @CIATTRTYPE_ID = ' + CAST(@CIATTRTYPE_ID as varchar(10)) + ', @CIATTRTYPE_NAME = ' + CAST(@CIATTRTYPE_NAME as varchar(10)) + ', @CIATTRTYPE_TYPE = ' + CAST(@CIATTRTYPE_TYPE as varchar(10)) + ', @CIATTRTYPE_SUBCI = ' + CAST(isnull(@CIATTRTYPE_SUBCI,0) as varchar(10)) + ', @MULTIPLE = ' + CAST(@MULTIPLE as varchar(10))

			IF @MULTIPLE = 1
			BEGIN
				SET @SUBCINAME = @CIATTRTYPE_NAME + N' POOL'

				EXEC Add_CI_Test 
					@CITypeName = N'POOL',  
					@ParentCI_ID = @NEW_CI_ID, 
					@CI_Name = @SUBCINAME, 
					@Use_MandatoryDefinition = @Use_MandatoryDefinition, 
					@NEW_CI_ID = @RetVal OUTPUT
				
				SET @SUBCI_CNT += 1	

				SET @NEW_CI_ID = @RetVal	
							
				PRINT  N'	Create POOL and new Parent is ' + CAST(@NEW_CI_ID as varchar(10)) + ' and @RetVal is ' + CAST(@RetVal as varchar(10))			
			END

			IF @CIATTRTYPE_TYPE in ( 1,3) 
			BEGIN
				INSERT INTO [dbo].[CIATTR]
							([CI_ID]
							,[CIATTRTYPE_ID]
							,[CIATTR_VALUE])
						VALUES
							(@NEW_CI_ID
							,@CIATTRTYPE_ID
							,'')
						   				
				SET @PRPERTY_CNT += 1
				PRINT  N'	Create Attribute for CI_ID ' + CAST(@NEW_CI_ID as varchar(10))				

			END
			ELSE IF @CIATTRTYPE_TYPE = 2 
			BEGIN	
				SET @SUBCINAME = (SELECT CITYPE_NAME FROM CITYPE WHERE CITYPE_ID = @CIATTRTYPE_SUBCI)

				EXEC Add_CI_Test 
					@CITypeName = @SUBCINAME,  
					@ParentCI_ID = @NEW_CI_ID, 
					@CI_Name = @SUBCINAME, 
					@Use_MandatoryDefinition = @Use_MandatoryDefinition, 
					@NEW_CI_ID = @RetVal OUTPUT
				
				SET @SUBCI_CNT += 1	
				PRINT  N'	Create Sub_CI with Parent_ID ' + CAST(@NEW_CI_ID as varchar(10))				
								
			END
			
			SET @NEW_CI_ID = @OLD_CI_ID		

			FETCH NEXT FROM PROPERTIES INTO
			@CIATTRTYPE_ID, @CIATTRTYPE_NAME, @CIATTRTYPE_TYPE, @CIATTRTYPE_SUBCI, @MULTIPLE
		END
 
		CLOSE PROPERTIES
		DEALLOCATE PROPERTIES

		/*--------------------------------------------------------------------------
		-- Greate Sub CIs
		
		DECLARE SUBCI CURSOR LOCAL
		FOR
		SELECT CIATTRTYPE_SUBCI
		FROM CIATTRTYPE
		WHERE (CIATTRTYPE_TYPE = 2) AND (CIATTRTYPE_ACTVE = 1) AND (CIATTRTYPE_CITYPEID = @Type_ID)

		OPEN SUBCI
		FETCH NEXT FROM SUBCI INTO
		@CIATTRTYPE_SUBCI
 
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @SUBCINAME = (SELECT CITYPE_NAME FROM CITYPE WHERE CITYPE_ID = @CIATTRTYPE_SUBCI)

			EXEC Add_CI_Test @CITypeName = @SUBCINAME,  @ParentCI_ID = @NEW_CI_ID, @CI_Name = @SUBCINAME, @Use_MandatoryDefinition = @Use_MandatoryDefinition, @NEW_CI_ID = @RetVal OUTPUT
				
			SET @SUBCI_cnt += 1			
						
			FETCH NEXT FROM SUBCI INTO
			@CIATTRTYPE_SUBCI
		END
 
		CLOSE SUBCI
		DEALLOCATE SUBCI
		--------------------------------------------------------------------------*/

		IF @@TRANCOUNT > 0  
			COMMIT TRANSACTION;  

 		RETURN 0;
	END TRY

	BEGIN CATCH
		BEGIN			
			SELECT  
				ERROR_NUMBER() AS ErrorNumber  
				,ERROR_SEVERITY() AS ErrorSeverity  
				,ERROR_STATE() AS ErrorState  
				,ERROR_PROCEDURE() AS ErrorProcedure  
				,ERROR_LINE() AS ErrorLine  
				,ERROR_MESSAGE() AS ErrorMessage;

			IF @@TRANCOUNT > 0  
					ROLLBACK TRANSACTION; 

			RETURN (@@ERROR)
		END
	END CATCH

	SELECT @PRPERTY_CNT, @SUBCI_cnt
END

GO
/****** Object:  StoredProcedure [dbo].[Add_New_Attribute]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Петьо Христов
-- Create date: 12.03.2019
-- Description:	Добавяне на нов аттрибут на Configuration Item 
-- =============================================
CREATE PROCEDURE [dbo].[Add_New_Attribute] 
	@CIID int,   --- ID на типът CI
	@AttribName nvarchar(50),
	@AttribDescription nvarchar(500),
	@Mandatory bit = 1,
	@Active bit = 1,
	------------------------------------------ 
	-- поне един от двата параметъра по долу трябва да е NULL
	@SubConfigCI int = NULL,  --  е ID -то на Тип CI който ще е chaild на настоящия
	@PredefineCI int = NULL,  --  е ID на Тип CI. ID-та на CI-и от въпросния тип могат да бъдат стойности на атрибута
	------------------------------------------
	@IsMultipal bit = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- CHECK INPUT PARAMETERS
	IF (@SubConfigCI IS NOT NULL AND @PredefineCI IS NOT NULL) RETURN 90001 -- One of param @SubConfigCI and @PredefineCI must be NULL

	DECLARE 
		@NEW_CI_ID INTEGER,
		@AttribType INTEGER = 1,
		@SubCI INTEGER
	
	IF @SubConfigCI IS NOT NULL 
	BEGIN
		-- Ако сме задали SubCI - ID на тип CI - Tabl CITYPE Col CITYPE_ID
		SET @AttribType = 2
		SET @SubCI = @SubConfigCI 
	END
	ELSE IF @PredefineCI IS NOT NULL 
	BEGIN
		-- Ако имаме зададено ID на MAIN_CI. Възможните стойности са ID-тата на неговите деца
		SET @AttribType = 3
		SET @SubCI = @PredefineCI
	END

	BEGIN TRY
		BEGIN TRANSACTION

		INSERT INTO [dbo].[CIATTRTYPE]
				   ([CIATTRTYPE_CITYPEID]
				   ,[CIATTRTYPE_NAME]
				   ,[CIATTRTYPE_DESCRIPTION]
				   ,[CIATTRTYPE_ACTVE]
				   ,[CIATTRTYPE_MANDATORY]
				   ,[CIATTRTYPE_TYPE]
				   ,[CIATTRTYPE_SUBCI]
				   ,[CIATTRTYPE_IS_MULTIPLE])
			 VALUES
				   (@CIID
				   ,@AttribName
				   ,@AttribDescription
				   ,@Active
				   ,@Mandatory
				   ,@AttribType
				   ,@SubCI
				   ,@IsMultipal)

		SET @NEW_CI_ID = SCOPE_IDENTITY()

		DECLARE @CI_ID INTEGER
		
		DECLARE AddAttribute CURSOR LOCAL
		FOR
		SELECT CI_ID
		FROM CI_V
		WHERE CI_TYPEID = @CIID

		OPEN AddAttribute
		FETCH NEXT FROM AddAttribute INTO
		@CI_ID
 
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @AttribType = 1 
				BEGIN 
						INSERT INTO [dbo].[CIATTR]
									([CI_ID]
									,[CIATTRTYPE_ID]
									,[CIATTR_VALUE])
								VALUES
									(@CI_ID
									,@NEW_CI_ID
									,'')
				END	
			ELSE IF @AttribType = 2
				BEGIN
					

					EXEC [dbo].[Add_CI]
						 @CITypeName = @AttribName,
						 @ParentCI_ID = @CI_ID,
						 @NEW_CI_ID = @NEW_CI_ID OUTPUT

					SELECT	@NEW_CI_ID as N'@NEW_CI_ID'
				END		
			FETCH NEXT FROM AddAttribute INTO
			@CI_ID
		END
			

		COMMIT
		RETURN 0;
	END TRY

	BEGIN CATCH
		BEGIN			
			SELECT  
				ERROR_NUMBER() AS ErrorNumber  
				,ERROR_SEVERITY() AS ErrorSeverity  
				,ERROR_STATE() AS ErrorState  
				,ERROR_PROCEDURE() AS ErrorProcedure  
				,ERROR_LINE() AS ErrorLine  
				,ERROR_MESSAGE() AS ErrorMessage;
			ROLLBACK
			RETURN (@@ERROR)
		END
	END CATCH



    -- Insert statements for procedure here
	--SELECT 
END
GO
/****** Object:  StoredProcedure [dbo].[Add_SoftwareCI]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Petyo Hristov
-- Create date: 24.02.2018
-- Description:	Add SW CI into CMDB
-- =============================================
CREATE PROCEDURE [dbo].[Add_SoftwareCI]
	@ParentCI_ID INTEGER,
	@CI_Name nvarchar(50) = '',
	@Property_Name nvarchar(200) = '',
	@Property_Technology nvarchar(200) = '',
	@Property_Vertion nvarchar(200) = '',
	@SW_CI_ID INTEGER OUTPUT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @NewROW_ID INTEGER;
	DECLARE @Parent_Name nvarchar(200);

	-- Get Parrent Name

	IF @CI_Name = ''
	BEGIN
			SELECT @Parent_Name = CI_NAME FROM CI WHERE CI_ID = @ParentCI_ID;
			SET @CI_Name = 'SW ' + @Parent_Name;
	END	

	BEGIN TRY
		BEGIN TRANSACTION
			-- Insert new Software CI
			INSERT INTO [dbo].[CI]
					   ([CI_NAME]
					   ,[CI_TYPEID]
					   ,[CI_STATUSID])
				 VALUES
					   (@CI_Name
					   ,(SELECT CITYPE_ID FROM dbo.CITYPE WHERE CITYPE_NAME = 'SW')
					   ,1);

			-- Get ID of new record into CI table
			SET @SW_CI_ID = SCOPE_IDENTITY();

			-- Create relation with parent
			INSERT INTO [dbo].[CIRELATION]
					   ([CIRELATION_CIID]
					   ,[CIRELATION_TYPEID]
					   ,[CIRELATION_NAME]
					   ,[CIRELATION_PARENTID])
				 VALUES
					   (@SW_CI_ID
					   ,6
					   ,'Relation to SW'
					   ,@ParentCI_ID);

			-- Greate Propeerties
			--
			-- NAME
			INSERT INTO [dbo].[CIATTR]
					   ([CI_ID]
					   ,[CIATTRTYPE_ID]
					   ,[CIATTR_VALUE])
				 VALUES
					   (@SW_CI_ID
					   ,12
					   ,@Property_Name);

			-- TECHNOLOGY
			INSERT INTO [dbo].[CIATTR]
					   ([CI_ID]
					   ,[CIATTRTYPE_ID]
					   ,[CIATTR_VALUE])
				 VALUES
					   (@SW_CI_ID
					   ,13
					   ,@Property_Technology);

			-- Version
			INSERT INTO [dbo].[CIATTR]
					   ([CI_ID]
					   ,[CIATTRTYPE_ID]
					   ,[CIATTR_VALUE])
				 VALUES
					   (@SW_CI_ID
					   ,14
					   ,@Property_Vertion);
			COMMIT
			RETURN 0;
		END TRY

		BEGIN CATCH
			BEGIN
				ROLLBACK
				RETURN (@@ERROR)
			END
		END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Delete_CI]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Petyo Hristov
-- Create date: 24.02.2018
-- Description:	Delete SW CI into CMDB
-- =============================================
CREATE PROCEDURE [dbo].[Delete_CI]
	@CI_ID INTEGER
AS
BEGIN
	
	BEGIN TRY
		BEGIN TRANSACTION
			DECLARE @RV INT = 0, @count INT = 1, @CIATTR_ID int

			
			-- Delete attributes
			DELETE CIATTR_LONGDESCRIPTION WHERE CIATTR_ID IN (SELECT A.CIATTR_ID FROM CIATTR A WHERE A.CI_ID = @CI_ID)
			DELETE CIATTR WHERE CI_ID = @CI_ID

			-- Delete CHELDREN CIs
			DECLARE @Chaild_CI INTEGER
			DECLARE MyCHELDREN CURSOR LOCAL
			FOR
			SELECT CIRELATION_CIID FROM CIRELATION WHERE CIRELATION_PARENTID = @CI_ID

			OPEN MyCHELDREN
			FETCH NEXT FROM MyCHELDREN INTO
			@Chaild_CI
 
			WHILE @@FETCH_STATUS = 0
			BEGIN
				EXEC @RV = Delete_CI @CI_ID = @Chaild_CI

				SET @count += @RV
						
				FETCH NEXT FROM MyCHELDREN INTO
				@Chaild_CI
			END
 
			CLOSE MyCHELDREN
			DEALLOCATE MyCHELDREN

			-- Delete relation
			DELETE CIRELATION WHERE CIRELATION_CIID = @CI_ID

			-- Delete CI
			DELETE CI WHERE CI_ID = @CI_ID
			
		COMMIT
		RETURN @count
	END TRY	

	BEGIN CATCH
		SELECT   
			ERROR_NUMBER() AS ErrorNumber  
			,ERROR_MESSAGE() AS ErrorMessage; 
		ROLLBACK
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[IncreaceUsability]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[IncreaceUsability] 
	@CI varchar(50)
AS
BEGIN 
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		declare 
		@CI_id int =round(substring (@CI,3,100),0),
		@cur_use int, 
		@CI_NAME varchar(100) = ''

	select @cur_use = COALESCE(SUM([USABILITY]),0) from ci where ci.CI_ID = @CI_id;

	update ci  SET ci.[USABILITY]=@cur_use+1 where ci.CI_ID = @CI_id;
	
	with a as (
		SELECT	CHILD, case when ciattr_value ='' then CHILD_NAME else ciattr_value end CHILD_NAME, PARENT, CI_TYPEID, USABILITY
			FROM	CI_V INNER JOIN CIATTR  ON CI_V.CI_ID = CIATTR.CI_ID 
						INNER JOIN CIATTRTYPE ON CIATTR.CIATTRTYPE_ID = CIATTRTYPE.CIATTRTYPE_ID AND (UPPER(CIATTRTYPE.CIATTRTYPE_NAME) = 'NAME')
			WHERE	(PARENT = @CI) AND CITYPE_TYPE = 'MAIN'

		union all

			SELECT	CHILD, CHILD_NAME, PARENT, CI_TYPEID, USABILITY
			FROM	CI_V 
			WHERE	(PARENT = @CI AND  CI_V.parent_name='CMDB_ROOT')
	)

	select * from a  ORDER BY USABILITY DESC, CHILD_NAME 
END
commit
GO
/****** Object:  StoredProcedure [dbo].[IncreaceUsability_ORG]    Script Date: 06.12.2021 17:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[IncreaceUsability_ORG] 
	@CI varchar(50)
AS
BEGIN 
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		declare 
		@CI_id int =round(substring (@CI,3,100),0),
		@cur_use int, 
		@CI_NAME varchar(100) = ''

	select @cur_use = COALESCE(SUM([USABILITY]),0) from ci where ci.CI_ID = @CI_id;

	update ci  SET ci.[USABILITY]=@cur_use+1 where ci.CI_ID = @CI_id;
	
	with a as (
		SELECT	CHILD, case when ciattr_value ='' then CHILD_NAME else ciattr_value end CHILD_NAME, PARENT, CI_TYPEID, USABILITY
			FROM	CI_V INNER JOIN CIATTR  ON CI_V.CI_ID = CIATTR.CI_ID 
						INNER JOIN CIATTRTYPE ON CIATTR.CIATTRTYPE_ID = CIATTRTYPE.CIATTRTYPE_ID AND (UPPER(CIATTRTYPE.CIATTRTYPE_NAME) = 'NAME')
			WHERE	(PARENT = @CI) AND CITYPE_TYPE = 'MAIN'

		union all

			SELECT	CHILD, CHILD_NAME, PARENT, CI_TYPEID, USABILITY
			FROM	CI_V 
			WHERE	(PARENT = @CI AND  CI_V.parent_name='CMDB_ROOT')
	)

	select * from a  ORDER BY USABILITY DESC, CHILD_NAME 
END
GO
