# Developer setup

## Connecting the report to a database

The semantic model reaches SQL Server through two Power Query parameters rather
than a hard-coded connection string, so the repository never carries anyone's
server name.

| Parameter | Committed value | What to set it to |
|---|---|---|
| `SqlServer` | `your-server.database.windows.net` | Your Azure SQL server |
| `SqlDatabase` | `ortho` | Your database name |

Set them in Power BI Desktop under **Home → Transform data → Edit parameters**,
then refresh. The values live in your local working copy only.

Build the database first from `database/Orthoma.Database` — it generates the
synthetic data the model expects. Create a read-only reader with
`database/Orthoma.Database/Security/pbi_report.User.sql` and point the report at
that account rather than an admin login.

## Keeping your server name out of git

`SqlServer` is the one parameter that gets overwritten constantly: every refresh
and save in Desktop writes your real hostname back into
`power-bi/Orthoma.SemanticModel/definition/expressions.tmdl`. Scrubbing that by
hand before each push is easy to forget, and forgetting it once is permanent —
it lands in history.

A git **clean filter** removes the problem. Your working copy keeps the real
hostname so refresh always works; git substitutes the placeholder automatically
whenever the file is staged.

Run these two commands once per clone:

```bash
git config filter.scrubhost.clean  "sed 's/paige\.database\.windows\.net/your-server.database.windows.net/g'"
git config filter.scrubhost.smudge cat
```

`.gitattributes` already binds the filter to the file:

```gitattributes
power-bi/Orthoma.SemanticModel/definition/expressions.tmdl filter=scrubhost
```

Substitute your own hostname in the `clean` command if it differs from the one
above.

### Why this needs doing on every clone

Filter definitions live in `.git/config`, which is not part of the repository —
git will not run a command that arrived with cloned content, and that is a
deliberate safety property, not an oversight. So the binding in `.gitattributes`
travels but the filter itself does not.

**Without the config, the file commits verbatim.** `.gitattributes` names a
filter that does not exist, and git passes the content through untouched rather
than failing. There is no warning.

### Verifying it works

After configuring, confirm the substitution actually happens:

```bash
git add power-bi/Orthoma.SemanticModel/definition/expressions.tmdl
git show :power-bi/Orthoma.SemanticModel/definition/expressions.tmdl | grep windows.net
```

The staged content should show `your-server.database.windows.net`. If it shows
your real hostname, the filter is not active — recheck the `git config`
commands above before pushing.

Worth running once after any fresh clone, and any time you have reason to doubt
it. It is a five-second check against a mistake that cannot be undone by a
later commit.
