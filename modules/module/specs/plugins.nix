{
  config,
  pkgs,
  lib,
  ...
}:
{
  config.specs.gitPlugins = {
    data = [ ];
  };

  config.specs.r = {
    data = [
      config.nvim-lib.neovimPlugins.r
    ];
  };

  config.specs.markdown-lazy = {
    lazy = true;
    data = [
      config.nvim-lib.neovimPlugins.cmp-pandoc-references
    ];
  };

  config.specs.general = {
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

  config.specs.lua = {
    data = with pkgs.vimPlugins; [
      luvit-meta
      {
        data = lazydev-nvim;
        pname = "lazydev";
      }
    ];
  };

  config.specs.markdown = {
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

  config.specs.utils = {
    data = with pkgs.vimPlugins; [
      blink-cmp
      nvim-lspconfig
      nvim-treesitter-context
      nvim-treesitter-textobjects
      {
        data = pkgs.codecompanion-nvim;
        pname = "codecompanion";
      }
    ];
  };

  config.specs.treesitterParsers = {
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

  config.specs.utils-lazy = {
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

  config.specs.gitPlugins-lazy = {
    lazy = true;
    data = [ ];
  };
}
