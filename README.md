# Agent Notify

Agent Notify lets a coding agent get your attention while you work elsewhere. It sends macOS notifications by default. An agent can use Bark to reach your iPhone when you ask it to.

The repository includes a small command-line helper, an agent skill, and an optional Cloudflare Worker for people who want to host their own Bark server.

## What it does

- Sends a macOS notification through `terminal-notifier`, with the default sound.
- Sends an iPhone notification through Bark when you choose `--target iphone` or `--target both`.
- Tries a configured self-hosted Bark Worker first, then falls back to Bark's public server.
- Keeps an append-only local log of notification attempts. The log includes the working directory and full notification text.
- Gives agents a simple rule for when to notify: when you ask, when they need your input, or after five minutes without a reply while they continue other work.

## Quick start

Agent Notify currently supports macOS. Install `terminal-notifier`, clone this repository, and copy the skill and helper to your agent's skill directory:

```sh
brew install terminal-notifier
git clone "https://github.com/CB2Moon/agent-notify.git"
cd agent-notify
./agent-notify/install-skill.sh "<agent-skill-directory>"
```

Replace each angle-bracket placeholder with your own value. The install script copies the skill, helper, and configuration examples. It does not copy credentials.

Read [SETUP.md](SETUP.md) for notification setup, Bark on iPhone, and the optional Cloudflare Worker.

## Use the helper

```sh
"<agent-skill-directory>/agent-notify" --title "Agent Notify" "Mac notification test"
"<agent-skill-directory>/agent-notify" --target iphone --title "Agent Notify" "iPhone test"
"<agent-skill-directory>/agent-notify" --target both --title "Agent Notify" "Mac and iPhone test"
"<agent-skill-directory>/agent-notify" logs
```

The target defaults to `mac`. The skill tells agents to use the iPhone only when you request it. `logs` opens the local log in `less`; `logs clear` empties it.

## Platform support

macOS is the only supported platform today. Contributions for Linux, Windows, and other agent environments are welcome. Please include setup steps and a way to verify each platform's notification backend.

## Bark and the Worker

Bark is an iOS app that receives push notifications from a Bark server. This repository vendors the D1 version of [cwxiaos/bark-worker](https://github.com/cwxiaos/bark-worker), pinned to the commit in `cloudflare/agent-bark/UPSTREAM.md`. The Worker and the original helper are covered by GPL-3.0-only. See [LICENSE](LICENSE) and the upstream license in `cloudflare/agent-bark/LICENSE`.

The Bark app creates a device key for each server you add. A key registered with `api.day.app` does not work with your own Worker. See the [Bark app guide](https://github.com/Finb/Bark/blob/master/docs/en-us/tutorial.md) and the optional Worker steps in [SETUP.md](SETUP.md).
