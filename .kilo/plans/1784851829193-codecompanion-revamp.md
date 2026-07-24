# CodeCompanion Revamp Plan

## Context

- Current: CodeCompanion **19.18.0** via nixpkgs `vimPlugins.codecompanion-nvim` (nixpkgs input lastModified ~2026-05-15).
- Latest: **19.20.0**. Key changes since 19.18.0:
  - v19.19.0: `claude-sonnet-5` support, async/dynamic model fetching, copilot `top_p` fixes, inline orphaned-keymap fix, background command deregistration.
  - v19.20.0: `gemini_interactions` adapter, PDF support for http adapters (`/file` on Anthropic/Copilot/OpenAI/OpenRouter), env vars from files, prompt-library items auto-receive default rule groups, copilot schema options removed.
- **Bug in current setup:** config sets `model = "claude-sonnet-5"` but 19.18.0 predates its support; the model name may not resolve. The nixpkgs bump fixes this.
- Files involved:
  - `plugin/24_completion.lua` — `get_codecompanion_config()`, setup, blink integration.
  - `plugin/10_keymap.lua` — `<leader>a*` keymaps (lines 69–84, contains duplicates/commented cruft).
  - `overlays/plugins.nix` — codecompanion overlay (nvimSkipModules); likely unchanged.
  - `modules/module/specs/plugins.nix` — plugin spec; unchanged.

## Decisions (confirmed with user)

1. **Version bump:** `nix flake update nixpkgs` (accepts wider plugin bump; do NOT override src).
2. **Adopt:** agent-mode keymaps, one workflow prompt, minor slash-command config (`/share` token). **No MCP.**
3. **Models:** `claude-sonnet-5` (copilot) for **chat only**; cheaper copilot model for **inline** and **background** (title generation) — use `gpt-5-mini` as placeholder; verify exact model id via `ga` model picker in a chat buffer after the bump and adjust.
4. **Codex (ChatGPT Edu) = heavy agent lane.** Copilot stays the default chat adapter; Codex ACP is launched explicitly for heavy autonomous tasks. Auth via ChatGPT login only (no API key) — user's existing `auth_method = "chatgpt"` is correct per the v19.20.0 adapter source (`"openai-api-key"|"codex-api-key"|"chatgpt"`; the docs page comment `"chat-gpt"` is stale).

## Tasks

1. **Bump nixpkgs**
   - Run `nix flake update nixpkgs`.
   - Verify: `nix eval --raw nixpkgs#vimPlugins.codecompanion-nvim.version` reports ≥ 19.20.0.
   - Rebuild the wrapped Neovim per this repo's normal build (`nix build` / the repo's usual package target) and smoke-test that the editor starts.

2. **`plugin/24_completion.lua` — `get_codecompanion_config()`**
   - Keep `interactions.chat.adapter = { name = "copilot", model = "claude-sonnet-5" }`.
   - Change `interactions.inline.adapter` to `{ name = "copilot", model = "gpt-5-mini" }` (cheap/fast).
   - Add a background adapter so title generation doesn't use Sonnet: set the background chat adapter to copilot/`gpt-5-mini` (config lives under `interactions.background.chat`; confirm exact key against `:h codecompanion` / `:checkhealth codecompanion` after the bump — the docs page "Generating Titles" says an adapter must be configured for background interactions).
   - Keep existing context_management, rules, display, shared keymaps unchanged.
   - Add `interactions.chat.slash_commands["share"].opts.token = os.getenv("GITHUB_GIST_TOKEN")`.
   - **Prompt library additions** (keep `expert`, `fixer`, `suggest`):
     - `["agent"]`: interaction "chat", alias `agent`, first user prompt starts with `@{agent}` plus selected code block, so Copilot/Claude gets the file-editing tool group (read_file, insert_edit_into_file, grep_search, run_command, etc., with approvals).
     - `["tdd"]` (name flexible): interaction "chat", `opts = { is_workflow = true, alias = "tdd" }` — 3-stage workflow: (1) plan/understand `#buffer`, (2) `@{agent}` implement, (3) `@{run_command}` run the test suite (leverages run_command's test-flag for agentic workflows).

3. **`plugin/10_keymap.lua` — clean up + add**
   - Remove duplicated/commented lines (70–71, 77, 81).
   - Add:
     - `nmap_leader("aa", "<cmd>CodeCompanionChat<CR>", "Agent chat (use @{agent})")` or directly `<cmd>CodeCompanion /agent<CR>`.
     - `xmap_leader("aa", "<cmd>CodeCompanion /agent<CR>", "Agent on selection")`.
     - `nmap_leader("aw", "<cmd>CodeCompanion /tdd<CR>", "Workflow: plan→implement→test")`.
     - `nmap_leader("aC", "<cmd>CodeCompanion /compact<CR>", "Compact chat")` (verify `<leader>aC` doesn't clash).
   - Keep existing mappings unchanged.

4. **No changes** to `overlays/plugins.nix` or `modules/module/specs/plugins.nix` unless the new version introduces new lazy-module load failures (re-run the build's check phase; `doCheck = false` is already set on the spec entry).

5. **Codex ACP lane (ChatGPT Edu)**
   - **Resolved prerequisite:** user has installed `codex-acp` at `~/.nix-profile/bin/codex-acp` (verified on PATH 2026-07-24). The preset adapter's default command (`codex-acp`) now works as-is — **no `commands` override in the Lua config**. Fallback only if the binary misbehaves: override with `commands = { default = { "codex", "acp" } }` (requires the codex CLI's built-in `acp` subcommand; verify with `codex acp --help`).
   - **Config change (small):** none strictly required — the existing `extend("codex", { defaults = { auth_method = "chatgpt" } })` block in `plugin/24_completion.lua` is correct. Keep it.
   - Auth: prereq is an active `codex login` session with the ChatGPT Edu account (`~/.codex/auth.json` exists — user confirms validity; if expired, re-run `codex login`, browser/ChatGPT-app flow, no API key).
   - Keep codex on-demand (do NOT make it the default chat adapter):
     - Keep `<leader>ak` (`:CodeCompanionChat adapter=codex`).
     - Add comment documenting ACP-only slash commands for this lane: `/resume` (restore past codex session, fresh chat only), `/mode` (switch agent mode), `/command`, `/acp_session_options`, plus `\`-triggered ACP command completion in the chat buffer.
   - Do not set a default codex model in config; pick per-session via `ga` / `/acp_session_options` (avoids hardcoding model ids that change with the Edu plan).
   - PATH note: Neovim must inherit a PATH containing `~/.nix-profile/bin` so the spawned `codex-acp` resolves — true when nvim is launched from the user's normal shell; call it out if validation fails with "command not found".

6. **Docs/habit notes** (add as comment block above the codecompanion setup, no separate docs file): `/compact`, `/fork`, `/symbols`, `/share`, `/resume`+`/mode` (codex ACP), `gm` (btw), `gty` (YOLO), `gba`/`gbd` (buffer sync), `gd` (debug window).

## Validation

- `nix flake update nixpkgs` then repo build succeeds.
- In Neovim: `:checkhealth codecompanion` clean.
- `:CodeCompanionChat`, press `ga` → copilot adapter lists `claude-sonnet-5`; send a trivial message and confirm response + auto title generation.
- In chat: type `@` → completion shows `agent`, `files`, `memory`, etc.; run `@{agent}` task on a scratch repo and confirm the approval prompt flow works.
- `:CodeCompanion /tdd` starts the workflow stages in order.
- Inline: visual-select code, `:CodeCompanion` prompt → confirm diff shows and `ga`/`gr` accept/reject still work on the cheap model.
- `:CodeCompanion /share` prompts/errors sensibly if `GITHUB_GIST_TOKEN` unset.
- **Codex lane:** `<leader>ak` opens a chat with the codex ACP adapter; the spawned `codex-acp` process initializes without auth errors (ChatGPT method), a trivial prompt gets a response, and `/mode` lists codex session modes. If it fails with command-not-found, check that Neovim inherited `~/.nix-profile/bin` in PATH (`:echo $PATH` inside nvim).

## Risks

- `nix flake update nixpkgs` bumps **all** vimPlugins and Neovim itself; other plugins may break. If the blast radius is too large, fall back to overriding codecompanion `src` to tag `v19.20.0` in `overlays/plugins.nix` (fetchFromGitHub, `doCheck = false`).
- Model ids (`claude-sonnet-5`, `gpt-5-mini`) must match the copilot adapter's choices post-bump; verify via `ga` picker and adjust literals.
- `gpt-5-mini` may not support tool use on copilot — fine, since inline/background don't use tools.
- `codex-acp` lives in the user's nix profile (outside this flake). If the profile is rebuilt/removed, the codex lane breaks — long-term consider adding `codex-acp` to this flake's runtime deps so it's pinned with the rest of the setup (optional follow-up, not required now).
- ChatGPT Edu accounts authenticate codex via browser/ChatGPT-app login; token expiry will surface as ACP auth errors → re-run `codex login`.

## Out of scope

- MCP server integration.
- Custom rules parsers, custom tools, extensions (mcphub/history/vectorcode).
