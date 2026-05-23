{
  config,
  pkgs,
  lib,
  ...
}: {
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
        data = pkgs.codecompanion-nvim.overrideAttrs (old: {
          doCheck = false;
        });
        pname = "codecompanion";
      }
    ];
  };

  config.specs.treesitterParsers = lib.mkIf (config.cats.treesitterParsers or false) {
    data = with pkgs.vimPlugins.nvim-treesitter-parsers; [
      bash
      c
      cpp
      csv
      diff
      dockerfile
      git_config
      git_rebase
      gitattributes
      gitcommit
      gitignore
      html
      javascript
      json
      julia
      latex
      lua
      luadoc
      make
      markdown
      markdown_inline
      nix
      python
      query
      r
      rnoweb
      regex
      sql
      toml
      vim
      vimdoc
      xml
      yaml
      zig
    ];
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
      nvim-dap
      nvim-dap-ui
      nvim-dap-virtual-text
      nvim-lint
      vim-slime
    ];
  };

  config.specs.gitPlugins-lazy = lib.mkIf (config.cats.gitPlugins or false) {
    lazy = true;
    data = [];
  };
}
