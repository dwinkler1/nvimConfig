{
  config,
  pkgs,
  lib,
  ...
}:
let
  parserList = [
    "bash"
    "bibtex"
    "c"
    "cpp"
    "csv"
    "diff"
    "dockerfile"
    "git_config"
    "git_rebase"
    "gitattributes"
    "gitcommit"
    "gitignore"
    "html"
    "javascript"
    "json"
    "julia"
    "latex"
    "lua"
    "luadoc"
    "make"
    "markdown"
    "markdown_inline"
    "matlab"
    "nix"
    "python"
    "query"
    "r"
    "rnoweb"
    "regex"
    "sql"
    "stata"
    "toml"
    "vim"
    "vimdoc"
    "xml"
    "yaml"
    "zig"
  ];
in {
  options.settings.treesitter_parsers = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = parserList;
    description = "Tree-sitter parser names to install when the treesitterParsers category is enabled.";
  };

  config.specs.gitPlugins = lib.mkIf (config.cats.gitPlugins or false) {
    data = [];
  };

  config.specs.r = lib.mkIf (config.cats.r or false) {
    data = with pkgs.vimPlugins; [
      pkgs.r-nvim
      quarto-nvim
      {
        data = otter-nvim;
        pname = "otter";
      }
    ];
  };

  config.specs.markdown-lazy = lib.mkIf (config.cats.markdown or false) {
    lazy = true;
    data = [
      config.nvim-lib.neovimPlugins.cmp-pandoc-references
      pkgs.vimPlugins.image-nvim
    ];
  };

  config.specs.general = lib.mkIf (config.cats.general or false) {
    data = with pkgs.vimPlugins; [
      lze
      lzextras
      plenary-nvim
      neogit
      {
        data = mini-nvim;
        pname = "mini.nvim";
      }
      {
        data = cyberdream-nvim;
        pname = "cyberdream";
      }
      {
        data = onedark-nvim;
        pname = "onedark";
      }
      {
        data = tokyonight-nvim;
        pname = "tokyonight";
      }
      {
        data = kanagawa-nvim;
        pname = "kanagawa";
      }
      {
        data = gruvbox-nvim;
        pname = "gruvbox";
      }
      {
        data = nord-nvim;
        pname = "nord";
      }
      {
        data = dracula-nvim;
        pname = "dracula";
      }
      {
        data = vscode-nvim;
        pname = "vscode";
      }
      {
        data = nightfox-nvim;
        pname = "nightfox";
      }
      {
        data = catppuccin-nvim;
        pname = "catppuccin";
      }
    ];
  };

  config.specs.lua = lib.mkIf (config.cats.lua or false) {
    data = with pkgs.vimPlugins; [
      luvit-meta
      {
        data = lazydev-nvim;
        pname = "lazydev";
      }
    ];
  };

  config.specs.markdown = lib.mkIf (config.cats.markdown or false) {
    data = with pkgs.vimPlugins; [
      quarto-nvim
      render-markdown-nvim
      vimtex
      {
        data = otter-nvim;
        pname = "otter";
      }
      {
        data = zk-nvim;
        pname = "zk";
      }
    ];
  };

  config.specs.utils = lib.mkIf (config.cats.utils or false) {
    data = with pkgs.vimPlugins; [
      blink-cmp
      nvim-lspconfig
      nvim-treesitter-context
      nvim-treesitter-textobjects
      {
        data = pkgs.vimPlugins.nvim-treesitter;
        pname = "nvim-treesitter";
      }
      {
        data = pkgs.codecompanion-nvim.overrideAttrs (old: {
          doCheck = false;
        });
        pname = "codecompanion";
      }
    ] ++ builtins.attrValues pkgs.vimPlugins.nvim-treesitter.queries;
  };

  config.specs.treesitterParsers = lib.mkIf (config.cats.treesitterParsers or false) {
    data = map (name: pkgs.vimPlugins.nvim-treesitter-parsers.${name}) config.settings.treesitter_parsers;
  };

  config.specs.utils-lazy = lib.mkIf (config.cats.utils or false) {
    lazy = true;
    data = with pkgs.vimPlugins; [
      blink-compat
      blink-copilot
      cmp-cmdline
      colorful-menu-nvim
      conform-nvim
      copilot-lua
      nvim-lint
      vim-slime
    ];
  };

  # Lazy-loaded plugins needed when the `r` cat is on. Kept separate from
  # `utils-lazy` so users with `r=true` and `utils=false` still get the
  # R debugger (via vscDebugger) and in-buffer image rendering for plots.
  config.specs.r-lazy = lib.mkIf (config.cats.r or false) {
    lazy = true;
    data = with pkgs.vimPlugins; [
      nvim-dap
      nvim-dap-ui
      nvim-dap-virtual-text
      image-nvim
    ];
  };

  config.specs.gitPlugins-lazy = lib.mkIf (config.cats.gitPlugins or false) {
    lazy = true;
    data = [];
  };
}
