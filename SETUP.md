# Setup

## Requirements

The helper currently supports macOS and uses Bash, `curl`, `less`, and [`terminal-notifier`](https://github.com/julienXX/terminal-notifier). Install `terminal-notifier` with Homebrew:

```sh
brew install terminal-notifier
```

Clone the repository and install the skill files into the directory your agent uses for skills:

```sh
git clone "https://github.com/CB2Moon/agent-notify.git"
cd agent-notify
./agent-notify/install-skill.sh "<agent-skill-directory>"
```

The destination must be the directory where the agent will find `SKILL.md`. Replace `<agent-skill-directory>` with that agent's path. The script copies `SKILL.md`, the `agent-notify` helper, and the two example configuration files. It does not copy `.env` or `self.env` credentials.

Test the Mac notification:

```sh
"<agent-skill-directory>/agent-notify" --title "Agent Notify test" "macOS delivery check"
```

If it does not appear, check macOS notification settings for `terminal-notifier` and confirm that notifications are enabled.

## Bark on iPhone

The iPhone route is optional. Install and open [Bark](https://github.com/Finb/Bark) on your iPhone. The app shows a test push URL and device key for its selected server. Copy the key for the server you want to use.

For Bark's public server, make a private config beside the installed helper:

```sh
cp "<agent-skill-directory>/.env.example" "<agent-skill-directory>/.env"
```

Edit `.env` and replace the example value with the key shown by Bark. Keep this file private. Then test delivery:

```sh
"<agent-skill-directory>/agent-notify" --target iphone --title "Agent Notify test" "Bark delivery check"
```

The helper sends Bark notifications with the `telegraph` sound. Bark can use other sounds and options, but the helper currently keeps its iPhone notification format fixed.

Each Bark server registers its own device key. If you add a Cloudflare Worker as another server in Bark, use the key Bark creates for that Worker in `self.env`. Keep the public-server key in `.env`; the helper uses it as a fallback if the Worker cannot be reached. Bark's [push guide](https://github.com/Finb/Bark/blob/master/docs/en-us/tutorial.md) describes the app's test URL and request format.

## Optional: deploy your own Bark Worker

The helper works with Bark's public server alone. To use a self-hosted Worker, you need a Cloudflare account, [Bun](https://bun.sh/), and Wrangler. The Worker source and pinned upstream license are in `cloudflare/agent-bark/`.

From the repository root:

```sh
cd cloudflare/agent-bark
cp wrangler.example.jsonc wrangler.jsonc
bun install
bunx wrangler login
bunx wrangler d1 create agent-bark-db
```

Wrangler prints the new D1 database ID. Put it in `d1_databases[0].database_id` in `wrangler.jsonc`. Keep the binding name `database` and database name `agent-bark-db` consistent with the config.

Apply the schema migrations to the remote database:

```sh
bun run db:migrate:remote
```

For first registration, change `ALLOW_NEW_DEVICE` to `true` in `wrangler.jsonc`, then deploy:

```sh
bunx wrangler deploy
```

In Bark, add the Worker URL printed by Wrangler as a server and select it. The app registers the device and receives a key for this Worker. After registration, change `ALLOW_NEW_DEVICE` back to `false` and deploy again. This stops new devices from registering without your approval.

Copy the Worker example config beside the installed helper and edit it with the Worker URL and the key Bark generated for that Worker:

```sh
cp "<agent-skill-directory>/worker.env.example" "<agent-skill-directory>/self.env"
```

`self.env` uses `BARK_SERVER_URL` and `BARK_KEY`. Keep it private. The helper tries this Worker first and falls back to `api.day.app` using `.env` if the Worker request fails. See Cloudflare's [Wrangler D1 commands](https://developers.cloudflare.com/d1/wrangler-commands/) for database command details.

## Logs and privacy

The helper appends each notification attempt to `~/Library/Logs/agent-notifications.log`. Each record contains the time, target, working directory, title, full message, and provider result. The log is local to the Mac, but notification text can contain private information.

Open it at the newest entry with:

```sh
"<agent-skill-directory>/agent-notify" logs
```

Clear it manually with:

```sh
"<agent-skill-directory>/agent-notify" logs clear
```
