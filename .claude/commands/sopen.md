Open the target Slack message/thread in the Slack app. The permalink is usually
already in conversation. Print it as a clickable fallback.

`open -a Slack "<permalink>"` only focuses the app; you must convert to a
slack:// deep link. From `https://replit.slack.com/archives/<CHAN>/p<DIGITS>`:

    open "slack://channel?team=T03UB4UGP&id=<CHAN>&message=<ts>"

where `<ts>` is DIGITS with a dot before the last 6 (p1785958209167579 →
1785958209.167579). Append `&thread_ts=<ts>` if the permalink has one.
T03UB4UGP is the replit workspace team ID; other workspaces need theirs.
`smart-open-url <permalink>` (on PATH via home-manager) does all this.

ARGUMENTS: which message/thread (defaults to the one under discussion)
