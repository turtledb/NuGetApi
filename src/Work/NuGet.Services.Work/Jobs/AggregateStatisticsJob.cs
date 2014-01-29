﻿using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data.SqlClient;
using System.Diagnostics.Tracing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Dapper;
using NuGet.Services.Configuration;

namespace NuGet.Services.Work.Jobs
{
    [Description("Aggregates individual package download statistics by Version, Id and Total")]
    public class AggregateStatisticsJob : JobHandler<AggregateStatisticsEventSource>
    {
        /// <summary>
        /// Gets or sets a connection string to the database containing package data.
        /// </summary>
        public SqlConnectionStringBuilder PackageDatabase { get; set; }

        protected ConfigurationHub Config { get; set; }

        public AggregateStatisticsJob(ConfigurationHub config)
        {
            Config = config;
        }

        protected internal override async Task Execute()
        {
            // Load default data if not provided
            PackageDatabase = PackageDatabase ?? Config.Sql.GetConnectionString(KnownSqlServer.Legacy);

            using (var connection = await PackageDatabase.ConnectTo())
            {
                Log.AggregatingStatistics(PackageDatabase.DataSource, PackageDatabase.InitialCatalog);
                if (!WhatIf)
                {
                    await connection.ExecuteAsync(AggregateStatsSql);
                }
                Log.AggregatedStatistics(PackageDatabase.DataSource, PackageDatabase.InitialCatalog);
            }
        }

        private const string AggregateStatsSql = @"
SET NOCOUNT ON

DECLARE @UpdatedGallerySettings TABLE
(
        MostRecentStatisticsId int
    ,   LastAggregatedStatisticsId int
)

BEGIN TRANSACTION

    -- Claim the latest PackageStatistics rows
    UPDATE  GallerySettings
    SET     DownloadStatsLastAggregatedId = (SELECT MAX([Key]) FROM PackageStatistics)
    OUTPUT  inserted.DownloadStatsLastAggregatedId AS MostRecentStatisticsId
        ,   deleted.DownloadStatsLastAggregatedId AS LastAggregatedStatisticsId
    INTO    @UpdatedGallerySettings

	DECLARE @mostRecentStatisticsId int
    DECLARE @lastAggregatedStatisticsId int

    SELECT  TOP 1
            @mostRecentStatisticsId = MostRecentStatisticsId
        ,   @lastAggregatedStatisticsId = LastAggregatedStatisticsId
    FROM    @UpdatedGallerySettings

    SELECT  @lastAggregatedStatisticsId = ISNULL(@lastAggregatedStatisticsId, 0)

	
    IF (@mostRecentStatisticsId IS NULL)
        RETURN

    DECLARE @DownloadStats TABLE
    (
            PackageKey int PRIMARY KEY
        ,   DownloadCount int
    )

    DECLARE @AffectedPackages TABLE
    (
            PackageRegistrationKey int
    )

    -- Grab package statistics
    INSERT      @DownloadStats
    SELECT      stats.PackageKey, DownloadCount = COUNT(1)
    FROM        PackageStatistics stats
    WHERE       [Key] > @lastAggregatedStatisticsId
            AND [Key] <= @mostRecentStatisticsId
    GROUP BY    stats.PackageKey

    -- Aggregate Package-level stats
	UPDATE      Packages
    SET         Packages.DownloadCount = Packages.DownloadCount + stats.DownloadCount,
    			Packages.LastUpdated = GetUtcDate()
    OUTPUT      inserted.PackageRegistrationKey INTO @AffectedPackages
    FROM        Packages
    INNER JOIN  @DownloadStats stats ON Packages.[Key] = stats.PackageKey        
    
    -- Aggregate PackageRegistration stats
    UPDATE      PackageRegistrations
    SET         DownloadCount = TotalDownloadCount
    FROM        (
                SELECT      Packages.PackageRegistrationKey
                        ,   SUM(Packages.DownloadCount) AS TotalDownloadCount
                FROM        (SELECT DISTINCT PackageRegistrationKey FROM @AffectedPackages) affected
                INNER JOIN  Packages ON Packages.PackageRegistrationKey = affected.PackageRegistrationKey
                GROUP BY    Packages.PackageRegistrationKey
                ) AffectedPackageRegistrations
    INNER JOIN  PackageRegistrations ON PackageRegistrations.[Key] = AffectedPackageRegistrations.PackageRegistrationKey

	UPDATE		GallerySettings
	SET			GallerySettings.TotalDownloadCount = GallerySettings.TotalDownloadCount + (SELECT ISNULL(SUM(DownloadCount), 0) FROM @DownloadStats)

COMMIT TRANSACTION
";
    }

    [EventSource(Name="Outercurve-NuGet-Jobs-AggregateStatistics")]
    public class AggregateStatisticsEventSource : EventSource 
    {
        public static readonly AggregateStatisticsEventSource Log = new AggregateStatisticsEventSource();
        private AggregateStatisticsEventSource() { }

        [Event(
            eventId: 1,
            Task = Tasks.AggregatingStatistics,
            Opcode = EventOpcode.Start,
            Level = EventLevel.Informational,
            Message = "Aggregating statistics in {0}/{1}")]
        public void AggregatingStatistics(string server, string database) { WriteEvent(1, server, database); }

        [Event(
            eventId: 2,
            Task = Tasks.AggregatingStatistics,
            Opcode = EventOpcode.Stop,
            Level = EventLevel.Informational,
            Message = "Aggregated statistics in {0}/{1}")]
        public void AggregatedStatistics(string server, string database) { WriteEvent(2, server, database); }

        public static class Tasks
        {
            public const EventTask AggregatingStatistics = (EventTask)0x1;
        }
    }
}
