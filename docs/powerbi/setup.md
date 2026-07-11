# Power BI setup

1. Rebuild the SQL database with `run_all.sql` so the `mart` schema is created and loaded.
2. Open `powerbi/B2BOrderAnalytics.pbip` in Power BI Desktop.
3. If prompted for credentials, use Windows authentication for the local SQL Server connection.
4. Refresh the semantic model.
5. Save the project after a successful refresh.

The semantic model points to `localhost` and database `B2BOrderAnalytics`. Change the M source in the TMDL table partitions if the SQL Server instance uses another name.

The report uses the enhanced PBIR format and the semantic model uses TMDL. Both are text-based project files intended to be versioned with the repository.
