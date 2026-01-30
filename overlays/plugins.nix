{ ... }:
final: prev:
{
  codecompanion-nvim = prev.vimPlugins.codecompanion-nvim.overrideAttrs {
    checkInputs = with prev.vimPlugins; [
      blink-cmp
      mini-nvim
    ];
    dependencies = [ prev.vimPlugins.plenary-nvim ];
    nvimSkipModules = [
      "codecompanion.actions.static"
      "codecompanion.actions.init"
      "minimal"
      "codecompanion.providers.actions.fzf_lua"
      "codecompanion.providers.completion.cmp.setup"
      "codecompanion.providers.actions.telescope"
      "codecompanion.providers.actions.snacks"
    ];
  };
  zk-nvim = prev.vimPlugins.zk-nvim.overrideAttrs {
    nvimSkipModules = [
      "zk.pickers.fzf_lua"
    ];
  };
}
