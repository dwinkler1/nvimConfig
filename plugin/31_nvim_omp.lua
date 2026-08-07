-- omp bridge entrypoint: start the RPC socket as early as possible so the omp
-- harness can read this instance's buffers on demand (see lua/nvim_omp/init.lua
-- and .omp/tools/nvim_buffers.mjs). Safe to fail silently — the socket is a
-- convenience, not a dependency of the editor.
local ok, nvim_omp = pcall(require, "nvim_omp")
if ok then
  nvim_omp.start()
end