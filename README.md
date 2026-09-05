# 1337farm/actions

Shared composite GitHub Actions for 1337farm Android builds. Pure shell, no third-party actions.

| Action | Purpose |
|---|---|
| `setup-android-env` | Point at runner-preinstalled SDK, export env, accept licenses |
| `setup-jdk` | Install Temurin JDK (`java-version`, default `17`) |
| `publish-release` | Replace a rolling release tag with files (`tag`, `title`, `notes`, `files`) |
| `squash-merge` | Directly squash-merge a PR (`pr-number`, `repo?`) |

Consume pinned: `1337farm/actions/setup-jdk@v1`. See each action's `action.yml` for inputs.

## License

MIT — see [LICENSE](LICENSE).
