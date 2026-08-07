{ ... }:
final: prev:
{
  zk-nvim = prev.vimPlugins.zk-nvim.overrideAttrs {
    nvimSkipModules = [
      "zk.pickers.fzf_lua"
    ];
  };
}
