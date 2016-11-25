USE MASTER;
GO
SELECT DISTINCT
   tb.trace_event_id,
   te.name AS 'Event Class',
   em.package_name AS 'Package',
   em.xe_event_name AS 'XEvent Name',
   tb.trace_column_id,
   tc.name AS 'SQL Trace Column',
   am.xe_action_name as 'Extended Events action'
FROM (sys.trace_events te LEFT OUTER JOIN sys.trace_xe_event_map em
   ON te.trace_event_id = em.trace_event_id) LEFT OUTER JOIN sys.trace_event_bindings tb
   ON em.trace_event_id = tb.trace_event_id LEFT OUTER JOIN sys.trace_columns tc
   ON tb.trace_column_id = tc.trace_column_id LEFT OUTER JOIN sys.trace_xe_action_map am
   ON tc.trace_column_id = am.trace_column_id
ORDER BY te.name, tc.name



/*


If all columns return NULL except for the Event Class column, this indicates that the event class was not migrated from SQL Trace.

If only the value in the Extended Events action column is NULL, this indicates that either of the following conditions is true:

	The SQL Trace column maps to one of the data fields that is associated with the Extended Events event.
	Note Note
	Each Extended Events event has a default set of data fields that are automatically included in the result set.

	The action column does not have a meaningful Extended Events equivalent. An example of this is the EventClass column in SQL Trace. This column is not needed in Extended Events because the event name serves the same purpose.

For user configurable SQL Trace event classes (UserConfigurable:1 through UserConfigurable:9), Extended Events uses a single event to replace these. The event is named user_event. This event is raised by using sp_trace_generateevent, which is the same stored procedure that is used by SQL Trace. The user_event event is returned regardless of which event ID is passed to the stored procedure. However, an event_id field is returned as part of the event data. This enables you to build a predicate that is based on the event ID. For example, if you use UserConfigurable:0 (event ID = 82) in the code, you can add the user_event event to the session, and specify a predicate of 'event_id = 82'. Therefore, you do not have to change the code because the sp_trace_generateevent stored procedure generates the Extended Events user_event event, and the equivalent SQL Trace event class.

If all columns return NULL except for the Event Class column, this indicates that the event class was not migrated from SQL Trace.

If only the value in the Extended Events action column is NULL, this indicates that either of the following conditions is true:

	The SQL Trace column maps to one of the data fields that is associated with the Extended Events event.
	Note Note
	Each Extended Events event has a default set of data fields that are automatically included in the result set.

	The action column does not have a meaningful Extended Events equivalent. An example of this is the EventClass column in SQL Trace. This column is not needed in Extended Events because the event name serves the same purpose.

For user configurable SQL Trace event classes (UserConfigurable:1 through UserConfigurable:9), Extended Events uses a single event to replace these. The event is named user_event. This event is raised by using sp_trace_generateevent, which is the same stored procedure that is used by SQL Trace. The user_event event is returned regardless of which event ID is passed to the stored procedure. However, an event_id field is returned as part of the event data. This enables you to build a predicate that is based on the event ID. For example, if you use UserConfigurable:0 (event ID = 82) in the code, you can add the user_event event to the session, and specify a predicate of 'event_id = 82'. Therefore, you do not have to change the code because the sp_trace_generateevent stored procedure generates the Extended Events user_event event, and the equivalent SQL Trace event class.


*/