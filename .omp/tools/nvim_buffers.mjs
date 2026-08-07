// omp custom tool: read this machine's running Neovim buffers over its RPC
// socket. Read-only and on-demand — the model calls it when it needs buffer
// content; nothing is injected into prompts automatically.
//
// Install options
//   1. Project scope (this project): keep the file in .omp/tools/ — omp picks it
//      up when a session's cwd is inside this repository.
//   2. All projects:  mkdir -p ~/.omp/agent/tools
//                          ln -s "$PWD/.omp/tools/nvim_buffers.mjs" ~/.omp/agent/tools/
//      then restart `omp` (custom tools are loaded at session bootstrap).
//
// Socket contract (must match lua/nvim_omp/init.lua):
//   path = $NVIM_OMP_SOCKET  or  <XDG_STATE_HOME|~/.local/state>/nvim/omp.sock
//   The nvim instance running this config starts the listener at startup.
//   Only one instance can own the socket; a second instance never replaces a
//   live owner. Remove a stale socket manually only after confirming no nvim
//   process owns it.

import os from "node:os";
import path from "node:path";

// Safe default cap so a large buffer cannot flood the conversation.
const DEFAULT_MAX_LINES = 2000;

export default function (pi) {
  // Resolve socket path with the same rule as lua/nvim_omp/init.lua.
  const socketPath = () => {
    const env = process.env.NVIM_OMP_SOCKET;
    if (env) return env;
    const state =
      process.env.XDG_STATE_HOME ||
      path.join(os.homedir(), ".local", "state");
    return path.join(state, "nvim", "omp.sock");
  };

  // Evaluate expr in the remote nvim via `nvim --server`; returns parsed JSON.
  const rpc = async (expr, signal) => {
    const bin = process.env.NVIM_BIN || "nvim";
    const { code, stdout, stderr, killed } = await pi.exec(
      bin,
      ["--server", socketPath(), "--remote-expr", expr],
      { signal },
    );
    if (killed) throw new Error("cancelled");
    if (code !== 0) {
      const why = String(stderr || "").trim();
      throw new Error(
        why.includes("E247")
          ? `No Neovim RPC socket at ${socketPath()}. ` +
            "Start nvim (or vv) first — the 31_nvim_omp.lua plugin binds the socket at startup."
          : `nvim RPC failed (${code}): ${why}`,
      );
    }
    const text = String(stdout ?? "").trim();
    if (!text) throw new Error("empty response from nvim RPC");
    return JSON.parse(text);
  };

  // Resolve a buffer argument (number, string, or partial path) to a buffer
  // number. Returns null when nothing matches.
  const resolveBuf = async (buffer, signal) => {
    if (buffer === undefined || buffer === null || buffer === "") {
      return rpc("json_encode(nvim_get_current_buf())", signal);
    }
    if (typeof buffer === "number") return buffer;
    const bufnum = Number(buffer);
    if (Number.isInteger(bufnum) && bufnum > 0) return bufnum;
    const list = await rpc(
      "json_encode(map(nvim_list_bufs(), {i, v -> " +
        "{'bufnr': v, 'name': nvim_buf_get_name(v)}}))",
      signal,
    );
    const q = String(buffer);
    const hit =
      list.find(
        (b) => b.name === q || b.name.endsWith("/" + q) || b.name.endsWith(q),
      ) ||
      list.find((b) => b.name.includes(q));
    return hit ? hit.bufnr : null;
  };

  const tools = [];

  // List open buffers -----------------------------------------------
  tools.push({
    name: "nvim_buffers",
    label: "Neovim Buffers",
    description:
      "List the buffers currently open in the user's running Neovim " +
      "(number, name, current/loaded state, modified). Use before " +
      "nvim_buffer to pick a buffer.",
    parameters: pi.arktype({}),
    async execute(_id, _params, _onUpdate, _ctx, _signal) {
      const list = await rpc(
        "json_encode(map(nvim_list_bufs(), {i, v -> {'nr': v, " +
          "'name': nvim_buf_get_name(v), " +
          "'current': v == nvim_get_current_buf(), " +
          "'loaded': nvim_buf_is_loaded(v), " +
          "'modified': getbufvar(v, '&modified')}}))",
      );
      if (!list.length) {
        return { content: [{ type: "text", text: "No buffers open." }] };
      }
      const lines = list.map(
        (b) =>
          `${b.nr}\t${b.name || "[no name]"}\t` +
          `${b.current ? "current " : ""}` +
          `${b.loaded ? "" : "unloaded "}` +
          `${b.modified ? "modified" : ""}`.trim(),
      );
      return {
        content: [
          {
            type: "text",
            text: `Open buffers (${list.length}):\n` + lines.join("\n"),
          },
        ],
      };
    },
  });

  // Read a single buffer, line-capped -------------------------------
  tools.push({
    name: "nvim_buffer",
    label: "Neovim Buffer",
    description:
      "Read lines of a Neovim buffer. `buffer` accepts the current buffer " +
      "(default), a buffer number from nvim_buffers, or a file name/path " +
      "open in Neovim. `maxLines` caps the returned lines (default 2000); " +
      "pass a larger value explicitly to read more of a long buffer.",
    parameters: pi.arktype({
      buffer: "string? | number?",
      maxLines: "number?",
    }),
    async execute(_id, params, _onUpdate, _ctx, signal) {
      const buf = await resolveBuf(params.buffer, signal);
      if (buf === null) {
        return {
          content: [
            {
              type: "text",
              text: `No buffer matches '${params.buffer}'. List open buffers with nvim_buffers.`,
            },
          ],
        };
      }
      const maxLines =
        Number.isInteger(params.maxLines) && params.maxLines > 0
          ? Math.min(params.maxLines, 100000)
          : DEFAULT_MAX_LINES;

      const expr =
        `json_encode({'name': nvim_buf_get_name(${buf}), ` +
        `'total': nvim_buf_line_count(${buf}), ` +
        `'lines': nvim_buf_get_lines(${buf}, 0, ${maxLines}, 0)})`;
      const { name, total, lines } = await rpc(expr, signal);
      if (!total) {
        return {
          content: [
            { type: "text", text: `Buffer ${buf} (${name}) is empty.` },
          ],
        };
      }
      const truncated =
        total > lines.length
          ? `\n... ${total - lines.length} more lines ` +
            `(raise maxLines to read them)`
          : "";
      const numbered = lines.map((l, i) => `${i + 1}: ${l}`).join("\n");
      return {
        content: [
          {
            type: "text",
            text:
              `Buffer ${buf} (${name}), ${total} lines:\n` +
              numbered +
              truncated,
          },
        ],
      };
    },
  });

  return tools;
}