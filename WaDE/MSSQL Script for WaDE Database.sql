USE [WaDE_Oct2014]
GO
/****** Object:  User [nodeadmin]    Script Date: 5/2/2017 2:54:39 PM ******/
CREATE USER [nodeadmin] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[wade]
GO
/****** Object:  User [sara]    Script Date: 5/2/2017 2:54:39 PM ******/
CREATE USER [sara] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[wade]
GO
/****** Object:  User [wade]    Script Date: 5/2/2017 2:54:39 PM ******/
CREATE USER [wade] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[wade]
GO
/****** Object:  User [wade_app1]    Script Date: 5/2/2017 2:54:39 PM ******/
CREATE USER [wade_app1] FOR LOGIN [wade_app1] WITH DEFAULT_SCHEMA=[wade]
GO
/****** Object:  DatabaseRole [wade_admin]    Script Date: 5/2/2017 2:54:39 PM ******/
CREATE ROLE [wade_admin]
GO
/****** Object:  DatabaseRole [wade_app]    Script Date: 5/2/2017 2:54:39 PM ******/
CREATE ROLE [wade_app]
GO
ALTER ROLE [wade_admin] ADD MEMBER [nodeadmin]
GO
ALTER ROLE [wade_admin] ADD MEMBER [sara]
GO
ALTER ROLE [wade_admin] ADD MEMBER [wade]
GO
ALTER ROLE [db_owner] ADD MEMBER [wade]
GO
ALTER ROLE [db_datareader] ADD MEMBER [wade]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [wade]
GO
ALTER ROLE [wade_app] ADD MEMBER [wade_app1]
GO
/****** Object:  Schema [wade]    Script Date: 5/2/2017 2:54:40 PM ******/
CREATE SCHEMA [wade]
GO
/****** Object:  Schema [wade_r]    Script Date: 5/2/2017 2:54:40 PM ******/
CREATE SCHEMA [wade_r]
GO
/****** Object:  UserDefinedFunction [wade_r].[ALLOCATION_AMOUNT]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[ALLOCATION_AMOUNT](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60)) 
RETURNS XML

BEGIN
DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT (SELECT WADE_R.XML_D_ALLOCATION_USE(@orgid,@reportid,@allocationid, DETAIL_SEQ_NO)),
	AMOUNT_VOLUME AS 'WC:AllocatedVolume/WC:AmountNumber',
	D.VALUE AS 'WC:AllocatedVolume/WC:AmountUnitsCode',
	AMOUNT_RATE AS 'WC:AllocatedRate/WC:AmountNumber',
	E.VALUE AS 'WC:AllocatedRate/WC:AmountUnitsCode',
	C.VALUE AS 'WC:SourceTypeName',
	B.VALUE AS 'WC:FreshSalineIndicator',
	ALLOCATION_START AS 'WC:TimeFrame/WC:TimeFrameStartName',
	ALLOCATION_END AS 'WC:TimeFrame/WC:TimeFrameEndName',
	SOURCE_NAME AS 'WC:SourceName',
	(SELECT WADE_R.XML_D_ALLOCATION_ACTUAL(@orgid, @reportid, @allocationid, DETAIL_SEQ_NO))
	
	FROM  
	
	WADE.D_ALLOCATION_FLOW A LEFT JOIN WADE.LU_FRESH_SALINE_INDICATOR B ON (A.FRESH_SALINE_IND=B.LU_SEQ_NO) LEFT JOIN WADE.LU_SOURCE_TYPE C ON (A.SOURCE_TYPE=C.LU_SEQ_NO)
	LEFT JOIN WADE.LU_UNITS D ON (A.UNIT_VOLUME=D.LU_SEQ_NO) LEFT JOIN WADE.LU_UNITS E ON (A.UNIT_RATE=E.LU_SEQ_NO)
	
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid
	
	FOR XML PATH('WC:WaterAllocated'));

If (@tmp IS NOT NULL)
BEGIN
WITH XMLNAMESPACES ('ReplaceMe' AS WC)
SELECT @tmp=(SELECT @tmp FOR XML PATH('WC:AllocationAmount'));
END	
RETURN (@tmp)
 
END
GO
/****** Object:  UserDefinedFunction [wade_r].[DataCatalog]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[DataCatalog](@orgid varchar(10), @reportid varchar(35), @loctype varchar(max), @loctxt varchar(max))
  RETURNS xml

BEGIN
--BEGIN FUNCTION

DECLARE @tmp XML='';

IF @loctype='HUC'

BEGIN
--BEGIN HUC

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT DATACATEGORY AS 'WC:DataCategory',
	(SELECT WADE_R.DataTypeCatalog(@orgid, @reportid, DATACATEGORY, @loctype, @loctxt))
	
	FROM 
	
	WADE_R.CATALOG_SUMMARY B WHERE B.ORGANIZATION_ID=@orgid AND B.REPORT_ID=@reportid 
	AND B.HUC=@loctxt GROUP BY DATACATEGORY FOR XML PATH ('WC:DataAvailable'));
	
END
--END HUC

IF @loctype='COUNTY'
BEGIN
--BEGIN COUNTY

WITH XMLNAMESPACES('ReplaceMe' AS WC)
SELECT @tmp=(SELECT DATACATEGORY AS 'WC:DataCategory',
	(SELECT WADE_R.DataTypeCatalog(@orgid, @reportid, DATACATEGORY, @loctype, @loctxt))
	
	FROM 
	
	WADE_R.CATALOG_SUMMARY B WHERE B.ORGANIZATION_ID=@orgid AND B.REPORT_ID=@reportid 
	AND B.COUNTY_FIPS=@loctxt GROUP BY DATACATEGORY FOR XML PATH ('WC:DataAvailable'));	
END
--END COUNTY

IF @loctype='REPORTUNIT'
BEGIN
--BEGIN REPORTUNIT

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT DATACATEGORY AS 'WC:DataCategory',
	(SELECT WADE_R.DataTypeCatalog(@orgid, @reportid, DATACATEGORY, @loctype, @loctxt))
	
	FROM 
	
	WADE_R.CATALOG_SUMMARY B WHERE B.ORGANIZATION_ID=@orgid AND B.REPORT_ID=@reportid 
	AND B.REPORT_UNIT_ID=@loctxt GROUP BY DATACATEGORY FOR XML PATH ('WC:DataAvailable'));	
	
END
--END REPORTUNIT

RETURN (@tmp)
		
END



GO
/****** Object:  UserDefinedFunction [wade_r].[DataTypeCatalog]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[DataTypeCatalog](@orgid varchar(10), @reportid varchar(35), @datacategory varchar(7), @loctype varchar(max), @loctxt varchar(max))
  RETURNS xml

BEGIN
--BEGIN FUNCTION

DECLARE @tmp XML='';

IF @loctype='HUC'

BEGIN
--BEGIN HUC

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT DATATYPE AS 'WC:DataType'
	
	FROM 
	
	WADE_R.CATALOG_SUMMARY B WHERE B.ORGANIZATION_ID=@orgid AND B.REPORT_ID=@reportid 
	AND DATACATEGORY=@datacategory AND B.HUC=@loctxt GROUP BY DATATYPE FOR XML PATH (''));
	
END
--END HUC

IF @loctype='COUNTY'
BEGIN
--BEGIN COUNTY

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT DATATYPE AS 'WC:DataType'
	
	FROM 
	
	WADE_R.CATALOG_SUMMARY B WHERE B.ORGANIZATION_ID=@orgid AND B.REPORT_ID=@reportid 
	AND DATACATEGORY=@datacategory AND B.COUNTY_FIPS=@loctxt GROUP BY DATATYPE FOR XML PATH (''));
	
END
--END COUNTY

IF @loctype='REPORTUNIT'
BEGIN
--BEGIN REPORTUNIT

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT DATATYPE AS 'WC:DataType'
	
	FROM 
	
	WADE_R.CATALOG_SUMMARY B WHERE B.ORGANIZATION_ID=@orgid AND B.REPORT_ID=@reportid 
	AND DATACATEGORY=@datacategory AND B.REPORT_UNIT_ID=@loctxt GROUP BY DATATYPE FOR XML PATH (''));
	
END
--END REPORTUNIT
If (@tmp IS NOT NULL)
BEGIN
WITH XMLNAMESPACES ('ReplaceMe' AS WC)
SELECT @tmp=(SELECT @tmp FOR XML PATH('WC:DataTypes'));
END	
RETURN (@tmp)
		
END



GO
/****** Object:  UserDefinedFunction [wade_r].[DIVERSION_AMOUNT]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[DIVERSION_AMOUNT](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60), @diversionid varchar(60)) 
RETURNS XML

BEGIN

DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT 
				(SELECT WADE_R.XML_D_DIVERSION_USE (@orgid, @reportid, @allocationid, @diversionid, DETAIL_SEQ_NO)),
				AMOUNT_VOLUME AS 'WC:AllocatedVolume/WC:AmountNumber',
				D.VALUE AS 'WC:AllocatedVolume/WC:AmountUnitsCode',
				AMOUNT_RATE AS 'WC:AllocatedRate/WC:AmountNumber',
				E.VALUE AS 'WC:AllocatedRate/WC:AmountUnitsCode',
				C.VALUE AS 'WC:SourceTypeName',
				B.VALUE AS 'WC:FreshSalineIndicator',
				DIVERSION_START AS 'WC:TimeFrame/WC:TimeFrameStartName',
				DIVERSION_END AS 'WC:TimeFrame/WC:TimeFrameEndName',
				SOURCE_NAME AS 'WC:SourceName',
				(SELECT WADE_R.XML_D_DIVERSION_ACTUAL (@orgid, @reportid, @allocationid, @diversionid, DETAIL_SEQ_NO))
	
	FROM  
	
	WADE.D_DIVERSION_FLOW A LEFT JOIN WADE.LU_FRESH_SALINE_INDICATOR B ON (A.FRESH_SALINE_IND=B.LU_SEQ_NO) LEFT JOIN WADE.LU_SOURCE_TYPE C ON (A.SOURCE_TYPE=C.LU_SEQ_NO)
	LEFT JOIN WADE.LU_UNITS D ON (A.UNIT_VOLUME=D.LU_SEQ_NO) LEFT JOIN WADE.LU_UNITS E ON (A.UNIT_RATE=E.LU_SEQ_NO)
	
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid AND DIVERSION_ID=@diversionid
	
	FOR XML PATH('WC:WaterAllocated'));
	
If (@tmp IS NOT NULL)
BEGIN
WITH XMLNAMESPACES ('ReplaceMe' AS WC)
SELECT @tmp=(SELECT @tmp FOR XML PATH('WC:DiversionAmount'));
END
	
RETURN (@tmp)
 
END
GO
/****** Object:  UserDefinedFunction [wade_r].[GeospatialRefDetail]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[GeospatialRefDetail](@orgid varchar(10), @reportid varchar(35),@datatype varchar(60))
  RETURNS xml

BEGIN

DECLARE @tmp XML;
IF @datatype <> 'ALL'
	BEGIN
	WITH XMLNAMESPACES('ReplaceMe' AS WC)

	SELECT @tmp=(SELECT WFS_DATACATEGORY AS 'WC:WFSType/WC:WFSDataCategory',
		WFS_DATATYPE AS 'WC:WFSType/WC:WFSTypeName',
		WFS_ADDRESS AS 'WC:WFSType/WC:WFSAddressLink',
		WFS_FEATURE_ID_FIELD AS 'WC:WFSType/WC:WFSFeatureIDFieldText'
	
	FROM 
	
	wade.GEOSPATIAL_REF WHERE ORGANIZATION_ID=@orgid AND WFS_DATACATEGORY='DETAIL'
	AND REPORT_ID=@reportid AND WFS_DATATYPE=@datatype
	
	FOR XML PATH(''));
	END
	
ELSE
	
	BEGIN
	
	WITH XMLNAMESPACES('ReplaceMe' AS WC)

	SELECT @tmp=(SELECT WFS_DATACATEGORY AS 'WC:WFSType/WC:WFSDataCategory',
		WFS_DATATYPE AS 'WC:WFSType/WC:WFSTypeName',
		WFS_ADDRESS AS 'WC:WFSType/WC:WFSAddressLink',
		WFS_FEATURE_ID_FIELD AS 'WC:WFSType/WC:WFSFeatureIDFieldText'
	
	FROM 
	
	wade.GEOSPATIAL_REF WHERE ORGANIZATION_ID=@orgid AND WFS_DATACATEGORY='DETAIL' AND REPORT_ID=@reportid
	FOR XML PATH (''));
	END

IF (@tmp IS NOT NULL)	

BEGIN
WITH XMLNAMESPACES ('ReplaceMe' AS WC)
SELECT @tmp = (SELECT @tmp FOR XML PATH ('WC:GeospatialReference'));
END

RETURN (@tmp)		
END

GO
/****** Object:  UserDefinedFunction [wade_r].[GeospatialRefSummary]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[GeospatialRefSummary](@orgid varchar(10), @reportid varchar(35),@datatype varchar(60))
  RETURNS xml

BEGIN

DECLARE @tmp XML;
IF @datatype <> 'ALL'
	BEGIN
	WITH XMLNAMESPACES('ReplaceMe' AS WC)

	SELECT @tmp=(SELECT WFS_DATACATEGORY AS 'WC:WFSType/WC:WFSDataCategory',
		WFS_DATATYPE AS 'WC:WFSType/WC:WFSTypeName',
		WFS_ADDRESS AS 'WC:WFSType/WC:WFSAddressLink',
		WFS_FEATURE_ID_FIELD AS 'WC:WFSType/WC:WFSFeatureIDFieldText'
	
	FROM 
	
	wade.GEOSPATIAL_REF WHERE ORGANIZATION_ID=@orgid AND WFS_DATACATEGORY='SUMMARY' 
	AND WFS_DATATYPE=@datatype AND REPORT_ID=@reportid 
	
	FOR XML PATH(''));
	END
	
ELSE
	
	BEGIN
	
	WITH XMLNAMESPACES('ReplaceMe' AS WC)

	SELECT @tmp=(SELECT WFS_DATACATEGORY AS 'WC:WFSType/WC:WFSDataCategory',
		WFS_DATATYPE AS 'WC:WFSType/WC:WFSTypeName',
		WFS_ADDRESS AS 'WC:WFSType/WC:WFSAddressLink',
		WFS_FEATURE_ID_FIELD AS 'WC:WFSType/WC:WFSFeatureIDFieldText'
	
	FROM 
	
	wade.GEOSPATIAL_REF WHERE ORGANIZATION_ID=@orgid AND WFS_DATACATEGORY='SUMMARY' AND REPORT_ID=@reportid
	FOR XML PATH (''));
	END

IF (@tmp IS NOT NULL)	

BEGIN
WITH XMLNAMESPACES ('ReplaceMe' AS WC)
SELECT @tmp = (SELECT @tmp FOR XML PATH ('WC:GeospatialReference'));
END

RETURN (@tmp)		
END

GO
/****** Object:  UserDefinedFunction [wade_r].[GetCatalog]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[GetCatalog](@loctype varchar(max), @loctxt varchar(max),@orgid varchar(10), @state varchar(3))
  RETURNS xml

BEGIN
--BEGIN FUNCTION

DECLARE @tmp XML='';

IF (@state='ALL' AND @orgid='ALL' AND @loctype='HUC')

BEGIN

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT A.ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription',
	WADE_URL AS 'WC:WaDEURLAddress', 
	FIRST_NAME AS 'WC:Contact/WC:FirstName',
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial',
	LAST_NAME AS 'WC:Contact/WC:LastName',
	TITLE AS 'WC:Contact/WC:IndividualTitleText',
	EMAIL AS 'WC:Contact/WC:EmailAddressText',
	PHONE AS 'WC:Contact/WC:TelephoneNumberText',
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText',
	FAX AS 'WC:Contact/WC:FaxNumberText',
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText',
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	(SELECT WADE_R.ReportCatalog(ORGANIZATION_ID,@loctype,@loctxt))
		
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS(SELECT B.ORGANIZATION_ID FROM WADE_R.CATALOG_SUMMARY B WHERE 
		A.ORGANIZATION_ID=B.ORGANIZATION_ID AND B.HUC =@loctxt)
		
		FOR XML PATH('WC:Organization'), ROOT('WC:WaDECatalog'));
END
--END HUC

IF (@state='ALL' AND @orgid='ALL' AND @loctype='COUNTY')
BEGIN
--STATE='ALL' AND ORG='ALL', BEGIN COUNTY

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT A.ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription', 
	WADE_URL AS 'WC:WaDEURLAddress', 
	FIRST_NAME AS 'WC:Contact/WC:FirstName',
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial',
	LAST_NAME AS 'WC:Contact/WC:LastName',
	TITLE AS 'WC:Contact/WC:IndividualTitleText',
	EMAIL AS 'WC:Contact/WC:EmailAddressText',
	PHONE AS 'WC:Contact/WC:TelephoneNumberText',
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText',
	FAX AS 'WC:Contact/WC:FaxNumberText',
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText',
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	(SELECT WADE_R.ReportCatalog(ORGANIZATION_ID,@loctype,@loctxt))
		
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS(SELECT B.ORGANIZATION_ID FROM WADE_R.CATALOG_SUMMARY B WHERE 
		A.ORGANIZATION_ID=B.ORGANIZATION_ID AND B.COUNTY_FIPS=@loctxt)
		
		FOR XML PATH('WC:Organization'), ROOT('WC:WaDECatalog'));
	
END
--END COUNTY

IF (@state='ALL' AND @orgid='ALL' AND @loctype='REPORTUNIT')
BEGIN
--STATE='ALL' AND ORG='ALL', BEGIN REPORTUNIT

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT A.ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription', 
	WADE_URL AS 'WC:WaDEURLAddress', 
	FIRST_NAME AS 'WC:Contact/WC:FirstName',
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial',
	LAST_NAME AS 'WC:Contact/WC:LastName',
	TITLE AS 'WC:Contact/WC:IndividualTitleText',
	EMAIL AS 'WC:Contact/WC:EmailAddressText',
	PHONE AS 'WC:Contact/WC:TelephoneNumberText',
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText',
	FAX AS 'WC:Contact/WC:FaxNumberText',
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText',
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	(SELECT WADE_R.ReportCatalog(ORGANIZATION_ID,@loctype,@loctxt))
		
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS(SELECT B.ORGANIZATION_ID FROM WADE_R.CATALOG_SUMMARY B WHERE 
		A.ORGANIZATION_ID=B.ORGANIZATION_ID AND B.REPORT_UNIT_ID=@loctxt)
		
		FOR XML PATH('WC:Organization'), ROOT('WC:WaDECatalog'));

END
--END REPORTUNIT

ELSE

IF (@state='ALL' AND @orgid <> 'ALL' AND @loctype='HUC')

BEGIN
--STATE ='ALL' AND ORG NOT 'ALL', BEGIN HUC

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT A.ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription', 
	WADE_URL AS 'WC:WaDEURLAddress', 	
	FIRST_NAME AS 'WC:Contact/WC:FirstName',
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial',
	LAST_NAME AS 'WC:Contact/WC:LastName',
	TITLE AS 'WC:Contact/WC:IndividualTitleText',
	EMAIL AS 'WC:Contact/WC:EmailAddressText',
	PHONE AS 'WC:Contact/WC:TelephoneNumberText',
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText',
	FAX AS 'WC:Contact/WC:FaxNumberText',
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText',
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	(SELECT WADE_R.ReportCatalog(ORGANIZATION_ID,@loctype,@loctxt))
		
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS(SELECT B.ORGANIZATION_ID FROM WADE_R.CATALOG_SUMMARY B WHERE 
		A.ORGANIZATION_ID=B.ORGANIZATION_ID AND B.HUC=@loctxt AND B.ORGANIZATION_ID=@orgid)
		
		FOR XML PATH('WC:Organization'), ROOT('WC:WaDECatalog'));
END
--END HUC

IF (@state='ALL' AND @orgid <> 'ALL' AND @loctype='COUNTY')
BEGIN
--STATE='ALL' AND ORG NOT 'ALL', BEGIN COUNTY

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT A.ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription', 
	WADE_URL AS 'WC:WaDEURLAddress',	
	FIRST_NAME AS 'WC:Contact/WC:FirstName',
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial',
	LAST_NAME AS 'WC:Contact/WC:LastName',
	TITLE AS 'WC:Contact/WC:IndividualTitleText',
	EMAIL AS 'WC:Contact/WC:EmailAddressText',
	PHONE AS 'WC:Contact/WC:TelephoneNumberText',
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText',
	FAX AS 'WC:Contact/WC:FaxNumberText',
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText',
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	(SELECT WADE_R.ReportCatalog(ORGANIZATION_ID,@loctype,@loctxt))
		
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS(SELECT B.ORGANIZATION_ID FROM WADE_R.CATALOG_SUMMARY B WHERE 
		A.ORGANIZATION_ID=B.ORGANIZATION_ID AND B.COUNTY_FIPS=@loctxt AND B.ORGANIZATION_ID=@orgid)
		
		FOR XML PATH('WC:Organization'), ROOT('WC:WaDECatalog'));
	
END
--END COUNTY

IF (@state='ALL' AND @orgid <> 'ALL' AND @loctype='REPORTUNIT')
BEGIN
--STATE='ALL' AND ORG NOT 'ALL', BEGIN REPORTUNIT

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT A.ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription',
	WADE_URL AS 'WC:WaDEURLAddress', 	 
	FIRST_NAME AS 'WC:Contact/WC:FirstName',
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial',
	LAST_NAME AS 'WC:Contact/WC:LastName',
	TITLE AS 'WC:Contact/WC:IndividualTitleText',
	EMAIL AS 'WC:Contact/WC:EmailAddressText',
	PHONE AS 'WC:Contact/WC:TelephoneNumberText',
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText',
	FAX AS 'WC:Contact/WC:FaxNumberText',
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText',
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	(SELECT WADE_R.ReportCatalog(ORGANIZATION_ID, @loctype,@loctxt))
		
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS(SELECT B.ORGANIZATION_ID FROM WADE_R.CATALOG_SUMMARY B WHERE 
		A.ORGANIZATION_ID=B.ORGANIZATION_ID AND B.REPORT_UNIT_ID=@loctxt AND B.ORGANIZATION_ID=@orgid)
		
		FOR XML PATH('WC:Organization'), ROOT('WC:WaDECatalog'));

END
--END REPORTUNIT, STATE = 'ALL' AND ORG NOT 'ALL'

ELSE

IF (@orgid='ALL' AND @state <> 'ALL' AND @loctype='HUC')

BEGIN
--STATE NOT 'ALL' - ORG = 'ALL', BEGIN HUC

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT A.ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription', 
	WADE_URL AS 'WC:WaDEURLAddress', 	
	FIRST_NAME AS 'WC:Contact/WC:FirstName',
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial',
	LAST_NAME AS 'WC:Contact/WC:LastName',
	TITLE AS 'WC:Contact/WC:IndividualTitleText',
	EMAIL AS 'WC:Contact/WC:EmailAddressText',
	PHONE AS 'WC:Contact/WC:TelephoneNumberText',
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText',
	FAX AS 'WC:Contact/WC:FaxNumberText',
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText',
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	(SELECT WADE_R.ReportCatalog(ORGANIZATION_ID,@loctype,@loctxt))
		
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS(SELECT B.ORGANIZATION_ID FROM WADE_R.CATALOG_SUMMARY B WHERE 
		A.ORGANIZATION_ID=B.ORGANIZATION_ID AND B.STATE=@state AND B.HUC=@loctxt)
		
		FOR XML PATH('WC:Organization'), ROOT('WC:WaDECatalog'));
END
--END HUC

IF (@orgid='ALL' AND @state <> 'ALL' AND @loctype='COUNTY')

BEGIN
--STATE NOT 'ALL' - ORG = 'ALL', BEGIN COUNTY

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT A.ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription', 
	WADE_URL AS 'WC:WaDEURLAddress', 	
	FIRST_NAME AS 'WC:Contact/WC:FirstName',
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial',
	LAST_NAME AS 'WC:Contact/WC:LastName',
	TITLE AS 'WC:Contact/WC:IndividualTitleText',
	EMAIL AS 'WC:Contact/WC:EmailAddressText',
	PHONE AS 'WC:Contact/WC:TelephoneNumberText',
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText',
	FAX AS 'WC:Contact/WC:FaxNumberText',
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText',
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	(SELECT WADE_R.ReportCatalog(ORGANIZATION_ID,@loctype,@loctxt))
		
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS(SELECT B.ORGANIZATION_ID FROM WADE_R.CATALOG_SUMMARY B WHERE 
		A.ORGANIZATION_ID=B.ORGANIZATION_ID AND B.STATE=@state AND B.COUNTY_FIPS=@loctxt)
		
		FOR XML PATH('WC:Organization'), ROOT('WC:WaDECatalog'));
	
END
--END COUNTY

IF (@orgid='ALL' AND @state <> 'ALL' AND @loctype='REPORTUNIT')

BEGIN
--STATE NOT 'ALL' - ORG = 'ALL', BEGIN REPORTUNIT

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT A.ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription', 
	WADE_URL AS 'WC:WaDEURLAddress', 	
	FIRST_NAME AS 'WC:Contact/WC:FirstName',
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial',
	LAST_NAME AS 'WC:Contact/WC:LastName',
	TITLE AS 'WC:Contact/WC:IndividualTitleText',
	EMAIL AS 'WC:Contact/WC:EmailAddressText',
	PHONE AS 'WC:Contact/WC:TelephoneNumberText',
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText',
	FAX AS 'WC:Contact/WC:FaxNumberText',
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText',
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	(SELECT WADE_R.ReportCatalog(ORGANIZATION_ID,@loctype,@loctxt))
		
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS(SELECT B.ORGANIZATION_ID FROM WADE_R.CATALOG_SUMMARY B WHERE 
		A.ORGANIZATION_ID=B.ORGANIZATION_ID AND B.STATE=@state AND B.REPORT_UNIT_ID=@loctxt)
		
		FOR XML PATH('WC:Organization'), ROOT('WC:WaDECatalog'));

END
--END REPORTUNIT, & OTHER
ELSE

IF (@orgid <> 'ALL' AND @state <> 'ALL' AND @loctype='HUC')

BEGIN
--BEGIN HUC

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT A.ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription',
	WADE_URL AS 'WC:WaDEURLAddress', 	 
	FIRST_NAME AS 'WC:Contact/WC:FirstName',
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial',
	LAST_NAME AS 'WC:Contact/WC:LastName',
	TITLE AS 'WC:Contact/WC:IndividualTitleText',
	EMAIL AS 'WC:Contact/WC:EmailAddressText',
	PHONE AS 'WC:Contact/WC:TelephoneNumberText',
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText',
	FAX AS 'WC:Contact/WC:FaxNumberText',
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText',
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	(SELECT WADE_R.ReportCatalog(ORGANIZATION_ID,@loctype,@loctxt))
		
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS(SELECT B.ORGANIZATION_ID FROM WADE_R.CATALOG_SUMMARY B WHERE 
		A.ORGANIZATION_ID=B.ORGANIZATION_ID  AND B.STATE=@state AND B.HUC=@loctxt AND B.ORGANIZATION_ID=@orgid)
		
		FOR XML PATH('WC:Organization'), ROOT('WC:WaDECatalog'));
END
--END HUC

IF (@orgid <> 'ALL' AND @state <> 'ALL' AND @loctype='COUNTY')

BEGIN
--BEGIN COUNTY

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT A.ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription', 
	WADE_URL AS 'WC:WaDEURLAddress', 	
	FIRST_NAME AS 'WC:Contact/WC:FirstName',
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial',
	LAST_NAME AS 'WC:Contact/WC:LastName',
	TITLE AS 'WC:Contact/WC:IndividualTitleText',
	EMAIL AS 'WC:Contact/WC:EmailAddressText',
	PHONE AS 'WC:Contact/WC:TelephoneNumberText',
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText',
	FAX AS 'WC:Contact/WC:FaxNumberText',
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText',
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	(SELECT WADE_R.ReportCatalog(ORGANIZATION_ID,@loctype,@loctxt))
		
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS(SELECT B.ORGANIZATION_ID FROM WADE_R.CATALOG_SUMMARY B WHERE 
		A.ORGANIZATION_ID=B.ORGANIZATION_ID AND B.STATE=@state AND B.COUNTY_FIPS=@loctxt AND B.ORGANIZATION_ID=@orgid)
		
		FOR XML PATH('WC:Organization'), ROOT('WC:WaDECatalog'));
	
END
--END COUNTY

IF (@orgid <> 'ALL' AND @state <> 'ALL' AND @loctype='REPORTUNIT')
BEGIN
--BEGIN REPORTUNIT

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT A.ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription', 
	WADE_URL AS 'WC:WaDEURLAddress', 	
	FIRST_NAME AS 'WC:Contact/WC:FirstName',
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial',
	LAST_NAME AS 'WC:Contact/WC:LastName',
	TITLE AS 'WC:Contact/WC:IndividualTitleText',
	EMAIL AS 'WC:Contact/WC:EmailAddressText',
	PHONE AS 'WC:Contact/WC:TelephoneNumberText',
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText',
	FAX AS 'WC:Contact/WC:FaxNumberText',
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText',
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	(SELECT WADE_R.ReportCatalog(ORGANIZATION_ID,@loctype,@loctxt))
		
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS(SELECT B.ORGANIZATION_ID FROM WADE_R.CATALOG_SUMMARY B WHERE 
		A.ORGANIZATION_ID=B.ORGANIZATION_ID AND B.STATE=@state AND B.REPORT_UNIT_ID=@loctxt AND B.ORGANIZATION_ID=@orgid)
		
		FOR XML PATH('WC:Organization'), ROOT('WC:WaDECatalog'));

END

SELECT @tmp=REPLACE(CONVERT(varchar(max),@tmp), ' xmlns:WC="ReplaceMe"','');

RETURN (@tmp)
		
END



GO
/****** Object:  UserDefinedFunction [wade_r].[GetCatalog_GetAll]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [wade_r].[GetCatalog_GetAll] (@orgid varchar(10))
  RETURNS xml

BEGIN
--BEGIN FUNCTION

DECLARE @tmp XML='';

BEGIN

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT A.ORGANIZATION_ID AS 'WC:OrganizationIdentifier',
			B.WADE_URL AS 'WC:WaDEURLAddress',
			A.REPORT_ID AS 'WC:ReportIdentifier',
			DATACATEGORY AS 'WC:DataCategory',
			DATATYPE AS 'WC:DataType',
			A.STATE AS 'WC:State',
			A.REPORT_UNIT_ID AS 'WC:ReportUnitIdentifier',
			C.REPORTING_UNIT_NAME AS 'WC:ReportUnitName',
			A.COUNTY_FIPS AS 'WC:CountyFIPS',
			A.HUC AS 'WC:HUC'
	
			FROM 
			WADE_R.CATALOG_SUMMARY A LEFT JOIN WADE.ORGANIZATION B ON A.ORGANIZATION_ID=B.ORGANIZATION_ID
			LEFT JOIN WADE.REPORTING_UNIT C ON A.ORGANIZATION_ID=C.ORGANIZATION_ID AND A.REPORT_ID=C.REPORT_ID AND
			A.REPORT_UNIT_ID=C.REPORT_UNIT_ID
					
			FOR XML PATH('WC:Organization'), ROOT('WC:WaDECatalog'));
END

SELECT @tmp=REPLACE(CONVERT(varchar(max),@tmp), ' xmlns:WC="ReplaceMe"','');

RETURN (@tmp)
		
END




GO
/****** Object:  UserDefinedFunction [wade_r].[GetCatalog_GetOrgTable]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [wade_r].[GetCatalog_GetOrgTable] (@orgid varchar(10))
  RETURNS xml

BEGIN
--BEGIN FUNCTION

DECLARE @tmp XML='';

BEGIN

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT ORGANIZATION_ID AS 'WC:OrganizationIdentifier',
			ORGANIZATION_NAME AS 'WC:OrganizationName',
			PURVUE_DESC AS 'WC:PurviewDescription',
			FIRST_NAME AS 'WC:FirstName',
			MIDDLE_INITIAL AS 'WC:MiddleInitial',
			LAST_NAME AS 'WC:LastName',
			TITLE AS 'WC:Title',
			EMAIL AS 'WC:Email',
			PHONE AS 'WC:Phone',
			PHONE_EXT AS 'WC:PhoneExt',
			FAX AS 'WC:Fax',
			ADDRESS AS 'WC:Address',
			ADDRESS_EXT AS 'WC:AddressExt',
			CITY AS 'WC:City',
			STATE AS 'WC:STATE',
			COUNTRY AS 'WC:COUNTRY',
			ZIPCODE AS 'WC:Zipcode',
			WADE_URL AS 'WC:WaDEURLAddress'
	
			FROM 
			WADE.ORGANIZATION
					
			FOR XML PATH('WC:CatalogOrganization'), ROOT('WC:WaDECatalog'));
END

SELECT @tmp=REPLACE(CONVERT(varchar(max),@tmp), ' xmlns:WC="ReplaceMe"','');

RETURN (@tmp)
		
END




GO
/****** Object:  UserDefinedFunction [wade_r].[GetCatalog_GetReportTable]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [wade_r].[GetCatalog_GetReportTable] (@orgid varchar(10))
  RETURNS xml

BEGIN
--BEGIN FUNCTION

DECLARE @tmp XML='';

BEGIN

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT ORGANIZATION_ID AS 'WC:OrganizationIdentifier',
			REPORT_ID AS 'WC:ReportIdentifier',
			REPORTING_DATE AS 'WC:ReportingDate',
			REPORTING_YEAR AS 'WC:ReportingYear',
			REPORT_NAME AS 'WC:ReportName',
			REPORT_LINK AS 'WC:ReportLink',
			YEAR_TYPE AS 'WC:YearType'
	
			FROM 
			WADE.REPORT
					
			FOR XML PATH('WC:CatalogReport'), ROOT('WC:WaDECatalog'));
END

SELECT @tmp=REPLACE(CONVERT(varchar(max),@tmp), ' xmlns:WC="ReplaceMe"','');

RETURN (@tmp)
		
END




GO
/****** Object:  UserDefinedFunction [wade_r].[GetDetailByLocation]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[GetDetailByLocation](@reportid varchar(35), @loctype varchar(max), @loctxt varchar(max), @datatype varchar(60))
RETURNS XML

BEGIN
--start function

DECLARE @tmp XML='';

IF @datatype <> 'ALL'

BEGIN
--start if not ALL

IF @loctype='HUC'

BEGIN
--start HUC

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription',
	WADE_URL AS 'WC:WaDEURLAddress',
	FIRST_NAME AS 'WC:Contact/WC:FirstName', 
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial', 
	LAST_NAME AS 'WC:Contact/WC:LastName', 
	TITLE AS 'WC:Contact/WC:IndividualTitleText', 
	EMAIL AS 'WC:Contact/WC:EmailAddressText', 
	PHONE AS 'WC:Contact/WC:TelephoneNumberText', 
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText', 
	FAX AS 'WC:Contact/WC:FaxNumberText', 
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText', 
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	
	(SELECT WADE_R.ReportDetail (ORGANIZATION_ID, @reportid, @loctype, @loctxt, @datatype))
	
	FROM
	
	WADE.ORGANIZATION A WHERE EXISTS (SELECT DISTINCT ORGANIZATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE 
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND HUC LIKE @loctxt + '%' AND DATATYPE=@datatype)
	
	FOR XML PATH('WC:Organization'), ROOT('WC:WaDE'));

SELECT @tmp=REPLACE(CONVERT(varchar(max),@tmp), ' xmlns:WC="ReplaceMe"','');

END
--end HUC

IF @loctype='COUNTY'

BEGIN
--start COUNTY
WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription',
	WADE_URL AS 'WC:WaDEURLAddress',
	FIRST_NAME AS 'WC:Contact/WC:FirstName', 
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial', 
	LAST_NAME AS 'WC:Contact/WC:LastName', 
	TITLE AS 'WC:Contact/WC:IndividualTitleText', 
	EMAIL AS 'WC:Contact/WC:EmailAddressText', 
	PHONE AS 'WC:Contact/WC:TelephoneNumberText', 
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText', 
	FAX AS 'WC:Contact/WC:FaxNumberText', 
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText', 
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	
	(SELECT WADE_R.ReportDetail(ORGANIZATION_ID, @reportid, @loctype, @loctxt, @datatype))
	
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS (SELECT DISTINCT ORGANIZATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE 
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND COUNTY_FIPS=@loctxt AND DATATYPE=@datatype)
	
	FOR XML PATH('WC:Organization'), ROOT('WC:WaDE'));
	
SELECT @tmp=REPLACE(CONVERT(varchar(max),@tmp), ' xmlns:WC="ReplaceMe"','');

END
--end county

IF @loctype='REPORTUNIT'

BEGIN
--start reportunit

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription',
	WADE_URL AS 'WC:WaDEURLAddress',
	FIRST_NAME AS 'WC:Contact/WC:FirstName', 
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial', 
	LAST_NAME AS 'WC:Contact/WC:LastName', 
	TITLE AS 'WC:Contact/WC:IndividualTitleText', 
	EMAIL AS 'WC:Contact/WC:EmailAddressText', 
	PHONE AS 'WC:Contact/WC:TelephoneNumberText', 
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText', 
	FAX AS 'WC:Contact/WC:FaxNumberText', 
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText', 
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	
	(SELECT WADE_R.ReportDetail(ORGANIZATION_ID, @reportid, @loctype, @loctxt, @datatype))
	
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS (SELECT DISTINCT ORGANIZATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE 
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND REPORTING_UNIT_ID=@loctxt AND DATATYPE=@datatype)
	
	FOR XML PATH('WC:Organization'), ROOT('WC:WaDE'));
	
SELECT @tmp=REPLACE(CONVERT(varchar(max),@tmp), ' xmlns:WC="ReplaceMe"','');

END
--end report unit
END

ELSE

BEGIN
--start 'ALL' Parameter

IF @loctype='HUC'

BEGIN
--start HUC

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription',
	WADE_URL AS 'WC:WaDEURLAddress',
	FIRST_NAME AS 'WC:Contact/WC:FirstName', 
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial', 
	LAST_NAME AS 'WC:Contact/WC:LastName', 
	TITLE AS 'WC:Contact/WC:IndividualTitleText', 
	EMAIL AS 'WC:Contact/WC:EmailAddressText', 
	PHONE AS 'WC:Contact/WC:TelephoneNumberText', 
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText', 
	FAX AS 'WC:Contact/WC:FaxNumberText', 
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText', 
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	
	(SELECT WADE_R.ReportDetail(ORGANIZATION_ID, @reportid, @loctype, @loctxt, @datatype))
	
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS (SELECT DISTINCT ORGANIZATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE 
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND HUC LIKE @loctxt + '%')
	
	FOR XML PATH('WC:Organization'), ROOT('WC:WaDE'));

SELECT @tmp=REPLACE(CONVERT(varchar(max),@tmp), ' xmlns:WC="ReplaceMe"','');
	
END
--end HUC

IF @loctype='COUNTY'

BEGIN
--start COUNTY

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription',
	WADE_URL AS 'WC:WaDEURLAddress',
	FIRST_NAME AS 'WC:Contact/WC:FirstName', 
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial', 
	LAST_NAME AS 'WC:Contact/WC:LastName', 
	TITLE AS 'WC:Contact/WC:IndividualTitleText', 
	EMAIL AS 'WC:Contact/WC:EmailAddressText', 
	PHONE AS 'WC:Contact/WC:TelephoneNumberText', 
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText', 
	FAX AS 'WC:Contact/WC:FaxNumberText', 
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText', 
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	
	(SELECT WADE_R.ReportDetail(ORGANIZATION_ID, @reportid, @loctype, @loctxt, @datatype))
	
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS (SELECT DISTINCT ORGANIZATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE 
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND COUNTY_FIPS=@loctxt)
	
	FOR XML PATH('WC:Organization'), ROOT('WC:WaDE'));

SELECT @tmp=REPLACE(CONVERT(varchar(max),@tmp), ' xmlns:WC="ReplaceMe"','');
	
END
--end COUNTY

IF @loctype='REPORTUNIT'

BEGIN
--start REPORTUNIT

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName', 
	PURVUE_DESC AS 'WC:PurviewDescription',
	WADE_URL AS 'WC:WaDEURLAddress',
	FIRST_NAME AS 'WC:Contact/WC:FirstName', 
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial', 
	LAST_NAME AS 'WC:Contact/WC:LastName', 
	TITLE AS 'WC:Contact/WC:IndividualTitleText', 
	EMAIL AS 'WC:Contact/WC:EmailAddressText', 
	PHONE AS 'WC:Contact/WC:TelephoneNumberText', 
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText', 
	FAX AS 'WC:Contact/WC:FaxNumberText', 
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText', 
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	
	(SELECT WADE_R.ReportDetail(ORGANIZATION_ID, @reportid, @loctype, @loctxt, @datatype))
	
	FROM 
	
	WADE.ORGANIZATION A WHERE EXISTS (SELECT DISTINCT ORGANIZATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE 
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND REPORTING_UNIT_ID=@loctxt)
	
	FOR XML PATH('WC:Organization'), ROOT('WC:WaDE'));
	
SELECT @tmp=REPLACE(CONVERT(varchar(max),@tmp), ' xmlns:WC="ReplaceMe"','');

END
--end REPORTUNIT
END
--end ALL Parameter

RETURN (@tmp);
END

--end function
GO
/****** Object:  UserDefinedFunction [wade_r].[GetMethod]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[GetMethod](@methodid varchar(10), @methodname varchar(255)) RETURNS XML

BEGIN

DECLARE @tmp XML='';

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName',
	FIRST_NAME AS 'WC:Contact/WC:FirstName', 
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial', 
	LAST_NAME AS 'WC:Contact/WC:LastName', 
	TITLE AS 'WC:Contact/WC:IndividualTitleText', 
	EMAIL AS 'WC:Contact/WC:EmailAddressText', 
	PHONE AS 'WC:Contact/WC:TelephoneNumberText', 
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText', 
	FAX AS 'WC:Contact/WC:FaxNumberText',
	
	(SELECT WADE_R.MethodSummary(@methodid,@methodname))
	
	FROM
	
	WADE.ORGANIZATION WHERE ORGANIZATION_ID=@methodid
	
	FOR XML PATH('WC:Organization'), ROOT('WC:MethodDescriptor'));

SELECT @tmp=REPLACE(CONVERT(varchar(max),@tmp), ' xmlns:WC="ReplaceMe"','');

RETURN (@tmp);

END



GO
/****** Object:  UserDefinedFunction [wade_r].[GetSummaryByLocation]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[GetSummaryByLocation](@loctype varchar(max), @loctxt varchar(max), @orgid varchar(10), @reportid varchar(35), @datatype varchar(60)) RETURNS XML

BEGIN

DECLARE @tmp XML='';

WITH XMLNAMESPACES('http://www.exchangenetwork.net/schema/WaDE/0.2' AS WC)

SELECT @tmp=(SELECT ORGANIZATION_ID AS 'WC:OrganizationIdentifier', 
	ORGANIZATION_NAME as 'WC:OrganizationName',
	PURVUE_DESC AS 'WC:PurviewDescription',
	WADE_URL AS 'WC:WaDEURLAddress',
	FIRST_NAME AS 'WC:Contact/WC:FirstName', 
	MIDDLE_INITIAL AS 'WC:Contact/WC:MiddleInitial', 
	LAST_NAME AS 'WC:Contact/WC:LastName', 
	TITLE AS 'WC:Contact/WC:IndividualTitleText', 
	EMAIL AS 'WC:Contact/WC:EmailAddressText', 
	PHONE AS 'WC:Contact/WC:TelephoneNumberText', 
	PHONE_EXT AS 'WC:Contact/WC:PhoneExtensionText', 
	FAX AS 'WC:Contact/WC:FaxNumberText', 
	ADDRESS AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressText', 
	ADDRESS_EXT AS 'WC:Contact/WC:MailingAddress/WC:SupplementalAddressText', 
	CITY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCityName', 
	STATE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressStateUSPSCode', 
	COUNTRY AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressCountryCode', 
	ZIPCODE AS 'WC:Contact/WC:MailingAddress/WC:MailingAddressZIPCode', 
	
	(SELECT WADE_R.ReportSummary(ORGANIZATION_ID, @reportid, @loctype, @loctxt, @datatype))
	
	FROM 
	
	WADE.ORGANIZATION WHERE ORGANIZATION_ID=@orgid 
	
	FOR XML PATH('WC:Organization'), ROOT('WC:WaDE'));

SELECT @tmp=REPLACE(CONVERT(varchar(max),@tmp), ' xmlns:WC="ReplaceMe"','');

RETURN (@tmp);

END


GO
/****** Object:  UserDefinedFunction [wade_r].[LocationCatalog]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[LocationCatalog](@orgid varchar(10), @reportid varchar(35), @loctype varchar(max), @loctxt varchar(max))
  RETURNS xml

BEGIN
--BEGIN FUNCTION

DECLARE @tmp XML='';

IF @loctype='HUC'

BEGIN
--BEGIN HUC

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT 'HUC' AS 'WC:LocationType',
	A.HUC AS 'WC:LocationText',
	B.REPORTING_UNIT_NAME AS 'WC:LocationName',
	(SELECT WADE_R.DataCatalog(@orgid, @reportid, @loctype, @loctxt))
	
	FROM 
	
	WADE_R.CATALOG_SUMMARY A LEFT JOIN WADE.REPORTING_UNIT B ON A.ORGANIZATION_ID = B.ORGANIZATION_ID AND A.REPORT_ID = B.REPORT_ID AND A.REPORT_UNIT_ID = B.HUC
	WHERE A.ORGANIZATION_ID=@orgid AND A.REPORT_ID=@reportid AND A.HUC=@loctxt GROUP BY A.HUC, REPORTING_UNIT_NAME FOR XML PATH ('WC:Location'));
	
END
--END HUC

IF @loctype='COUNTY'
BEGIN
--BEGIN COUNTY

WITH XMLNAMESPACES('ReplaceMe' AS WC)
SELECT @tmp=(SELECT 'COUNTY' AS 'WC:LocationType',
	A.COUNTY_FIPS AS 'WC:LocationText',
	B.REPORTING_UNIT_NAME AS 'WC:LocationName',
	(SELECT WADE_R.DataCatalog(@orgid, @reportid, @loctype, @loctxt))
	
	FROM 
	
	WADE_R.CATALOG_SUMMARY A LEFT JOIN WADE.REPORTING_UNIT B ON A.ORGANIZATION_ID = B.ORGANIZATION_ID AND A.REPORT_ID = B.REPORT_ID AND A.REPORT_UNIT_ID = B.COUNTY_FIPS
	WHERE A.ORGANIZATION_ID=@orgid AND A.REPORT_ID=@reportid AND A.COUNTY_FIPS=@loctxt GROUP BY A.COUNTY_FIPS, REPORTING_UNIT_NAME FOR XML PATH ('WC:Location'));
	
END
--END COUNTY

IF @loctype='REPORTUNIT'
BEGIN
--BEGIN REPORTUNIT

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT 'REPORTUNIT' AS 'WC:LocationType',
	A.REPORT_UNIT_ID AS 'WC:LocationText',
	B.REPORTING_UNIT_NAME AS 'WC:LocationName',
	(SELECT WADE_R.DataCatalog(@orgid, @reportid, @loctype, @loctxt))
	
	FROM 
	
	WADE_R.CATALOG_SUMMARY A LEFT JOIN WADE.REPORTING_UNIT B ON A.ORGANIZATION_ID = B.ORGANIZATION_ID AND A.REPORT_ID = B.REPORT_ID AND A.REPORT_UNIT_ID = B.REPORT_UNIT_ID
	WHERE A.ORGANIZATION_ID=@orgid AND A.REPORT_ID=@reportid AND A.REPORT_UNIT_ID=@loctxt GROUP BY A.REPORT_UNIT_ID, REPORTING_UNIT_NAME FOR XML PATH ('WC:Location'));
	
	
END
--END REPORTUNIT

RETURN (@tmp)
		
END



GO
/****** Object:  UserDefinedFunction [wade_r].[MethodSummary]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[MethodSummary](@methodid varchar(10),@methodname varchar(255)) RETURNS XML

BEGIN

DECLARE @tmp XML='';

IF (@methodname='ALL')

BEGIN

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT METHOD_ID AS 'WC:MethodIdentifier', 
	METHOD_NAME as 'WC:MethodName',
	METHOD_DESC as 'WC:MethodDescriptionText',
	METHOD_DATE as 'WC:MethodDevelopmentDate',
	METHOD_TYPE as 'WC:MethodTypeText',
	TIME_SCALE as 'WC:TimeScaleText',
	METHOD_LINK as 'WC:MethodLinkText',
	RESOURCE_TYPE as 'WC:ResourceType/WC:ResourceTypeText',
	LOCATION_NAME as 'WC:ApplicableAreas/WC:LocationNameText',
	B.SOURCE_ID as 'WC:DataSource/WC:DataSourceIdentifier',
	SOURCE_NAME as 'WC:DataSource/WC:DataSourceName',
	SOURCE_DESC as 'WC:DataSource/WC:DataSourceDescription',
	SOURCE_START_DATE as 'WC:DataSource/WC:DataSourceTimePeriod/WC:TimePeriodStartDate',
	SOURCE_END_DATE as 'WC:DataSource/WC:DataSourceTimePeriod/WC:TimePeriodEndDate',
	SOURCE_LINK as 'WC:DataSource/WC:DataSourceLinkText'
	
	FROM
	
	WADE.METHODS 
	
	A LEFT JOIN WADE.DATA_SOURCES B ON (A.SOURCE_ID = B.SOURCE_ID) 
	
	WHERE METHOD_CONTEXT=@methodid
	
	FOR XML PATH('WC:Method'));
				
END
ELSE
		
BEGIN

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT METHOD_ID AS 'WC:MethodIdentifier', 
	METHOD_NAME as 'WC:MethodName',
	METHOD_DESC as 'WC:MethodDescriptionText',
	METHOD_DATE as 'WC:MethodDevelopmentDate',
	METHOD_TYPE as 'WC:MethodTypeText',
	TIME_SCALE as 'WC:TimeScaleText',
	METHOD_LINK as 'WC:MethodLinkText',
	RESOURCE_TYPE as 'WC:ResourceType/WC:ResourceTypeText',
	LOCATION_NAME as 'WC:ApplicableAreas/WC:LocationNameText',
	B.SOURCE_ID as 'WC:DataSource/WC:DataSourceIdentifier',
	SOURCE_NAME as 'WC:DataSource/WC:DataSourceName',
	SOURCE_DESC as 'WC:DataSource/WC:DataSourceDescription',
	SOURCE_START_DATE as 'WC:DataSource/WC:DataSourceTimePeriod/WC:TimePeriodStartDate',
	SOURCE_END_DATE as 'WC:DataSource/WC:DataSourceTimePeriod/WC:TimePeriodEndDate',
	SOURCE_LINK as 'WC:DataSource/WC:DataSourceLinkText'
	
	FROM
	
	WADE.METHODS 
	
	A LEFT JOIN WADE.DATA_SOURCES B ON (A.SOURCE_ID = B.SOURCE_ID)
	
	WHERE METHOD_CONTEXT=@methodid AND METHOD_NAME=@methodname
	
	FOR XML PATH('WC:Method'));
	
END

RETURN (@tmp);

END
GO
/****** Object:  UserDefinedFunction [wade_r].[ReportCatalog]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[ReportCatalog](@orgid varchar(10), @loctype varchar(max), @loctxt varchar(max))
  RETURNS xml

BEGIN
--BEGIN FUNCTION

DECLARE @tmp XML='';

IF @loctype='HUC'

BEGIN
--BEGIN HUC

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT REPORT_ID AS 'WC:ReportIdentifier',
	REPORTING_DATE AS 'WC:ReportingDate',
	REPORTING_YEAR AS 'WC:ReportingYear',
	REPORT_NAME AS 'WC:ReportName',
	REPORT_LINK AS 'WC:ReportLink',
	YEAR_TYPE AS 'WC:YearType',
	(SELECT WADE_R.LocationCatalog(@orgid, REPORT_ID, @loctype, @loctxt))
	
	FROM 
	
	WADE.REPORT A WHERE ORGANIZATION_ID=@orgid AND EXISTS (SELECT B.ORGANIZATION_ID, B.REPORT_ID 
	FROM WADE_R.CATALOG_SUMMARY B WHERE A.ORGANIZATION_ID=B.ORGANIZATION_ID AND A.REPORT_ID=B.REPORT_ID 
	AND B.HUC=@loctxt) FOR XML PATH ('WC:Report'));
	
END
--END HUC

IF @loctype='COUNTY'
BEGIN
--BEGIN COUNTY

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT REPORT_ID AS 'WC:ReportIdentifier',
	REPORTING_DATE AS 'WC:ReportingDate',
	REPORTING_YEAR AS 'WC:ReportingYear',
	REPORT_NAME AS 'WC:ReportName',
	REPORT_LINK AS 'WC:ReportLink',
	YEAR_TYPE AS 'WC:YearType',
	(SELECT WADE_R.LocationCatalog(@orgid, REPORT_ID, @loctype, @loctxt))
	
	FROM 
	
	WADE.REPORT A WHERE ORGANIZATION_ID=@orgid and EXISTS (SELECT B.ORGANIZATION_ID, B.REPORT_ID 
	FROM WADE_R.CATALOG_SUMMARY B WHERE A.ORGANIZATION_ID=B.ORGANIZATION_ID AND A.REPORT_ID=B.REPORT_ID 
	AND B.COUNTY_FIPS=@loctxt) FOR XML PATH ('WC:Report'));
	
END
--END COUNTY

IF @loctype='REPORTUNIT'
BEGIN
--BEGIN REPORTUNIT

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT REPORT_ID AS 'WC:ReportIdentifier',
	REPORTING_DATE AS 'WC:ReportingDate',
	REPORTING_YEAR AS 'WC:ReportingYear',
	REPORT_NAME AS 'WC:ReportName',
	REPORT_LINK AS 'WC:ReportLink',
	YEAR_TYPE AS 'WC:YearType',
	(SELECT WADE_R.LocationCatalog(@orgid, REPORT_ID, @loctype, @loctxt))
	
	FROM 
	
	WADE.REPORT A WHERE ORGANIZATION_ID=@orgid and EXISTS (SELECT B.ORGANIZATION_ID, B.REPORT_ID 
	FROM WADE_R.CATALOG_SUMMARY B WHERE A.ORGANIZATION_ID=B.ORGANIZATION_ID AND A.REPORT_ID=B.REPORT_ID 
	AND B.REPORT_UNIT_ID=@loctxt) FOR XML PATH ('WC:Report'));
	
END
--END REPORTUNIT

RETURN (@tmp)
		
END



GO
/****** Object:  UserDefinedFunction [wade_r].[ReportDetail]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[ReportDetail](@orgid varchar(10), @reportid varchar(35), @loctype varchar(max), @loctxt varchar(max), @datatype varchar(60)) 

RETURNS XML

BEGIN
--START FUNCTION

DECLARE @tmp XML='';

IF (@datatype <>'ALL')

BEGIN
--START NOT ALL

IF @loctype='HUC'

BEGIN
--START HUC

WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT REPORT_ID AS 'WC:ReportIdentifier',
	REPORTING_DATE AS 'WC:ReportingDate',
	REPORTING_YEAR AS 'WC:ReportingYear',
	REPORT_NAME AS 'WC:ReportName',
	REPORT_LINK AS 'WC:ReportLink',
	YEAR_TYPE AS 'WC:YearType',
	(SELECT WADE_R.GeospatialRefDetail (@orgid, REPORT_ID, @datatype)),
	(SELECT WADE_R.XML_ALLOCATION_DETAIL (@orgid, REPORT_ID, @loctype, @loctxt, @datatype))
	
	FROM 
	
	WADE.REPORT A WHERE EXISTS (SELECT DISTINCT ORGANIZATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE A.ORGANIZATION_ID=B.ORGANIZATION_ID AND
	A.REPORT_ID=@reportid AND B.ORGANIZATION_ID=@orgid and HUC LIKE @loctxt + '%' AND DATATYPE=@datatype) FOR XML PATH (''));
	
END
--END HUC
	
IF @loctype='COUNTY'

BEGIN
--START COUNTY

WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT REPORT_ID AS 'WC:ReportIdentifier',
	REPORTING_DATE AS 'WC:ReportingDate',
	REPORTING_YEAR AS 'WC:ReportingYear',
	REPORT_NAME AS 'WC:ReportName',
	REPORT_LINK AS 'WC:ReportLink',
	YEAR_TYPE AS 'WC:YearType',
	(SELECT WADE_R.GeospatialRefDetail (@orgid, REPORT_ID, @datatype)),
	(SELECT WADE_R.XML_ALLOCATION_DETAIL (@orgid, REPORT_ID, @loctype, @loctxt, @datatype))
	
	FROM 
	
	WADE.REPORT A WHERE EXISTS (SELECT DISTINCT ORGANIZATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE A.ORGANIZATION_ID=B.ORGANIZATION_ID AND
	A.REPORT_ID=@reportid AND B.ORGANIZATION_ID=@orgid and COUNTY_FIPS=@loctxt AND DATATYPE=@datatype) FOR XML PATH (''));

END 
--END COUNTY

IF @loctype='REPORTUNIT'

BEGIN
--START REPORT UNIT

WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT REPORT_ID AS 'WC:ReportIdentifier',
	REPORTING_DATE AS 'WC:ReportingDate',
	REPORTING_YEAR AS 'WC:ReportingYear',
	REPORT_NAME AS 'WC:ReportName',
	REPORT_LINK AS 'WC:ReportLink',
	YEAR_TYPE AS 'WC:YearType',
	(SELECT WADE_R.GeospatialRefDetail (@orgid, REPORT_ID, @datatype)),
	(SELECT WADE_R.XML_ALLOCATION_DETAIL (@orgid, REPORT_ID, @loctype, @loctxt, @datatype))
	
	FROM 
	
	WADE.REPORT A WHERE EXISTS (SELECT DISTINCT ORGANIZATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE A.ORGANIZATION_ID=B.ORGANIZATION_ID AND
	A.REPORT_ID=@reportid AND B.ORGANIZATION_ID=@orgid and REPORTING_UNIT_ID=@loctxt AND DATATYPE=@datatype) FOR XML PATH (''));

END
--END REPORT UNIT

END
--END IF NOT ALL

ELSE

BEGIN
--START IF ALL

IF @loctype='HUC'

BEGIN
--START HUC

WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT REPORT_ID AS 'WC:ReportIdentifier',
	REPORTING_DATE AS 'WC:ReportingDate',
	REPORTING_YEAR AS 'WC:ReportingYear',
	REPORT_NAME AS 'WC:ReportName',
	REPORT_LINK AS 'WC:ReportLink',
	YEAR_TYPE AS 'WC:YearType',	
	(SELECT WADE_R.GeospatialRefDetail (@orgid, REPORT_ID, @datatype)),
	(SELECT WADE_R.XML_ALLOCATION_DETAIL (@orgid, REPORT_ID, @loctype, @loctxt, @datatype))
	
	FROM 
	
	WADE.REPORT A WHERE EXISTS (SELECT DISTINCT ORGANIZATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE A.ORGANIZATION_ID=B.ORGANIZATION_ID AND
	A.REPORT_ID=@reportid AND B.ORGANIZATION_ID=@orgid and HUC LIKE @loctxt + '%') FOR XML PATH (''));

END 
--END HUC

IF @loctype='COUNTY'

BEGIN
--START COUNTY

WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT REPORT_ID AS 'WC:ReportIdentifier',
	REPORTING_DATE AS 'WC:ReportingDate',
	REPORTING_YEAR AS 'WC:ReportingYear',
	REPORT_NAME AS 'WC:ReportName',
	REPORT_LINK AS 'WC:ReportLink',
	YEAR_TYPE AS 'WC:YearType',
		(SELECT WADE_R.GeospatialRefDetail (@orgid, REPORT_ID, @datatype)),
		(SELECT WADE_R.XML_ALLOCATION_DETAIL (@orgid, REPORT_ID, @loctype, @loctxt, @datatype))
	
	FROM 
	
	WADE.REPORT A WHERE EXISTS (SELECT DISTINCT ORGANIZATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE A.ORGANIZATION_ID=B.ORGANIZATION_ID AND
	A.REPORT_ID=@reportid AND B.ORGANIZATION_ID=@orgid and COUNTY_FIPS=@loctxt) FOR XML PATH (''));

END 
--END COUNTY

IF @loctype='REPORTUNIT'

BEGIN
--START REPORT UNIT

WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT REPORT_ID AS 'WC:ReportIdentifier',
	REPORTING_DATE AS 'WC:ReportingDate',
	REPORTING_YEAR AS 'WC:ReportingYear',
	REPORT_NAME AS 'WC:ReportName',
	REPORT_LINK AS 'WC:ReportLink',
	YEAR_TYPE AS 'WC:YearType',
		(SELECT WADE_R.GeospatialRefDetail (@orgid, REPORT_ID, @datatype)),
		(SELECT WADE_R.XML_ALLOCATION_DETAIL (@orgid, REPORT_ID, @loctype, @loctxt, @datatype))
	
	FROM 
	
	WADE.REPORT A WHERE EXISTS (SELECT DISTINCT ORGANIZATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE A.ORGANIZATION_ID=B.ORGANIZATION_ID AND
	A.REPORT_ID=@reportid AND B.ORGANIZATION_ID=@orgid and REPORTING_UNIT_ID=@loctxt) FOR XML PATH (''));
	
END
--END REPORT UNIT

END
--END IF ALL

BEGIN
--START TAG

WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT @tmp FOR XML PATH('WC:Report'));

END
--END TAG

RETURN(@tmp) 

END
--END FUNCTION
GO
/****** Object:  UserDefinedFunction [wade_r].[ReportSummary]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[ReportSummary](@orgid varchar(10), @reportid varchar(35), @loctype varchar(max), @loctxt varchar(max), @datatype varchar(60))
  RETURNS xml

BEGIN

DECLARE @tmp XML;

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT REPORT_ID AS 'WC:ReportIdentifier', 
	REPORTING_DATE as 'WC:ReportingDate', 
	REPORTING_YEAR AS 'WC:ReportingYear', 
	REPORT_NAME AS 'WC:ReportName', 
	REPORT_LINK AS 'WC:ReportLink', 
	YEAR_TYPE AS 'WC:YearType',
	(SELECT wade_r.GeospatialRefSummary (@orgid, @reportid, @datatype)),
	(SELECT wade_r.ReportUnitSummary (@orgid, @reportid, @loctype, @loctxt, @datatype))
	
	FROM 
	
	wade.REPORT WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid 
	
	FOR XML PATH('WC:Report'))

RETURN (@tmp)
		
END

GO
/****** Object:  UserDefinedFunction [wade_r].[ReportUnitSummary]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[ReportUnitSummary](@orgid varchar(10), @reportid varchar(35), @loctype varchar(max), @loctxt varchar(max), @datatype varchar(60))
  RETURNS xml 

BEGIN
--BEGIN FUNCTION
DECLARE @tmp XML;

IF @datatype<>'ALL'	

BEGIN
--BEGIN IF NOT ALL PARAMETER
IF @loctype='HUC'
BEGIN
--BEGIN HUC
WITH XMLNAMESPACES('ReplaceMe' AS WC)
	SELECT @tmp=(SELECT REPORT_UNIT_ID AS 'WC:ReportingUnitIdentifier', 
	REPORTING_UNIT_NAME as 'WC:ReportingUnitName', 
	REPORTING_UNIT_TYPE AS 'WC:ReportingUnitTypeName', 
	B.VALUE AS 'WC:Location/WC:StateCode', 
	COUNTY_FIPS AS 'WC:Location/WC:CountyFipsCode', 
	HUC AS 'WC:Location/WC:HydrologicUnitCode',
		(SELECT CASE WHEN @datatype='AVAILABILITY' THEN (SELECT WADE_R.XML_AVAILABILITY_SUMMARY(@orgid,REPORT_ID,REPORT_UNIT_ID))
        WHEN @datatype='ALLOCATION' THEN (SELECT WADE_R.XML_ALLOCATION_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID))
		WHEN @datatype='USE' THEN (SELECT WADE_R.XML_USE_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID))
		WHEN @datatype='SUPPLY' THEN (SELECT WADE_R.XML_SUPPLY_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID))
		WHEN @datatype='REGULATORY' THEN (SELECT WADE_R.XML_REGULATORY_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID))end)
	
	FROM  
	
	WADE.REPORTING_UNIT A LEFT JOIN WADE.LU_STATE B ON (A.STATE=B.LU_SEQ_NO) WHERE EXISTS (SELECT B.REPORT_UNIT_ID FROM WADE_R.SUMMARY_LOCATION B WHERE
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND A.REPORT_ID=B.REPORT_ID AND A.REPORT_UNIT_ID=B.REPORT_UNIT_ID AND B.ORGANIZATION_ID=@orgid AND 
	B.REPORT_ID=@reportid AND B.HUC=@loctxt AND B.DATATYPE=@datatype) AND A.ORGANIZATION_ID=@orgid AND A.REPORT_ID=@reportid
	
 	FOR XML PATH(''));

END
--END HUC
IF @loctype='COUNTY'
BEGIN
--BEGIN COUNTY
WITH XMLNAMESPACES('ReplaceMe' AS WC)
	SELECT @tmp=(SELECT REPORT_UNIT_ID AS 'WC:ReportingUnitIdentifier', 
	REPORTING_UNIT_NAME as 'WC:ReportingUnitName', 
	REPORTING_UNIT_TYPE AS 'WC:ReportingUnitTypeName', 
	B.VALUE AS 'WC:Location/WC:StateCode', 
	COUNTY_FIPS AS 'WC:Location/WC:CountyFipsCode', 
	HUC AS 'WC:Location/WC:HydrologicUnitCode',
	(SELECT CASE WHEN @datatype='AVAILABILITY' THEN (SELECT WADE_R.XML_AVAILABILITY_SUMMARY(@orgid,REPORT_ID,REPORT_UNIT_ID))
    WHEN @datatype='ALLOCATION' THEN  (SELECT WADE_R.XML_ALLOCATION_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID))
	WHEN @datatype='USE' THEN (SELECT WADE_R.XML_USE_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID))
	WHEN @datatype='SUPPLY' THEN (SELECT WADE_R.XML_SUPPLY_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID))
	WHEN @datatype='REGULATORY' THEN (SELECT WADE_R.XML_REGULATORY_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID))end)
	
	FROM  
	
	WADE.REPORTING_UNIT A LEFT JOIN WADE.LU_STATE B ON (A.STATE=B.LU_SEQ_NO) WHERE EXISTS(SELECT B.REPORT_UNIT_ID FROM WADE_R.SUMMARY_LOCATION B WHERE
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND A.REPORT_ID=B.REPORT_ID AND A.REPORT_UNIT_ID=B.REPORT_UNIT_ID AND B.ORGANIZATION_ID=@orgid AND
	B.REPORT_ID=@reportid AND B.COUNTY_FIPS=@loctxt AND B.DATATYPE=@datatype) AND A.ORGANIZATION_ID=@orgid AND A.REPORT_ID=@reportid
	
 	FOR XML PATH(''));

END
--END COUNTY
IF @loctype='REPORTUNIT'
BEGIN
--BEGIN REPORTUNIT
WITH XMLNAMESPACES('ReplaceMe' AS WC)
SELECT @tmp=(SELECT REPORT_UNIT_ID AS 'WC:ReportingUnitIdentifier', 
	REPORTING_UNIT_NAME as 'WC:ReportingUnitName', 
	REPORTING_UNIT_TYPE AS 'WC:ReportingUnitTypeName', 
	B.VALUE AS 'WC:Location/WC:StateCode', 
	COUNTY_FIPS AS 'WC:Location/WC:CountyFipsCode', 
	HUC AS 'WC:Location/WC:HydrologicUnitCode',
		(SELECT CASE WHEN @datatype='AVAILABILITY' THEN (SELECT WADE_R.XML_AVAILABILITY_SUMMARY(@orgid,REPORT_ID,REPORT_UNIT_ID))
		WHEN @datatype='ALLOCATION' THEN  (SELECT WADE_R.XML_ALLOCATION_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID))
		WHEN @datatype='USE' THEN (SELECT WADE_R.XML_USE_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID))
		WHEN @datatype='SUPPLY' THEN (SELECT WADE_R.XML_SUPPLY_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID))
		WHEN @datatype='REGULATORY' THEN (SELECT WADE_R.XML_REGULATORY_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID))end)
		
	FROM
	  
	WADE.REPORTING_UNIT A LEFT JOIN WADE.LU_STATE B ON (A.STATE=B.LU_SEQ_NO) WHERE EXISTS(SELECT B.REPORT_UNIT_ID FROM WADE_R.SUMMARY_LOCATION B WHERE
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND A.REPORT_ID=B.REPORT_ID AND A.REPORT_UNIT_ID=B.REPORT_UNIT_ID AND B.ORGANIZATION_ID=@orgid AND
	B.REPORT_ID=@reportid AND B.REPORT_UNIT_ID=@loctxt AND B.DATATYPE=@datatype) AND A.ORGANIZATION_ID=@orgid AND A.REPORT_ID=@reportid
	
 	FOR XML PATH(''));

END
--END REPORTUNIT
END
--END  NOT ALL

ELSE

BEGIN
--BEGIN ALL PARAMETER

IF @loctype='HUC'

BEGIN
--BEGIN HUC

WITH XMLNAMESPACES('ReplaceMe' AS WC)
	SELECT @tmp=(SELECT REPORT_UNIT_ID AS 'WC:ReportingUnitIdentifier', 
	REPORTING_UNIT_NAME as 'WC:ReportingUnitName', 
	REPORTING_UNIT_TYPE AS 'WC:ReportingUnitTypeName', 
	B.VALUE AS 'WC:Location/WC:StateCode', 
	COUNTY_FIPS AS 'WC:Location/WC:CountyFipsCode', 
	HUC AS 'WC:Location/WC:HydrologicUnitCode',
		(SELECT WADE_R.XML_AVAILABILITY_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID)),
		(SELECT WADE_R.XML_ALLOCATION_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID)),
		(SELECT WADE_R.XML_USE_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID)),
		(SELECT WADE_R.XML_SUPPLY_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID)),
		(SELECT WADE_R.XML_REGULATORY_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID))
	
	FROM  
	
	WADE.REPORTING_UNIT A LEFT JOIN WADE.LU_STATE B ON (A.STATE=B.LU_SEQ_NO) WHERE EXISTS (SELECT B.REPORT_UNIT_ID FROM WADE_R.SUMMARY_LOCATION B WHERE
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND A.REPORT_ID=B.REPORT_ID	AND A.REPORT_UNIT_ID=B.REPORT_UNIT_ID AND B.ORGANIZATION_ID=@orgid 
	AND B.REPORT_ID=@reportid 
	AND B.HUC=@loctxt) AND A.ORGANIZATION_ID=@orgid 
	AND A.REPORT_ID=@reportid
	
 	FOR XML PATH(''));
 	
END
--END HUC

IF @loctype='COUNTY'
BEGIN
--BEGIN COUNTY

WITH XMLNAMESPACES('ReplaceMe' AS WC)	

SELECT @tmp=(SELECT REPORT_UNIT_ID AS 'WC:ReportingUnitIdentifier', 
	REPORTING_UNIT_NAME as 'WC:ReportingUnitName', 
	REPORTING_UNIT_TYPE AS 'WC:ReportingUnitTypeName', 
	B.VALUE AS 'WC:Location/WC:StateCode', 
	COUNTY_FIPS AS 'WC:Location/WC:CountyFipsCode', 
	HUC AS 'WC:Location/WC:HydrologicUnitCode',
	(SELECT WADE_R.XML_AVAILABILITY_SUMMARY(@orgid,REPORT_ID,REPORT_UNIT_ID)),
        (SELECT WADE_R.XML_ALLOCATION_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID)),
		(SELECT WADE_R.XML_USE_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID)),
		(SELECT WADE_R.XML_SUPPLY_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID)),
		(SELECT WADE_R.XML_REGULATORY_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID))
		
	FROM
	  
	WADE.REPORTING_UNIT A LEFT JOIN WADE.LU_STATE B ON (A.STATE=B.LU_SEQ_NO) WHERE EXISTS(SELECT B.REPORT_UNIT_ID FROM WADE_R.SUMMARY_LOCATION B WHERE
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND A.REPORT_ID=B.REPORT_ID AND A.REPORT_UNIT_ID=B.REPORT_UNIT_ID AND B.ORGANIZATION_ID=@orgid 
	AND B.REPORT_ID=@reportid 
	AND B.COUNTY_FIPS=@loctxt) AND A.ORGANIZATION_ID=@orgid 
	AND A.REPORT_ID=@reportid
	
 	FOR XML PATH(''));
 	
END
--END COUNTY

IF @loctype='REPORTUNIT'
BEGIN
--BEGIN REPORTUNIT

WITH XMLNAMESPACES('ReplaceMe' AS WC)	

SELECT @tmp=(SELECT REPORT_UNIT_ID AS 'WC:ReportingUnitIdentifier', 
	REPORTING_UNIT_NAME as 'WC:ReportingUnitName', 
	REPORTING_UNIT_TYPE AS 'WC:ReportingUnitTypeName', 
	B.VALUE AS 'WC:Location/WC:StateCode', 
	COUNTY_FIPS AS 'WC:Location/WC:CountyFipsCode', 
	HUC AS 'WC:Location/WC:HydrologicUnitCode',
		(SELECT WADE_R.XML_AVAILABILITY_SUMMARY(@orgid,REPORT_ID,REPORT_UNIT_ID)),
        (SELECT WADE_R.XML_ALLOCATION_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID)),
		(SELECT WADE_R.XML_USE_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID)),
		(SELECT WADE_R.XML_SUPPLY_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID)),
		(SELECT WADE_R.XML_REGULATORY_SUMMARY(@orgid, REPORT_ID, REPORT_UNIT_ID))
		
	FROM
	  
	WADE.REPORTING_UNIT A LEFT JOIN WADE.LU_STATE B ON (A.STATE=B.LU_SEQ_NO) WHERE EXISTS(SELECT B.REPORT_UNIT_ID FROM WADE_R.SUMMARY_LOCATION B WHERE
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND A.REPORT_ID=B.REPORT_ID AND A.REPORT_UNIT_ID=B.REPORT_UNIT_ID AND B.ORGANIZATION_ID=@orgid 
	AND B.REPORT_ID=@reportid 
	AND B.REPORT_UNIT_ID=@loctxt) AND A.ORGANIZATION_ID=@orgid 
	AND A.REPORT_ID=@reportid
	
 	FOR XML PATH(''));
 	
END
--END REPORTUNIT

END
--END ALL
IF @tmp IS NOT NULL
BEGIN
WITH XMLNAMESPACES ('ReplaceMe' AS WC)
SELECT @tmp = (SELECT @tmp FOR XML PATH ('WC:ReportingUnit'));
END

RETURN(@tmp)

END
--END FUNCTION

GO
/****** Object:  UserDefinedFunction [wade_r].[USE_AMOUNT]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[USE_AMOUNT](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60), @wateruserid varchar(60))
  RETURNS XML

BEGIN

DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT C.VALUE AS 'WC:SourceTypeName',
	B.VALUE AS 'WC:FreshSalineIndicator',
	SOURCE_NAME AS 'WC:SourceName',
	(SELECT WADE_R.XML_D_COMMUNITY_WATER_SUPPLY(@orgid, @reportid, @allocationid, @wateruserid, BENEFICIAL_USE_ID)),
	(SELECT WADE_R.XML_D_IRRIGATION(@orgid, @reportid, @allocationid, @wateruserid, BENEFICIAL_USE_ID)),
	(SELECT WADE_R.XML_D_THERMOELECTRIC(@orgid, @reportid, @allocationid, @wateruserid, BENEFICIAL_USE_ID)),
	(SELECT WADE_R.XML_D_USE_AMOUNT(@orgid, @reportid, @allocationid, @wateruserid, BENEFICIAL_USE_ID))
	
	FROM 
	
	WADE.D_CONSUMPTIVE_USE A LEFT JOIN WADE.LU_FRESH_SALINE_INDICATOR B ON (A.FRESH_SALINE_IND=B.LU_SEQ_NO) LEFT JOIN WADE.LU_SOURCE_TYPE C ON (A.SOURCE_TYPE=C.LU_SEQ_NO)
	
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid and WATER_USER_ID=@wateruserid
	
	FOR XML PATH(''));

If (@tmp IS NOT NULL)
BEGIN
WITH XMLNAMESPACES ('ReplaceMe' AS WC)
SELECT @tmp=(SELECT @tmp FOR XML PATH('WC:UseAmount'));
END
RETURN (@tmp)

END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_ALLOCATION_DETAIL]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[XML_ALLOCATION_DETAIL](@orgid varchar(10), @reportid varchar(35), @loctype varchar(max), @loctxt varchar(max),@datatype varchar(60)) 

RETURNS XML

BEGIN
--START FUNCTION

DECLARE @tmp XML;

IF @datatype<>'ALL'

BEGIN
--START NOT ALL

IF @loctype='HUC'

BEGIN
--START HUC

WITH XMLNAMESPACES ('ReplaceMe' AS WC)
	
SELECT @tmp=(SELECT ALLOCATION_ID AS 'WC:AllocationIdentifier',
	ALLOCATION_OWNER as 'WC:AllocationOwnerName',
	APPLICATION_DATE AS 'WC:ApplicationDate',
	PRIORITY_DATE AS 'WC:PriorityDate',
	END_DATE AS 'WC:EndDate',
	C.VALUE AS 'WC:LegalStatusCode',
	(SELECT WADE_R.XML_D_ALLOCATION_LOCATION (@orgid, @reportid, @loctype, @loctxt,A.ALLOCATION_ID)),
	(SELECT CASE WHEN @datatype='ALLOCATION' THEN (SELECT WADE_R.ALLOCATION_AMOUNT(@orgid, @reportid, A.ALLOCATION_ID))
	WHEN @datatype='DIVERSION' THEN (SELECT WADE_R.ALLOCATION_AMOUNT(@orgid, @reportid, A.ALLOCATION_ID), 
									(SELECT WADE_R.XML_DIVERSION_DETAIL(@orgid, @reportid, A.ALLOCATION_ID)) FOR XML PATH (''),TYPE)
	WHEN @datatype='USE' THEN (SELECT WADE_R.XML_USE_DETAIL(@orgid, @reportid, A.ALLOCATION_ID))
	WHEN @datatype='RETURN' THEN (SELECT WADE_R.XML_RETURNFLOW_DETAIL(@orgid, @reportid, A.ALLOCATION_ID))end)
	
	FROM WADE.DETAIL_ALLOCATION A LEFT JOIN WADE.LU_LEGAL_STATUS C ON (A.LEGAL_STATUS=C.LU_SEQ_NO) WHERE EXISTS (SELECT B.ALLOCATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND A.REPORT_ID=B.REPORT_ID AND A.ALLOCATION_ID=B.ALLOCATION_ID 
	AND B.ORGANIZATION_ID=@orgid AND B.REPORT_ID=@reportid AND B.HUC LIKE @loctxt + '%' AND B.DATATYPE=@datatype)
	
	FOR XML PATH ('WC:WaterAllocation'));

END
--END HUC	

IF @loctype='COUNTY'

BEGIN
--START COUNTY

WITH XMLNAMESPACES ('ReplaceMe' AS WC)
	
SELECT @tmp=(SELECT ALLOCATION_ID AS 'WC:AllocationIdentifier',
	ALLOCATION_OWNER as 'WC:AllocationOwnerName',
	APPLICATION_DATE AS 'WC:ApplicationDate',
	PRIORITY_DATE AS 'WC:PriorityDate',
	END_DATE AS 'WC:EndDate',
	C.VALUE AS 'WC:LegalStatusCode',
	(SELECT WADE_R.XML_D_ALLOCATION_LOCATION (@orgid, @reportid, @loctype, @loctxt,A.ALLOCATION_ID)),
	(SELECT CASE WHEN @datatype='ALLOCATION' THEN (SELECT WADE_R.ALLOCATION_AMOUNT(@orgid, @reportid, A.ALLOCATION_ID))
	WHEN @datatype='DIVERSION' THEN (SELECT WADE_R.ALLOCATION_AMOUNT(@orgid, @reportid, A.ALLOCATION_ID), 
									(SELECT WADE_R.XML_DIVERSION_DETAIL(@orgid, @reportid, A.ALLOCATION_ID)) FOR XML PATH (''),TYPE)
	WHEN @datatype='USE' THEN (SELECT WADE_R.XML_USE_DETAIL(@orgid, @reportid, A.ALLOCATION_ID))
	WHEN @datatype='RETURN' THEN (SELECT WADE_R.XML_RETURNFLOW_DETAIL(@orgid, @reportid, A.ALLOCATION_ID))end)
	
	FROM WADE.DETAIL_ALLOCATION A LEFT JOIN WADE.LU_LEGAL_STATUS C ON (A.LEGAL_STATUS=C.LU_SEQ_NO) WHERE EXISTS (SELECT B.ALLOCATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND A.REPORT_ID=B.REPORT_ID AND A.ALLOCATION_ID=B.ALLOCATION_ID 
	AND B.ORGANIZATION_ID=@orgid AND B.REPORT_ID=@reportid AND B.COUNTY_FIPS=@loctxt AND B.DATATYPE=@datatype)
	
	FOR XML PATH ('WC:WaterAllocation'));

END
--END COUNTY

IF @loctype='REPORTUNIT'
BEGIN
--START REPORTUNIT

WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT ALLOCATION_ID AS 'WC:AllocationIdentifier',
	ALLOCATION_OWNER AS 'WC:AllocationOwnerName', 
	APPLICATION_DATE AS 'WC:ApplicationDate',
	PRIORITY_DATE AS 'WC:PriorityDate', 
	END_DATE AS 'WC:EndDate',
	C.VALUE AS 'WC:LegalStatusCode', 
	(SELECT WADE_R.XML_D_ALLOCATION_LOCATION (@orgid, @reportid, @loctype, @loctxt,A.ALLOCATION_ID)),
	(SELECT CASE WHEN @datatype='ALLOCATION' THEN (SELECT WADE_R.ALLOCATION_AMOUNT(@orgid, @reportid, A.ALLOCATION_ID))
	WHEN @datatype='DIVERSION' THEN (SELECT WADE_R.ALLOCATION_AMOUNT(@orgid, @reportid, A.ALLOCATION_ID), 
									(SELECT WADE_R.XML_DIVERSION_DETAIL(@orgid, @reportid, A.ALLOCATION_ID)) FOR XML PATH (''),TYPE)
	WHEN @datatype='USE' THEN (SELECT WADE_R.XML_USE_DETAIL(@orgid, @reportid, A.ALLOCATION_ID))
	WHEN @datatype='RETURN' THEN (SELECT WADE_R.XML_RETURNFLOW_DETAIL(@orgid, @reportid, A.ALLOCATION_ID))end)
		
	FROM WADE.DETAIL_ALLOCATION A LEFT JOIN WADE.LU_LEGAL_STATUS C ON (A.LEGAL_STATUS=C.LU_SEQ_NO) WHERE EXISTS (SELECT B.ALLOCATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND A.REPORT_ID=B.REPORT_ID AND A.ALLOCATION_ID=B.ALLOCATION_ID 
	AND B.ORGANIZATION_ID=@orgid AND B.REPORT_ID=@reportid AND B.REPORTING_UNIT_ID=@loctxt AND B.DATATYPE=@datatype)
	
	FOR XML PATH ('WC:WaterAllocation'));
	
END
--END REPORT UNIT

END
--END NOT ALL PARAMETER

ELSE

BEGIN
--BEGIN 'ALL' PARAMETER

IF @loctype='HUC'

BEGIN
--START HUC

WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT ALLOCATION_ID AS 'WC:AllocationIdentifier',
	ALLOCATION_OWNER as 'WC:AllocationOwnerName',
	APPLICATION_DATE AS 'WC:ApplicationDate',
	PRIORITY_DATE AS 'WC:PriorityDate',
	END_DATE AS 'WC:EndDate',
	C.VALUE AS 'WC:LegalStatusCode',
	(SELECT WADE_R.XML_D_ALLOCATION_LOCATION(@orgid,@reportid,@loctype, @loctxt,A.ALLOCATION_ID)),
	(SELECT WADE_R.ALLOCATION_AMOUNT(@orgid, @reportid, A.ALLOCATION_ID)),
	(SELECT WADE_R.XML_DIVERSION_DETAIL(@orgid, @reportid, A.ALLOCATION_ID)),
	(SELECT WADE_R.XML_USE_DETAIL(@orgid, @reportid, A.ALLOCATION_ID)),
	(SELECT WADE_R.XML_RETURNFLOW_DETAIL(@orgid, @reportid, A.ALLOCATION_ID))
	
	FROM WADE.DETAIL_ALLOCATION A LEFT JOIN WADE.LU_LEGAL_STATUS C ON (A.LEGAL_STATUS=C.LU_SEQ_NO) WHERE EXISTS (SELECT B.ALLOCATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND A.REPORT_ID=B.REPORT_ID AND A.ALLOCATION_ID=B.ALLOCATION_ID 
	AND B.ORGANIZATION_ID=@orgid AND B.REPORT_ID=@reportid AND B.HUC LIKE @loctxt + '%')
	
	FOR XML PATH ('WC:WaterAllocation'));
	
END 
--END HUC

IF @loctype='COUNTY'

BEGIN
--START COUNTY

WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT ALLOCATION_ID AS 'WC:AllocationIdentifier',
	ALLOCATION_OWNER AS 'WC:AllocationOwnerName', 
	APPLICATION_DATE AS 'WC:ApplicationDate',
	PRIORITY_DATE AS 'WC:PriorityDate', 
	END_DATE AS 'WC:EndDate',
	C.VALUE AS 'WC:LegalStatusCode',
	(SELECT WADE_R.XML_D_ALLOCATION_LOCATION(@orgid,@reportid,@loctype, @loctxt,A.ALLOCATION_ID)), 
	(SELECT WADE_R.ALLOCATION_AMOUNT(@orgid, @reportid, A.ALLOCATION_ID)),
	(SELECT WADE_R.XML_DIVERSION_DETAIL(@orgid, @reportid, A.ALLOCATION_ID)),
	(SELECT WADE_R.XML_USE_DETAIL(@orgid, @reportid, A.ALLOCATION_ID)),
	(SELECT WADE_R.XML_RETURNFLOW_DETAIL(@orgid, @reportid, A.ALLOCATION_ID))
	
	FROM WADE.DETAIL_ALLOCATION A LEFT JOIN WADE.LU_LEGAL_STATUS C ON (A.LEGAL_STATUS=C.LU_SEQ_NO) WHERE EXISTS (SELECT B.ALLOCATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND A.REPORT_ID=B.REPORT_ID AND A.ALLOCATION_ID=B.ALLOCATION_ID 
	AND B.ORGANIZATION_ID=@orgid AND B.REPORT_ID=@reportid AND B.COUNTY_FIPS=@loctxt)
	
	FOR XML PATH ('WC:WaterAllocation'));
	
END 
--END COUNTY

IF @loctype='REPORTUNIT'

BEGIN
--START REPORT UNIT

WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT ALLOCATION_ID AS 'WC:AllocationIdentifier',
	ALLOCATION_OWNER AS 'WC:AllocationOwnerName', 
	APPLICATION_DATE AS 'WC:ApplicationDate',
	PRIORITY_DATE AS 'WC:PriorityDate', 
	END_DATE AS 'WC:EndDate',
	C.VALUE AS 'WC:LegalStatusCode', 
	(SELECT WADE_R.XML_D_ALLOCATION_LOCATION(@orgid,@reportid,@loctype, @loctxt,A.ALLOCATION_ID)),
	(SELECT WADE_R.ALLOCATION_AMOUNT(@orgid, @reportid, A.ALLOCATION_ID)),
	(SELECT WADE_R.XML_DIVERSION_DETAIL(@orgid, @reportid, A.ALLOCATION_ID)),
	(SELECT WADE_R.XML_USE_DETAIL(@orgid, @reportid, A.ALLOCATION_ID)),
	(SELECT WADE_R.XML_RETURNFLOW_DETAIL(@orgid, @reportid, A.ALLOCATION_ID))
	
	FROM WADE.DETAIL_ALLOCATION A LEFT JOIN WADE.LU_LEGAL_STATUS C ON (A.LEGAL_STATUS=C.LU_SEQ_NO) WHERE EXISTS (SELECT B.ALLOCATION_ID FROM WADE_R.DETAIL_LOCATION B WHERE
	A.ORGANIZATION_ID=B.ORGANIZATION_ID AND A.REPORT_ID=B.REPORT_ID AND A.ALLOCATION_ID=B.ALLOCATION_ID 
	AND B.ORGANIZATION_ID=@orgid AND B.REPORT_ID=@reportid AND B.REPORTING_UNIT_ID=@loctxt)
	
	FOR XML PATH ('WC:WaterAllocation'));
	
END
--END REPORT UNIT

END
--END ALL PARAMETER

BEGIN
--ADD TAG
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT @tmp FOR XML PATH('WC:ReportDetails'));

END
--END TAG

RETURN(@tmp) 

END
--END FUNCTION
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_ALLOCATION_SUMMARY]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[XML_ALLOCATION_SUMMARY](@orgid varchar(10), @reportid varchar(35), @reportunitid varchar(35))
  RETURNS xml 

BEGIN

DECLARE @tmp XML='';

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp = (SELECT WFS_FEATURE_REF AS 'WC:WFSReference/WC:WFSFeatureIdentifier',
		B.CONTEXT AS 'WC:AllocationUseContext', 
		B.VALUE as 'WC:AllocationUseTypeName', 
		(SELECT AMOUNT AS 'WC:AmountNumber', 
		C.VALUE AS 'WC:FreshSalineIndicator', 
		D.VALUE AS 'WC:SourceTypeName', 
		POWER_GENERATED AS 'WC:PowerGeneratedNumber', 
		POPULATION_SERVED AS 'WC:PopulationServedNumber',
		(SELECT WADE_R.XML_S_ALLOCATION_IRRIGATION(@orgid, @reportid, @reportunitid, SUMMARY_SEQ)) FOR XML PATH ('WC:AllocationAmountSummary'), type)
	
	FROM  
	
	WADE.SUMMARY_ALLOCATION A LEFT OUTER JOIN WADE.LU_BENEFICIAL_USE B ON (A.BENEFICIAL_USE_ID=B.LU_SEQ_NO) LEFT JOIN WADE.LU_FRESH_SALINE_INDICATOR C ON (A.FRESH_SALINE_IND=C.LU_SEQ_NO)
	LEFT JOIN WADE.LU_SOURCE_TYPE D ON (A.SOURCE_TYPE=D.LU_SEQ_NO)

	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND REPORT_UNIT_ID=@reportunitid 
	
	FOR XML PATH('WC:AllocationUse'));
		
IF (@tmp is not null)

BEGIN

WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp =(SELECT @tmp FOR XML PATH('WC:AllocationSummary'));

END

RETURN(@tmp)

END




GO
/****** Object:  UserDefinedFunction [wade_r].[XML_AVAILABILITY_SUMMARY]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[XML_AVAILABILITY_SUMMARY](@orgid varchar(10), @reportid varchar(35), @reportunitid varchar(35)) 
RETURNS xml

BEGIN

DECLARE @tmp XML='';

;WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT WFS_FEATURE_REF AS 'WC:WFSReference/WC:WFSFeatureIdentifier',
			AVAILABILITY_TYPE AS 'WC:AvailabilityTypeName',
			B.VALUE AS 'WC:FreshSalineIndicator', 
			C.VALUE AS 'WC:SourceTypeName',
			(SELECT (SELECT WADE_R.XML_S_AVAILABILITY_AMOUNT(@orgid, @reportid, @reportunitid, SUMMARY_SEQ)),
			(SELECT WADE_R.XML_S_AVAILABILITY_METRIC(@orgid, @reportid, @reportunitid, SUMMARY_SEQ)) FOR XML PATH('WC:AvailabilityEstimate'), type)
	   
	   FROM
	   
	   WADE.SUMMARY_AVAILABILITY A LEFT JOIN WADE.LU_FRESH_SALINE_INDICATOR B ON (A.FRESH_SALINE_IND=B.LU_SEQ_NO) LEFT JOIN WADE.LU_SOURCE_TYPE C ON (A.SOURCE_TYPE=C.LU_SEQ_NO)
	   
	   WHERE
	   
	   ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND REPORT_UNIT_ID=@reportunitid FOR XML PATH ('WC:AvailabilitySummary'));

RETURN (@tmp)
END	   

GO
/****** Object:  UserDefinedFunction [wade_r].[XML_D_ALLOCATION_ACTUAL]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[XML_D_ALLOCATION_ACTUAL](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60), @seqno numeric(18,0)) 
RETURNS XML

BEGIN
DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT AMOUNT_VOLUME AS 'WC:ActualVolume/WC:ActualAmountNumber',
	D.VALUE AS 'WC:ActualVolume/WC:ActualAmountUnitsCode',
	F.DESCRIPTION AS 'WC:ActualVolume/WC:ValueTypeCode',
	B.METHOD_CONTEXT AS 'WC:ActualVolume/WC:Method/WC:MethodContext',
	B.METHOD_NAME AS 'WC:ActualVolume/WC:Method/WC:MethodName',
	AMOUNT_RATE AS 'WC:ActualRate/WC:ActualAmountNumber',
	E.VALUE AS 'WC:ActualRate/WC:ActualAmountUnitsCode',
	G.DESCRIPTION AS 'WC:ActualRate/WC:ValueTypeCode',
	C.METHOD_CONTEXT AS 'WC:ActualRate/WC:Method/WC:MethodContext',
	C.METHOD_NAME AS 'WC:ActualRate/WC:Method/WC:MethodName',
	START_DATE AS 'WC:TimeFrame/WC:TimeFrameStartName',
	END_DATE AS 'WC:TimeFrame/WC:TimeFrameEndName'
	
	FROM  
	
	WADE.D_ALLOCATION_ACTUAL A LEFT JOIN WADE.METHODS B ON (A.METHOD_ID_VOLUME=B.METHOD_ID) LEFT JOIN WADE.METHODS C ON (A.METHOD_ID_RATE=C.METHOD_ID)
	LEFT JOIN WADE.LU_UNITS D ON (A.UNIT_VOLUME=D.LU_SEQ_NO) LEFT JOIN WADE.LU_UNITS E ON (A.UNIT_RATE=E.LU_SEQ_NO)
	LEFT JOIN WADE.LU_VALUE_TYPE F ON (A.VALUE_TYPE_VOLUME=F.LU_SEQ_NO) LEFT JOIN WADE.LU_VALUE_TYPE G ON (A.VALUE_TYPE_RATE=G.LU_SEQ_NO)
	
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid AND DETAIL_SEQ_NO=@seqno
	
	FOR XML PATH('WC:ActualFlow'));
	
RETURN (@tmp)
 
END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_D_ALLOCATION_LOCATION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[XML_D_ALLOCATION_LOCATION](@orgid varchar(10), @reportid varchar(35), @loctype varchar(max), @loctxt varchar(max),@allocationid varchar(60)) 
RETURNS XML

BEGIN
DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT @loctype AS 'WC:PrimaryLocationType',
	@loctxt AS 'WC:PrimaryLocationText',
	B.VALUE AS 'WC:StateCode',
	REPORTING_UNIT_ID AS 'WC:ReportingUnitIdentifier',
	COUNTY_FIPS AS 'WC:CountyFipsCode',
	HUC AS 'WC:HydrologicUnitCode',
	WFS_FEATURE_REF AS 'WC:WFSReference/WC:WFSFeatureIdentifier'
	
	FROM  
	
	WADE.D_ALLOCATION_LOCATION A LEFT JOIN WADE.LU_STATE B ON (A.STATE=B.LU_SEQ_NO)
	
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid
	
	FOR XML PATH('WC:DetailLocation'));
	
RETURN (@tmp)
 
END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_D_ALLOCATION_USE]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[XML_D_ALLOCATION_USE](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60), @seqno numeric (18,0)) 
RETURNS XML

BEGIN
DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT B.CONTEXT AS 'WC:BeneficialUseContext',
	B.DESCRIPTION AS 'WC:BeneficialUseTypeName'
	
	FROM  
	
	WADE.D_ALLOCATION_USE A LEFT OUTER JOIN WADE.LU_BENEFICIAL_USE B ON (A.BENEFICIAL_USE_ID=B.LU_SEQ_NO) 
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid AND DETAIL_SEQ_NO=@seqno
	
	FOR XML PATH('WC:BeneficialUse'));

RETURN (@tmp)
 
END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_D_COMMUNITY_WATER_SUPPLY]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[XML_D_COMMUNITY_WATER_SUPPLY](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60), @wateruserid varchar(50), @useid numeric(18,0))
RETURNS XML

BEGIN
DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT POPULATION_SERVED AS 'WC:TotalPopulationServedNumber',
	WATER_SUPPLY_NAME AS 'WC:CommunityWaterSupplyName' 
 
	FROM
	
	WADE.D_COMMUNITY_WATER_SUPPLY WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid 
	AND WATER_USER_ID=@wateruserid AND BENEFICIAL_USE_ID=@useid 
	
	FOR XML PATH('WC:CommunityWaterSupply'));

RETURN (@tmp)
END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_D_CONSUMPTIVE_USE]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[XML_D_CONSUMPTIVE_USE](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60), @wateruserid varchar(50))
  RETURNS XML

BEGIN

DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT 
	B.CONTEXT AS 'WC:BeneficialUseContext',
	B.VALUE as 'WC:BeneficialUseTypeName',
	
	(SELECT WADE_R.USE_AMOUNT (@orgid, @reportid, @allocationid, @wateruserid))
	
	FROM  
	WADE.D_CONSUMPTIVE_USE A LEFT OUTER JOIN WADE.LU_BENEFICIAL_USE B ON (A.BENEFICIAL_USE_ID=B.LU_SEQ_NO) 
	
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid AND WATER_USER_ID=@wateruserid 
	
	FOR XML PATH('WC:UseEstimate'));

RETURN(@tmp)
		
END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_D_DIVERSION_ACTUAL]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[XML_D_DIVERSION_ACTUAL](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60), @diversionid varchar(35), @seqno numeric(18,0)) 
RETURNS XML

BEGIN
DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT AMOUNT_VOLUME AS 'WC:ActualVolume/WC:ActualAmountNumber',
	D.VALUE AS 'WC:ActualVolume/WC:ActualAmountUnitsCode',
	F.DESCRIPTION AS 'WC:ActualVolume/WC:ValueTypeCode',
	B.METHOD_CONTEXT AS 'WC:ActualVolume/WC:Method/WC:MethodContext',
	B.METHOD_NAME AS 'WC:ActualVolume/WC:Method/WC:MethodName',
	AMOUNT_RATE AS 'WC:ActualRate/WC:ActualAmountNumber',
	E.VALUE AS 'WC:ActualRate/WC:ActualAmountUnitsCode',
	G.DESCRIPTION AS 'WC:ActualRate/WC:ValueTypeCode',
	C.METHOD_CONTEXT AS 'WC:ActualRate/WC:Method/WC:MethodContext',
	C.METHOD_NAME AS 'WC:ActualRate/WC:Method/WC:MethodName',
	START_DATE AS 'WC:TimeFrame/WC:TimeFrameStartName',
	END_DATE AS 'WC:TimeFrame/WC:TimeFrameEndName'
		
	FROM  
		WADE.D_DIVERSION_ACTUAL A LEFT JOIN WADE.METHODS B ON (A.METHOD_ID_VOLUME=B.METHOD_ID) LEFT JOIN WADE.METHODS C ON (A.METHOD_ID_RATE=C.METHOD_ID)	LEFT JOIN WADE.LU_UNITS D ON (A.UNIT_VOLUME=D.LU_SEQ_NO) LEFT JOIN WADE.LU_UNITS E ON (A.UNIT_RATE=E.LU_SEQ_NO)	LEFT JOIN WADE.LU_VALUE_TYPE F ON (A.VALUE_TYPE_VOLUME=F.LU_SEQ_NO) LEFT JOIN WADE.LU_VALUE_TYPE G ON (A.VALUE_TYPE_RATE=G.LU_SEQ_NO)			WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid AND DIVERSION_ID=@diversionid AND DETAIL_SEQ_NO=@seqno	
	FOR XML PATH('WC:ActualFlow'));
	
RETURN (@tmp)
 
END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_D_DIVERSION_USE]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [wade_r].[XML_D_DIVERSION_USE](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60), @diversionid varchar(35), @seqno numeric (18,0)) 
RETURNS XML

BEGIN

DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT B.CONTEXT AS 'WC:BeneficialUseContext', 
	B.DESCRIPTION AS 'WC:BeneficialUseTypeName'
	
	FROM  
	
	WADE.D_DIVERSION_USE A LEFT OUTER JOIN WADE.LU_BENEFICIAL_USE B ON (A.BENEFICIAL_USE_ID=B.LU_SEQ_NO) 
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid AND DIVERSION_ID=@diversionid AND DETAIL_SEQ_NO=@seqno
	FOR XML PATH('WC:BeneficialUse'));

RETURN (@tmp)
 
END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_D_IRRIGATION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[XML_D_IRRIGATION](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60), @wateruserid varchar(50), @useid numeric(18,0)) 
RETURNS XML

BEGIN
DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT C.VALUE AS 'WC:IrrigationMethodName',
	ACRES_IRRIGATED AS 'WC:AcresIrrigatedNumber', 
	B.VALUE AS 'WC:CropTypeName'
	
	FROM    
	
	WADE.D_IRRIGATION A LEFT JOIN WADE.LU_CROP_TYPE B ON (A.CROP_TYPE=B.LU_SEQ_NO) LEFT JOIN WADE.LU_IRRIGATION_METHOD C ON (A.IRRIGATION_METHOD=C.LU_SEQ_NO)
	
	WHERE
	
	ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid AND WATER_USER_ID=@wateruserid AND BENEFICIAL_USE_ID=@useid 
	
	FOR XML PATH('WC:IrrigationWaterSupply'));
	
RETURN(@tmp)
 
END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_D_RETURN_FLOW_ACTUAL]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[XML_D_RETURN_FLOW_ACTUAL](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60), @returnflowid varchar(60))
  RETURNS XML


BEGIN

DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT AMOUNT_VOLUME AS 'WC:ReturnVolume/WC:AmountNumber', 
	D.VALUE AS 'WC:ReturnVolume/WC:AmountUnitsCode',
	F.DESCRIPTION AS 'WC:ReturnVolume/WC:ValueTypeCode',
	B.METHOD_CONTEXT AS 'WC:ReturnVolume/WC:Method/WC:MethodContext',
	B.METHOD_NAME As 'WC:ReturnVolume/WC:Method/WC:MethodName',
	AMOUNT_RATE AS 'WC:ReturnRate/WC:AmountNumber',
	E.VALUE AS 'WC:ReturnRate/WC:AmountUnitsCode', 
	G.DESCRIPTION AS 'WC:ReturnRate/WC:ValueTypeCode',
	C.METHOD_CONTEXT AS 'WC:ReturnRate/WC:Method/WC:MethodContext',
	C.METHOD_NAME AS 'WC:ReturnRate/WC:Method/WC:MethodName',
	START_DATE AS 'WC:ReturnRate/WC:TimeFrame/WC:TimeFrameStartName',
	END_DATE AS 'WC:ReturnRate/WC:TimeFrame/WC:TimeFrameEndName'

	FROM 
	
	WADE.D_RETURN_FLOW_ACTUAL A LEFT JOIN WADE.METHODS B ON (A.METHOD_ID_VOLUME=B.METHOD_ID)
	LEFT JOIN WADE.METHODS C ON (A.METHOD_ID_RATE=C.METHOD_ID)
	LEFT JOIN WADE.LU_UNITS D ON (A.UNIT_VOLUME=D.LU_SEQ_NO)
	LEFT JOIN WADE.LU_UNITS E ON (A.UNIT_RATE=E.LU_SEQ_NO)
	LEFT JOIN WADE.LU_VALUE_TYPE F ON (A.VALUE_TYPE_VOLUME=F.LU_SEQ_NO)
	LEFT JOIN WADE.LU_VALUE_TYPE G ON (A.VALUE_TYPE_RATE=G.LU_SEQ_NO)
	
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid AND RETURN_FLOW_ID=@returnflowid 
	
	FOR XML PATH('WC:ReturnFlowAmount'));
	
RETURN (@tmp)

END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_D_THERMOELECTRIC]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[XML_D_THERMOELECTRIC](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60), @wateruserid varchar(50), @useid numeric(18,0)) 
RETURNS XML

BEGIN
DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT VALUE AS 'WC:GeneratorTypeName',
	POWER_CAPACITY AS 'WC:PowerCapacityNumber'
	
	FROM     
	
	WADE.D_THERMOELECTRIC A LEFT JOIN WADE.LU_GENERATOR_TYPE B ON (A.GENERATOR_TYPE=B.LU_SEQ_NO)
	
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid AND WATER_USER_ID=@wateruserid AND BENEFICIAL_USE_ID=@useid 
	
	FOR XML PATH('WC:ThermoElectricWaterSupply'));
	
RETURN(@tmp)
 
END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_D_USE_AMOUNT]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[XML_D_USE_AMOUNT](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60), @wateruserid varchar(60), @useid numeric(18,0))

RETURNS xml 

BEGIN

DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT AMOUNT_VOLUME AS 'WC:AmountNumber',
	C.VALUE AS 'WC:AmountUnitsCode',
	D.DESCRIPTION AS 'WC:ValueTypeCode',
	METHOD_CONTEXT AS 'WC:Method/WC:MethodContext',
	METHOD_NAME AS 'WC:Method/WC:MethodName',
	START_DATE AS 'WC:TimeFrame/WC:TimeFrameStartName',
	END_DATE AS 'WC:TimeFrame/WC:TimeFrameEndName'
 
	FROM 
	
	WADE.D_USE_AMOUNT A LEFT JOIN WADE.METHODS B ON (A.METHOD_ID_VOLUME=B.METHOD_ID)
	LEFT JOIN WADE.LU_UNITS C ON (A.UNIT_VOLUME=C.LU_SEQ_NO) LEFT JOIN WADE.LU_VALUE_TYPE D ON (A.VALUE_TYPE_VOLUME=D.LU_SEQ_NO)
	
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid AND WATER_USER_ID=@wateruserid AND BENEFICIAL_USE_ID=@useid 
	
	FOR XML PATH ('WC:UseVolume'));
	
RETURN(@tmp)	

END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_D_USE_LOCATION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[XML_D_USE_LOCATION](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60), @wateruserid varchar(60))
  RETURNS xml 

BEGIN
DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT B.VALUE AS 'WC:StateCode', 
	REPORTING_UNIT_ID AS 'WC:ReportingUnitIdentifier', 
	COUNTY_FIPS AS 'WC:CountyFipsCode', 
	HUC AS 'WC:HydrologicUnitCode',
	WFS_FEATURE_REF AS 'WC:WFSReference/WC:WFSFeatureIdentifier'
	
	FROM 
	
	WADE.D_USE_LOCATION A LEFT JOIN WADE.LU_STATE B ON (A.STATE=B.LU_SEQ_NO) 
	
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid AND WATER_USER_ID=@wateruserid
	
	FOR XML PATH ('WC:DetailLocation'));
	
RETURN (@tmp)	

END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_DIVERSION_DETAIL]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[XML_DIVERSION_DETAIL](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60)) 
RETURNS XML

BEGIN

DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT DIVERSION_ID AS 'WC:DiversionIdentifier',
	DIVERSION_NAME AS 'WC:DiversionName',
	F.VALUE AS 'WC:DetailLocation/WC:StateCode', 
	REPORTING_UNIT_ID AS 'WC:DetailLocation/WC:ReportingUnitIdentifier', 
	COUNTY_FIPS AS 'WC:DetailLocation/WC:CountyFipsCode',
	HUC AS 'WC:DetailLocation/WC:HydrologicUnitCode',
	WFS_FEATURE_REF AS 'WC:DetailLocation/WC:WFSReference/WC:WFSFeatureIdentifier',
	
	(SELECT WADE_R.DIVERSION_AMOUNT(@orgid, @reportid, @allocationid, DIVERSION_ID))

	FROM  
	
	WADE.DETAIL_DIVERSION A LEFT JOIN WADE.LU_STATE F ON (A.STATE=F.LU_SEQ_NO) 
		
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid 
	
	FOR XML PATH('WC:Diversion'));
	
RETURN (@tmp)
 
END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_REGULATORY_SUMMARY]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[XML_REGULATORY_SUMMARY](@orgid varchar(10), @reportid varchar(35), @reportunitid varchar(35))

RETURNS xml 

BEGIN

DECLARE @tmp XML='';

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp = (SELECT WFS_FEATURE_REF AS 'WC:WFSReference/WC:WFSFeatureIdentifier',
	REGULATORY_TYPE AS 'WC:RegulatoryTypeName', 
	B.VALUE as 'WC:RegulatoryStatusText', 
	OVERSIGHT_AGENCY AS 'WC:OversightAgencyName', 
	REGULATORY_DESCRIPTION AS 'WC:RegulatoryDescriptionText'
	
	FROM  
	
	WADE.SUMMARY_REGULATORY A LEFT JOIN WADE.LU_REGULATORY_STATUS B ON (A.REGULATORY_STATUS=B.LU_SEQ_NO)
	
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND REPORT_UNIT_ID=@reportunitid 
	
	FOR XML PATH('WC:RegulatoryType'));

IF (@tmp IS NOT NULL)

BEGIN
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp = (SELECT @tmp FOR XML PATH('WC:RegulatorySummary'));

END

RETURN(@tmp)
		
END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_RETURNFLOW_DETAIL]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[XML_RETURNFLOW_DETAIL](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60))
  RETURNS XML

BEGIN
DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp= (SELECT RETURN_FLOW_ID AS 'WC:ReturnFlowIdentifier',
	RETURN_FLOW_NAME AS 'WC:ReturnFlowName',
	B.VALUE AS 'WC:DetailLocation/WC:StateCode', 
	REPORTING_UNIT_ID AS 'WC:DetailLocation/WC:ReportingUnitIdentifier', 
	COUNTY_FIPS AS 'WC:DetailLocation/WC:CountyFipsCode', 
	HUC AS 'WC:DetailLocation/WC:HydrologicUnitCode',
	WFS_FEATURE_REF AS 'WC:DetailLocation/WC:WFSReference/WC:WFSFeatureIdentifier',
	(SELECT WADE_R.XML_D_RETURN_FLOW_ACTUAL(@orgid, @reportid, @allocationid, RETURN_FLOW_ID))

	FROM 

	WADE.DETAIL_RETURN_FLOW A LEFT JOIN WADE.LU_STATE B ON (A.STATE=B.LU_SEQ_NO)

	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid 
	
	FOR XML PATH('WC:ReturnFlow'));
	
RETURN (@tmp)

END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_S_ALLOCATION_IRRIGATION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[XML_S_ALLOCATION_IRRIGATION](@orgid varchar(10), @reportid varchar(35), @reportunitid varchar(35), @seqno numeric(18,0))
  RETURNS xml 
  
BEGIN


DECLARE @tmp XML='';

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT C.VALUE AS 'WC:IrrigationMethodName', 
	ACRES_IRRIGATED as 'WC:AcresIrrigatedNumber',
	B.VALUE AS 'WC:CropTypeName'

	FROM  

	WADE.S_ALLOCATION_IRRIGATION A LEFT JOIN WADE.LU_CROP_TYPE B ON (A.CROP_TYPE=B.LU_SEQ_NO) LEFT JOIN WADE.LU_IRRIGATION_METHOD C ON (A.IRRIGATION_METHOD=C.LU_SEQ_NO)
	
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND REPORT_UNIT_ID=@reportunitid AND SUMMARY_SEQ=@seqno 
	
	FOR XML PATH('WC:IrrigationWaterSupply'));
	
RETURN(@tmp)	
END


GO
/****** Object:  UserDefinedFunction [wade_r].[XML_S_AVAILABILITY_AMOUNT]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[XML_S_AVAILABILITY_AMOUNT](@orgid varchar(10), @reportid varchar(35), @reportunitid varchar(35), @seqno numeric(18,0))

RETURNS xml

BEGIN
DECLARE @tmp XML='';

;WITH XMLNAMESPACES('ReplaceMe' AS WC)
SELECT @tmp=(SELECT AMOUNT as 'WC:AmountNumber',
	METHOD_CONTEXT AS 'WC:Method/WC:MethodContext',
	METHOD_NAME AS 'WC:Method/WC:MethodName',
	START_DATE AS 'WC:TimeFrame/WC:TimeFrameStartName',
	END_DATE AS 'WC:TimeFrame/WC:TimeFrameEndName'
	
	FROM
	
	WADE.S_AVAILABILITY_AMOUNT A LEFT JOIN WADE.METHODS B ON (A.METHOD_ID=B.METHOD_ID)

	WHERE
	
	ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND REPORT_UNIT_ID=@reportunitid AND SUMMARY_SEQ=@seqno
	
	FOR XML PATH ('WC:AvailabilityAmount'));

RETURN(@tmp)

END


GO
/****** Object:  UserDefinedFunction [wade_r].[XML_S_AVAILABILITY_METRIC]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[XML_S_AVAILABILITY_METRIC](@orgid varchar(10), @reportid varchar(35), @reportunitid varchar(35), @seqno numeric(18,0))

RETURNS xml

BEGIN

DECLARE @tmp XML='';

;WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT D.VALUE AS 'WC:MetricName',
	       METRIC_VALUE AS 'WC:MetricValue',
	       METRIC_SCALE AS 'WC:MetricScaleNumber',
	       REVERSE_SCALE_IND AS 'WC:ReverseScaleIndicator',
	       C.METHOD_CONTEXT AS 'WC:Method/WC:MethodContext',
	       C.METHOD_NAME AS 'WC:Method/WC:MethodName',
	       START_DATE AS 'WC:TimeFrame/WC:TimeFrameStartName',
	       END_DATE AS 'WC:TimeFrame/WC:TimeFrameEndName'
	
	FROM
	
	WADE.S_AVAILABILITY_METRIC A LEFT JOIN WADE.METHODS C ON (A.METHOD_ID=C.METHOD_ID) 
	LEFT JOIN WADE.METRICS D ON (A.METRIC_ID=D.METRIC_ID)

	WHERE
	
	ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND REPORT_UNIT_ID=@reportunitid AND SUMMARY_SEQ=@seqno
	
	FOR XML PATH ('WC:AvailabilityMetric'));

RETURN(@tmp)
	
END


GO
/****** Object:  UserDefinedFunction [wade_r].[XML_S_USE_AMOUNT]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[XML_S_USE_AMOUNT](@orgid varchar(10), @reportid varchar(35), @reportunitid varchar(35), @seqno numeric(18,0), @useid numeric(18,0))
RETURNS xml

BEGIN

DECLARE @tmp XML='';

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT AMOUNT AS 'WC:AmountNumber',
		CONSUMPTIVE_INDICATOR AS 'WC:ConsumptiveIndicator',
		METHOD_CONTEXT AS 'WC:Method/WC:MethodContext',
		METHOD_NAME AS 'WC:Method/WC:MethodName',
		START_DATE AS 'WC:TimeFrame/WC:TimeFrameStartName',
		END_DATE AS 'WC:TimeFrame/WC:TimeFrameEndName'
		
		FROM
		
		WADE.S_USE_AMOUNT A LEFT JOIN WADE.METHODS b ON (A.METHOD_ID=B.METHOD_ID)
		
		WHERE
		
		ORGANIZATION_ID = @orgid AND REPORT_ID=@reportid AND
		REPORT_UNIT_ID=@reportunitid AND SUMMARY_SEQ=@seqno
		
		FOR XML PATH ('WC:WaterUseAmount'));
		
RETURN(@tmp)
		
END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_S_USE_IRRIGATION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[XML_S_USE_IRRIGATION](@orgid varchar(10), @reportid varchar(35), @reportunitid varchar(35), @seqno numeric(18,0), @useid numeric(18,0))
RETURNS xml

BEGIN

DECLARE @tmp XML='';

WITH XMLNAMESPACES('ReplaceMe' AS WC)

SELECT @tmp=(SELECT C.VALUE AS 'WC:IrrigationMethodName',
		ACRES_IRRIGATED AS 'WC:AcresIrrigatedNumber',
		B.VALUE AS 'WC:CropTypeName'
		
		FROM
		
		WADE.S_USE_IRRIGATION A LEFT JOIN WADE.LU_CROP_TYPE B ON (A.CROP_TYPE=B.LU_SEQ_NO) LEFT JOIN WADE.LU_IRRIGATION_METHOD C ON (A.IRRIGATION_METHOD=C.LU_SEQ_NO)
		
		WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND REPORT_UNIT_ID=@reportunitid AND SUMMARY_SEQ=@seqno AND BENEFICIAL_USE_ID=@useid 
		
		FOR XML PATH ('WC:IrrigationWaterSupply'));
		
RETURN(@tmp)
		
END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_S_WATER_SUPPLY_AMOUNT]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[XML_S_WATER_SUPPLY_AMOUNT](@orgid varchar(10), 
		@reportid varchar(35), @reportunitid varchar(35), @seqno numeric(18,0))

RETURNS xml

BEGIN

DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT AMOUNT AS 'WC:AmountNumber',
		METHOD_CONTEXT AS 'WC:Method/WC:MethodContext',
		METHOD_NAME AS 'WC:Method/WC:MethodName',
		START_DATE AS 'WC:TimeFrame/WC:TimeFrameStartName',
		END_DATE AS 'WC:TimeFrame/WC:TimeFrameEndName'
	
		FROM
		
		WADE.S_WATER_SUPPLY_AMOUNT A LEFT OUTER JOIN WADE.METHODS B ON (A.METHOD_ID=B.METHOD_ID) WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid
		AND REPORT_UNIT_ID=@reportunitid AND SUMMARY_SEQ=@seqno 
		
		FOR XML PATH ('WC:SupplyAmountSummary'));
		
RETURN (@tmp)
END

GO
/****** Object:  UserDefinedFunction [wade_r].[XML_SUPPLY_SUMMARY]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [wade_r].[XML_SUPPLY_SUMMARY](@orgid varchar(10), 
		@reportid varchar(35), @reportunitid varchar(35))

RETURNS xml

BEGIN

DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT WFS_FEATURE_REF AS 'WC:WFSReference/WC:WFSFeatureIdentifier',
		B.VALUE AS 'WC:WaterSupplyTypeName',
		(SELECT WADE_R.XML_S_WATER_SUPPLY_AMOUNT(@orgid, @reportid, @reportunitid, SUMMARY_SEQ))
	
	FROM
		
	WADE.SUMMARY_WATER_SUPPLY A LEFT JOIN WADE.LU_WATER_SUPPLY_TYPE B ON (A.WATER_SUPPLY_TYPE=B.LU_SEQ_NO)
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid
		AND REPORT_UNIT_ID=@reportunitid 
		
		FOR XML PATH ('WC:DerivedWaterSupplyType'));
		
IF (@tmp IS NOT NULL)
BEGIN

WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp = (SELECT @tmp FOR XML PATH('WC:DerivedWaterSupplySummary'));
	
END
RETURN (@tmp)
END

GO
/****** Object:  UserDefinedFunction [wade_r].[XML_USE_DETAIL]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[XML_USE_DETAIL](@orgid varchar(10), @reportid varchar(35), @allocationid varchar(60))
  RETURNS xml 

BEGIN

DECLARE @tmp XML='';

WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT WATER_USER_ID AS 'WC:UserIdentifier',
	WATER_USER_NAME AS 'WC:UserName', 
	(SELECT WADE_R.XML_D_USE_LOCATION(@orgid, @reportid, @allocationid, WATER_USER_ID)),
	(SELECT WADE_R.XML_D_CONSUMPTIVE_USE(@orgid, @reportid, @allocationid, WATER_USER_ID))
	
	FROM 
	
	WADE.DETAIL_USE WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND ALLOCATION_ID=@allocationid 
	
	FOR XML PATH('WC:ConsumptiveUse'));

RETURN (@tmp)

END
GO
/****** Object:  UserDefinedFunction [wade_r].[XML_USE_SUMMARY]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [wade_r].[XML_USE_SUMMARY](@orgid varchar(10), @reportid varchar(35), @reportunitid varchar(35))
  RETURNS xml 

BEGIN

DECLARE @tmp XML='';
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT WFS_FEATURE_REF AS 'WC:WFSReference/WC:WFSFeatureIdentifier',
		B.CONTEXT AS 'WC:WaterUseContext',
		B.VALUE as 'WC:WaterUseTypeName', 
		(SELECT C.VALUE AS 'WC:FreshSalineIndicator',
		D.VALUE AS 'WC:SourceTypeName', 
		POWER_GENERATED AS 'WC:PowerGeneratedNumber', 
		POPULATION_SERVED AS 'WC:PopulationServedNumber',
			(SELECT WADE_R.XML_S_USE_IRRIGATION (@orgid, @reportid, @reportunitid, SUMMARY_SEQ, BENEFICIAL_USE_ID)),
			(SELECT WADE_R.XML_S_USE_AMOUNT (@orgid, @reportid, @reportunitid, SUMMARY_SEQ, BENEFICIAL_USE_ID)) FOR XML PATH ('WC:WaterUseAmountSummary'), type)
			
	FROM  
	
	WADE.SUMMARY_USE A LEFT OUTER JOIN WADE.LU_BENEFICIAL_USE B ON (A.BENEFICIAL_USE_ID=B.LU_SEQ_NO) LEFT JOIN WADE.LU_FRESH_SALINE_INDICATOR C ON (A.FRESH_SALINE_IND=C.LU_SEQ_NO)
	LEFT JOIN WADE.LU_SOURCE_TYPE D ON (A.SOURCE_TYPE=D.LU_SEQ_NO)
		
	WHERE ORGANIZATION_ID=@orgid AND REPORT_ID=@reportid AND REPORT_UNIT_ID=@reportunitid 
	
	FOR XML PATH('WC:WaterUse'));
	
If (@tmp IS NOT NULL)
BEGIN
WITH XMLNAMESPACES ('ReplaceMe' AS WC)

SELECT @tmp=(SELECT @tmp FOR XML PATH('WC:WaterUseSummary'));

END

RETURN(@tmp)
		
END
GO
/****** Object:  Table [dbo].[dtproperties]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[dtproperties](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[objectid] [int] NULL,
	[property] [varchar](64) NOT NULL,
	[value] [varchar](255) NULL,
	[uvalue] [nvarchar](255) NULL,
	[lvalue] [image] NULL,
	[version] [int] NOT NULL,
 CONSTRAINT [pk_dtproperties] PRIMARY KEY CLUSTERED 
(
	[id] ASC,
	[property] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[D_ALLOCATION_ACTUAL]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[D_ALLOCATION_ACTUAL](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[DETAIL_SEQ_NO] [numeric](18, 0) NOT NULL,
	[ACTUAL_SEQ_NO] [numeric](18, 0) NOT NULL,
	[AMOUNT_VOLUME] [numeric](18, 3) NULL,
	[UNIT_VOLUME] [numeric](18, 0) NULL,
	[VALUE_TYPE_VOLUME] [numeric](18, 0) NULL,
	[METHOD_ID_VOLUME] [numeric](18, 0) NULL,
	[AMOUNT_RATE] [numeric](18, 3) NULL,
	[UNIT_RATE] [numeric](18, 0) NULL,
	[VALUE_TYPE_RATE] [numeric](18, 0) NULL,
	[METHOD_ID_RATE] [numeric](18, 0) NULL,
	[START_DATE] [varchar](5) NULL,
	[END_DATE] [varchar](5) NULL,
 CONSTRAINT [PK_D_ALLOCATION_ACTUAL] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[DETAIL_SEQ_NO] ASC,
	[ACTUAL_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[D_ALLOCATION_FLOW]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[D_ALLOCATION_FLOW](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[DETAIL_SEQ_NO] [numeric](18, 0) NOT NULL,
	[AMOUNT_VOLUME] [numeric](18, 3) NULL,
	[UNIT_VOLUME] [numeric](18, 0) NULL,
	[AMOUNT_RATE] [numeric](18, 3) NULL,
	[UNIT_RATE] [numeric](18, 0) NULL,
	[SOURCE_TYPE] [numeric](18, 0) NULL,
	[FRESH_SALINE_IND] [numeric](18, 0) NULL,
	[ALLOCATION_START] [varchar](5) NULL,
	[ALLOCATION_END] [varchar](5) NULL,
	[SOURCE_NAME] [varchar](60) NULL,
 CONSTRAINT [PK_D_ALLOCATION_FLOW] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[DETAIL_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[D_ALLOCATION_LOCATION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[D_ALLOCATION_LOCATION](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[LOCATION_SEQ] [numeric](18, 0) NOT NULL,
	[STATE] [numeric](18, 0) NOT NULL,
	[REPORTING_UNIT_ID] [varchar](35) NULL,
	[COUNTY_FIPS] [char](5) NULL,
	[HUC] [varchar](12) NULL,
	[WFS_FEATURE_REF] [varchar](35) NULL,
 CONSTRAINT [PK_D_ALLOCATION_LOCATION] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[LOCATION_SEQ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[D_ALLOCATION_USE]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[D_ALLOCATION_USE](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[DETAIL_SEQ_NO] [numeric](18, 0) NOT NULL,
	[BENEFICIAL_USE_ID] [numeric](18, 0) NOT NULL,
 CONSTRAINT [PK_D_ALLOCATION_USE] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[DETAIL_SEQ_NO] ASC,
	[BENEFICIAL_USE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[D_COMMUNITY_WATER_SUPPLY]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[D_COMMUNITY_WATER_SUPPLY](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[WATER_USER_ID] [varchar](50) NOT NULL,
	[BENEFICIAL_USE_ID] [numeric](18, 0) NOT NULL,
	[DETAIL_SEQ_NO] [numeric](18, 0) NOT NULL,
	[POPULATION_SERVED] [numeric](18, 0) NOT NULL,
	[WATER_SUPPLY_NAME] [varchar](60) NULL,
 CONSTRAINT [PK_D_COMMUNITY_WATER_SUPPLY] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[WATER_USER_ID] ASC,
	[BENEFICIAL_USE_ID] ASC,
	[DETAIL_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[D_CONSUMPTIVE_USE]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[D_CONSUMPTIVE_USE](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[WATER_USER_ID] [varchar](50) NOT NULL,
	[BENEFICIAL_USE_ID] [numeric](18, 0) NOT NULL,
	[SOURCE_TYPE] [numeric](18, 0) NULL,
	[FRESH_SALINE_IND] [numeric](18, 0) NULL,
	[SOURCE_NAME] [varchar](60) NULL,
 CONSTRAINT [PK_D_CONSUMPTIVE_USE] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[WATER_USER_ID] ASC,
	[BENEFICIAL_USE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[D_DIVERSION_ACTUAL]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[D_DIVERSION_ACTUAL](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[DIVERSION_ID] [varchar](35) NOT NULL,
	[DETAIL_SEQ_NO] [numeric](18, 0) NOT NULL,
	[ACTUAL_SEQ_NO] [numeric](18, 0) NOT NULL,
	[AMOUNT_VOLUME] [numeric](18, 3) NULL,
	[UNIT_VOLUME] [numeric](18, 0) NULL,
	[VALUE_TYPE_VOLUME] [numeric](18, 0) NULL,
	[METHOD_ID_VOLUME] [numeric](18, 0) NULL,
	[AMOUNT_RATE] [numeric](18, 3) NULL,
	[UNIT_RATE] [numeric](18, 0) NULL,
	[VALUE_TYPE_RATE] [numeric](18, 0) NULL,
	[METHOD_ID_RATE] [numeric](18, 0) NULL,
	[START_DATE] [varchar](5) NULL,
	[END_DATE] [varchar](5) NULL,
 CONSTRAINT [PK_D_DIVERSION_ACTUAL] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[DIVERSION_ID] ASC,
	[DETAIL_SEQ_NO] ASC,
	[ACTUAL_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[D_DIVERSION_FLOW]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[D_DIVERSION_FLOW](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[DIVERSION_ID] [varchar](35) NOT NULL,
	[DETAIL_SEQ_NO] [numeric](18, 0) NOT NULL,
	[AMOUNT_VOLUME] [numeric](18, 3) NULL,
	[UNIT_VOLUME] [numeric](18, 0) NULL,
	[AMOUNT_RATE] [numeric](18, 3) NULL,
	[UNIT_RATE] [numeric](18, 0) NULL,
	[SOURCE_TYPE] [numeric](18, 0) NULL,
	[FRESH_SALINE_IND] [numeric](18, 0) NULL,
	[DIVERSION_START] [char](5) NULL,
	[DIVERSION_END] [varchar](5) NULL,
	[SOURCE_NAME] [varchar](60) NULL,
 CONSTRAINT [PK_D_DIVERSION_FLOW] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[DIVERSION_ID] ASC,
	[DETAIL_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[D_DIVERSION_USE]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[D_DIVERSION_USE](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[DIVERSION_ID] [varchar](35) NOT NULL,
	[DETAIL_SEQ_NO] [numeric](18, 0) NOT NULL,
	[BENEFICIAL_USE_ID] [numeric](18, 0) NOT NULL,
 CONSTRAINT [PK_D_DIVERSION_USE] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[DETAIL_SEQ_NO] ASC,
	[DIVERSION_ID] ASC,
	[BENEFICIAL_USE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[D_IRRIGATION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[D_IRRIGATION](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[WATER_USER_ID] [varchar](50) NOT NULL,
	[BENEFICIAL_USE_ID] [numeric](18, 0) NOT NULL,
	[DETAIL_SEQ_NO] [numeric](18, 0) NOT NULL,
	[IRRIGATION_METHOD] [numeric](18, 0) NULL,
	[ACRES_IRRIGATED] [numeric](18, 3) NOT NULL,
	[CROP_TYPE] [numeric](18, 0) NULL,
 CONSTRAINT [PK_D_IRRIGATION] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[WATER_USER_ID] ASC,
	[BENEFICIAL_USE_ID] ASC,
	[DETAIL_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[D_RETURN_FLOW_ACTUAL]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[D_RETURN_FLOW_ACTUAL](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[RETURN_FLOW_ID] [varchar](35) NOT NULL,
	[ACTUAL_SEQ_NO] [numeric](18, 0) NOT NULL,
	[AMOUNT_VOLUME] [numeric](18, 3) NULL,
	[UNIT_VOLUME] [numeric](18, 0) NULL,
	[VALUE_TYPE_VOLUME] [numeric](18, 0) NULL,
	[METHOD_ID_VOLUME] [numeric](18, 0) NULL,
	[AMOUNT_RATE] [numeric](18, 3) NULL,
	[UNIT_RATE] [numeric](18, 0) NULL,
	[VALUE_TYPE_RATE] [numeric](18, 0) NULL,
	[METHOD_ID_RATE] [numeric](18, 0) NULL,
	[START_DATE] [varchar](5) NULL,
	[END_DATE] [varchar](5) NULL,
 CONSTRAINT [PK_D_RETURN_FLOW_ACTUAL] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[RETURN_FLOW_ID] ASC,
	[ACTUAL_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[D_THERMOELECTRIC]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[D_THERMOELECTRIC](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[WATER_USER_ID] [varchar](50) NOT NULL,
	[BENEFICIAL_USE_ID] [numeric](18, 0) NOT NULL,
	[DETAIL_SEQ_NO] [numeric](18, 0) NOT NULL,
	[GENERATOR_TYPE] [numeric](18, 0) NOT NULL,
	[POWER_CAPACITY] [numeric](18, 0) NULL,
 CONSTRAINT [PK_D_THERMOELECTRIC] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[WATER_USER_ID] ASC,
	[BENEFICIAL_USE_ID] ASC,
	[DETAIL_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[D_USE_AMOUNT]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[D_USE_AMOUNT](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[WATER_USER_ID] [varchar](50) NOT NULL,
	[BENEFICIAL_USE_ID] [numeric](18, 0) NOT NULL,
	[ROW_SEQ] [numeric](18, 0) NOT NULL,
	[AMOUNT_VOLUME] [numeric](18, 3) NULL,
	[UNIT_VOLUME] [numeric](18, 0) NULL,
	[VALUE_TYPE_VOLUME] [numeric](18, 0) NULL,
	[METHOD_ID_VOLUME] [numeric](18, 0) NULL,
	[START_DATE] [varchar](5) NULL,
	[END_DATE] [varchar](5) NULL,
 CONSTRAINT [PK_D_USE_AMOUNT] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[WATER_USER_ID] ASC,
	[BENEFICIAL_USE_ID] ASC,
	[ROW_SEQ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[D_USE_LOCATION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[D_USE_LOCATION](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[WATER_USER_ID] [varchar](50) NOT NULL,
	[LOCATION_SEQ] [numeric](18, 0) NOT NULL,
	[STATE] [numeric](18, 0) NOT NULL,
	[REPORTING_UNIT_ID] [varchar](35) NULL,
	[COUNTY_FIPS] [char](5) NULL,
	[HUC] [varchar](12) NULL,
	[WFS_FEATURE_REF] [varchar](35) NULL,
 CONSTRAINT [PK_D_USE_LOCATION] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[LOCATION_SEQ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[DATA_SOURCES]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[DATA_SOURCES](
	[SOURCE_ID] [numeric](18, 0) NOT NULL,
	[SOURCE_CONTEXT] [varchar](10) NOT NULL,
	[SOURCE_NAME] [varchar](255) NOT NULL,
	[SOURCE_DESC] [varchar](1000) NULL,
	[STATE] [char](2) NULL,
	[SOURCE_START_DATE] [date] NOT NULL,
	[SOURCE_END_DATE] [date] NOT NULL,
	[SOURCE_LINK] [varchar](1000) NULL,
	[LAST_CHANGE_DATE] [date] NULL,
	[RETIRED_FLAG] [char](1) NULL,
 CONSTRAINT [PK_DATA_SOURCES] PRIMARY KEY CLUSTERED 
(
	[SOURCE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[DBVERSION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[DBVERSION](
	[VERSION] [varchar](3) NOT NULL,
	[CHANGE] [varchar](200) NULL,
	[UPDATE_SCRIPT] [varchar](100) NULL,
 CONSTRAINT [PK_DBVERSION] PRIMARY KEY CLUSTERED 
(
	[VERSION] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[DETAIL_ALLOCATION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[DETAIL_ALLOCATION](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[ALLOCATION_OWNER] [varchar](100) NULL,
	[APPLICATION_DATE] [date] NULL,
	[PRIORITY_DATE] [date] NULL,
	[LEGAL_STATUS] [numeric](18, 0) NULL,
	[END_DATE] [date] NULL,
 CONSTRAINT [PK_DETAIL_ALLOCATION] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[DETAIL_DIVERSION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[DETAIL_DIVERSION](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[DIVERSION_ID] [varchar](35) NOT NULL,
	[DIVERSION_NAME] [varchar](255) NULL,
	[STATE] [numeric](18, 0) NOT NULL,
	[REPORTING_UNIT_ID] [varchar](35) NULL,
	[COUNTY_FIPS] [char](5) NULL,
	[HUC] [varchar](12) NULL,
	[WFS_FEATURE_REF] [varchar](35) NULL,
 CONSTRAINT [PK_DETAIL_DIVERSION] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[DIVERSION_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[DETAIL_RETURN_FLOW]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[DETAIL_RETURN_FLOW](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[RETURN_FLOW_ID] [varchar](35) NOT NULL,
	[RETURN_FLOW_NAME] [varchar](80) NULL,
	[STATE] [numeric](18, 0) NULL,
	[REPORTING_UNIT_ID] [char](35) NULL,
	[COUNTY_FIPS] [char](5) NULL,
	[HUC] [varchar](12) NULL,
	[WFS_FEATURE_REF] [varchar](35) NULL,
 CONSTRAINT [PK_DETAIL_RETURN_FLOW] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[RETURN_FLOW_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[DETAIL_USE]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[DETAIL_USE](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[ALLOCATION_ID] [varchar](60) NOT NULL,
	[WATER_USER_ID] [varchar](50) NOT NULL,
	[WATER_USER_NAME] [varchar](100) NULL,
 CONSTRAINT [PK_DETAIL_USE] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[ALLOCATION_ID] ASC,
	[WATER_USER_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[GEOSPATIAL_REF]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[GEOSPATIAL_REF](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[WFS_ID] [varchar](35) NOT NULL,
	[WFS_DATACATEGORY] [varchar](80) NOT NULL,
	[WFS_DATATYPE] [varchar](80) NOT NULL,
	[WFS_ADDRESS] [varchar](200) NOT NULL,
	[WFS_FEATURE_ID_FIELD] [varchar](35) NOT NULL,
 CONSTRAINT [PK_GEOSPATIAL_REF] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[WFS_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[LU_BENEFICIAL_USE]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[LU_BENEFICIAL_USE](
	[LU_SEQ_NO] [numeric](18, 0) NOT NULL,
	[CONTEXT] [varchar](10) NOT NULL,
	[VALUE] [varchar](35) NOT NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[STATE] [char](2) NULL,
	[LAST_CHANGE_DATE] [date] NULL,
	[RETIRED_FLAG] [char](1) NULL,
 CONSTRAINT [PK_LU_BENEFICIAL_USE] PRIMARY KEY CLUSTERED 
(
	[LU_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[LU_CROP_TYPE]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[LU_CROP_TYPE](
	[LU_SEQ_NO] [numeric](18, 0) NOT NULL,
	[CONTEXT] [varchar](10) NOT NULL,
	[VALUE] [varchar](60) NOT NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[STATE] [char](2) NULL,
	[LAST_CHANGE_DATE] [date] NULL,
	[RETIRED_FLAG] [char](1) NULL,
 CONSTRAINT [PK_LU_CROP_TYPE] PRIMARY KEY CLUSTERED 
(
	[LU_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[LU_FRESH_SALINE_INDICATOR]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[LU_FRESH_SALINE_INDICATOR](
	[LU_SEQ_NO] [numeric](18, 0) NOT NULL,
	[CONTEXT] [varchar](10) NOT NULL,
	[VALUE] [varchar](10) NOT NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[STATE] [char](2) NULL,
	[LAST_CHANGE_DATE] [date] NULL,
	[RETIRED_FLAG] [char](1) NULL,
 CONSTRAINT [PK_LU_FRESH_SALINE_INDICATOR] PRIMARY KEY CLUSTERED 
(
	[LU_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[LU_GENERATOR_TYPE]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[LU_GENERATOR_TYPE](
	[LU_SEQ_NO] [numeric](18, 0) NOT NULL,
	[CONTEXT] [varchar](10) NOT NULL,
	[VALUE] [varchar](60) NOT NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[STATE] [char](2) NULL,
	[LAST_CHANGE_DATE] [date] NULL,
	[RETIRED_FLAG] [char](1) NULL,
 CONSTRAINT [PK_LU_GENERATOR_TYPE] PRIMARY KEY CLUSTERED 
(
	[LU_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[LU_IRRIGATION_METHOD]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[LU_IRRIGATION_METHOD](
	[LU_SEQ_NO] [numeric](18, 0) NOT NULL,
	[CONTEXT] [varchar](10) NOT NULL,
	[VALUE] [varchar](30) NOT NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[STATE] [char](2) NULL,
	[LAST_CHANGE_DATE] [date] NULL,
	[RETIRED_FLAG] [char](1) NULL,
 CONSTRAINT [PK_LU_IRRIGATION_METHOD] PRIMARY KEY CLUSTERED 
(
	[LU_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[LU_LEGAL_STATUS]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[LU_LEGAL_STATUS](
	[LU_SEQ_NO] [numeric](18, 0) NOT NULL,
	[CONTEXT] [varchar](10) NOT NULL,
	[VALUE] [varchar](25) NOT NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[STATE] [char](2) NULL,
	[LAST_CHANGE_DATE] [date] NULL,
	[RETIRED_FLAG] [char](1) NULL,
 CONSTRAINT [PK_LU_LEGAL_STATUS] PRIMARY KEY CLUSTERED 
(
	[LU_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[LU_REGULATORY_STATUS]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[LU_REGULATORY_STATUS](
	[LU_SEQ_NO] [numeric](18, 0) NOT NULL,
	[CONTEXT] [varchar](10) NOT NULL,
	[VALUE] [varchar](35) NOT NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[STATE] [char](2) NULL,
	[LAST_CHANGE_DATE] [date] NULL,
	[RETIRED_FLAG] [char](1) NULL,
 CONSTRAINT [PK_LU_REGULATORY_STATUS] PRIMARY KEY CLUSTERED 
(
	[LU_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[LU_SOURCE_TYPE]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[LU_SOURCE_TYPE](
	[LU_SEQ_NO] [numeric](18, 0) NOT NULL,
	[CONTEXT] [varchar](10) NOT NULL,
	[VALUE] [varchar](10) NOT NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[STATE] [char](2) NULL,
	[LAST_CHANGE_DATE] [date] NULL,
	[RETIRED_FLAG] [char](1) NULL,
 CONSTRAINT [PK_LU_SOURCE_TYPE] PRIMARY KEY CLUSTERED 
(
	[LU_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[LU_STATE]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[LU_STATE](
	[LU_SEQ_NO] [numeric](18, 0) NOT NULL,
	[CONTEXT] [varchar](10) NOT NULL,
	[VALUE] [varchar](2) NOT NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[STATE] [char](2) NULL,
	[LAST_CHANGE_DATE] [date] NULL,
	[RETIRED_FLAG] [char](1) NULL,
 CONSTRAINT [PK_LU_STATE] PRIMARY KEY CLUSTERED 
(
	[LU_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[LU_UNITS]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[LU_UNITS](
	[LU_SEQ_NO] [numeric](18, 0) NOT NULL,
	[CONTEXT] [varchar](10) NOT NULL,
	[VALUE] [varchar](10) NOT NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[STATE] [char](2) NULL,
	[LAST_CHANGE_DATE] [date] NULL,
	[RETIRED_FLAG] [char](1) NULL,
 CONSTRAINT [PK_LU_UNITS] PRIMARY KEY CLUSTERED 
(
	[LU_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[LU_VALUE_TYPE]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[LU_VALUE_TYPE](
	[LU_SEQ_NO] [numeric](18, 0) NOT NULL,
	[CONTEXT] [varchar](10) NOT NULL,
	[VALUE] [char](1) NOT NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[STATE] [char](2) NULL,
	[LAST_CHANGE_DATE] [date] NULL,
	[RETIRED_FLAG] [char](1) NULL,
 CONSTRAINT [PK_LU_VALUE_TYPE] PRIMARY KEY CLUSTERED 
(
	[LU_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[LU_WATER_SUPPLY_TYPE]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[LU_WATER_SUPPLY_TYPE](
	[LU_SEQ_NO] [numeric](18, 0) NOT NULL,
	[CONTEXT] [varchar](10) NOT NULL,
	[VALUE] [varchar](35) NOT NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[STATE] [char](2) NULL,
	[LAST_CHANGE_DATE] [date] NULL,
	[RETIRED_FLAG] [char](1) NULL,
 CONSTRAINT [PK_LU_WATER_SUPPLY_TYPE] PRIMARY KEY CLUSTERED 
(
	[LU_SEQ_NO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[METHODS]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[METHODS](
	[METHOD_ID] [numeric](18, 0) NOT NULL,
	[METHOD_CONTEXT] [varchar](10) NOT NULL,
	[METHOD_NAME] [varchar](255) NOT NULL,
	[METHOD_DESC] [varchar](400) NULL,
	[STATE] [char](2) NULL,
	[METHOD_DATE] [date] NOT NULL,
	[METHOD_TYPE] [varchar](50) NOT NULL,
	[TIME_SCALE] [varchar](40) NULL,
	[METHOD_LINK] [varchar](1000) NULL,
	[SOURCE_ID] [numeric](18, 0) NULL,
	[RESOURCE_TYPE] [varchar](50) NOT NULL,
	[LOCATION_NAME] [varchar](100) NOT NULL,
	[LAST_CHANGE_DATE] [date] NULL,
	[RETIRED_FLAG] [char](1) NULL,
 CONSTRAINT [PK_METHODS] PRIMARY KEY CLUSTERED 
(
	[METHOD_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[METRICS]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[METRICS](
	[METRIC_ID] [numeric](18, 0) NOT NULL,
	[CONTEXT] [varchar](10) NOT NULL,
	[VALUE] [varchar](35) NOT NULL,
	[DESCRIPTION] [varchar](255) NULL,
	[STATE] [char](2) NULL,
	[LAST_CHANGE_DATE] [date] NULL,
	[RETIRED_FLAG] [char](1) NULL,
 CONSTRAINT [PK_METRICS] PRIMARY KEY CLUSTERED 
(
	[METRIC_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[ORGANIZATION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[ORGANIZATION](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[ORGANIZATION_NAME] [varchar](150) NOT NULL,
	[PURVUE_DESC] [varchar](250) NULL,
	[FIRST_NAME] [varchar](15) NOT NULL,
	[MIDDLE_INITIAL] [char](1) NULL,
	[LAST_NAME] [varchar](15) NOT NULL,
	[TITLE] [varchar](45) NULL,
	[EMAIL] [varchar](240) NULL,
	[PHONE] [varchar](15) NULL,
	[PHONE_EXT] [varchar](6) NULL,
	[FAX] [char](15) NULL,
	[ADDRESS] [varchar](30) NULL,
	[ADDRESS_EXT] [varchar](30) NULL,
	[CITY] [varchar](25) NULL,
	[STATE] [char](2) NULL,
	[COUNTRY] [char](2) NULL,
	[ZIPCODE] [varchar](14) NULL,
	[WADE_URL] [varchar](300) NULL,
 CONSTRAINT [PK_ORGANIZATION] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[REPORT]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[REPORT](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[REPORTING_DATE] [date] NOT NULL,
	[REPORTING_YEAR] [char](4) NOT NULL,
	[REPORT_NAME] [varchar](80) NULL,
	[REPORT_LINK] [varchar](255) NULL,
	[YEAR_TYPE] [varchar](25) NULL,
 CONSTRAINT [PK_REPORT] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[REPORTING_UNIT]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[REPORTING_UNIT](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[REPORT_UNIT_ID] [varchar](35) NOT NULL,
	[REPORTING_UNIT_NAME] [varchar](240) NOT NULL,
	[REPORTING_UNIT_TYPE] [varchar](35) NOT NULL,
	[STATE] [numeric](18, 0) NOT NULL,
	[COUNTY_FIPS] [char](5) NULL,
	[HUC] [varchar](12) NULL,
 CONSTRAINT [PK_REPORTING_UNIT] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[REPORT_UNIT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[S_ALLOCATION_IRRIGATION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[S_ALLOCATION_IRRIGATION](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[REPORT_UNIT_ID] [varchar](35) NOT NULL,
	[SUMMARY_SEQ] [numeric](18, 0) NOT NULL,
	[IRRIGATION_SEQ] [numeric](18, 0) NOT NULL,
	[IRRIGATION_METHOD] [numeric](18, 0) NOT NULL,
	[ACRES_IRRIGATED] [numeric](18, 3) NOT NULL,
	[CROP_TYPE] [numeric](18, 0) NOT NULL,
 CONSTRAINT [PK_S_ALLOCATION_IRRIGATION] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[REPORT_UNIT_ID] ASC,
	[SUMMARY_SEQ] ASC,
	[IRRIGATION_SEQ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[S_AVAILABILITY_AMOUNT]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[S_AVAILABILITY_AMOUNT](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[REPORT_UNIT_ID] [varchar](35) NOT NULL,
	[SUMMARY_SEQ] [numeric](18, 0) NOT NULL,
	[ROW_SEQ] [numeric](18, 0) NOT NULL,
	[AMOUNT] [numeric](18, 3) NULL,
	[METHOD_ID] [numeric](18, 0) NOT NULL,
	[START_DATE] [char](5) NOT NULL,
	[END_DATE] [char](5) NOT NULL,
 CONSTRAINT [PK_S_AVAILABILITY_AMOUNT] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[REPORT_UNIT_ID] ASC,
	[SUMMARY_SEQ] ASC,
	[ROW_SEQ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[S_AVAILABILITY_METRIC]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[S_AVAILABILITY_METRIC](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[REPORT_UNIT_ID] [varchar](35) NOT NULL,
	[SUMMARY_SEQ] [numeric](18, 0) NOT NULL,
	[ROW_SEQ] [numeric](18, 0) NOT NULL,
	[METRIC_ID] [numeric](18, 0) NULL,
	[METRIC_VALUE] [numeric](18, 3) NULL,
	[METRIC_SCALE] [numeric](18, 3) NULL,
	[REVERSE_SCALE_IND] [char](1) NULL,
	[METHOD_ID] [numeric](18, 0) NOT NULL,
	[START_DATE] [char](5) NOT NULL,
	[END_DATE] [char](5) NOT NULL,
 CONSTRAINT [PK_S_AVAILABILITY_METRIC] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[REPORT_UNIT_ID] ASC,
	[SUMMARY_SEQ] ASC,
	[ROW_SEQ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[S_USE_AMOUNT]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[S_USE_AMOUNT](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[REPORT_UNIT_ID] [varchar](35) NOT NULL,
	[BENEFICIAL_USE_ID] [numeric](18, 0) NOT NULL,
	[SUMMARY_SEQ] [numeric](18, 0) NOT NULL,
	[ROW_SEQ] [numeric](18, 0) NOT NULL,
	[AMOUNT] [numeric](18, 3) NULL,
	[CONSUMPTIVE_INDICATOR] [varchar](10) NOT NULL,
	[METHOD_ID] [numeric](18, 0) NOT NULL,
	[START_DATE] [char](5) NOT NULL,
	[END_DATE] [char](5) NOT NULL,
 CONSTRAINT [PK_S_USE_AMOUNT] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[REPORT_UNIT_ID] ASC,
	[BENEFICIAL_USE_ID] ASC,
	[SUMMARY_SEQ] ASC,
	[ROW_SEQ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[S_USE_IRRIGATION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[S_USE_IRRIGATION](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[REPORT_UNIT_ID] [varchar](35) NOT NULL,
	[SUMMARY_SEQ] [numeric](18, 0) NOT NULL,
	[BENEFICIAL_USE_ID] [numeric](18, 0) NOT NULL,
	[IRRIGATION_SEQ] [numeric](18, 0) NOT NULL,
	[IRRIGATION_METHOD] [numeric](18, 0) NOT NULL,
	[ACRES_IRRIGATED] [numeric](18, 3) NOT NULL,
	[CROP_TYPE] [numeric](18, 0) NOT NULL,
 CONSTRAINT [PK_S_USE_IRRIGATION] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[REPORT_UNIT_ID] ASC,
	[SUMMARY_SEQ] ASC,
	[BENEFICIAL_USE_ID] ASC,
	[IRRIGATION_SEQ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[S_WATER_SUPPLY_AMOUNT]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[S_WATER_SUPPLY_AMOUNT](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[REPORT_UNIT_ID] [varchar](35) NOT NULL,
	[SUMMARY_SEQ] [numeric](18, 0) NOT NULL,
	[ROW_SEQ] [numeric](18, 0) NOT NULL,
	[AMOUNT] [numeric](18, 3) NULL,
	[METHOD_ID] [numeric](18, 0) NOT NULL,
	[START_DATE] [char](5) NOT NULL,
	[END_DATE] [char](5) NOT NULL,
 CONSTRAINT [PK_S_WATER_SUPPLY_AMOUNT] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[REPORT_UNIT_ID] ASC,
	[SUMMARY_SEQ] ASC,
	[ROW_SEQ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[SUMMARY_ALLOCATION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[SUMMARY_ALLOCATION](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[REPORT_UNIT_ID] [varchar](35) NOT NULL,
	[SUMMARY_SEQ] [numeric](18, 0) NOT NULL,
	[BENEFICIAL_USE_ID] [numeric](18, 0) NOT NULL,
	[AMOUNT] [numeric](18, 3) NOT NULL,
	[FRESH_SALINE_IND] [numeric](18, 0) NOT NULL,
	[SOURCE_TYPE] [numeric](18, 0) NOT NULL,
	[POWER_GENERATED] [numeric](18, 3) NULL,
	[POPULATION_SERVED] [numeric](18, 3) NULL,
	[WFS_FEATURE_REF] [varchar](35) NULL,
 CONSTRAINT [PK_SUMMARY_ALLOCATIONS] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[REPORT_UNIT_ID] ASC,
	[SUMMARY_SEQ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[SUMMARY_AVAILABILITY]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[SUMMARY_AVAILABILITY](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[REPORT_UNIT_ID] [varchar](35) NOT NULL,
	[SUMMARY_SEQ] [numeric](18, 0) NOT NULL,
	[AVAILABILITY_TYPE] [varchar](50) NOT NULL,
	[FRESH_SALINE_IND] [numeric](18, 0) NOT NULL,
	[SOURCE_TYPE] [numeric](18, 0) NOT NULL,
	[WFS_FEATURE_REF] [varchar](35) NULL,
 CONSTRAINT [PK_SUMMARY_AVAILABILITY] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[REPORT_UNIT_ID] ASC,
	[SUMMARY_SEQ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[SUMMARY_REGULATORY]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[SUMMARY_REGULATORY](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[REPORT_UNIT_ID] [varchar](35) NOT NULL,
	[SUMMARY_SEQ] [numeric](18, 0) NOT NULL,
	[REGULATORY_TYPE] [varchar](50) NOT NULL,
	[REGULATORY_STATUS] [numeric](18, 0) NOT NULL,
	[OVERSIGHT_AGENCY] [varchar](60) NULL,
	[REGULATORY_DESCRIPTION] [varchar](255) NULL,
	[WFS_FEATURE_REF] [varchar](35) NULL,
 CONSTRAINT [PK_SUMMARY_REGULATORY] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[REPORT_UNIT_ID] ASC,
	[SUMMARY_SEQ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[SUMMARY_USE]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[SUMMARY_USE](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[REPORT_UNIT_ID] [varchar](35) NOT NULL,
	[SUMMARY_SEQ] [numeric](18, 0) NOT NULL,
	[BENEFICIAL_USE_ID] [numeric](18, 0) NOT NULL,
	[FRESH_SALINE_IND] [numeric](18, 0) NOT NULL,
	[SOURCE_TYPE] [numeric](18, 0) NOT NULL,
	[POWER_GENERATED] [numeric](18, 3) NULL,
	[POPULATION_SERVED] [numeric](18, 3) NULL,
	[WFS_FEATURE_REF] [varchar](35) NULL,
 CONSTRAINT [PK_SUMMARY_USE] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[REPORT_UNIT_ID] ASC,
	[SUMMARY_SEQ] ASC,
	[BENEFICIAL_USE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [wade].[SUMMARY_WATER_SUPPLY]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [wade].[SUMMARY_WATER_SUPPLY](
	[ORGANIZATION_ID] [varchar](10) NOT NULL,
	[REPORT_ID] [varchar](35) NOT NULL,
	[REPORT_UNIT_ID] [varchar](35) NOT NULL,
	[SUMMARY_SEQ] [numeric](18, 0) NOT NULL,
	[WATER_SUPPLY_TYPE] [numeric](18, 0) NOT NULL,
	[WFS_FEATURE_REF] [varchar](35) NULL,
 CONSTRAINT [PK_SUMMARY_WATER_SUPPLY] PRIMARY KEY CLUSTERED 
(
	[ORGANIZATION_ID] ASC,
	[REPORT_ID] ASC,
	[REPORT_UNIT_ID] ASC,
	[SUMMARY_SEQ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [wade_r].[DETAIL_LOCATION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- View: "WADE_R"."DETAIL_LOCATION"

-- DROP VIEW "WADE_R"."DETAIL_LOCATION";

CREATE VIEW [wade_r].[DETAIL_LOCATION] AS 
        (((SELECT DISTINCT a."ORGANIZATION_ID", 
        a."REPORT_ID", 
        a."ALLOCATION_ID", 
        'DETAIL' AS "DATACATEGORY", 
        'ALLOCATION' AS "DATATYPE", 
        b."STATE", 
        b."REPORTING_UNIT_ID", 
        b."COUNTY_FIPS", 
        b."HUC"
        
        FROM "WADE"."DETAIL_ALLOCATION" 
        a JOIN "WADE"."D_ALLOCATION_LOCATION" b ON a."ORGANIZATION_ID" = b."ORGANIZATION_ID" 
        AND a."REPORT_ID" = b."REPORT_ID" 
        AND a."ALLOCATION_ID" = b."ALLOCATION_ID"
           
        WHERE b.REPORTING_UNIT_ID IS NOT NULL OR 
        b.COUNTY_FIPS IS NOT NULL OR b.HUC IS NOT NULL)
        
        UNION 
        
        SELECT DISTINCT "DETAIL_DIVERSION"."ORGANIZATION_ID",
        "DETAIL_DIVERSION"."REPORT_ID",
        "DETAIL_DIVERSION"."ALLOCATION_ID",
        'DETAIL' AS "DATACATEGORY",
        'DIVERSION' AS "DATATYPE", 
        "DETAIL_DIVERSION"."STATE", 
        "DETAIL_DIVERSION"."REPORTING_UNIT_ID", 
        "DETAIL_DIVERSION"."COUNTY_FIPS", 
        "DETAIL_DIVERSION"."HUC"
        FROM "WADE"."DETAIL_DIVERSION" 
        WHERE "DETAIL_DIVERSION"."REPORTING_UNIT_ID" IS NOT NULL 
        OR "DETAIL_DIVERSION"."COUNTY_FIPS" IS NOT NULL 
        OR "DETAIL_DIVERSION"."HUC" IS NOT NULL)
           
           UNION SELECT DISTINCT a."ORGANIZATION_ID", a."REPORT_ID", a."ALLOCATION_ID", 'DETAIL' AS "DATACATEGORY", 'USE' AS "DATATYPE", b."STATE", b."REPORTING_UNIT_ID", b."COUNTY_FIPS", b."HUC"
           FROM "WADE"."DETAIL_USE" a JOIN "WADE"."D_USE_LOCATION" b ON a."ORGANIZATION_ID" = b."ORGANIZATION_ID" AND a."REPORT_ID" = b."REPORT_ID" AND a."ALLOCATION_ID" = b."ALLOCATION_ID"
           WHERE b.REPORTING_UNIT_ID IS NOT NULL OR b.COUNTY_FIPS IS NOT NULL OR b.HUC IS NOT NULL)
           
           UNION SELECT DISTINCT "DETAIL_RETURN_FLOW"."ORGANIZATION_ID", "DETAIL_RETURN_FLOW"."REPORT_ID", "DETAIL_RETURN_FLOW"."ALLOCATION_ID", 'DETAIL' AS "DATACATEGORY", 'RETURN' AS "DATATYPE", "DETAIL_RETURN_FLOW"."STATE", "DETAIL_RETURN_FLOW"."REPORTING_UNIT_ID", "DETAIL_RETURN_FLOW"."COUNTY_FIPS", "DETAIL_RETURN_FLOW"."HUC"
           FROM "WADE"."DETAIL_RETURN_FLOW" WHERE "DETAIL_RETURN_FLOW"."REPORTING_UNIT_ID" IS NOT NULL OR "DETAIL_RETURN_FLOW"."COUNTY_FIPS" IS NOT NULL OR "DETAIL_RETURN_FLOW"."HUC" IS NOT NULL;



GO
/****** Object:  View [wade_r].[SUMMARY_LOCATION]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- View: "WADE_R"."SUMMARY_LOCATION"

-- DROP VIEW "WADE_R"."SUMMARY_LOCATION";

CREATE VIEW [wade_r].[SUMMARY_LOCATION] AS 
        (((SELECT DISTINCT a."ORGANIZATION_ID", a."REPORT_ID", '' AS "ALLOCATION_ID",
         'SUMMARY' AS "DATACATEGORY",
         'ALLOCATION' AS "DATATYPE", b."STATE", b."REPORT_UNIT_ID", b."COUNTY_FIPS", b."HUC"
                                   
          FROM "WADE"."SUMMARY_ALLOCATION" a
          JOIN "WADE"."REPORTING_UNIT" b ON a."REPORT_UNIT_ID" = b."REPORT_UNIT_ID" AND a."REPORT_ID" = b."REPORT_ID" AND a."ORGANIZATION_ID" = b."ORGANIZATION_ID"
          
          UNION 
                 
          SELECT DISTINCT a."ORGANIZATION_ID", a."REPORT_ID", '' AS "ALLOCATION_ID", 
          'SUMMARY' AS "DATACATEGORY", 
          'AVAILABILITY' AS "DATATYPE", b."STATE", b."REPORT_UNIT_ID", b."COUNTY_FIPS", b."HUC"
          FROM "WADE"."SUMMARY_AVAILABILITY" a
          JOIN "WADE"."REPORTING_UNIT" b ON a."REPORT_UNIT_ID" = b."REPORT_UNIT_ID" AND a."REPORT_ID" = b."REPORT_ID" AND a."ORGANIZATION_ID" = b."ORGANIZATION_ID")
          
          UNION 
          
          SELECT DISTINCT a."ORGANIZATION_ID", a."REPORT_ID", '' AS "ALLOCATION_ID", 
          'SUMMARY' AS "DATACATEGORY", 
          'REGULATORY' AS "DATATYPE", b."STATE", b."REPORT_UNIT_ID", b."COUNTY_FIPS", b."HUC"
          FROM "WADE"."SUMMARY_REGULATORY" a
          JOIN "WADE"."REPORTING_UNIT" b ON a."REPORT_UNIT_ID" = b."REPORT_UNIT_ID" AND a."REPORT_ID" = b."REPORT_ID" AND a."ORGANIZATION_ID" = b."ORGANIZATION_ID")
          
		  UNION 
                 
          SELECT DISTINCT a."ORGANIZATION_ID", a."REPORT_ID", '' AS "ALLOCATION_ID", 
          'SUMMARY' AS "DATACATEGORY", 
          'USE' AS "DATATYPE", b."STATE", b."REPORT_UNIT_ID", b."COUNTY_FIPS", b."HUC"
          FROM "WADE"."SUMMARY_USE" a
          JOIN "WADE"."REPORTING_UNIT" b ON a."REPORT_UNIT_ID" = b."REPORT_UNIT_ID" AND a."REPORT_ID" = b."REPORT_ID" AND a."ORGANIZATION_ID" = b."ORGANIZATION_ID")
          
		  UNION 

          SELECT DISTINCT a."ORGANIZATION_ID", a."REPORT_ID", '' AS "ALLOCATION_ID", 
          'SUMMARY' AS "DATACATEGORY", 
          'SUPPLY' AS "DATATYPE", b."STATE", b."REPORT_UNIT_ID", b."COUNTY_FIPS", b."HUC"
          FROM "WADE"."SUMMARY_WATER_SUPPLY" a
          JOIN "WADE"."REPORTING_UNIT" b ON a."REPORT_UNIT_ID" = b."REPORT_UNIT_ID" AND a."REPORT_ID" = b."REPORT_ID" AND a."ORGANIZATION_ID" = b."ORGANIZATION_ID";





GO
/****** Object:  View [wade_r].[FULL_CATALOG]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- View: "WADE_R"."FULL_CATALOG"

-- DROP VIEW "WADE_R"."FULL_CATALOG";

CREATE VIEW [wade_r].[FULL_CATALOG] AS
	(SELECT WADE_R.SUMMARY_LOCATION.ORGANIZATION_ID,
	WADE_R.SUMMARY_LOCATION.REPORT_ID,
	WADE_R.SUMMARY_LOCATION.ALLOCATION_ID,
	WADE_R.SUMMARY_LOCATION.DATACATEGORY,
	WADE_R.SUMMARY_LOCATION.DATATYPE,
	WADE_R.SUMMARY_LOCATION.STATE,
	WADE_R.SUMMARY_LOCATION.REPORT_UNIT_ID,
	WADE_R.SUMMARY_LOCATION.COUNTY_FIPS,
	WADE_R.SUMMARY_LOCATION.HUC

	FROM WADE_R.SUMMARY_LOCATION
	UNION
	(SELECT WADE_R.DETAIL_LOCATION.ORGANIZATION_ID,
	WADE_R.DETAIL_LOCATION.REPORT_ID,
	WADE_R.DETAIL_LOCATION.ALLOCATION_ID,
	WADE_R.DETAIL_LOCATION.DATACATEGORY,
	WADE_R.DETAIL_LOCATION.DATATYPE,
	WADE_R.DETAIL_LOCATION.STATE,
	WADE_R.DETAIL_LOCATION.REPORTING_UNIT_ID AS "REPORT_UNIT_ID",
	WADE_R.DETAIL_LOCATION.COUNTY_FIPS,
	WADE_R.DETAIL_LOCATION.HUC
	FROM WADE_R.DETAIL_LOCATION));
	


GO
/****** Object:  View [wade_r].[CATALOG_SUMMARY]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- View: "WADE_R"."CATALOG_SUMMARY"

-- DROP VIEW "WADE_R"."CATALOG_SUMMARY";

CREATE VIEW [wade_r].[CATALOG_SUMMARY] AS
	(SELECT A.ORGANIZATION_ID,
	A.REPORT_ID,
	A.DATACATEGORY,
	A.DATATYPE,
	A.STATE,
	A.REPORT_UNIT_ID,
	A.COUNTY_FIPS,
	A.HUC,
	(COUNT(A.ALLOCATION_ID)-1) AS NUMOFALLOCATIONS

	FROM WADE_R.FULL_CATALOG A GROUP BY A.ORGANIZATION_ID,
	A.REPORT_ID,
	A.DATACATEGORY,
	A.DATATYPE,
	A.STATE,
	A.REPORT_UNIT_ID,
	A.COUNTY_FIPS,
	A.HUC);
	

GO
/****** Object:  View [dbo].[TEXT_XOM]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[TEXT_XOM]
AS
SELECT      wade_r.XML_ORGANIZATION('COWCB') AS Expr1

GO
ALTER TABLE [dbo].[dtproperties] ADD  DEFAULT ((0)) FOR [version]
GO
ALTER TABLE [wade].[D_ALLOCATION_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_ALLOCATION_ACTUAL_D_ALLOCATION_FLOW] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [DETAIL_SEQ_NO])
REFERENCES [wade].[D_ALLOCATION_FLOW] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [DETAIL_SEQ_NO])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[D_ALLOCATION_ACTUAL] CHECK CONSTRAINT [FK_D_ALLOCATION_ACTUAL_D_ALLOCATION_FLOW]
GO
ALTER TABLE [wade].[D_ALLOCATION_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_ALLOCATION_ACTUAL_LU_UNITS] FOREIGN KEY([UNIT_RATE])
REFERENCES [wade].[LU_UNITS] ([LU_SEQ_NO])
GO
ALTER TABLE [wade].[D_ALLOCATION_ACTUAL] CHECK CONSTRAINT [FK_D_ALLOCATION_ACTUAL_LU_UNITS]
GO
ALTER TABLE [wade].[D_ALLOCATION_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_ALLOCATION_ACTUAL_LU_UNITS1] FOREIGN KEY([UNIT_VOLUME])
REFERENCES [wade].[LU_UNITS] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_ALLOCATION_ACTUAL] CHECK CONSTRAINT [FK_D_ALLOCATION_ACTUAL_LU_UNITS1]
GO
ALTER TABLE [wade].[D_ALLOCATION_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_ALLOCATION_ACTUAL_LU_VALUE_TYPE] FOREIGN KEY([VALUE_TYPE_RATE])
REFERENCES [wade].[LU_VALUE_TYPE] ([LU_SEQ_NO])
GO
ALTER TABLE [wade].[D_ALLOCATION_ACTUAL] CHECK CONSTRAINT [FK_D_ALLOCATION_ACTUAL_LU_VALUE_TYPE]
GO
ALTER TABLE [wade].[D_ALLOCATION_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_ALLOCATION_ACTUAL_LU_VALUE_TYPE1] FOREIGN KEY([VALUE_TYPE_VOLUME])
REFERENCES [wade].[LU_VALUE_TYPE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_ALLOCATION_ACTUAL] CHECK CONSTRAINT [FK_D_ALLOCATION_ACTUAL_LU_VALUE_TYPE1]
GO
ALTER TABLE [wade].[D_ALLOCATION_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_ALLOCATION_ACTUAL_METHODS] FOREIGN KEY([METHOD_ID_VOLUME])
REFERENCES [wade].[METHODS] ([METHOD_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_ALLOCATION_ACTUAL] CHECK CONSTRAINT [FK_D_ALLOCATION_ACTUAL_METHODS]
GO
ALTER TABLE [wade].[D_ALLOCATION_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_ALLOCATION_ACTUAL_METHODS1] FOREIGN KEY([METHOD_ID_RATE])
REFERENCES [wade].[METHODS] ([METHOD_ID])
GO
ALTER TABLE [wade].[D_ALLOCATION_ACTUAL] CHECK CONSTRAINT [FK_D_ALLOCATION_ACTUAL_METHODS1]
GO
ALTER TABLE [wade].[D_ALLOCATION_FLOW]  WITH CHECK ADD  CONSTRAINT [FK_D_ALLOCATION_FLOW_DETAIL_ALLOCATION] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID])
REFERENCES [wade].[DETAIL_ALLOCATION] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[D_ALLOCATION_FLOW] CHECK CONSTRAINT [FK_D_ALLOCATION_FLOW_DETAIL_ALLOCATION]
GO
ALTER TABLE [wade].[D_ALLOCATION_FLOW]  WITH CHECK ADD  CONSTRAINT [FK_D_ALLOCATION_FLOW_LU_FRESH_SALINE_INDICATOR] FOREIGN KEY([FRESH_SALINE_IND])
REFERENCES [wade].[LU_FRESH_SALINE_INDICATOR] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_ALLOCATION_FLOW] CHECK CONSTRAINT [FK_D_ALLOCATION_FLOW_LU_FRESH_SALINE_INDICATOR]
GO
ALTER TABLE [wade].[D_ALLOCATION_FLOW]  WITH CHECK ADD  CONSTRAINT [FK_D_ALLOCATION_FLOW_LU_SOURCE_TYPE] FOREIGN KEY([SOURCE_TYPE])
REFERENCES [wade].[LU_SOURCE_TYPE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_ALLOCATION_FLOW] CHECK CONSTRAINT [FK_D_ALLOCATION_FLOW_LU_SOURCE_TYPE]
GO
ALTER TABLE [wade].[D_ALLOCATION_FLOW]  WITH CHECK ADD  CONSTRAINT [FK_D_ALLOCATION_FLOW_LU_UNITS] FOREIGN KEY([UNIT_RATE])
REFERENCES [wade].[LU_UNITS] ([LU_SEQ_NO])
GO
ALTER TABLE [wade].[D_ALLOCATION_FLOW] CHECK CONSTRAINT [FK_D_ALLOCATION_FLOW_LU_UNITS]
GO
ALTER TABLE [wade].[D_ALLOCATION_FLOW]  WITH CHECK ADD  CONSTRAINT [FK_D_ALLOCATION_FLOW_LU_UNITS1] FOREIGN KEY([UNIT_VOLUME])
REFERENCES [wade].[LU_UNITS] ([LU_SEQ_NO])
GO
ALTER TABLE [wade].[D_ALLOCATION_FLOW] CHECK CONSTRAINT [FK_D_ALLOCATION_FLOW_LU_UNITS1]
GO
ALTER TABLE [wade].[D_ALLOCATION_LOCATION]  WITH CHECK ADD  CONSTRAINT [FK_D_ALLOCATION_LOCATION_DETAIL_ALLOCATION] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID])
REFERENCES [wade].[DETAIL_ALLOCATION] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[D_ALLOCATION_LOCATION] CHECK CONSTRAINT [FK_D_ALLOCATION_LOCATION_DETAIL_ALLOCATION]
GO
ALTER TABLE [wade].[D_ALLOCATION_LOCATION]  WITH CHECK ADD  CONSTRAINT [FK_D_ALLOCATION_LOCATION_LU_STATE] FOREIGN KEY([STATE])
REFERENCES [wade].[LU_STATE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_ALLOCATION_LOCATION] CHECK CONSTRAINT [FK_D_ALLOCATION_LOCATION_LU_STATE]
GO
ALTER TABLE [wade].[D_ALLOCATION_USE]  WITH CHECK ADD  CONSTRAINT [FK_D_ALLOCATION_USE_D_ALLOCATION_FLOW] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [DETAIL_SEQ_NO])
REFERENCES [wade].[D_ALLOCATION_FLOW] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [DETAIL_SEQ_NO])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[D_ALLOCATION_USE] CHECK CONSTRAINT [FK_D_ALLOCATION_USE_D_ALLOCATION_FLOW]
GO
ALTER TABLE [wade].[D_ALLOCATION_USE]  WITH CHECK ADD  CONSTRAINT [FK_D_ALLOCATION_USE_LU_BENEFICIAL_USE] FOREIGN KEY([BENEFICIAL_USE_ID])
REFERENCES [wade].[LU_BENEFICIAL_USE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_ALLOCATION_USE] CHECK CONSTRAINT [FK_D_ALLOCATION_USE_LU_BENEFICIAL_USE]
GO
ALTER TABLE [wade].[D_COMMUNITY_WATER_SUPPLY]  WITH CHECK ADD  CONSTRAINT [FK_D_COMMUNITY_WATER_SUPPLY_D_CONSUMPTIVE_USE] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [WATER_USER_ID], [BENEFICIAL_USE_ID])
REFERENCES [wade].[D_CONSUMPTIVE_USE] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [WATER_USER_ID], [BENEFICIAL_USE_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[D_COMMUNITY_WATER_SUPPLY] CHECK CONSTRAINT [FK_D_COMMUNITY_WATER_SUPPLY_D_CONSUMPTIVE_USE]
GO
ALTER TABLE [wade].[D_CONSUMPTIVE_USE]  WITH CHECK ADD  CONSTRAINT [FK_D_CONSUMPTIVE_USE_DETAIL_USE] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [WATER_USER_ID])
REFERENCES [wade].[DETAIL_USE] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [WATER_USER_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_CONSUMPTIVE_USE] CHECK CONSTRAINT [FK_D_CONSUMPTIVE_USE_DETAIL_USE]
GO
ALTER TABLE [wade].[D_CONSUMPTIVE_USE]  WITH CHECK ADD  CONSTRAINT [FK_D_CONSUMPTIVE_USE_LU_BENEFICIAL_USE] FOREIGN KEY([BENEFICIAL_USE_ID])
REFERENCES [wade].[LU_BENEFICIAL_USE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_CONSUMPTIVE_USE] CHECK CONSTRAINT [FK_D_CONSUMPTIVE_USE_LU_BENEFICIAL_USE]
GO
ALTER TABLE [wade].[D_CONSUMPTIVE_USE]  WITH CHECK ADD  CONSTRAINT [FK_D_CONSUMPTIVE_USE_LU_FRESH_SALINE_INDICATOR] FOREIGN KEY([FRESH_SALINE_IND])
REFERENCES [wade].[LU_FRESH_SALINE_INDICATOR] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_CONSUMPTIVE_USE] CHECK CONSTRAINT [FK_D_CONSUMPTIVE_USE_LU_FRESH_SALINE_INDICATOR]
GO
ALTER TABLE [wade].[D_CONSUMPTIVE_USE]  WITH CHECK ADD  CONSTRAINT [FK_D_CONSUMPTIVE_USE_LU_SOURCE_TYPE] FOREIGN KEY([SOURCE_TYPE])
REFERENCES [wade].[LU_SOURCE_TYPE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_CONSUMPTIVE_USE] CHECK CONSTRAINT [FK_D_CONSUMPTIVE_USE_LU_SOURCE_TYPE]
GO
ALTER TABLE [wade].[D_DIVERSION_ACTUAL]  WITH NOCHECK ADD  CONSTRAINT [FK_D_DIVERSION_ACTUAL_D_DIVERSION_FLOW] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [DIVERSION_ID], [DETAIL_SEQ_NO])
REFERENCES [wade].[D_DIVERSION_FLOW] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [DIVERSION_ID], [DETAIL_SEQ_NO])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[D_DIVERSION_ACTUAL] CHECK CONSTRAINT [FK_D_DIVERSION_ACTUAL_D_DIVERSION_FLOW]
GO
ALTER TABLE [wade].[D_DIVERSION_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_DIVERSION_ACTUAL_LU_UNITS] FOREIGN KEY([UNIT_RATE])
REFERENCES [wade].[LU_UNITS] ([LU_SEQ_NO])
GO
ALTER TABLE [wade].[D_DIVERSION_ACTUAL] CHECK CONSTRAINT [FK_D_DIVERSION_ACTUAL_LU_UNITS]
GO
ALTER TABLE [wade].[D_DIVERSION_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_DIVERSION_ACTUAL_LU_UNITS1] FOREIGN KEY([UNIT_VOLUME])
REFERENCES [wade].[LU_UNITS] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_DIVERSION_ACTUAL] CHECK CONSTRAINT [FK_D_DIVERSION_ACTUAL_LU_UNITS1]
GO
ALTER TABLE [wade].[D_DIVERSION_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_DIVERSION_ACTUAL_LU_VALUE_TYPE] FOREIGN KEY([VALUE_TYPE_RATE])
REFERENCES [wade].[LU_VALUE_TYPE] ([LU_SEQ_NO])
GO
ALTER TABLE [wade].[D_DIVERSION_ACTUAL] CHECK CONSTRAINT [FK_D_DIVERSION_ACTUAL_LU_VALUE_TYPE]
GO
ALTER TABLE [wade].[D_DIVERSION_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_DIVERSION_ACTUAL_LU_VALUE_TYPE1] FOREIGN KEY([VALUE_TYPE_VOLUME])
REFERENCES [wade].[LU_VALUE_TYPE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_DIVERSION_ACTUAL] CHECK CONSTRAINT [FK_D_DIVERSION_ACTUAL_LU_VALUE_TYPE1]
GO
ALTER TABLE [wade].[D_DIVERSION_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_DIVERSION_ACTUAL_METHODS] FOREIGN KEY([METHOD_ID_RATE])
REFERENCES [wade].[METHODS] ([METHOD_ID])
GO
ALTER TABLE [wade].[D_DIVERSION_ACTUAL] CHECK CONSTRAINT [FK_D_DIVERSION_ACTUAL_METHODS]
GO
ALTER TABLE [wade].[D_DIVERSION_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_DIVERSION_ACTUAL_METHODS1] FOREIGN KEY([METHOD_ID_VOLUME])
REFERENCES [wade].[METHODS] ([METHOD_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_DIVERSION_ACTUAL] CHECK CONSTRAINT [FK_D_DIVERSION_ACTUAL_METHODS1]
GO
ALTER TABLE [wade].[D_DIVERSION_FLOW]  WITH NOCHECK ADD  CONSTRAINT [FK_D_DIVERSION_FLOW_DETAIL_DIVERSION] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [DIVERSION_ID])
REFERENCES [wade].[DETAIL_DIVERSION] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [DIVERSION_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[D_DIVERSION_FLOW] CHECK CONSTRAINT [FK_D_DIVERSION_FLOW_DETAIL_DIVERSION]
GO
ALTER TABLE [wade].[D_DIVERSION_FLOW]  WITH CHECK ADD  CONSTRAINT [FK_D_DIVERSION_FLOW_LU_FRESH_SALINE_INDICATOR] FOREIGN KEY([FRESH_SALINE_IND])
REFERENCES [wade].[LU_FRESH_SALINE_INDICATOR] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_DIVERSION_FLOW] CHECK CONSTRAINT [FK_D_DIVERSION_FLOW_LU_FRESH_SALINE_INDICATOR]
GO
ALTER TABLE [wade].[D_DIVERSION_FLOW]  WITH CHECK ADD  CONSTRAINT [FK_D_DIVERSION_FLOW_LU_SOURCE_TYPE] FOREIGN KEY([SOURCE_TYPE])
REFERENCES [wade].[LU_SOURCE_TYPE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_DIVERSION_FLOW] CHECK CONSTRAINT [FK_D_DIVERSION_FLOW_LU_SOURCE_TYPE]
GO
ALTER TABLE [wade].[D_DIVERSION_FLOW]  WITH CHECK ADD  CONSTRAINT [FK_D_DIVERSION_FLOW_LU_UNITS] FOREIGN KEY([UNIT_RATE])
REFERENCES [wade].[LU_UNITS] ([LU_SEQ_NO])
GO
ALTER TABLE [wade].[D_DIVERSION_FLOW] CHECK CONSTRAINT [FK_D_DIVERSION_FLOW_LU_UNITS]
GO
ALTER TABLE [wade].[D_DIVERSION_FLOW]  WITH CHECK ADD  CONSTRAINT [FK_D_DIVERSION_FLOW_LU_UNITS1] FOREIGN KEY([UNIT_VOLUME])
REFERENCES [wade].[LU_UNITS] ([LU_SEQ_NO])
GO
ALTER TABLE [wade].[D_DIVERSION_FLOW] CHECK CONSTRAINT [FK_D_DIVERSION_FLOW_LU_UNITS1]
GO
ALTER TABLE [wade].[D_DIVERSION_USE]  WITH NOCHECK ADD  CONSTRAINT [FK_D_DIVERSION_USE_D_DIVERSION_FLOW] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [DIVERSION_ID], [DETAIL_SEQ_NO])
REFERENCES [wade].[D_DIVERSION_FLOW] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [DIVERSION_ID], [DETAIL_SEQ_NO])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[D_DIVERSION_USE] CHECK CONSTRAINT [FK_D_DIVERSION_USE_D_DIVERSION_FLOW]
GO
ALTER TABLE [wade].[D_DIVERSION_USE]  WITH CHECK ADD  CONSTRAINT [FK_D_DIVERSION_USE_LU_BENEFICIAL_USE] FOREIGN KEY([BENEFICIAL_USE_ID])
REFERENCES [wade].[LU_BENEFICIAL_USE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_DIVERSION_USE] CHECK CONSTRAINT [FK_D_DIVERSION_USE_LU_BENEFICIAL_USE]
GO
ALTER TABLE [wade].[D_IRRIGATION]  WITH CHECK ADD  CONSTRAINT [FK_D_IRRIGATION_D_CONSUMPTIVE_USE] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [WATER_USER_ID], [BENEFICIAL_USE_ID])
REFERENCES [wade].[D_CONSUMPTIVE_USE] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [WATER_USER_ID], [BENEFICIAL_USE_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[D_IRRIGATION] CHECK CONSTRAINT [FK_D_IRRIGATION_D_CONSUMPTIVE_USE]
GO
ALTER TABLE [wade].[D_IRRIGATION]  WITH CHECK ADD  CONSTRAINT [FK_D_IRRIGATION_LU_CROP_TYPE] FOREIGN KEY([CROP_TYPE])
REFERENCES [wade].[LU_CROP_TYPE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_IRRIGATION] CHECK CONSTRAINT [FK_D_IRRIGATION_LU_CROP_TYPE]
GO
ALTER TABLE [wade].[D_IRRIGATION]  WITH CHECK ADD  CONSTRAINT [FK_D_IRRIGATION_LU_IRRIGATION_METHOD] FOREIGN KEY([IRRIGATION_METHOD])
REFERENCES [wade].[LU_IRRIGATION_METHOD] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_IRRIGATION] CHECK CONSTRAINT [FK_D_IRRIGATION_LU_IRRIGATION_METHOD]
GO
ALTER TABLE [wade].[D_RETURN_FLOW_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_RETURN_FLOW_ACTUAL_DETAIL_RETURN_FLOW] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [RETURN_FLOW_ID])
REFERENCES [wade].[DETAIL_RETURN_FLOW] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [RETURN_FLOW_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[D_RETURN_FLOW_ACTUAL] CHECK CONSTRAINT [FK_D_RETURN_FLOW_ACTUAL_DETAIL_RETURN_FLOW]
GO
ALTER TABLE [wade].[D_RETURN_FLOW_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_RETURN_FLOW_ACTUAL_LU_UNITS] FOREIGN KEY([UNIT_RATE])
REFERENCES [wade].[LU_UNITS] ([LU_SEQ_NO])
GO
ALTER TABLE [wade].[D_RETURN_FLOW_ACTUAL] CHECK CONSTRAINT [FK_D_RETURN_FLOW_ACTUAL_LU_UNITS]
GO
ALTER TABLE [wade].[D_RETURN_FLOW_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_RETURN_FLOW_ACTUAL_LU_UNITS1] FOREIGN KEY([UNIT_VOLUME])
REFERENCES [wade].[LU_UNITS] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_RETURN_FLOW_ACTUAL] CHECK CONSTRAINT [FK_D_RETURN_FLOW_ACTUAL_LU_UNITS1]
GO
ALTER TABLE [wade].[D_RETURN_FLOW_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_RETURN_FLOW_ACTUAL_LU_VALUE_TYPE] FOREIGN KEY([VALUE_TYPE_RATE])
REFERENCES [wade].[LU_VALUE_TYPE] ([LU_SEQ_NO])
GO
ALTER TABLE [wade].[D_RETURN_FLOW_ACTUAL] CHECK CONSTRAINT [FK_D_RETURN_FLOW_ACTUAL_LU_VALUE_TYPE]
GO
ALTER TABLE [wade].[D_RETURN_FLOW_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_RETURN_FLOW_ACTUAL_LU_VALUE_TYPE1] FOREIGN KEY([VALUE_TYPE_VOLUME])
REFERENCES [wade].[LU_VALUE_TYPE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_RETURN_FLOW_ACTUAL] CHECK CONSTRAINT [FK_D_RETURN_FLOW_ACTUAL_LU_VALUE_TYPE1]
GO
ALTER TABLE [wade].[D_RETURN_FLOW_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_RETURN_FLOW_ACTUAL_METHODS] FOREIGN KEY([METHOD_ID_RATE])
REFERENCES [wade].[METHODS] ([METHOD_ID])
GO
ALTER TABLE [wade].[D_RETURN_FLOW_ACTUAL] CHECK CONSTRAINT [FK_D_RETURN_FLOW_ACTUAL_METHODS]
GO
ALTER TABLE [wade].[D_RETURN_FLOW_ACTUAL]  WITH CHECK ADD  CONSTRAINT [FK_D_RETURN_FLOW_ACTUAL_METHODS1] FOREIGN KEY([METHOD_ID_VOLUME])
REFERENCES [wade].[METHODS] ([METHOD_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_RETURN_FLOW_ACTUAL] CHECK CONSTRAINT [FK_D_RETURN_FLOW_ACTUAL_METHODS1]
GO
ALTER TABLE [wade].[D_THERMOELECTRIC]  WITH CHECK ADD  CONSTRAINT [FK_D_THERMOELECTRIC_D_CONSUMPTIVE_USE] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [WATER_USER_ID], [BENEFICIAL_USE_ID])
REFERENCES [wade].[D_CONSUMPTIVE_USE] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [WATER_USER_ID], [BENEFICIAL_USE_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[D_THERMOELECTRIC] CHECK CONSTRAINT [FK_D_THERMOELECTRIC_D_CONSUMPTIVE_USE]
GO
ALTER TABLE [wade].[D_THERMOELECTRIC]  WITH CHECK ADD  CONSTRAINT [FK_D_THERMOELECTRIC_LU_GENERATOR_TYPE] FOREIGN KEY([GENERATOR_TYPE])
REFERENCES [wade].[LU_GENERATOR_TYPE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_THERMOELECTRIC] CHECK CONSTRAINT [FK_D_THERMOELECTRIC_LU_GENERATOR_TYPE]
GO
ALTER TABLE [wade].[D_USE_AMOUNT]  WITH CHECK ADD  CONSTRAINT [FK_D_USE_AMOUNT_D_CONSUMPTIVE_USE] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [WATER_USER_ID], [BENEFICIAL_USE_ID])
REFERENCES [wade].[D_CONSUMPTIVE_USE] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [WATER_USER_ID], [BENEFICIAL_USE_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[D_USE_AMOUNT] CHECK CONSTRAINT [FK_D_USE_AMOUNT_D_CONSUMPTIVE_USE]
GO
ALTER TABLE [wade].[D_USE_AMOUNT]  WITH CHECK ADD  CONSTRAINT [FK_D_USE_AMOUNT_LU_UNITS] FOREIGN KEY([UNIT_VOLUME])
REFERENCES [wade].[LU_UNITS] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_USE_AMOUNT] CHECK CONSTRAINT [FK_D_USE_AMOUNT_LU_UNITS]
GO
ALTER TABLE [wade].[D_USE_AMOUNT]  WITH CHECK ADD  CONSTRAINT [FK_D_USE_AMOUNT_LU_VALUE_TYPE] FOREIGN KEY([VALUE_TYPE_VOLUME])
REFERENCES [wade].[LU_VALUE_TYPE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_USE_AMOUNT] CHECK CONSTRAINT [FK_D_USE_AMOUNT_LU_VALUE_TYPE]
GO
ALTER TABLE [wade].[D_USE_AMOUNT]  WITH CHECK ADD  CONSTRAINT [FK_D_USE_AMOUNT_METHODS] FOREIGN KEY([METHOD_ID_VOLUME])
REFERENCES [wade].[METHODS] ([METHOD_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_USE_AMOUNT] CHECK CONSTRAINT [FK_D_USE_AMOUNT_METHODS]
GO
ALTER TABLE [wade].[D_USE_LOCATION]  WITH NOCHECK ADD  CONSTRAINT [FK_D_USE_LOCATION_DETAIL_USE] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [WATER_USER_ID])
REFERENCES [wade].[DETAIL_USE] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID], [WATER_USER_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[D_USE_LOCATION] CHECK CONSTRAINT [FK_D_USE_LOCATION_DETAIL_USE]
GO
ALTER TABLE [wade].[D_USE_LOCATION]  WITH CHECK ADD  CONSTRAINT [FK_D_USE_LOCATION_LU_STATE] FOREIGN KEY([STATE])
REFERENCES [wade].[LU_STATE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[D_USE_LOCATION] CHECK CONSTRAINT [FK_D_USE_LOCATION_LU_STATE]
GO
ALTER TABLE [wade].[DETAIL_ALLOCATION]  WITH CHECK ADD  CONSTRAINT [FK_DETAIL_ALLOCATION_LU_LEGAL_STATUS] FOREIGN KEY([LEGAL_STATUS])
REFERENCES [wade].[LU_LEGAL_STATUS] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[DETAIL_ALLOCATION] CHECK CONSTRAINT [FK_DETAIL_ALLOCATION_LU_LEGAL_STATUS]
GO
ALTER TABLE [wade].[DETAIL_ALLOCATION]  WITH CHECK ADD  CONSTRAINT [FK_DETAIL_ALLOCATION_REPORT] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID])
REFERENCES [wade].[REPORT] ([ORGANIZATION_ID], [REPORT_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[DETAIL_ALLOCATION] CHECK CONSTRAINT [FK_DETAIL_ALLOCATION_REPORT]
GO
ALTER TABLE [wade].[DETAIL_DIVERSION]  WITH NOCHECK ADD  CONSTRAINT [FK_DETAIL_DIVERSION_DETAIL_ALLOCATION] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID])
REFERENCES [wade].[DETAIL_ALLOCATION] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[DETAIL_DIVERSION] CHECK CONSTRAINT [FK_DETAIL_DIVERSION_DETAIL_ALLOCATION]
GO
ALTER TABLE [wade].[DETAIL_DIVERSION]  WITH CHECK ADD  CONSTRAINT [FK_DETAIL_DIVERSION_LU_STATE] FOREIGN KEY([STATE])
REFERENCES [wade].[LU_STATE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[DETAIL_DIVERSION] CHECK CONSTRAINT [FK_DETAIL_DIVERSION_LU_STATE]
GO
ALTER TABLE [wade].[DETAIL_RETURN_FLOW]  WITH CHECK ADD  CONSTRAINT [FK_DETAIL_RETURN_FLOW_DETAIL_ALLOCATION] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID])
REFERENCES [wade].[DETAIL_ALLOCATION] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[DETAIL_RETURN_FLOW] CHECK CONSTRAINT [FK_DETAIL_RETURN_FLOW_DETAIL_ALLOCATION]
GO
ALTER TABLE [wade].[DETAIL_RETURN_FLOW]  WITH CHECK ADD  CONSTRAINT [FK_DETAIL_RETURN_FLOW_LU_STATE] FOREIGN KEY([STATE])
REFERENCES [wade].[LU_STATE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[DETAIL_RETURN_FLOW] CHECK CONSTRAINT [FK_DETAIL_RETURN_FLOW_LU_STATE]
GO
ALTER TABLE [wade].[DETAIL_USE]  WITH NOCHECK ADD  CONSTRAINT [FK_DETAIL_USE_DETAIL_ALLOCATION] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID])
REFERENCES [wade].[DETAIL_ALLOCATION] ([ORGANIZATION_ID], [REPORT_ID], [ALLOCATION_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[DETAIL_USE] CHECK CONSTRAINT [FK_DETAIL_USE_DETAIL_ALLOCATION]
GO
ALTER TABLE [wade].[GEOSPATIAL_REF]  WITH NOCHECK ADD  CONSTRAINT [FK_GEOSPATIAL_REF_REPORT] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID])
REFERENCES [wade].[REPORT] ([ORGANIZATION_ID], [REPORT_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[GEOSPATIAL_REF] CHECK CONSTRAINT [FK_GEOSPATIAL_REF_REPORT]
GO
ALTER TABLE [wade].[METHODS]  WITH CHECK ADD  CONSTRAINT [FK_METHODS_DATA_SOURCES] FOREIGN KEY([SOURCE_ID])
REFERENCES [wade].[DATA_SOURCES] ([SOURCE_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[METHODS] CHECK CONSTRAINT [FK_METHODS_DATA_SOURCES]
GO
ALTER TABLE [wade].[REPORT]  WITH NOCHECK ADD  CONSTRAINT [FK_REPORT_ORGANIZATION] FOREIGN KEY([ORGANIZATION_ID])
REFERENCES [wade].[ORGANIZATION] ([ORGANIZATION_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[REPORT] CHECK CONSTRAINT [FK_REPORT_ORGANIZATION]
GO
ALTER TABLE [wade].[REPORTING_UNIT]  WITH CHECK ADD  CONSTRAINT [FK_REPORTING_UNIT_LU_STATE] FOREIGN KEY([STATE])
REFERENCES [wade].[LU_STATE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[REPORTING_UNIT] CHECK CONSTRAINT [FK_REPORTING_UNIT_LU_STATE]
GO
ALTER TABLE [wade].[REPORTING_UNIT]  WITH NOCHECK ADD  CONSTRAINT [FK_REPORTING_UNIT_REPORT] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID])
REFERENCES [wade].[REPORT] ([ORGANIZATION_ID], [REPORT_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[REPORTING_UNIT] CHECK CONSTRAINT [FK_REPORTING_UNIT_REPORT]
GO
ALTER TABLE [wade].[S_ALLOCATION_IRRIGATION]  WITH CHECK ADD  CONSTRAINT [FK_S_ALLOCATION_IRRIGATION_LU_CROP_TYPE] FOREIGN KEY([CROP_TYPE])
REFERENCES [wade].[LU_CROP_TYPE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[S_ALLOCATION_IRRIGATION] CHECK CONSTRAINT [FK_S_ALLOCATION_IRRIGATION_LU_CROP_TYPE]
GO
ALTER TABLE [wade].[S_ALLOCATION_IRRIGATION]  WITH CHECK ADD  CONSTRAINT [FK_S_ALLOCATION_IRRIGATION_LU_IRRIGATION_METHOD] FOREIGN KEY([IRRIGATION_METHOD])
REFERENCES [wade].[LU_IRRIGATION_METHOD] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[S_ALLOCATION_IRRIGATION] CHECK CONSTRAINT [FK_S_ALLOCATION_IRRIGATION_LU_IRRIGATION_METHOD]
GO
ALTER TABLE [wade].[S_ALLOCATION_IRRIGATION]  WITH CHECK ADD  CONSTRAINT [FK_S_ALLOCATION_IRRIGATION_SUMMARY_ALLOCATION] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID], [SUMMARY_SEQ])
REFERENCES [wade].[SUMMARY_ALLOCATION] ([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID], [SUMMARY_SEQ])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[S_ALLOCATION_IRRIGATION] CHECK CONSTRAINT [FK_S_ALLOCATION_IRRIGATION_SUMMARY_ALLOCATION]
GO
ALTER TABLE [wade].[S_AVAILABILITY_AMOUNT]  WITH CHECK ADD  CONSTRAINT [FK_S_AVAILABILITY_AMOUNT_METHODS] FOREIGN KEY([METHOD_ID])
REFERENCES [wade].[METHODS] ([METHOD_ID])
GO
ALTER TABLE [wade].[S_AVAILABILITY_AMOUNT] CHECK CONSTRAINT [FK_S_AVAILABILITY_AMOUNT_METHODS]
GO
ALTER TABLE [wade].[S_AVAILABILITY_AMOUNT]  WITH NOCHECK ADD  CONSTRAINT [FK_S_AVAILABILITY_AMOUNT_SUMMARY_AVAILABILITY] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID], [SUMMARY_SEQ])
REFERENCES [wade].[SUMMARY_AVAILABILITY] ([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID], [SUMMARY_SEQ])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[S_AVAILABILITY_AMOUNT] CHECK CONSTRAINT [FK_S_AVAILABILITY_AMOUNT_SUMMARY_AVAILABILITY]
GO
ALTER TABLE [wade].[S_AVAILABILITY_METRIC]  WITH CHECK ADD  CONSTRAINT [FK_S_AVAILABILITY_METRIC_METHODS] FOREIGN KEY([METHOD_ID])
REFERENCES [wade].[METHODS] ([METHOD_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[S_AVAILABILITY_METRIC] CHECK CONSTRAINT [FK_S_AVAILABILITY_METRIC_METHODS]
GO
ALTER TABLE [wade].[S_AVAILABILITY_METRIC]  WITH CHECK ADD  CONSTRAINT [FK_S_AVAILABILITY_METRIC_METRICS] FOREIGN KEY([METRIC_ID])
REFERENCES [wade].[METRICS] ([METRIC_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[S_AVAILABILITY_METRIC] CHECK CONSTRAINT [FK_S_AVAILABILITY_METRIC_METRICS]
GO
ALTER TABLE [wade].[S_AVAILABILITY_METRIC]  WITH NOCHECK ADD  CONSTRAINT [FK_S_AVAILABILITY_METRIC_SUMMARY_AVAILABILITY] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID], [SUMMARY_SEQ])
REFERENCES [wade].[SUMMARY_AVAILABILITY] ([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID], [SUMMARY_SEQ])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[S_AVAILABILITY_METRIC] CHECK CONSTRAINT [FK_S_AVAILABILITY_METRIC_SUMMARY_AVAILABILITY]
GO
ALTER TABLE [wade].[S_USE_AMOUNT]  WITH CHECK ADD  CONSTRAINT [FK_S_USE_AMOUNT_METHODS] FOREIGN KEY([METHOD_ID])
REFERENCES [wade].[METHODS] ([METHOD_ID])
GO
ALTER TABLE [wade].[S_USE_AMOUNT] CHECK CONSTRAINT [FK_S_USE_AMOUNT_METHODS]
GO
ALTER TABLE [wade].[S_USE_AMOUNT]  WITH CHECK ADD  CONSTRAINT [FK_S_USE_AMOUNT_SUMMARY_USE] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID], [SUMMARY_SEQ], [BENEFICIAL_USE_ID])
REFERENCES [wade].[SUMMARY_USE] ([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID], [SUMMARY_SEQ], [BENEFICIAL_USE_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[S_USE_AMOUNT] CHECK CONSTRAINT [FK_S_USE_AMOUNT_SUMMARY_USE]
GO
ALTER TABLE [wade].[S_USE_IRRIGATION]  WITH CHECK ADD  CONSTRAINT [FK_S_USE_IRRIGATION_LU_CROP_TYPE] FOREIGN KEY([CROP_TYPE])
REFERENCES [wade].[LU_CROP_TYPE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[S_USE_IRRIGATION] CHECK CONSTRAINT [FK_S_USE_IRRIGATION_LU_CROP_TYPE]
GO
ALTER TABLE [wade].[S_USE_IRRIGATION]  WITH CHECK ADD  CONSTRAINT [FK_S_USE_IRRIGATION_LU_IRRIGATION_METHOD] FOREIGN KEY([IRRIGATION_METHOD])
REFERENCES [wade].[LU_IRRIGATION_METHOD] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[S_USE_IRRIGATION] CHECK CONSTRAINT [FK_S_USE_IRRIGATION_LU_IRRIGATION_METHOD]
GO
ALTER TABLE [wade].[S_USE_IRRIGATION]  WITH NOCHECK ADD  CONSTRAINT [FK_S_USE_IRRIGATION_SUMMARY_USE] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID], [SUMMARY_SEQ], [BENEFICIAL_USE_ID])
REFERENCES [wade].[SUMMARY_USE] ([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID], [SUMMARY_SEQ], [BENEFICIAL_USE_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[S_USE_IRRIGATION] CHECK CONSTRAINT [FK_S_USE_IRRIGATION_SUMMARY_USE]
GO
ALTER TABLE [wade].[S_WATER_SUPPLY_AMOUNT]  WITH CHECK ADD  CONSTRAINT [FK_S_WATER_SUPPLY_AMOUNT_METHODS] FOREIGN KEY([METHOD_ID])
REFERENCES [wade].[METHODS] ([METHOD_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[S_WATER_SUPPLY_AMOUNT] CHECK CONSTRAINT [FK_S_WATER_SUPPLY_AMOUNT_METHODS]
GO
ALTER TABLE [wade].[S_WATER_SUPPLY_AMOUNT]  WITH CHECK ADD  CONSTRAINT [FK_S_WATER_SUPPLY_AMOUNT_SUMMARY_WATER_SUPPLY] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID], [SUMMARY_SEQ])
REFERENCES [wade].[SUMMARY_WATER_SUPPLY] ([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID], [SUMMARY_SEQ])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[S_WATER_SUPPLY_AMOUNT] CHECK CONSTRAINT [FK_S_WATER_SUPPLY_AMOUNT_SUMMARY_WATER_SUPPLY]
GO
ALTER TABLE [wade].[SUMMARY_ALLOCATION]  WITH CHECK ADD  CONSTRAINT [FK_SUMMARY_ALLOCATION_LU_BENEFICIAL_USE] FOREIGN KEY([BENEFICIAL_USE_ID])
REFERENCES [wade].[LU_BENEFICIAL_USE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[SUMMARY_ALLOCATION] CHECK CONSTRAINT [FK_SUMMARY_ALLOCATION_LU_BENEFICIAL_USE]
GO
ALTER TABLE [wade].[SUMMARY_ALLOCATION]  WITH CHECK ADD  CONSTRAINT [FK_SUMMARY_ALLOCATION_LU_FRESH_SALINE_INDICATOR] FOREIGN KEY([FRESH_SALINE_IND])
REFERENCES [wade].[LU_FRESH_SALINE_INDICATOR] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[SUMMARY_ALLOCATION] CHECK CONSTRAINT [FK_SUMMARY_ALLOCATION_LU_FRESH_SALINE_INDICATOR]
GO
ALTER TABLE [wade].[SUMMARY_ALLOCATION]  WITH CHECK ADD  CONSTRAINT [FK_SUMMARY_ALLOCATION_LU_SOURCE_TYPE] FOREIGN KEY([SOURCE_TYPE])
REFERENCES [wade].[LU_SOURCE_TYPE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[SUMMARY_ALLOCATION] CHECK CONSTRAINT [FK_SUMMARY_ALLOCATION_LU_SOURCE_TYPE]
GO
ALTER TABLE [wade].[SUMMARY_ALLOCATION]  WITH CHECK ADD  CONSTRAINT [FK_SUMMARY_ALLOCATION_REPORTING_UNIT] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID])
REFERENCES [wade].[REPORTING_UNIT] ([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[SUMMARY_ALLOCATION] CHECK CONSTRAINT [FK_SUMMARY_ALLOCATION_REPORTING_UNIT]
GO
ALTER TABLE [wade].[SUMMARY_AVAILABILITY]  WITH CHECK ADD  CONSTRAINT [FK_SUMMARY_AVAILABILITY_LU_FRESH_SALINE_INDICATOR] FOREIGN KEY([FRESH_SALINE_IND])
REFERENCES [wade].[LU_FRESH_SALINE_INDICATOR] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[SUMMARY_AVAILABILITY] CHECK CONSTRAINT [FK_SUMMARY_AVAILABILITY_LU_FRESH_SALINE_INDICATOR]
GO
ALTER TABLE [wade].[SUMMARY_AVAILABILITY]  WITH CHECK ADD  CONSTRAINT [FK_SUMMARY_AVAILABILITY_LU_SOURCE_TYPE] FOREIGN KEY([SOURCE_TYPE])
REFERENCES [wade].[LU_SOURCE_TYPE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[SUMMARY_AVAILABILITY] CHECK CONSTRAINT [FK_SUMMARY_AVAILABILITY_LU_SOURCE_TYPE]
GO
ALTER TABLE [wade].[SUMMARY_AVAILABILITY]  WITH NOCHECK ADD  CONSTRAINT [FK_SUMMARY_AVAILABILITY_REPORTING_UNIT] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID])
REFERENCES [wade].[REPORTING_UNIT] ([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[SUMMARY_AVAILABILITY] CHECK CONSTRAINT [FK_SUMMARY_AVAILABILITY_REPORTING_UNIT]
GO
ALTER TABLE [wade].[SUMMARY_REGULATORY]  WITH CHECK ADD  CONSTRAINT [FK_REGULATORY_SUMMARY_REPORTING_UNIT] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID])
REFERENCES [wade].[REPORTING_UNIT] ([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[SUMMARY_REGULATORY] CHECK CONSTRAINT [FK_REGULATORY_SUMMARY_REPORTING_UNIT]
GO
ALTER TABLE [wade].[SUMMARY_REGULATORY]  WITH CHECK ADD  CONSTRAINT [FK_SUMMARY_REGULATORY_LU_REGULATORY_STATUS] FOREIGN KEY([REGULATORY_STATUS])
REFERENCES [wade].[LU_REGULATORY_STATUS] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[SUMMARY_REGULATORY] CHECK CONSTRAINT [FK_SUMMARY_REGULATORY_LU_REGULATORY_STATUS]
GO
ALTER TABLE [wade].[SUMMARY_USE]  WITH CHECK ADD  CONSTRAINT [FK_SUMMARY_USE_LU_BENEFICIAL_USE] FOREIGN KEY([BENEFICIAL_USE_ID])
REFERENCES [wade].[LU_BENEFICIAL_USE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[SUMMARY_USE] CHECK CONSTRAINT [FK_SUMMARY_USE_LU_BENEFICIAL_USE]
GO
ALTER TABLE [wade].[SUMMARY_USE]  WITH CHECK ADD  CONSTRAINT [FK_SUMMARY_USE_LU_FRESH_SALINE_INDICATOR] FOREIGN KEY([FRESH_SALINE_IND])
REFERENCES [wade].[LU_FRESH_SALINE_INDICATOR] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[SUMMARY_USE] CHECK CONSTRAINT [FK_SUMMARY_USE_LU_FRESH_SALINE_INDICATOR]
GO
ALTER TABLE [wade].[SUMMARY_USE]  WITH CHECK ADD  CONSTRAINT [FK_SUMMARY_USE_LU_SOURCE_TYPE] FOREIGN KEY([SOURCE_TYPE])
REFERENCES [wade].[LU_SOURCE_TYPE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[SUMMARY_USE] CHECK CONSTRAINT [FK_SUMMARY_USE_LU_SOURCE_TYPE]
GO
ALTER TABLE [wade].[SUMMARY_USE]  WITH NOCHECK ADD  CONSTRAINT [FK_SUMMARY_USE_REPORTING_UNIT] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID])
REFERENCES [wade].[REPORTING_UNIT] ([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[SUMMARY_USE] CHECK CONSTRAINT [FK_SUMMARY_USE_REPORTING_UNIT]
GO
ALTER TABLE [wade].[SUMMARY_WATER_SUPPLY]  WITH CHECK ADD  CONSTRAINT [FK_SUMMARY_WATER_SUPPLY_LU_WATER_SUPPLY_TYPE] FOREIGN KEY([WATER_SUPPLY_TYPE])
REFERENCES [wade].[LU_WATER_SUPPLY_TYPE] ([LU_SEQ_NO])
ON UPDATE CASCADE
GO
ALTER TABLE [wade].[SUMMARY_WATER_SUPPLY] CHECK CONSTRAINT [FK_SUMMARY_WATER_SUPPLY_LU_WATER_SUPPLY_TYPE]
GO
ALTER TABLE [wade].[SUMMARY_WATER_SUPPLY]  WITH NOCHECK ADD  CONSTRAINT [FK_SUMMARY_WATER_SUPPLY_REPORTING_UNIT] FOREIGN KEY([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID])
REFERENCES [wade].[REPORTING_UNIT] ([ORGANIZATION_ID], [REPORT_ID], [REPORT_UNIT_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [wade].[SUMMARY_WATER_SUPPLY] CHECK CONSTRAINT [FK_SUMMARY_WATER_SUPPLY_REPORTING_UNIT]
GO
/****** Object:  StoredProcedure [dbo].[dt_adduserobject]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	Add an object to the dtproperties table
*/
create procedure [dbo].[dt_adduserobject]
as
	set nocount on
	/*
	** Create the user object if it does not exist already
	*/
	begin transaction
		insert dbo.dtproperties (property) VALUES ('DtgSchemaOBJECT')
		update dbo.dtproperties set objectid=@@identity 
			where id=@@identity and property='DtgSchemaOBJECT'
	commit
	return @@identity

GO
/****** Object:  StoredProcedure [dbo].[dt_droppropertiesbyid]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	Drop one or all the associated properties of an object or an attribute 
**
**	dt_dropproperties objid, null or '' -- drop all properties of the object itself
**	dt_dropproperties objid, property -- drop the property
*/
create procedure [dbo].[dt_droppropertiesbyid]
	@id int,
	@property varchar(64)
as
	set nocount on

	if (@property is null) or (@property = '')
		delete from dbo.dtproperties where objectid=@id
	else
		delete from dbo.dtproperties 
			where objectid=@id and property=@property


GO
/****** Object:  StoredProcedure [dbo].[dt_dropuserobjectbyid]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	Drop an object from the dbo.dtproperties table
*/
create procedure [dbo].[dt_dropuserobjectbyid]
	@id int
as
	set nocount on
	delete from dbo.dtproperties where objectid=@id

GO
/****** Object:  StoredProcedure [dbo].[dt_generateansiname]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
**	Generate an ansi name that is unique in the dtproperties.value column 
*/ 
create procedure [dbo].[dt_generateansiname](@name varchar(255) output) 
as 
	declare @prologue varchar(20) 
	declare @indexstring varchar(20) 
	declare @index integer 
 
	set @prologue = 'MSDT-A-' 
	set @index = 1 
 
	while 1 = 1 
	begin 
		set @indexstring = cast(@index as varchar(20)) 
		set @name = @prologue + @indexstring 
		if not exists (select value from dtproperties where value = @name) 
			break 
		 
		set @index = @index + 1 
 
		if (@index = 10000) 
			goto TooMany 
	end 
 
Leave: 
 
	return 
 
TooMany: 
 
	set @name = 'DIAGRAM' 
	goto Leave 

GO
/****** Object:  StoredProcedure [dbo].[dt_getobjwithprop]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	Retrieve the owner object(s) of a given property
*/
create procedure [dbo].[dt_getobjwithprop]
	@property varchar(30),
	@value varchar(255)
as
	set nocount on

	if (@property is null) or (@property = '')
	begin
		raiserror('Must specify a property name.',-1,-1)
		return (1)
	end

	if (@value is null)
		select objectid id from dbo.dtproperties
			where property=@property

	else
		select objectid id from dbo.dtproperties
			where property=@property and value=@value

GO
/****** Object:  StoredProcedure [dbo].[dt_getobjwithprop_u]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	Retrieve the owner object(s) of a given property
*/
create procedure [dbo].[dt_getobjwithprop_u]
	@property varchar(30),
	@uvalue nvarchar(255)
as
	set nocount on

	if (@property is null) or (@property = '')
	begin
		raiserror('Must specify a property name.',-1,-1)
		return (1)
	end

	if (@uvalue is null)
		select objectid id from dbo.dtproperties
			where property=@property

	else
		select objectid id from dbo.dtproperties
			where property=@property and uvalue=@uvalue

GO
/****** Object:  StoredProcedure [dbo].[dt_getpropertiesbyid]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	Retrieve properties by id's
**
**	dt_getproperties objid, null or '' -- retrieve all properties of the object itself
**	dt_getproperties objid, property -- retrieve the property specified
*/
create procedure [dbo].[dt_getpropertiesbyid]
	@id int,
	@property varchar(64)
as
	set nocount on

	if (@property is null) or (@property = '')
		select property, version, value, lvalue
			from dbo.dtproperties
			where  @id=objectid
	else
		select property, version, value, lvalue
			from dbo.dtproperties
			where  @id=objectid and @property=property

GO
/****** Object:  StoredProcedure [dbo].[dt_getpropertiesbyid_u]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	Retrieve properties by id's
**
**	dt_getproperties objid, null or '' -- retrieve all properties of the object itself
**	dt_getproperties objid, property -- retrieve the property specified
*/
create procedure [dbo].[dt_getpropertiesbyid_u]
	@id int,
	@property varchar(64)
as
	set nocount on

	if (@property is null) or (@property = '')
		select property, version, uvalue, lvalue
			from dbo.dtproperties
			where  @id=objectid
	else
		select property, version, uvalue, lvalue
			from dbo.dtproperties
			where  @id=objectid and @property=property

GO
/****** Object:  StoredProcedure [dbo].[dt_setpropertybyid]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	If the property already exists, reset the value; otherwise add property
**		id -- the id in sysobjects of the object
**		property -- the name of the property
**		value -- the text value of the property
**		lvalue -- the binary value of the property (image)
*/
create procedure [dbo].[dt_setpropertybyid]
	@id int,
	@property varchar(64),
	@value varchar(255),
	@lvalue image
as
	set nocount on
	declare @uvalue nvarchar(255) 
	set @uvalue = convert(nvarchar(255), @value) 
	if exists (select * from dbo.dtproperties 
			where objectid=@id and property=@property)
	begin
		--
		-- bump the version count for this row as we update it
		--
		update dbo.dtproperties set value=@value, uvalue=@uvalue, lvalue=@lvalue, version=version+1
			where objectid=@id and property=@property
	end
	else
	begin
		--
		-- version count is auto-set to 0 on initial insert
		--
		insert dbo.dtproperties (property, objectid, value, uvalue, lvalue)
			values (@property, @id, @value, @uvalue, @lvalue)
	end


GO
/****** Object:  StoredProcedure [dbo].[dt_setpropertybyid_u]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	If the property already exists, reset the value; otherwise add property
**		id -- the id in sysobjects of the object
**		property -- the name of the property
**		uvalue -- the text value of the property
**		lvalue -- the binary value of the property (image)
*/
create procedure [dbo].[dt_setpropertybyid_u]
	@id int,
	@property varchar(64),
	@uvalue nvarchar(255),
	@lvalue image
as
	set nocount on
	-- 
	-- If we are writing the name property, find the ansi equivalent. 
	-- If there is no lossless translation, generate an ansi name. 
	-- 
	declare @avalue varchar(255) 
	set @avalue = null 
	if (@uvalue is not null) 
	begin 
		if (convert(nvarchar(255), convert(varchar(255), @uvalue)) = @uvalue) 
		begin 
			set @avalue = convert(varchar(255), @uvalue) 
		end 
		else 
		begin 
			if 'DtgSchemaNAME' = @property 
			begin 
				exec dbo.dt_generateansiname @avalue output 
			end 
		end 
	end 
	if exists (select * from dbo.dtproperties 
			where objectid=@id and property=@property)
	begin
		--
		-- bump the version count for this row as we update it
		--
		update dbo.dtproperties set value=@avalue, uvalue=@uvalue, lvalue=@lvalue, version=version+1
			where objectid=@id and property=@property
	end
	else
	begin
		--
		-- version count is auto-set to 0 on initial insert
		--
		insert dbo.dtproperties (property, objectid, value, uvalue, lvalue)
			values (@property, @id, @avalue, @uvalue, @lvalue)
	end

GO
/****** Object:  StoredProcedure [dbo].[dt_verstamp006]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	This procedure returns the version number of the stored
**    procedures used by legacy versions of the Microsoft
**	Visual Database Tools.  Version is 7.0.00.
*/
create procedure [dbo].[dt_verstamp006]
as
	select 7000

GO
/****** Object:  StoredProcedure [dbo].[dt_verstamp007]    Script Date: 5/2/2017 2:54:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
**	This procedure returns the version number of the stored
**    procedures used by the the Microsoft Visual Database Tools.
**	Version is 7.0.05.
*/
create procedure [dbo].[dt_verstamp007]
as
	select 7005

GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_ACTUAL', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifer for the report assigned by the reporting organziation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_ACTUAL', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifer for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_ACTUAL', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the detail information.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_ACTUAL', @level2type=N'COLUMN',@level2name=N'DETAIL_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Volume of water allocated for this use to this allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_ACTUAL', @level2type=N'COLUMN',@level2name=N'AMOUNT_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Volume unit of measure' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_ACTUAL', @level2type=N'COLUMN',@level2name=N'UNIT_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Indicator on how the actual amount was determied' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_ACTUAL', @level2type=N'COLUMN',@level2name=N'VALUE_TYPE_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'ID rerferencing the method used to estimate the volume' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_ACTUAL', @level2type=N'COLUMN',@level2name=N'METHOD_ID_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Rate of use allocated for this beneficial use.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_ACTUAL', @level2type=N'COLUMN',@level2name=N'AMOUNT_RATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unit of measure.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_ACTUAL', @level2type=N'COLUMN',@level2name=N'UNIT_RATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Indicator on how the actual amount was determied' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_ACTUAL', @level2type=N'COLUMN',@level2name=N'VALUE_TYPE_RATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'ID rerferencing the method used to estimate the rate' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_ACTUAL', @level2type=N'COLUMN',@level2name=N'METHOD_ID_RATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Starting date for the allcoation (in MM/DD).' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_ACTUAL', @level2type=N'COLUMN',@level2name=N'START_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Allocation end date as MM/DD.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_ACTUAL', @level2type=N'COLUMN',@level2name=N'END_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_FLOW', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifer for the report assigned by the reporting organziation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_FLOW', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifer for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_FLOW', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the detail information.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_FLOW', @level2type=N'COLUMN',@level2name=N'DETAIL_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Volume of water allocated for this use to this allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_FLOW', @level2type=N'COLUMN',@level2name=N'AMOUNT_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Volume unit of measure' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_FLOW', @level2type=N'COLUMN',@level2name=N'UNIT_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Rate of use allocated for this beneficial use.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_FLOW', @level2type=N'COLUMN',@level2name=N'AMOUNT_RATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unit of measure.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_FLOW', @level2type=N'COLUMN',@level2name=N'UNIT_RATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Water source: ground, surface, reuse, total.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_FLOW', @level2type=N'COLUMN',@level2name=N'SOURCE_TYPE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Indicates whether the source is fresh water, saline water, or represents the total of both.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_FLOW', @level2type=N'COLUMN',@level2name=N'FRESH_SALINE_IND'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Starting date for the allcoation (in MM/DD).' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_FLOW', @level2type=N'COLUMN',@level2name=N'ALLOCATION_START'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Allocation end date as MM/DD.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_FLOW', @level2type=N'COLUMN',@level2name=N'ALLOCATION_END'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Name of the aquifer for groundwater sources or river basin for surface water sources.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_FLOW', @level2type=N'COLUMN',@level2name=N'SOURCE_NAME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_LOCATION', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_LOCATION', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_LOCATION', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the location.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_LOCATION', @level2type=N'COLUMN',@level2name=N'LOCATION_SEQ'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Code representing the 2-digit abbreviation for the state.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_LOCATION', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned tot he reporting unit by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_LOCATION', @level2type=N'COLUMN',@level2name=N'REPORTING_UNIT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'County FIPS code (including the state FIPS code) representing the county.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_LOCATION', @level2type=N'COLUMN',@level2name=N'COUNTY_FIPS'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N' A unique identifier assigned to the organziation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_USE', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organziation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_USE', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_USE', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier identifying the beneficial use.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_ALLOCATION_USE', @level2type=N'COLUMN',@level2name=N'BENEFICIAL_USE_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_COMMUNITY_WATER_SUPPLY', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_COMMUNITY_WATER_SUPPLY', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_COMMUNITY_WATER_SUPPLY', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the water user.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_COMMUNITY_WATER_SUPPLY', @level2type=N'COLUMN',@level2name=N'WATER_USER_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the beneficial use.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_COMMUNITY_WATER_SUPPLY', @level2type=N'COLUMN',@level2name=N'BENEFICIAL_USE_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the reported information.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_COMMUNITY_WATER_SUPPLY', @level2type=N'COLUMN',@level2name=N'DETAIL_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Population served by the community water supply' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_COMMUNITY_WATER_SUPPLY', @level2type=N'COLUMN',@level2name=N'POPULATION_SERVED'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Name of the community.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_COMMUNITY_WATER_SUPPLY', @level2type=N'COLUMN',@level2name=N'WATER_SUPPLY_NAME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N' A unique identifier assigned to the organziation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_CONSUMPTIVE_USE', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organziation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_CONSUMPTIVE_USE', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_CONSUMPTIVE_USE', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the water user.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_CONSUMPTIVE_USE', @level2type=N'COLUMN',@level2name=N'WATER_USER_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier identifying the beneficial use.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_CONSUMPTIVE_USE', @level2type=N'COLUMN',@level2name=N'BENEFICIAL_USE_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_ACTUAL', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the report assigned by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_ACTUAL', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_ACTUAL', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the detail information.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_ACTUAL', @level2type=N'COLUMN',@level2name=N'DETAIL_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Volume of water actually diverted at this diversion.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_ACTUAL', @level2type=N'COLUMN',@level2name=N'AMOUNT_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Volume unit of measure' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_ACTUAL', @level2type=N'COLUMN',@level2name=N'UNIT_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Indicator on how the actual amount was determined' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_ACTUAL', @level2type=N'COLUMN',@level2name=N'VALUE_TYPE_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'ID referencing the method used to estimate the volume' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_ACTUAL', @level2type=N'COLUMN',@level2name=N'METHOD_ID_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Rate of water actually diverted at this diversion.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_ACTUAL', @level2type=N'COLUMN',@level2name=N'AMOUNT_RATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unit of measure.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_ACTUAL', @level2type=N'COLUMN',@level2name=N'UNIT_RATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Indicator on how the actual amount was determined' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_ACTUAL', @level2type=N'COLUMN',@level2name=N'VALUE_TYPE_RATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'ID referencing the method used to estimate the rate' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_ACTUAL', @level2type=N'COLUMN',@level2name=N'METHOD_ID_RATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Starting date for the amount (in MM/DD).' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_ACTUAL', @level2type=N'COLUMN',@level2name=N'START_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Ending date for the amount as MM/DD.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_ACTUAL', @level2type=N'COLUMN',@level2name=N'END_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_FLOW', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the report assigned by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_FLOW', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N' A unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_USE', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_USE', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_USE', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the diversion.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_USE', @level2type=N'COLUMN',@level2name=N'DIVERSION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier identifying the beneficial use.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_DIVERSION_USE', @level2type=N'COLUMN',@level2name=N'BENEFICIAL_USE_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_IRRIGATION', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_IRRIGATION', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_IRRIGATION', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the water user.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_IRRIGATION', @level2type=N'COLUMN',@level2name=N'WATER_USER_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the beneficial use.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_IRRIGATION', @level2type=N'COLUMN',@level2name=N'BENEFICIAL_USE_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the reported information.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_IRRIGATION', @level2type=N'COLUMN',@level2name=N'DETAIL_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Name of the method used to irrigate (i.e. sprinkler, flood, microirrigation, etc.)' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_IRRIGATION', @level2type=N'COLUMN',@level2name=N'IRRIGATION_METHOD'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Number of acres irrigated.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_IRRIGATION', @level2type=N'COLUMN',@level2name=N'ACRES_IRRIGATED'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Crop type being irrigated' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_IRRIGATION', @level2type=N'COLUMN',@level2name=N'CROP_TYPE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_RETURN_FLOW_ACTUAL', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the report assigned by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_RETURN_FLOW_ACTUAL', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_RETURN_FLOW_ACTUAL', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the return flow' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_RETURN_FLOW_ACTUAL', @level2type=N'COLUMN',@level2name=N'RETURN_FLOW_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Volume of water allocated for this use to this allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_RETURN_FLOW_ACTUAL', @level2type=N'COLUMN',@level2name=N'AMOUNT_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Volume unit of measure' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_RETURN_FLOW_ACTUAL', @level2type=N'COLUMN',@level2name=N'UNIT_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Indicator on how the actual amount was determined' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_RETURN_FLOW_ACTUAL', @level2type=N'COLUMN',@level2name=N'VALUE_TYPE_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'ID referencing the method used to estimate the volume' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_RETURN_FLOW_ACTUAL', @level2type=N'COLUMN',@level2name=N'METHOD_ID_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Rate of use allocated for this beneficial use.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_RETURN_FLOW_ACTUAL', @level2type=N'COLUMN',@level2name=N'AMOUNT_RATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unit of measure.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_RETURN_FLOW_ACTUAL', @level2type=N'COLUMN',@level2name=N'UNIT_RATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Indicator on how the actual amount was determined' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_RETURN_FLOW_ACTUAL', @level2type=N'COLUMN',@level2name=N'VALUE_TYPE_RATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'ID referencing the method used to estimate the rate' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_RETURN_FLOW_ACTUAL', @level2type=N'COLUMN',@level2name=N'METHOD_ID_RATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Starting date for the allocation (in MM/DD).' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_RETURN_FLOW_ACTUAL', @level2type=N'COLUMN',@level2name=N'START_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Allocation end date as MM/DD.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_RETURN_FLOW_ACTUAL', @level2type=N'COLUMN',@level2name=N'END_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_THERMOELECTRIC', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_THERMOELECTRIC', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_THERMOELECTRIC', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the water user.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_THERMOELECTRIC', @level2type=N'COLUMN',@level2name=N'WATER_USER_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the beneficial use.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_THERMOELECTRIC', @level2type=N'COLUMN',@level2name=N'BENEFICIAL_USE_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the reported information.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_THERMOELECTRIC', @level2type=N'COLUMN',@level2name=N'DETAIL_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The type of generator used to generate electricity.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_THERMOELECTRIC', @level2type=N'COLUMN',@level2name=N'GENERATOR_TYPE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The amount of power capacity in megawatt hours.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_THERMOELECTRIC', @level2type=N'COLUMN',@level2name=N'POWER_CAPACITY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the report assigned by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for this row of information.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'ROW_SEQ'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Volume of water actually diverted at this diversion.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'AMOUNT_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Volume unit of measure' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'UNIT_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Indicator on how the actual amount was determined' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'VALUE_TYPE_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'ID referencing the method used to estimate the volume' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'METHOD_ID_VOLUME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Starting date for the amount (in MM/DD).' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'START_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Ending date for the amount as MM/DD.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'END_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_LOCATION', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_LOCATION', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_LOCATION', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the water user.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_LOCATION', @level2type=N'COLUMN',@level2name=N'WATER_USER_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the location.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_LOCATION', @level2type=N'COLUMN',@level2name=N'LOCATION_SEQ'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Code representing the 2-digit abbreviation for the state.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_LOCATION', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned tot he reporting unit by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_LOCATION', @level2type=N'COLUMN',@level2name=N'REPORTING_UNIT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'County FIPS code (including the state FIPS code) representing the county.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'D_USE_LOCATION', @level2type=N'COLUMN',@level2name=N'COUNTY_FIPS'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the data source used by a method' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DATA_SOURCES', @level2type=N'COLUMN',@level2name=N'SOURCE_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Context for the data source' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DATA_SOURCES', @level2type=N'COLUMN',@level2name=N'SOURCE_CONTEXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Data Source Name' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DATA_SOURCES', @level2type=N'COLUMN',@level2name=N'SOURCE_NAME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the data source.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DATA_SOURCES', @level2type=N'COLUMN',@level2name=N'SOURCE_DESC'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'State that the Look-up value applies to.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DATA_SOURCES', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Start date for the data source time period' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DATA_SOURCES', @level2type=N'COLUMN',@level2name=N'SOURCE_START_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'End date for the data source time period' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DATA_SOURCES', @level2type=N'COLUMN',@level2name=N'SOURCE_END_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'URL for acquiring more information on the data source' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DATA_SOURCES', @level2type=N'COLUMN',@level2name=N'SOURCE_LINK'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last change date for the look-up.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DATA_SOURCES', @level2type=N'COLUMN',@level2name=N'LAST_CHANGE_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_ALLOCATION', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organziation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_ALLOCATION', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_ALLOCATION', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Name of the entity with the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_ALLOCATION', @level2type=N'COLUMN',@level2name=N'ALLOCATION_OWNER'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The date on which the water right was applied for.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_ALLOCATION', @level2type=N'COLUMN',@level2name=N'APPLICATION_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The priority date for the water right.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_ALLOCATION', @level2type=N'COLUMN',@level2name=N'PRIORITY_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The legal status of the water right (i.e. is it a proven right, perfected, or being adjudicated, etc.)' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_ALLOCATION', @level2type=N'COLUMN',@level2name=N'LEGAL_STATUS'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_DIVERSION', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organziation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_DIVERSION', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_DIVERSION', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the diversion.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_DIVERSION', @level2type=N'COLUMN',@level2name=N'DIVERSION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Name of the diversion.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_DIVERSION', @level2type=N'COLUMN',@level2name=N'DIVERSION_NAME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Code representing the 2-digit abbreviation for the state.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_DIVERSION', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned tot he reporting unit by the reporting 

organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_DIVERSION', @level2type=N'COLUMN',@level2name=N'REPORTING_UNIT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'County FIPS code (including the state FIPS code) representing the county.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_DIVERSION', @level2type=N'COLUMN',@level2name=N'COUNTY_FIPS'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_RETURN_FLOW', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the report assigned by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_RETURN_FLOW', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_RETURN_FLOW', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the return flow' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_RETURN_FLOW', @level2type=N'COLUMN',@level2name=N'RETURN_FLOW_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Name for the return flow.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_RETURN_FLOW', @level2type=N'COLUMN',@level2name=N'RETURN_FLOW_NAME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Code representing the two-digit abbreviation for the state.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_RETURN_FLOW', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the reporting unit by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_RETURN_FLOW', @level2type=N'COLUMN',@level2name=N'REPORTING_UNIT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'County FIPS code ( including the state FIPS code) representing the county.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_RETURN_FLOW', @level2type=N'COLUMN',@level2name=N'COUNTY_FIPS'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_USE', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_USE', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the allocation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_USE', @level2type=N'COLUMN',@level2name=N'ALLOCATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the water user.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_USE', @level2type=N'COLUMN',@level2name=N'WATER_USER_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The name of the water user.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'DETAIL_USE', @level2type=N'COLUMN',@level2name=N'WATER_USER_NAME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'GEOSPATIAL_REF', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the report by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'GEOSPATIAL_REF', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the web feature service by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'GEOSPATIAL_REF', @level2type=N'COLUMN',@level2name=N'WFS_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The data category (SUMMARY or DETAIL) of web feature service layer added by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'GEOSPATIAL_REF', @level2type=N'COLUMN',@level2name=N'WFS_DATACATEGORY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The data type(AVAILABILITY, SUPPLY, USE, REGULATORY, ALLOCATION, DIVERSION, or RETURN) of web feature service layer added by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'GEOSPATIAL_REF', @level2type=N'COLUMN',@level2name=N'WFS_DATATYPE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The URL address of the web feature service layer added by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'GEOSPATIAL_REF', @level2type=N'COLUMN',@level2name=N'WFS_ADDRESS'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The field or column that references the unique feature ID of the web feature service layer added by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'GEOSPATIAL_REF', @level2type=N'COLUMN',@level2name=N'WFS_FEATURE_ID_FIELD'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the Look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_BENEFICIAL_USE', @level2type=N'COLUMN',@level2name=N'LU_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Context for the lookk-up value' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_BENEFICIAL_USE', @level2type=N'COLUMN',@level2name=N'CONTEXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Look up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_BENEFICIAL_USE', @level2type=N'COLUMN',@level2name=N'VALUE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_BENEFICIAL_USE', @level2type=N'COLUMN',@level2name=N'DESCRIPTION'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'State that the Look-up value applies to.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_BENEFICIAL_USE', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last change date for the look-up.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_BENEFICIAL_USE', @level2type=N'COLUMN',@level2name=N'LAST_CHANGE_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the Look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_CROP_TYPE', @level2type=N'COLUMN',@level2name=N'LU_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Context for the lookk-up value' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_CROP_TYPE', @level2type=N'COLUMN',@level2name=N'CONTEXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Look up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_CROP_TYPE', @level2type=N'COLUMN',@level2name=N'VALUE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_CROP_TYPE', @level2type=N'COLUMN',@level2name=N'DESCRIPTION'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'State that the Look-up value applies to.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_CROP_TYPE', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last change date for the look-up.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_CROP_TYPE', @level2type=N'COLUMN',@level2name=N'LAST_CHANGE_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the Look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_FRESH_SALINE_INDICATOR', @level2type=N'COLUMN',@level2name=N'LU_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Context for the lookk-up value' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_FRESH_SALINE_INDICATOR', @level2type=N'COLUMN',@level2name=N'CONTEXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Look up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_FRESH_SALINE_INDICATOR', @level2type=N'COLUMN',@level2name=N'VALUE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_FRESH_SALINE_INDICATOR', @level2type=N'COLUMN',@level2name=N'DESCRIPTION'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'State that the Look-up value applies to.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_FRESH_SALINE_INDICATOR', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last change date for the look-up.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_FRESH_SALINE_INDICATOR', @level2type=N'COLUMN',@level2name=N'LAST_CHANGE_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the Look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_GENERATOR_TYPE', @level2type=N'COLUMN',@level2name=N'LU_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Context for the lookk-up value' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_GENERATOR_TYPE', @level2type=N'COLUMN',@level2name=N'CONTEXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Look up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_GENERATOR_TYPE', @level2type=N'COLUMN',@level2name=N'VALUE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_GENERATOR_TYPE', @level2type=N'COLUMN',@level2name=N'DESCRIPTION'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'State that the Look-up value applies to.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_GENERATOR_TYPE', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last change date for the look-up.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_GENERATOR_TYPE', @level2type=N'COLUMN',@level2name=N'LAST_CHANGE_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the Look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_IRRIGATION_METHOD', @level2type=N'COLUMN',@level2name=N'LU_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Context for the lookk-up value' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_IRRIGATION_METHOD', @level2type=N'COLUMN',@level2name=N'CONTEXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Look up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_IRRIGATION_METHOD', @level2type=N'COLUMN',@level2name=N'VALUE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_IRRIGATION_METHOD', @level2type=N'COLUMN',@level2name=N'DESCRIPTION'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'State that the Look-up value applies to.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_IRRIGATION_METHOD', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last change date for the look-up.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_IRRIGATION_METHOD', @level2type=N'COLUMN',@level2name=N'LAST_CHANGE_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the Look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_LEGAL_STATUS', @level2type=N'COLUMN',@level2name=N'LU_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Context for the lookk-up value' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_LEGAL_STATUS', @level2type=N'COLUMN',@level2name=N'CONTEXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Look up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_LEGAL_STATUS', @level2type=N'COLUMN',@level2name=N'VALUE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_LEGAL_STATUS', @level2type=N'COLUMN',@level2name=N'DESCRIPTION'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'State that the Look-up value applies to.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_LEGAL_STATUS', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last change date for the look-up.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_LEGAL_STATUS', @level2type=N'COLUMN',@level2name=N'LAST_CHANGE_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the Look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_REGULATORY_STATUS', @level2type=N'COLUMN',@level2name=N'LU_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Context for the lookk-up value' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_REGULATORY_STATUS', @level2type=N'COLUMN',@level2name=N'CONTEXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Look up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_REGULATORY_STATUS', @level2type=N'COLUMN',@level2name=N'VALUE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_REGULATORY_STATUS', @level2type=N'COLUMN',@level2name=N'DESCRIPTION'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'State that the Look-up value applies to.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_REGULATORY_STATUS', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last change date for the look-up.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_REGULATORY_STATUS', @level2type=N'COLUMN',@level2name=N'LAST_CHANGE_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the Look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_SOURCE_TYPE', @level2type=N'COLUMN',@level2name=N'LU_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Context for the lookk-up value' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_SOURCE_TYPE', @level2type=N'COLUMN',@level2name=N'CONTEXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Look up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_SOURCE_TYPE', @level2type=N'COLUMN',@level2name=N'VALUE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_SOURCE_TYPE', @level2type=N'COLUMN',@level2name=N'DESCRIPTION'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'State that the Look-up value applies to.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_SOURCE_TYPE', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last change date for the look-up.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_SOURCE_TYPE', @level2type=N'COLUMN',@level2name=N'LAST_CHANGE_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the Look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_STATE', @level2type=N'COLUMN',@level2name=N'LU_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Context for the lookk-up value' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_STATE', @level2type=N'COLUMN',@level2name=N'CONTEXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Look up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_STATE', @level2type=N'COLUMN',@level2name=N'VALUE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_STATE', @level2type=N'COLUMN',@level2name=N'DESCRIPTION'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'State that the Look-up value applies to.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_STATE', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last change date for the look-up.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_STATE', @level2type=N'COLUMN',@level2name=N'LAST_CHANGE_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the Look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_UNITS', @level2type=N'COLUMN',@level2name=N'LU_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Context for the lookk-up value' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_UNITS', @level2type=N'COLUMN',@level2name=N'CONTEXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Look up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_UNITS', @level2type=N'COLUMN',@level2name=N'VALUE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_UNITS', @level2type=N'COLUMN',@level2name=N'DESCRIPTION'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'State that the Look-up value applies to.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_UNITS', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last change date for the look-up.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_UNITS', @level2type=N'COLUMN',@level2name=N'LAST_CHANGE_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the Look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_VALUE_TYPE', @level2type=N'COLUMN',@level2name=N'LU_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Context for the lookk-up value' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_VALUE_TYPE', @level2type=N'COLUMN',@level2name=N'CONTEXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Look up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_VALUE_TYPE', @level2type=N'COLUMN',@level2name=N'VALUE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_VALUE_TYPE', @level2type=N'COLUMN',@level2name=N'DESCRIPTION'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'State that the Look-up value applies to.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_VALUE_TYPE', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last change date for the look-up.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_VALUE_TYPE', @level2type=N'COLUMN',@level2name=N'LAST_CHANGE_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the Look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_WATER_SUPPLY_TYPE', @level2type=N'COLUMN',@level2name=N'LU_SEQ_NO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Context for the lookk-up value' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_WATER_SUPPLY_TYPE', @level2type=N'COLUMN',@level2name=N'CONTEXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Look up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_WATER_SUPPLY_TYPE', @level2type=N'COLUMN',@level2name=N'VALUE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_WATER_SUPPLY_TYPE', @level2type=N'COLUMN',@level2name=N'DESCRIPTION'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'State that the Look-up value applies to.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_WATER_SUPPLY_TYPE', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last change date for the look-up.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'LU_WATER_SUPPLY_TYPE', @level2type=N'COLUMN',@level2name=N'LAST_CHANGE_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the Method' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METHODS', @level2type=N'COLUMN',@level2name=N'METHOD_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Context for the look-up value' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METHODS', @level2type=N'COLUMN',@level2name=N'METHOD_CONTEXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Method Name' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METHODS', @level2type=N'COLUMN',@level2name=N'METHOD_NAME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METHODS', @level2type=N'COLUMN',@level2name=N'METHOD_DESC'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'State that the Look-up value applies to.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METHODS', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date that the method was developed or came into use.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METHODS', @level2type=N'COLUMN',@level2name=N'METHOD_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Describes whether method used for water availability, consumptive use or other.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METHODS', @level2type=N'COLUMN',@level2name=N'METHOD_TYPE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Timescale that the method applies to , daily, weekly, monthly, seasonal, annual' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METHODS', @level2type=N'COLUMN',@level2name=N'TIME_SCALE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'URL for acquiring more information on the method' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METHODS', @level2type=N'COLUMN',@level2name=N'METHOD_LINK'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Key for Data Sources table link' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METHODS', @level2type=N'COLUMN',@level2name=N'SOURCE_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Text describing the water resource type, surface water, groundwater, surface/ground, wastewater reuse' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METHODS', @level2type=N'COLUMN',@level2name=N'RESOURCE_TYPE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Areas for which the method is used, statewide, HUC, aquifer source, basin' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METHODS', @level2type=N'COLUMN',@level2name=N'LOCATION_NAME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last change date for the look-up.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METHODS', @level2type=N'COLUMN',@level2name=N'LAST_CHANGE_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the Look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METRICS', @level2type=N'COLUMN',@level2name=N'METRIC_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Context for the look-up value' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METRICS', @level2type=N'COLUMN',@level2name=N'CONTEXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Look up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METRICS', @level2type=N'COLUMN',@level2name=N'VALUE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the look-up value.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METRICS', @level2type=N'COLUMN',@level2name=N'DESCRIPTION'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'State that the Look-up value applies to.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METRICS', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last change date for the look-up.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'METRICS', @level2type=N'COLUMN',@level2name=N'LAST_CHANGE_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the organziation.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'ORGANIZATION', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Name corresponding to the unique organization ID.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'ORGANIZATION', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_NAME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A description of the perview of the agency (i.e. water rights, consumptive use, planning, etc.)' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'ORGANIZATION', @level2type=N'COLUMN',@level2name=N'PURVUE_DESC'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'First name of the contact person.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'ORGANIZATION', @level2type=N'COLUMN',@level2name=N'FIRST_NAME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'last name of a person' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'ORGANIZATION', @level2type=N'COLUMN',@level2name=N'LAST_NAME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Title of the contact person.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'ORGANIZATION', @level2type=N'COLUMN',@level2name=N'TITLE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'email address' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'ORGANIZATION', @level2type=N'COLUMN',@level2name=N'EMAIL'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Telephone number.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'ORGANIZATION', @level2type=N'COLUMN',@level2name=N'PHONE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Phone number extension.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'ORGANIZATION', @level2type=N'COLUMN',@level2name=N'PHONE_EXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Fax number' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'ORGANIZATION', @level2type=N'COLUMN',@level2name=N'FAX'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Mailing adress' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'ORGANIZATION', @level2type=N'COLUMN',@level2name=N'ADDRESS'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Additional address information.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'ORGANIZATION', @level2type=N'COLUMN',@level2name=N'ADDRESS_EXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'City or locality name.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'ORGANIZATION', @level2type=N'COLUMN',@level2name=N'CITY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'State USPS code (i.e. KS)' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'ORGANIZATION', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Country Code' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'ORGANIZATION', @level2type=N'COLUMN',@level2name=N'COUNTRY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'ZIP CODE' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'ORGANIZATION', @level2type=N'COLUMN',@level2name=N'ZIPCODE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'REPORT', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the report by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'REPORT', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date on which the report was created.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'REPORT', @level2type=N'COLUMN',@level2name=N'REPORTING_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'year for which the report was created.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'REPORT', @level2type=N'COLUMN',@level2name=N'REPORTING_YEAR'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Name of the report' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'REPORT', @level2type=N'COLUMN',@level2name=N'REPORT_NAME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Link to the PDF or web page for teh narrative report that contains the information.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'REPORT', @level2type=N'COLUMN',@level2name=N'REPORT_LINK'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Report year type: Calendar year, Water Year, etc.  If not provided, then Calendar year will be assumed.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'REPORT', @level2type=N'COLUMN',@level2name=N'YEAR_TYPE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'REPORTING_UNIT', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'water summary or water detail report.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'REPORTING_UNIT', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the reporting unit by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'REPORTING_UNIT', @level2type=N'COLUMN',@level2name=N'REPORT_UNIT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Name of the reporting unit.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'REPORTING_UNIT', @level2type=N'COLUMN',@level2name=N'REPORTING_UNIT_NAME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The type of unit being reported (i.e. county, HUC-8, user-defined boundary, etc.)' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'REPORTING_UNIT', @level2type=N'COLUMN',@level2name=N'REPORTING_UNIT_TYPE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'code representing the 2 digit abbreviation for the state.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'REPORTING_UNIT', @level2type=N'COLUMN',@level2name=N'STATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'County FIPS code (including the state FIPS code) representing the county.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'REPORTING_UNIT', @level2type=N'COLUMN',@level2name=N'COUNTY_FIPS'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_ALLOCATION_IRRIGATION', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the report by the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_ALLOCATION_IRRIGATION', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the reporting unit.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_ALLOCATION_IRRIGATION', @level2type=N'COLUMN',@level2name=N'REPORT_UNIT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the Organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_AMOUNT', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_AMOUNT', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the reporting unit by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_AMOUNT', @level2type=N'COLUMN',@level2name=N'REPORT_UNIT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique sequence number assigned to the summary set of information for this reporting unit.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_AMOUNT', @level2type=N'COLUMN',@level2name=N'SUMMARY_SEQ'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique sequence number assigned to this row.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_AMOUNT', @level2type=N'COLUMN',@level2name=N'ROW_SEQ'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Value reported, measured, calculated, or estimated' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_AMOUNT', @level2type=N'COLUMN',@level2name=N'AMOUNT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier referencing the method.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_AMOUNT', @level2type=N'COLUMN',@level2name=N'METHOD_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The start date for the estimate in the format MM/DD.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_AMOUNT', @level2type=N'COLUMN',@level2name=N'START_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The end date for the estimate in the format MM/DD.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_AMOUNT', @level2type=N'COLUMN',@level2name=N'END_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the Organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_METRIC', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_METRIC', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the reporting unit by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_METRIC', @level2type=N'COLUMN',@level2name=N'REPORT_UNIT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique sequence number assigned to the summary set of information for this reporting unit.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_METRIC', @level2type=N'COLUMN',@level2name=N'SUMMARY_SEQ'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique sequence number assigned to this row.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_METRIC', @level2type=N'COLUMN',@level2name=N'ROW_SEQ'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier referencing the metric.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_METRIC', @level2type=N'COLUMN',@level2name=N'METRIC_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Value of the metric.  Higher numbers should indicate more relative availability.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_METRIC', @level2type=N'COLUMN',@level2name=N'METRIC_VALUE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Highest allowed value for the metric.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_METRIC', @level2type=N'COLUMN',@level2name=N'METRIC_SCALE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'This should be marked with a "Y" if the scale is reversed (i.e. higher numbers indicate less availability).' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_METRIC', @level2type=N'COLUMN',@level2name=N'REVERSE_SCALE_IND'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The start date for the estimate in the format MM/DD.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_METRIC', @level2type=N'COLUMN',@level2name=N'START_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The end date for the estimate in the format MM/DD.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_AVAILABILITY_METRIC', @level2type=N'COLUMN',@level2name=N'END_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the Organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the reporting unit by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'REPORT_UNIT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the beneficial use.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'BENEFICIAL_USE_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique sequence number assigned to the summary set of information for this reporting unit.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'SUMMARY_SEQ'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique sequence number assigned to this row.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'ROW_SEQ'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Value reported, measured, calculated, or estimated' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'AMOUNT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'An indicator of whether the amount represents a consumptive use or a diversion.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'CONSUMPTIVE_INDICATOR'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier referencing the method.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'METHOD_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The start date for the estimate in the format MM/DD.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'START_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The end date for the estimate in the format MM/DD.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_USE_AMOUNT', @level2type=N'COLUMN',@level2name=N'END_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_USE_IRRIGATION', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the report by the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_USE_IRRIGATION', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the reporting unit.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_USE_IRRIGATION', @level2type=N'COLUMN',@level2name=N'REPORT_UNIT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the Organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_WATER_SUPPLY_AMOUNT', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_WATER_SUPPLY_AMOUNT', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the reporting unit by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_WATER_SUPPLY_AMOUNT', @level2type=N'COLUMN',@level2name=N'REPORT_UNIT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique sequence number assigned to the summary set of information for this reporting unit.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_WATER_SUPPLY_AMOUNT', @level2type=N'COLUMN',@level2name=N'SUMMARY_SEQ'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique sequence number assigned to this row.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_WATER_SUPPLY_AMOUNT', @level2type=N'COLUMN',@level2name=N'ROW_SEQ'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Value reported, measured, calculated, or estimated' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_WATER_SUPPLY_AMOUNT', @level2type=N'COLUMN',@level2name=N'AMOUNT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier referencing the method.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_WATER_SUPPLY_AMOUNT', @level2type=N'COLUMN',@level2name=N'METHOD_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The start date for the estimate in the format MM/DD.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_WATER_SUPPLY_AMOUNT', @level2type=N'COLUMN',@level2name=N'START_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The end date for the estimate in the format MM/DD.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'S_WATER_SUPPLY_AMOUNT', @level2type=N'COLUMN',@level2name=N'END_DATE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_ALLOCATION', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_ALLOCATION', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the reporting unit by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_ALLOCATION', @level2type=N'COLUMN',@level2name=N'REPORT_UNIT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique sequence number for the summary.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_ALLOCATION', @level2type=N'COLUMN',@level2name=N'SUMMARY_SEQ'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the beneficial use.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_ALLOCATION', @level2type=N'COLUMN',@level2name=N'BENEFICIAL_USE_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'unique identifier for the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_AVAILABILITY', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_AVAILABILITY', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the reporting unit by the reporting organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_AVAILABILITY', @level2type=N'COLUMN',@level2name=N'REPORT_UNIT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique numeric key for summary.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_AVAILABILITY', @level2type=N'COLUMN',@level2name=N'SUMMARY_SEQ'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'The type of water available.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_AVAILABILITY', @level2type=N'COLUMN',@level2name=N'AVAILABILITY_TYPE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Indicates whether the source is fresh water, saline water, or represents the total of both.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_AVAILABILITY', @level2type=N'COLUMN',@level2name=N'FRESH_SALINE_IND'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_REGULATORY', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the report by the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_REGULATORY', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the reporting unit by the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_REGULATORY', @level2type=N'COLUMN',@level2name=N'REPORT_UNIT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the summary.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_REGULATORY', @level2type=N'COLUMN',@level2name=N'SUMMARY_SEQ'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Name of the type of restriction on surface water, groundwater, or reuse.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_REGULATORY', @level2type=N'COLUMN',@level2name=N'REGULATORY_TYPE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the regulatory status in the reporting unit (i.e. open, closed, partial, etc.)' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_REGULATORY', @level2type=N'COLUMN',@level2name=N'REGULATORY_STATUS'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Name of the special management district or oversight committee/basin group.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_REGULATORY', @level2type=N'COLUMN',@level2name=N'OVERSIGHT_AGENCY'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Description of the regulatory restriction.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_REGULATORY', @level2type=N'COLUMN',@level2name=N'REGULATORY_DESCRIPTION'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_USE', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_USE', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the reporting unit by the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_USE', @level2type=N'COLUMN',@level2name=N'REPORT_UNIT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the use summary.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_USE', @level2type=N'COLUMN',@level2name=N'SUMMARY_SEQ'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique identifier for the beneficial use.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_USE', @level2type=N'COLUMN',@level2name=N'BENEFICIAL_USE_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'unique identifier assigned to the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_WATER_SUPPLY', @level2type=N'COLUMN',@level2name=N'ORGANIZATION_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the report by the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_WATER_SUPPLY', @level2type=N'COLUMN',@level2name=N'REPORT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier assigned to the reporting unit by the organization.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_WATER_SUPPLY', @level2type=N'COLUMN',@level2name=N'REPORT_UNIT_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'A unique identifier for the summary.' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_WATER_SUPPLY', @level2type=N'COLUMN',@level2name=N'SUMMARY_SEQ'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Name of the water supply type (i.e. flow, storage, etc.)' , @level0type=N'SCHEMA',@level0name=N'wade', @level1type=N'TABLE',@level1name=N'SUMMARY_WATER_SUPPLY', @level2type=N'COLUMN',@level2name=N'WATER_SUPPLY_TYPE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1[50] 4[25] 3) )"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1[50] 2[25] 3) )"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1[75] 4) )"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 8
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      PaneHidden = 
      Begin ParameterDefaults = ""
      End
      RowHeights = 220
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'TEXT_XOM'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'TEXT_XOM'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Orientation', @value=0x00 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'TEXT_XOM'
GO
