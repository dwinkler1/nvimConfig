# Neovim + Nix setup review

Scope: `flake.nix`, `overlays/`, `modules/`, `plugin/*.lua`, `lua/*`, `ftplugin/*`, CI/workflows, and cross-check against the pinned versions in `flake.lock` (nixpkgs weekly `241313f4`).

## Pinned package versions (from current lock)
- neovim `0.12.2`
- blink-cmp `1.10.2`
- codecompanion-nvim `19.13.0`
- nvim-treesitter `0.10.0-unstable-2026-04-03` (main-branch rewrite)
- nvim-treesitter-textobjects `0-unstable-2026-04-07` (main-branch rewrite)
- copilot-lua `2.0.3`
- render-markdown-nvim `8.12.0-unstable-2026-05-07`
- zk-nvim `0.4.7-unstable-2026-03-13`
- mini.nvim `0.17.0-unstable-2026-05-12`
- quarto-nvim `2.1.0`
- otter-nvim `2.14.5`
- lspconfig `2.9.0`

---

## CRITICAL: Treesitter is currently non-functional

### Finding
The nixpkgs `nvim-treesitter` package is the **main-branch rewrite** — there is no `lua/nvim-treesitter/configs.lua`. The whole module in `plugin/20_startup.lua` lines 212-294 is dead code:

```lua
local ok_configs, configs = pcall(require, "nvim-treesitter.configs")  -- fails
```

The working tree already removed the fallback `vim.treesitter.start()` FileType autocmd (the "fixed treesitter" commit deleted it). Net result: **no treesitter highlighting, indentexpr, foldexpr, or textobjects are configured**.

### Impact
- Syntax highlighting falls back to Neovim's regex-only engine.
- All textobject keymaps (`]a`, `[a`, `]f`, `[f`, `]e`/`[e`, `<leader>x`/`X`, lsp_interop `<leader>lm`) are inert.
- `foldexpr`/`indentexpr` based folding does nothing.

### Fix direction
Rewrite `plugin/20_startup.lua` for main-branch API:
1. FileType autocmd → `vim.treesitter.start()` (and optionally `indentexpr`/`foldexpr`).
2. `require("nvim-treesitter-textobjects").setup({ move = { set_jumps = true } })` + explicit keymaps using `move.goto_next_start(query, "textobjects")` and `swap.swap_next(...)`.
3. The non-Nix `ensure_installed` block should set `opts.ensure_installed` BEFORE the filter (line 278 reads it before line 286 defines it).

Also remove duplicate `vim.treesitter.language.register("markdown", ...)` between `plugin/20_startup.lua` and `plugin/21_datascience.lua`.

---

## CodeCompanion version mismatch

### Finding
Config targets features absent in `19.13.0` (present only in `≥19.19.0`/main):

| Config usage | Present in 19.13? | Present in main (`v19.20.0`) |
|---|---|---|
| `interactions.chat.opts.context_management.editing` | No (flat `trigger`/`enabled` only) | Yes |
| `interactions.chat.opts.context_management.compaction` | No | Yes |
| `<leader>aC` requiring `codecompanion.interactions.chat.context_management.compaction` | **RUNTIME ERROR** | Works |
| `slash_commands.share` (`opts.token = ...`) | No (absent from defaults) | Yes |
| `adapters.acp.codex.defaults.auth_method = "chatgpt"` | Yes | Yes |
| `interactions.chat.adapter = { name = ..., model = ... }` table form | Yes | Yes |

### Risk
On today's lock (`19.13.0`): `/share` is inert, compaction-only keymap throws module-not-found, and `editing`/`compaction` tuning is silently ignored. On `≥19.19.0`/main: everything works.

### Decision needed (BLOCKING)
Choose **exactly one**:

- **A — Upgrade the plugin pin** (`overlays/plugins.nix` fetch to `v19.20.0` or `main`, bump the lock, and keep the current config). Riskiest change but matches what the config is written for.
- **B — Downgrade config call sites** to match `19.13.0`: remove `slash_commands.share`, remove `editing`/`compaction` keys (or collapse to flat `trigger: 0.75`), remove or gate `<leader>aC` on "newer" version.
- **C — Version-gate the config**: keep current code, read the installed version at startup and skip the new features when < 19.19.

I recommend A (the config clearly intends to track upstream main-ish behavior; `nix flake update` already bumped it to `19.18.0` in a prior session and you only reverted because the nightly was still too old — `v19.20.0` is now available).

---

## DEAD / DUPLICATE code

- `plugin/20_startup.lua` — the entire `configs.setup(opts)` block is dead (see Treesitter finding above).
- `plugin/10_keymap.lua`:
  - `nmap_leader('od', '<Cmd>Neogen<CR>', ...)` — `neogen` plugin is **not shipped** in `specs/plugins.nix`. Mapping errors on press.
  - `nmap_leader('fp', '<Cmd>Pick projects<CR>', ...)` — `MiniExtra.pickers.projects` doesn't exist in mini.extra; would error.
  - `nmap_leader('oS', '<Cmd>lua Config.insert_section()<CR>', ...)` — `Config.insert_section` is never defined.
  - `vim.lsp.buf.definition()` is bound to `grd`; Neovim 0.11+ defaults include `gr` aliases. Cosmetic, but `]d`/`[d` exist on modern LSP config and would be more idiomatic.
- `plugin/23_editor.lua`:
  - `my_styler` formatter (calls `R -s -e styler::...`) is defined but never referenced — dead.
- `plugin/24_completion.lua`:
  - `providers.cmp_r` is defined in the blink source list but never enabled in `default` or `per_filetype`; inert.
  - `BLINK_VERSION = "v1.4.1"` — only consulted in the non-Nix install path; nixpkgs is `1.10.2`. Pin it to current or drop.
  - `get_blink_fuzzy_setting().prebuilt_binary = { force_version = BLINK_VERSION }` — singular key is wrong; blink option is `fuzzy.prebuilt_binaries` (plural). Being skipped in-Nix anyway, but still wrong key.
- `modules/module/specs/plugins.nix` — `specs.utils-lazy` ships `nvim-dap*` and `nvim-lint` but there is zero config/tooling that references them in this repo.
- `ftplugin/quarto.lua`:
  - Second top-level `require('quarto').setup()` with **no args** runs _after_ `21_datascience.lua`'s setup and **resets** it to defaults (no `lspFeatures`, no `codeRunner`).
  - Top-level `require('quarto')` at FileType load also crashes if the quarto plugin isn't installed (e.g. cats off and a `.qmd`/`.quarto` file is opened): Neovim detects `quarto` ft natively in 0.10+.
- `plugin/00_options.lua`:
  - Lines 146-163: two back-to-back FileType autocmds that both remove `r`/`o` from `formatoptions`. The second references an undefined `augroup` variable (nil → autocmd is global, happens to still work).

---

## STALE / WRONG options

- `plugin/10_keymap.lua` line 174:
  ```lua
  require("conform").format({ lsp_fallback = true })
  ```
  `lsp_fallback` is the **deprecated** boolean form of `conform.nvim`; should be `lsp_format = "fallback"` (the form already used in `plugin/23_editor.lua` and `ftplugin/python.lua`). In newer conform this may warn or error.
- `ftplugin/quarto.lua`:
  - Sets `<Plug>RDSendLine` and R-style keymaps on _all_ quarto buffers, including Python/Julia chunks. This collides with quarto-runner mappings set in `21_datascience.lua`. Should gate on `vim.bo.filetype == "r"` (the ftplugin already imports quarto.runner for python, but the R keys leak).
- `.github/dependapot.yml` — filename typo. GitHub expects `dependabot.yml`; Dependabot won't run.
- `.github/workflows/check.yml`:
  - `nix develop` without a `-c` command just launches an interactive shell. In CI it does nothing useful (or hangs). Replace with `nix develop -c echo ok` or drop.
  - Path filter `'modules'` only matches the root directory itself; should be `modules/**` (or `'modules/**'`).
  - Changing `plugin/`, `lua/`, `overlays/`, `ftplugin/`, etc. does **not** trigger CI.
- `flake.nix` / `.envrc` shellHook:
  ```sh
  export R_LIBS_SITE=$(strings "$(command -v R)" | grep -oP '/nix/store/[^:]+/library' ...)
  ```
  `grep -oP` (PCRE) is **not available in macOS BSD grep**. On `aarch64-darwin` this silently fails → `R_LIBS_SITE` is empty. Either depend on `ripgrep` regex (`strings ... | rg -o '...'`) or use `gsed` (GNU sed).
- `overlays/plugins.nix` — `zk-nvim` skip list contains `zk.pickers.fzf_lua`; current zk-nvim package likely doesn't load that regardless, but harmless.
- `modules/module/settings/core.nix` — `config.settings.nvim_lua_env` references `lp.tiktoken_core` but `tiktoken_core` is **not in `catPkgs.general` or anywhere else** in these files. If there's an extra Lua/tiktoken module, fine; otherwise this option is placeholder dead code.
- `modules/module/settings/hosts.nix` — host `m` (marimo) is defined with `enable = false` but also configured with `package`, `argv0`, `addFlag`. Dead block.

---

## PORTABILITY / DARWIN issues

- Shell hook `grep -oP` (above) fails on macOS.
- `mkdir -p "$R_LIBS_USER"` fine; but `command -v R` on macOS returns the wrapper; the wrapper path injection still works.

---

## DEAD WEIGHT (shipped but unused)

- `catPkgs.r` includes `pkgs.rnvimserver` — `rnvimserver` is needed by R.nvim only when using the _socket_ transport; `21_datascience.lua` only uses vim-slime. Acceptable, but `rnvimserver` adds to build time. Include if you actually use it? Currently not used.
- `specs.utils-lazy` ships `nvim-dap`, `nvim-dap-ui`, `nvim-dap-virtual-text`, `nvim-lint` — none of these are referenced anywhere in `plugin/` or `lua/`. Consider moving them to a devShell-only cat, or drop them.
- `.gitignore` `*.R` — prevents tracking any new `.R` files. `tests/test.R` is already committed so it isn't actively harmful, but it's surprising for a repo whose default cats include R.
- `.commandcode/` dir is listed in `.gitignore` but is in the worktree; fine, but worth cleaning up if it's an artifact.

---

## IMPROVEMENTS given updated packages

- `catPkgs.markdown` — add `marksman` (it's the LSP used by `render-markdown.nvim` wiki links and configured in LSP). Same binary is needed by `render-markdown` for wiki link ISP.
- `vim.lsp.enable` servers configured but binaries missing in PATH:
  - `marksman` (LSP + render-markdown wiki integration).
  - `r_ls` (new R language server — package name in nixpkgs is likely `r-languageserver` or `r_ls`; current `catPkgs.r` doesn't ship either).
  - `clangd` — not required for this data-science setup; either drop or add to `external`.
  - `julials` — require `LanguageServer.jl` in `settings.lang_packages.julia` for it to be useful.
- `blink.cmp` is `1.10.2` but config pins `BLINK_VERSION = "v1.4.1"` for the non-Nix path. Either drop the `BLINK_VERSION` constant (let MiniDeps track HEAD or the tag pinned in flake) or update it to `v1.10.2`.
- `conform.nvim` already uses `lsp_format = "fallback"` in `23_editor.lua` and `ftplugin/python.lua`, but `10_keymap.lua` still calls the deprecated `lsp_fallback = true`. Align to `lsp_format = "fallback"`.
- `.github/workflows/check.yml` — add path filters for `plugin/**`, `lua/**`, `overlays/**`, `ftplugin/**`, `modules/**`.
- `tests/init.lua` smoke-test and `tests/test.R` are present but **not wired into `nix flake check`**. Add a trivial check that runs `lua tests/init.lua` via `nix-shell -A ...`.

---

## CONFLICTS

- `<leader>up` (terminal bracketed paste toggle in `10_keymap.lua`) conflicts with `mini.basics.mappings.option_toggle_prefix = "<leader>u"` (paste toggle), which is set up later in `20_startup.lua` via `now()`. Result: the user's `<leader>up` mapping gets overwritten. Portable workaround: remap to `<leader>tp` (terminal namespace) and keep `<leader>tb` as alternative — both already mapped in 10_keymap.
- `ftplugin/quarto.lua` resets quarto-nvim config (kills `lspFeatures`/`codeRunner` set in `21_datascience.lua`) and injects R plug mappings into non-R quarto chunks.

---

## CLEAN summary for implementer

### Immediate (not version-dependent)
1. Restore treesitter highlighting + textobjects in `plugin/20_startup.lua` using main-branch API.
2. Remove duplicate `vim.treesitter.language.register` in `21_datascience.lua`.
3. Fix `plugin/10_keymap.lua`: remove/resolve `Neogen`, `Pick projects`, `Config.insert_section` dangling mappings.
4. Replace deprecated `lsp_fallback = true` with `lsp_format = "fallback"` in `plugin/10_keymap.lua`.
5. Gate `ftplugin/quarto.lua` to not reset config and to not leak R keys into non-R chunks; guard against missing `quarto` plugin.
6. Remove duplicate `formatoptions` autocmds (or at least dedupe).
7. Dedupe `RNVIM_COMPLDIR` / `TMPDIR` setup (do it in one place).
8. Rename `.github/dependapot.yml` to `.github/dependabot.yml`.
9. Remove or gate dead host `m` in `hosts.nix`.
10. Remove unused `rsplit`? no, irrelevant.
11. Add `marksman` to `catPkgs.markdown` and remove orphan LSP entries or ship the binaries.
12. Remove dead `conform` formatter `my_styler` and dead blink `cmp_r` provider, or wire them up.

### Version-dependent (BLOCKED)
- **Reset the CodeCompanion version decision**: either pin to `v19.20.0` (keep config, fix `slash_commands.share`, drop the `<leader>aC` compatibility shim, keep `editing`/`compaction`) OR downgrade config to match `19.13.0` (remove `share`, collapse `context_management`).

### CI / packaging
- Fix `nix develop` usage and path filters in `.github/workflows/check.yml`.
- Replace `grep -oP` in `flake.nix` shellHook with portable `rg -o` or add `gnused` to `catPkgs.always` and use `gsed`.
- Wire `tests/init.lua` into `flake check`.

### Verification
- `nix flake check` on both `aarch64-darwin` and `x86_64-linux`.
- `nix build .#packages.<system>.default` succeeds (already does).
- Start nvim, verify :TSContext works, treesitter highlighting is on, and `]f`/`[f` textobjects move.
- Open a `.qmd` file with cats off → no ftplugin crash.
- Confirm `<leader>up` still toggles bracketed paste.
- Confirm `:Pick projects` and `:Neogen` and `Config.insert_section` no longer error (or are mapped to valid handlers).
