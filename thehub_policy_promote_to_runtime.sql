--------------------------------------------------------------------------
-- THE HUB - Promote THEHUB from build-time to runtime-only privileges
-- Run as ADMIN after schema/app build is complete and validated.
--------------------------------------------------------------------------

REVOKE THEHUB_BUILD_ROLE FROM THEHUB;

-- Keep runtime login and object-space growth.
GRANT CREATE SESSION TO THEHUB;
ALTER USER THEHUB QUOTA UNLIMITED ON DATA;

PROMPT THEHUB now has runtime-oriented grants only.
PROMPT To inspect grants, run @thehub_policy_verify.sql
