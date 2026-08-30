/*
    Pre-deployment migration -- preserve Player.ShirtNumber before it is retired.

    SqlPackage runs a deployment in three phases, in this order:
      1. this pre-deployment script,
      2. the schema change (ADD [SquadNumber], DROP [ShirtNumber]),
      3. the post-deployment seed.

    So at phase 1 the old [ShirtNumber] column still exists and the new [SquadNumber]
    column does not exist yet. We cannot write to [SquadNumber] here, and there is no hook
    between the ADD and the DROP in phase 2. So we copy each player's number into a staging
    table now, while [ShirtNumber] is still present. The post-deployment step lands those
    values in [SquadNumber] after phase 2 has created it.

    Idempotent: the copy only runs while the old column still exists, and the staging table
    is rebuilt each time, so re-running the deployment is safe.
*/
IF COL_LENGTH('football.Player', 'ShirtNumber') IS NOT NULL
BEGIN
    DROP TABLE IF EXISTS [football].[ShirtNumberBackfill];

    SELECT p.[PlayerId], p.[ShirtNumber]
    INTO [football].[ShirtNumberBackfill]
    FROM [football].[Player] AS p
    WHERE p.[ShirtNumber] IS NOT NULL;
END;
