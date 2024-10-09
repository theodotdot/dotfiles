local wezterm = require("wezterm")
local mux = wezterm.mux
local c = wezterm.config_builder()

-- build your config according to
-- https://wezfurlong.org/wezterm/config/lua/wezterm/config_builder.html

-- to have specific setup on startup
wezterm.on('gui-startup', function(cmd)
  -- allow `wezterm start -- something` to affect what we spawn
  -- in our initial window
  local args = {}
  if cmd then
    args = cmd.args
  end

  -- Set a workspace for dbt on a current project
  -- Top pane is for the editor, bottom pane is for the build tool
  local project_dir = wezterm.home_dir .. '/dbt'
  local tab, pane, window = mux.spawn_window {
    workspace = 'dbt',
    cwd = project_dir,
    args = args,
  }

  window:gui_window():maximize()

  wezterm.sleep_ms(2)

  local terminal_pane = pane:split {
    direction = 'Bottom',
    size = 0.2,
    cwd = project_dir,
  }

-- Send 'hx' to the main pane (top)
  pane:send_text 'hx\n'

  -- Send 'sourcevenv' to the bottom pane (terminal)
  --terminal_pane:send_text 'sourcevenv\n'

  -- We want to startup in the dbt workspace
  mux.set_active_workspace 'dbt'
end)

-- font
c.font = wezterm.font("MonoLisa Nerd Font")

-- Enable the scrollbar.
-- It will occupy the right window padding space.
-- If right padding is set to 0 then it will be increased
-- to a single cell width
c.enable_scroll_bar = true

-- keybinds
--c.disable_default_key_bindings = true

c.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

c.keys = {

    -- custom key binds
    
     -- split vertical
    { key = 'v', mods = 'LEADER', action = wezterm.action.SplitVertical{ domain =  'CurrentPaneDomain' } },
    -- split horizontal
    { key = 'h', mods = 'LEADER', action = wezterm.action.SplitHorizontal{ domain =  'CurrentPaneDomain' } },
    
    -- maximise/minimise current pane
    { key = 'm', mods = 'LEADER', action = wezterm.action.TogglePaneZoomState },

    -- switch pane
    { key = 'h', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Left' },
    { key = 'j', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Down' },
    { key = 'k', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Up' },
    { key = 'l', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Right' },
    
    
    -- resize pane
    { key = 'h', mods = 'SUPER|ALT', action = wezterm.action.AdjustPaneSize{ 'Left', 1 } },
    { key = 'j', mods = 'SUPER|ALT', action = wezterm.action.AdjustPaneSize{ 'Down', 1 } },
    { key = 'k', mods = 'SUPER|ALT', action = wezterm.action.AdjustPaneSize{ 'Up', 1 } },
    { key = 'l', mods = 'SUPER|ALT', action = wezterm.action.AdjustPaneSize{ 'Right', 1 } },
    
    -- close current tab
    { key = 'q', mods = 'LEADER', action = wezterm.action.CloseCurrentTab{ confirm = true } },

    -- close current pane
    { key = 'w', mods = 'LEADER', action = wezterm.action.CloseCurrentPane { confirm = true } },
    
    -- reorganise panes
    { key = 'r', mods = 'LEADER', action = wezterm.action.RotatePanes "Clockwise" },
    { key = 'Space', mods = 'LEADER', action = wezterm.action.PaneSelect { mode = 'SwapWithActive' }},

    -- switch workspace
    { key = 'F2', mods = 'LEADER', action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' }, },


    -- default key binds
    { key = 'Tab', mods = 'CTRL', action = wezterm.action.ActivateTabRelative(1) },
    { key = 'Tab', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTabRelative(-1) },
    { key = 'Enter', mods = 'ALT', action = wezterm.action.ToggleFullScreen },
    { key = '!', mods = 'CTRL', action = wezterm.action.ActivateTab(0) },
    { key = '!', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(0) },    
    { key = '#', mods = 'CTRL', action = wezterm.action.ActivateTab(2) },
    { key = '#', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(2) },
    { key = '$', mods = 'CTRL', action = wezterm.action.ActivateTab(3) },
    { key = '$', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(3) },
    { key = '%', mods = 'CTRL', action = wezterm.action.ActivateTab(4) },
    { key = '%', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(4) },
    { key = '&', mods = 'CTRL', action = wezterm.action.ActivateTab(6) },
    { key = '&', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(6) },
    { key = '(', mods = 'CTRL', action = wezterm.action.ActivateTab(-1) },
    { key = '(', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(-1) },
    { key = ')', mods = 'CTRL', action = wezterm.action.ResetFontSize },
    { key = ')', mods = 'SHIFT|CTRL', action = wezterm.action.ResetFontSize },
    { key = '*', mods = 'CTRL', action = wezterm.action.ActivateTab(7) },
    { key = '*', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(7) },
    { key = '+', mods = 'CTRL', action = wezterm.action.IncreaseFontSize },
    { key = '+', mods = 'SHIFT|CTRL', action = wezterm.action.IncreaseFontSize },
    { key = '-', mods = 'CTRL', action = wezterm.action.DecreaseFontSize },
    { key = '-', mods = 'SHIFT|CTRL', action = wezterm.action.DecreaseFontSize },
    { key = '-', mods = 'SUPER', action = wezterm.action.DecreaseFontSize },
    { key = '0', mods = 'CTRL', action = wezterm.action.ResetFontSize },
    { key = '0', mods = 'SHIFT|CTRL', action = wezterm.action.ResetFontSize },
    { key = '0', mods = 'SUPER', action = wezterm.action.ResetFontSize },
    { key = '1', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(0) },
    { key = '1', mods = 'SUPER', action = wezterm.action.ActivateTab(0) },
    { key = '2', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(1) },
    { key = '2', mods = 'SUPER', action = wezterm.action.ActivateTab(1) },
    { key = '3', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(2) },
    { key = '3', mods = 'SUPER', action = wezterm.action.ActivateTab(2) },
    { key = '4', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(3) },
    { key = '4', mods = 'SUPER', action = wezterm.action.ActivateTab(3) },
    { key = '5', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(4) },
    { key = '5', mods = 'SHIFT|ALT|CTRL', action = wezterm.action.SplitHorizontal{ domain =  'CurrentPaneDomain' } },
    { key = '5', mods = 'SUPER', action = wezterm.action.ActivateTab(4) },
    { key = '6', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(5) },
    { key = '6', mods = 'SUPER', action = wezterm.action.ActivateTab(5) },
    { key = '7', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(6) },
    { key = '7', mods = 'SUPER', action = wezterm.action.ActivateTab(6) },
    { key = '8', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(7) },
    { key = '8', mods = 'SUPER', action = wezterm.action.ActivateTab(7) },
    { key = '9', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(-1) },
    { key = '9', mods = 'SUPER', action = wezterm.action.ActivateTab(-1) },
    { key = '=', mods = 'CTRL', action = wezterm.action.IncreaseFontSize },
    { key = '=', mods = 'SHIFT|CTRL', action = wezterm.action.IncreaseFontSize },
    { key = '=', mods = 'SUPER', action = wezterm.action.IncreaseFontSize },
    { key = '@', mods = 'CTRL', action = wezterm.action.ActivateTab(1) },
    { key = '@', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(1) },
    { key = 'C', mods = 'CTRL', action = wezterm.action.CopyTo 'Clipboard' },
    { key = 'C', mods = 'SHIFT|CTRL', action = wezterm.action.CopyTo 'Clipboard' },
    { key = 'F', mods = 'CTRL', action = wezterm.action.Search 'CurrentSelectionOrEmptyString' },
    { key = 'F', mods = 'SHIFT|CTRL', action = wezterm.action.Search 'CurrentSelectionOrEmptyString' },
    { key = 'K', mods = 'CTRL', action = wezterm.action.ClearScrollback 'ScrollbackOnly' },
    { key = 'K', mods = 'SHIFT|CTRL', action = wezterm.action.ClearScrollback 'ScrollbackOnly' },
    { key = 'L', mods = 'CTRL', action = wezterm.action.ShowDebugOverlay },
    { key = 'L', mods = 'SHIFT|CTRL', action = wezterm.action.ShowDebugOverlay },
    { key = 'M', mods = 'CTRL', action = wezterm.action.Hide },
    { key = 'M', mods = 'SHIFT|CTRL', action = wezterm.action.Hide },
    { key = 'N', mods = 'CTRL', action = wezterm.action.SpawnWindow },
    { key = 'N', mods = 'SHIFT|CTRL', action = wezterm.action.SpawnWindow },
    { key = 'P', mods = 'CTRL', action = wezterm.action.ActivateCommandPalette },
    { key = 'P', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateCommandPalette },
    { key = 'R', mods = 'CTRL', action = wezterm.action.ReloadConfiguration },
    { key = 'R', mods = 'SHIFT|CTRL', action = wezterm.action.ReloadConfiguration },
    { key = 'T', mods = 'CTRL', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
    { key = 'T', mods = 'SHIFT|CTRL', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
    { key = 'U', mods = 'CTRL', action = wezterm.action.CharSelect{ copy_on_select = true, copy_to =  'ClipboardAndPrimarySelection' } },
    { key = 'U', mods = 'SHIFT|CTRL', action = wezterm.action.CharSelect{ copy_on_select = true, copy_to =  'ClipboardAndPrimarySelection' } },
    { key = 'V', mods = 'CTRL', action = wezterm.action.PasteFrom 'Clipboard' },
    { key = 'V', mods = 'SHIFT|CTRL', action = wezterm.action.PasteFrom 'Clipboard' },
    { key = 'X', mods = 'CTRL', action = wezterm.action.ActivateCopyMode },
    { key = 'X', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateCopyMode },
    { key = '[', mods = 'SHIFT|SUPER', action = wezterm.action.ActivateTabRelative(-1) },
    { key = ']', mods = 'SHIFT|SUPER', action = wezterm.action.ActivateTabRelative(1) },
    { key = '^', mods = 'CTRL', action = wezterm.action.ActivateTab(5) },
    { key = '^', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateTab(5) },
    { key = '_', mods = 'CTRL', action = wezterm.action.DecreaseFontSize },
    { key = '_', mods = 'SHIFT|CTRL', action = wezterm.action.DecreaseFontSize },
    { key = 'c', mods = 'SHIFT|CTRL', action = wezterm.action.CopyTo 'Clipboard' },
    { key = 'c', mods = 'SUPER', action = wezterm.action.CopyTo 'Clipboard' },
    { key = 'f', mods = 'SHIFT|CTRL', action = wezterm.action.Search 'CurrentSelectionOrEmptyString' },
    { key = 'f', mods = 'SUPER', action = wezterm.action.Search 'CurrentSelectionOrEmptyString' },
    { key = 'k', mods = 'SHIFT|CTRL', action = wezterm.action.ClearScrollback 'ScrollbackOnly' },
    { key = 'k', mods = 'SUPER', action = wezterm.action.ClearScrollback 'ScrollbackOnly' },
    { key = 'l', mods = 'SHIFT|CTRL', action = wezterm.action.ShowDebugOverlay },
    { key = 'm', mods = 'SHIFT|CTRL', action = wezterm.action.Hide },
    { key = 'm', mods = 'SUPER', action = wezterm.action.Hide },
    { key = 'n', mods = 'SHIFT|CTRL', action = wezterm.action.SpawnWindow },
    { key = 'n', mods = 'SUPER', action = wezterm.action.SpawnWindow },
    { key = 'p', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateCommandPalette },
    { key = 'r', mods = 'SHIFT|CTRL', action = wezterm.action.ReloadConfiguration },
    { key = 'r', mods = 'SUPER', action = wezterm.action.ReloadConfiguration },
    { key = 't', mods = 'SHIFT|CTRL', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
    { key = 't', mods = 'SUPER', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
    { key = 'u', mods = 'SHIFT|CTRL', action = wezterm.action.CharSelect{ copy_on_select = true, copy_to =  'ClipboardAndPrimarySelection' } },
    { key = 'v', mods = 'SHIFT|CTRL', action = wezterm.action.PasteFrom 'Clipboard' },
    { key = 'x', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateCopyMode },
    { key = '{', mods = 'SUPER', action = wezterm.action.ActivateTabRelative(-1) },
    { key = '{', mods = 'SHIFT|SUPER', action = wezterm.action.ActivateTabRelative(-1) },
    { key = '}', mods = 'SUPER', action = wezterm.action.ActivateTabRelative(1) },
    { key = '}', mods = 'SHIFT|SUPER', action = wezterm.action.ActivateTabRelative(1) },
    { key = 'phys:Space', mods = 'SHIFT|CTRL', action = wezterm.action.QuickSelect },
    { key = 'PageUp', mods = 'SHIFT', action = wezterm.action.ScrollByPage(-1) },
    { key = 'PageUp', mods = 'CTRL', action = wezterm.action.ActivateTabRelative(-1) },
    { key = 'PageUp', mods = 'SHIFT|CTRL', action = wezterm.action.MoveTabRelative(-1) },
    { key = 'PageDown', mods = 'SHIFT', action = wezterm.action.ScrollByPage(1) },
    { key = 'PageDown', mods = 'CTRL', action = wezterm.action.ActivateTabRelative(1) },
    { key = 'PageDown', mods = 'SHIFT|CTRL', action = wezterm.action.MoveTabRelative(1) },
    { key = 'Insert', mods = 'SHIFT', action = wezterm.action.PasteFrom 'PrimarySelection' },
    { key = 'Insert', mods = 'CTRL', action = wezterm.action.CopyTo 'PrimarySelection' },
    { key = 'Copy', mods = 'NONE', action = wezterm.action.CopyTo 'Clipboard' },
    { key = 'Paste', mods = 'NONE', action = wezterm.action.PasteFrom 'Clipboard' },
  }


-- the plugin is currently made for Catppuccin only
c.color_scheme = "Catppuccin Macchiato"

-- then finally apply the plugin
-- these are currently the defaults:
wezterm.plugin.require("https://github.com/nekowinston/wezterm-bar").apply_to_config(c, {
  position = "bottom",
  max_width = 32,
  dividers = "slant_right", -- or "slant_left", "arrows", "rounded", false
  indicator = {
    leader = {
      enabled = true,
      off = " ",
      on = " ",
    },
    mode = {
      enabled = true,
      names = {
        resize_mode = "RESIZE",
        copy_mode = "VISUAL",
        search_mode = "SEARCH",
      },
    },
  },
  tabs = {
    numerals = "arabic", -- or "roman"
    pane_count = "superscript", -- or "subscript", false
    brackets = {
      active = { "", ":" },
      inactive = { "", ":" },
    },
  },
  clock = { -- note that this overrides the whole set_right_status
    enabled = false,
    format = "%H:%M", -- use https://wezfurlong.org/wezterm/config/lua/wezterm.time/Time/format.html
  },
})
wezterm.on('update-right-status', function(window, pane)
  window:set_right_status(window:active_workspace())
end)
return c
