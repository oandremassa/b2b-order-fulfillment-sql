:setvar DatabaseName "B2BOrderAnalytics"
:On Error exit


SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

PRINT '============================================================';
PRINT 'B2B Order Fulfillment & Inventory Analytics';
PRINT 'Rebuilding database: $(DatabaseName)';
PRINT '============================================================';

:r .\sql\00_setup\00_reset_and_create_database.sql
:r .\sql\00_setup\01_create_schemas.sql
:r .\sql\01_ddl\10_create_tables.sql
:r .\sql\01_ddl\11_create_constraints.sql
:r .\sql\01_ddl\12_create_indexes.sql
:r .\sql\02_seed\20_seed_reference_data.sql
:r .\sql\02_seed\21_generate_master_data.sql
:r .\sql\02_seed\22_generate_orders_and_returns.sql
:r .\sql\02_seed\23_generate_inventory.sql
:r .\sql\03_views\30_create_views.sql
:r .\sql\04_procedures\40_create_reporting_procedures.sql
:r .\sql\04_procedures\41_create_inventory_procedure.sql
:r .\sql\05_quality\50_create_quality_checks.sql
:r .\sql\07_tests\70_smoke_tests.sql

PRINT '============================================================';
PRINT 'Build completed successfully.';
PRINT 'Run sql\06_analysis\60_business_questions.sql next.';
PRINT '============================================================';
