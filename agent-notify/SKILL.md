---
name: agent-notify
description: Notify the user when they explicitly ask, when you are blocked on their input, or after five minutes without a reply while continuing other work.
---

# Agent notifications

Run the `agent-notify` executable beside this `SKILL.md`. It handles macOS delivery, Bark credentials, and logging. Do not call the providers directly or read `.env` or `self.env`.

When running the helper from a sandboxed agent, use elevated filesystem access so it can complete the notification workflow.

## When to notify

- Send an alert when the user explicitly asks you to notify them.
- If you cannot continue without the user's answer, send an alert immediately.
- If the user has not answered a question but you can continue independent work, wait five minutes from asking. If it is still unanswered, send one alert. Do not send repeated reminders for the same question.
- Keep routine progress and task completion quiet unless the user asked for an alert.
- Include the task or agent name, the specific question or useful result, and an exact file path or URL when it helps the user act.
- Treat an away status as applying to that task until it ends or the user updates it. Away status alone does not select the iPhone.

## Choose a target

The default target is the Mac. Use `--target iphone` only when the user explicitly requests a phone alert. Use `--target both` only when the user explicitly asks for both devices. An away status does not change this choice.

```sh
"<agent-skill-directory>/agent-notify" --title "Agent · project-name" "Please review the generated report: /absolute/path/report.md"
"<agent-skill-directory>/agent-notify" --target iphone --title "Agent · project-name" "I need your decision on the deployment."
"<agent-skill-directory>/agent-notify" --target both --title "Agent · project-name" "The external review bundle is ready: /absolute/path/review.zip"
```

The CLI accepts one message, an optional `--title`, and an optional `--target mac|iphone|both`.

For iPhone delivery, the helper reads the public Bark key from `.env`. If `self.env` is beside the helper, it tries that self-hosted Worker first, then falls back to `https://api.day.app` with the public key. Each Bark server has its own device key. Keep `.env` and `self.env` private and never include their values in a notification. `AGENT_NOTIFY_ENV_FILE` and `AGENT_NOTIFY_WORKER_ENV_FILE` can override their paths.

The helper appends one record per attempted target to `~/Library/Logs/agent-notifications.log`. It records the timestamp, target, working directory, exact title and message, and whether delivery succeeded. The log is shared across projects and stays on this Mac. Treat it as private because it contains notification text.

Run `agent-notify logs` to open the log in `less` at the newest entry. Run `agent-notify logs clear` to empty it. Mac alerts request the default notification sound; macOS notification settings can still mute it.
