SELECT
     S.ScheduleID AS SQLAgent_Job_Name
     ,SUB.Description AS Sub_Desc
     ,SUB.DeliveryExtension AS Sub_Del_Extension
     ,C.Name AS ReportName
     ,C.Path AS ReportPath
FROM ReportSchedule RS
     INNER JOIN Schedule S ON (RS.ScheduleID = S.ScheduleID)
     INNER JOIN Subscriptions SUB ON (RS.SubscriptionID = SUB.SubscriptionID)
     INNER JOIN [Catalog] C ON (RS.ReportID = C.ItemID AND SUB.Report_OID = C.ItemID)
WHERE
     C.Name LIKE '%cluster%' --Enter Report Name to find Job_Name