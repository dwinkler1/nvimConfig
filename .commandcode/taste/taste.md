# nix
- For R.nvim in the Nix wrapper, both RNVIM_COMPLDIR (C server compilation) and a writable R_LIBS_USER directory (nvimcom R package installation) must be configured — fixing only one leaves permission errors in the other. Confidence: 0.65
- For R.nvim writable directories (RNVIM_COMPLDIR, R_LIBS_USER, TMPDIR), prefer project-local paths (e.g., $PWD/.Rlibs) over global cache paths — the cache approach may let the build succeed but still fail at runtime. Confidence: 0.70
- Do not use lib.mkDefault on values consumed by lib.optionals or other boolean-checking functions — mkDefault wraps values in a priority set that fails "expected a Boolean" at evaluation time. Use plain booleans for inline conditionals, reserving mkDefault for module options resolved by the merge system. Confidence: 0.70

# Taste (Continuously Learned by [CommandCode][cmd])

[cmd]: https://commandcode.ai/

