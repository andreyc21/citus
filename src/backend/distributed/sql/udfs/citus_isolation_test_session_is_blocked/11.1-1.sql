CREATE OR REPLACE FUNCTION pg_catalog.citus_isolation_test_session_is_blocked(pBlockedPid integer, pInterestingPids integer[])
RETURNS boolean AS $$
  DECLARE
    mBlockedGlobalPid int8;
    workerProcessId integer := current_setting('citus.isolation_test_session_remote_process_id');
    coordinatorProcessId integer := current_setting('citus.isolation_test_session_process_id');
    r record;
  BEGIN
    IF pg_catalog.old_pg_isolation_test_session_is_blocked(pBlockedPid, pInterestingPids) THEN
      RETURN true;
    END IF;

    -- pg says we're not blocked locally; check whether we're blocked globally.
    -- Note that worker process may be blocked or waiting for a lock. So we need to
    -- get transaction number for both of them. Following IF provides the transaction
    -- number when the worker process waiting for other session.
    IF EXISTS (SELECT 1 FROM get_global_active_transactions()
               WHERE process_id = workerProcessId AND pBlockedPid = coordinatorProcessId) THEN
      SELECT global_pid INTO mBlockedGlobalPid FROM get_global_active_transactions()
      WHERE process_id = workerProcessId AND pBlockedPid = coordinatorProcessId;
    ELSE
      -- Check whether transactions initiated from the coordinator get locked
      SELECT global_pid INTO mBlockedGlobalPid
        FROM get_all_active_transactions() WHERE process_id = pBlockedPid;
    END IF;

    FOR r IN select a1.query blocking_query, a2.query waiting_query from citus_internal_global_blocked_processes() p join pg_stat_activity a1 on p.blocking_pid = a1.pid join  pg_stat_activity a2 on p.waiting_pid = a2.pid WHERE waiting_global_pid = mBlockedGlobalPid
    LOOP
        RAISE WARNING E'%\nBLOCKS\n%', r.blocking_query, r.waiting_query;
    END LOOP;

    RETURN EXISTS (
      SELECT 1 FROM citus_internal_global_blocked_processes()
        WHERE waiting_global_pid = mBlockedGlobalPid
    );
  END;
$$ LANGUAGE plpgsql;

REVOKE ALL ON FUNCTION citus_isolation_test_session_is_blocked(integer,integer[]) FROM PUBLIC;
