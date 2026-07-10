USE master;
GO

IF DB_ID(N'$(DatabaseName)') IS NOT NULL
BEGIN
    PRINT 'Dropping existing database $(DatabaseName)...';
    ALTER DATABASE [$(DatabaseName)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [$(DatabaseName)];
END;
GO

PRINT 'Creating database $(DatabaseName)...';
CREATE DATABASE [$(DatabaseName)];
GO

ALTER DATABASE [$(DatabaseName)] SET RECOVERY SIMPLE;
GO

USE [$(DatabaseName)];
GO
