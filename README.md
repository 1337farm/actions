# 1337farm/actions

Shared composite GitHub Actions for 1337farm Android builds. Pure shell, no third-party actions.

| Action | Purpose |
|---|---|
| `setup-android-env` | Locate the Android SDK (configurable path), export env, accept licenses |
| `setup-android-ndk` | Install a specific Android NDK via `sdkmanager` and export NDK env |
| `setup-jdk` | Install Temurin JDK (`java-version`, default `17`); linux/macOS, x64/aarch64, tool-cache reuse |
| `publish-release` | Replace a rolling release tag with files (`tag`, `title`, `notes`, `files`); globs + strict failures |
| `squash-merge` | Squash-merge a PR with preflight + idempotence (`pr-number`, `repo?`) |
| `setup-sccache` | Install sccache with GHA cache backend (`version?`); consumers set `RUSTC_WRAPPER=sccache` |
| `cache-cargo` | Cache cargo registry + target dirs (`workspaces?`, `shared-key` pins target + features, `cache-targets?`) |
| `cache-musl-toolchain` | Restore/download aarch64 musl toolchain, export `TOOLCHAIN_BIN`/`PATH`/`CC_*`/`AR_*` (`cache-key?`, `cache-path?`, `mirrors?`) |

Consume pinned: `1337farm/actions/setup-jdk@v1`. See each action's `action.yml` for inputs.

## Support matrix

| Action | Linux x64 | Linux ARM64 | macOS x64 | macOS ARM64 |
|---|---|---|---|---|
| `setup-jdk` | ✓ | ✓ | ✓ | ✓ |
| `setup-android-env` | ✓ (SDK must exist) | ✓ | — | — |
| `setup-android-ndk` | ✓ (SDK must exist) | ✓ | — | — |
| `publish-release` | ✓ | ✓ | ✓ | ✓ |
| `squash-merge` | ✓ | ✓ | ✓ | ✓ |
| `setup-sccache` | ✓ | ✓ | ✓ | ✓ |
| `cache-cargo` | ✓ | ✓ | ✓ | ✓ |
| `cache-musl-toolchain` | ✓ | ✓ | ✓ | — |

Android tooling (SDK/NDK) only exists on GitHub's Ubuntu runners; on other platforms
`setup-android-env`/`setup-android-ndk` require a pre-provisioned SDK (set `sdk-path`,
`ANDROID_SDK_ROOT`, or `ANDROID_HOME`).

## CI

`.github/workflows/ci.yml` lints the workflows/actions (`actionlint` + `shellcheck`)
and runs an end-to-end smoke test that installs and runs every action (JDK 17 + 21,
Android SDK/NDK wiring, a real rolling `publish-release` against this repo, and the
`squash-merge` preflight guard).

## License

MIT — see [LICENSE](LICENSE).