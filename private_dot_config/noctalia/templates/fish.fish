set -U fish_color_autosuggestion {{colors.terminal_bright_black.default.hex_stripped}}
set -U fish_color_cancel {{colors.terminal_normal_red.default.hex_stripped}}
set -U fish_color_command {{colors.terminal_normal_blue.default.hex_stripped}}
set -U fish_color_comment {{colors.terminal_bright_black.default.hex_stripped}}
set -U fish_color_cwd {{colors.terminal_normal_yellow.default.hex_stripped}}
set -U fish_color_cwd_root {{colors.terminal_normal_red.default.hex_stripped}}
set -U fish_color_end {{colors.terminal_bright_yellow.default.hex_stripped}}
set -U fish_color_error {{colors.terminal_normal_red.default.hex_stripped}}
set -U fish_color_escape {{colors.terminal_bright_red.default.hex_stripped}}
set -U fish_color_gray {{colors.terminal_bright_black.default.hex_stripped}}
set -U fish_color_history_current --bold
set -U fish_color_host {{colors.terminal_normal_blue.default.hex_stripped}}
set -U fish_color_host_remote {{colors.terminal_normal_green.default.hex_stripped}}
set -U fish_color_keyword {{colors.terminal_normal_red.default.hex_stripped}}
set -U fish_color_normal {{colors.terminal_foreground.default.hex_stripped}}
set -U fish_color_operator {{colors.terminal_normal_magenta.default.hex_stripped}}
set -U fish_color_option {{colors.terminal_normal_green.default.hex_stripped}}
set -U fish_color_param {{colors.terminal_bright_red.default.hex_stripped}}
set -U fish_color_quote {{colors.terminal_normal_green.default.hex_stripped}}
set -U fish_color_redirection {{colors.terminal_bright_magenta.default.hex_stripped}}
set -U fish_color_search_match --background={{colors.terminal_selection_bg.default.hex_stripped}}
set -U fish_color_selection --background={{colors.terminal_selection_bg.default.hex_stripped}}
set -U fish_color_status {{colors.terminal_normal_red.default.hex_stripped}}
set -U fish_color_user {{colors.terminal_normal_cyan.default.hex_stripped}}
set -U fish_color_valid_path --underline
set -U fish_pager_color_completion {{colors.terminal_foreground.default.hex_stripped}}
set -U fish_pager_color_description {{colors.terminal_bright_black.default.hex_stripped}}
set -U fish_pager_color_prefix {{colors.terminal_bright_magenta.default.hex_stripped}}
set -U fish_pager_color_progress {{colors.terminal_bright_black.default.hex_stripped}}

set -Ux FZF_DEFAULT_OPTS "\
--color=bg+:{{colors.surface_variant.default.hex}}
--color=bg:{{colors.surface.default.hex}}
--color=spinner:{{colors.terminal_cursor.default.hex}}
--color=hl:{{colors.error.default.hex}}
--color=fg:{{colors.terminal_foreground.default.hex}}
--color=header:{{colors.error.default.hex}}
--color=info:{{colors.primary.default.hex}}
--color=pointer:{{colors.terminal_cursor.default.hex}}
--color=marker:{{colors.on_surface_variant.default.hex}}
--color=fg+:{{colors.on_surface.default.hex}}
--color=prompt:{{colors.primary.default.hex}}
--color=hl+:{{colors.error.default.hex}}
--color=selected-bg:{{colors.terminal_normal_black.default.hex}}
--color=border:{{colors.terminal_selection_bg.default.hex}}
--color=label:{{colors.on_surface.default.hex}}"
