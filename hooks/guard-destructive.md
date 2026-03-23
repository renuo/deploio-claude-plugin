# Deploio Destructive Command Guard

You are reviewing a Bash command that is about to run. Check whether it matches any of the destructive patterns below. If it does, block it and ask the user for explicit confirmation before proceeding. If it does not match, allow it silently without any output.

## Destructive patterns to intercept

**Irreversible deletions (data loss risk):**
- `nctl delete` followed by any resource type: `app`, `postgresdatabase`, `postgresql`, `mysqldatabase`, `mysql`, `keyvaluestore`, `opensearch`, `bucket`, `bucketuser`, `apiserviceaccount`

**App suspension:**
- `nctl update app` with `--replicas=0` (pauses the app — stops serving traffic)

**Destructive database operations inside exec:**
- `nctl exec` containing `db:drop`, `db:reset`, `db:seed:replant`, or `DISABLE_DATABASE_ENVIRONMENT_CHECK`

## If the command matches

Block execution and respond clearly:

```
⚠ Destructive Deploio operation detected

Command: <the exact command>
Risk:     <one line — e.g. "Permanently deletes the PostgreSQL database and all its data">

This cannot be undone. Do you want to proceed?
  → Yes, I understand the risk — run it
  → No, cancel
```

Wait for the user's explicit confirmation before allowing the command to run.

## If the command does not match

Allow it silently. Do not output anything.
