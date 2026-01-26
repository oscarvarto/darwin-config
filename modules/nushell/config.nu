# Nushell Config File

# For more information on defining custom themes, see
# https://www.nushell.sh/book/coloring_and_theming.html
# And here is the theme collection
# https://github.com/nushell/nu_scripts/tree/main/themes
# Theme definitions - must be defined before $env.config block
# Catppuccin Mocha theme (dark)
let catppuccin_mocha_theme = {
    # color for nushell primitives
    separator: "#cdd6f4"      # text
    leading_trailing_space_bg: { attr: n }
    header: { fg: "#a6e3a1" attr: b }  # green bold
    empty: "#89b4fa"         # blue
    bool: { |v| if $v { "#a6e3a1" } else { "#f38ba8" } }  # green/red
    int: "#fab387"           # peach
    filesize: "#89b4fa"      # blue
    duration: "#f9e2af"      # yellow
    date: "#cba6f7"          # mauve
    range: "#f9e2af"         # yellow
    float: "#fab387"         # peach
    string: "#a6e3a1"        # green
    nothing: "#6c7086"       # overlay0
    binary: "#f38ba8"        # red
    cell-path: "#cdd6f4"     # text
    row_index: { fg: "#a6e3a1" attr: b }  # green bold
    record: "#cdd6f4"        # text
    list: "#cdd6f4"          # text
    block: "#89b4fa"         # blue
    hints: "#6c7086"         # overlay0
    search_result: { fg: "#11111b" bg: "#f38ba8" }  # crust on red
    shape_and: { fg: "#cba6f7" attr: b }          # mauve bold
    shape_binary: { fg: "#cba6f7" attr: b }       # mauve bold
    shape_block: { fg: "#89b4fa" attr: b }        # blue bold
    shape_bool: "#f5c2e7"                        # pink
    shape_closure: { fg: "#a6e3a1" attr: b }     # green bold
    shape_custom: "#89b4fa"                      # blue
    shape_datetime: { fg: "#cba6f7" attr: b }    # mauve bold
    shape_directory: "#89b4fa"                   # blue
    shape_external: "#a6e3a1"                    # green
    shape_externalarg: { fg: "#a6e3a1" attr: b } # green bold
    shape_external_resolved: { fg: "#f9e2af" attr: b }  # yellow bold
    shape_filepath: "#89b4fa"                    # blue
    shape_flag: { fg: "#89b4fa" attr: b }        # blue bold
    shape_float: { fg: "#fab387" attr: b }       # peach bold
    shape_garbage: { fg: "#cdd6f4" bg: "#f38ba8" attr: b }  # text on red bold
    shape_globpattern: { fg: "#89b4fa" attr: b } # blue bold
    shape_int: { fg: "#fab387" attr: b }         # peach bold
    shape_internalcall: { fg: "#89b4fa" attr: b }  # blue bold
    shape_keyword: { fg: "#cba6f7" attr: b }     # mauve bold
    shape_list: { fg: "#89b4fa" attr: b }        # blue bold
    shape_literal: "#89b4fa"                     # blue
    shape_match_pattern: "#a6e3a1"              # green
    shape_matching_brackets: { attr: u }         # underline
    shape_nothing: "#f5c2e7"                     # pink
    shape_operator: "#f9e2af"                    # yellow
    shape_or: { fg: "#cba6f7" attr: b }          # mauve bold
    shape_pipe: { fg: "#cba6f7" attr: b }        # mauve bold
    shape_range: { fg: "#f9e2af" attr: b }       # yellow bold
    shape_record: { fg: "#89b4fa" attr: b }      # blue bold
    shape_redirection: { fg: "#cba6f7" attr: b } # mauve bold
    shape_signature: { fg: "#a6e3a1" attr: b }  # green bold
    shape_string: "#a6e3a1"                     # green
    shape_string_interpolation: { fg: "#89b4fa" attr: b }  # blue bold
    shape_table: { fg: "#89b4fa" attr: b }       # blue bold
    shape_variable: "#cba6f7"                    # mauve
    shape_vardecl: "#cba6f7"                     # mauve
    shape_raw_string: "#f5c2e7"                  # pink
}

# Catppuccin Latte theme (light) - high contrast for light backgrounds
let catppuccin_latte_theme = {
    # color for nushell primitives
    separator: "#4c4f69"      # text (dark)
    leading_trailing_space_bg: { attr: n }
    header: { fg: "#40a02b" attr: b }  # green bold
    empty: "#1e66f5"         # blue
    bool: { |v| if $v { "#40a02b" } else { "#d20f39" } }  # green/red
    int: "#fe640b"           # peach
    filesize: "#1e66f5"      # blue
    duration: "#df8e1d"      # yellow
    date: "#8839ef"          # mauve
    range: "#df8e1d"         # yellow
    float: "#fe640b"         # peach
    string: "#40a02b"        # green
    nothing: "#9ca0b0"       # overlay0
    binary: "#d20f39"        # red
    cell-path: "#4c4f69"     # text
    row_index: { fg: "#40a02b" attr: b }  # green bold
    record: "#4c4f69"        # text
    list: "#4c4f69"          # text
    block: "#1e66f5"         # blue
    hints: "#9ca0b0"         # overlay0
    search_result: { fg: "#eff1f5" bg: "#d20f39" }  # base on red
    shape_and: { fg: "#8839ef" attr: b }          # mauve bold
    shape_binary: { fg: "#8839ef" attr: b }       # mauve bold
    shape_block: { fg: "#1e66f5" attr: b }        # blue bold
    shape_bool: "#ea76cb"                        # pink
    shape_closure: { fg: "#40a02b" attr: b }     # green bold
    shape_custom: "#1e66f5"                      # blue
    shape_datetime: { fg: "#8839ef" attr: b }    # mauve bold
    shape_directory: "#1e66f5"                   # blue
    shape_external: "#40a02b"                    # green
    shape_externalarg: { fg: "#40a02b" attr: b } # green bold
    shape_external_resolved: { fg: "#df8e1d" attr: b }  # yellow bold
    shape_filepath: "#1e66f5"                    # blue
    shape_flag: { fg: "#1e66f5" attr: b }        # blue bold
    shape_float: { fg: "#fe640b" attr: b }       # peach bold
    shape_garbage: { fg: "#4c4f69" bg: "#d20f39" attr: b }  # text on red bold
    shape_globpattern: { fg: "#1e66f5" attr: b } # blue bold
    shape_int: { fg: "#fe640b" attr: b }         # peach bold
    shape_internalcall: { fg: "#1e66f5" attr: b }  # blue bold
    shape_keyword: { fg: "#8839ef" attr: b }     # mauve bold
    shape_list: { fg: "#1e66f5" attr: b }        # blue bold
    shape_literal: "#1e66f5"                     # blue
    shape_match_pattern: "#40a02b"              # green
    shape_matching_brackets: { attr: u }         # underline
    shape_nothing: "#ea76cb"                     # pink
    shape_operator: "#df8e1d"                    # yellow
    shape_or: { fg: "#8839ef" attr: b }          # mauve bold
    shape_pipe: { fg: "#8839ef" attr: b }        # mauve bold
    shape_range: { fg: "#df8e1d" attr: b }       # yellow bold
    shape_record: { fg: "#1e66f5" attr: b }      # blue bold
    shape_redirection: { fg: "#8839ef" attr: b } # mauve bold
    shape_signature: { fg: "#40a02b" attr: b }  # green bold
    shape_string: "#40a02b"                     # green
    shape_string_interpolation: { fg: "#1e66f5" attr: b }  # blue bold
    shape_table: { fg: "#1e66f5" attr: b }       # blue bold
    shape_variable: "#8839ef"                    # mauve
    shape_vardecl: "#8839ef"                     # mauve
    shape_raw_string: "#ea76cb"                  # pink
}

# Theme aliases - must be defined before $env.config block
let dark_theme = $catppuccin_mocha_theme
let light_theme = $catppuccin_latte_theme

# Completers
let fish_completer = {|spans|
    fish --command $"complete '--do-complete=($spans | str replace --all "'" "\\'" | str join ' ')'"
    | from tsv --flexible --noheaders --no-infer
    | rename value description
    | update value {|row|
      let value = $row.value
      let need_quote = ['\' ',' '[' ']' '(' ')' ' ' '\t' "'" '"' "`"] | any {$in in $value}
      if ($need_quote and ($value | path exists)) {
        let expanded_path = if ($value starts-with ~) {$value | path expand --no-symlink} else {$value}
        $'"($expanded_path | str replace --all "\"" "\\\"")"'
      } else {$value}
    }
}

let carapace_completer = {|spans: list<string>|
    carapace $spans.0 nushell ...$spans
    | from json
    | if ($in | default [] | any {|| $in.display | str starts-with "ERR"}) { null } else { $in }
}

# This completer will use carapace by default
let external_completer = {|spans|
    let expanded_alias = scope aliases
    | where name == $spans.0
    | get -o 0.expansion

    let spans = if $expanded_alias != null {
        $spans
        | skip 1
        | prepend ($expanded_alias | split row ' ' | take 1)
    } else {
        $spans
    }

    match $spans.0 {
        # carapace completions are incorrect for nu
        nu => $fish_completer
        # fish completes commits and branch names in a nicer way
        git => $fish_completer
        # carapace doesn't have completions for asdf
        asdf => $fish_completer
        # carapace brew completer has a panic bug, use fish instead
        brew => $fish_completer
        _ => $carapace_completer
    } | do $in $spans
}

# The default config record. This is where much of your global configuration is setup.
$env.config = {
    show_banner: false # true or false to enable or disable the welcome banner at startup

    ls: {
        use_ls_colors: false # disable LS_COLORS to prevent theme conflicts
        clickable_links: true # enable or disable clickable links. Your terminal has to support links.
    }

    rm: {
        always_trash: false # always act as if -t was given. Can be overridden with -p
    }

    table: {
        mode: rounded # basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, other
        index_mode: always # "always" show indexes, "never" show indexes, "auto" = show indexes when a table has "index" column
        show_empty: true # show 'empty list' and 'empty record' placeholders for command output
        padding: { left: 1, right: 1 } # a left right padding of each column in a table
        trim: {
            methodology: wrapping # wrapping or truncating
            wrapping_try_keep_words: true # A strategy used by the 'wrapping' methodology
            truncating_suffix: "..." # A suffix used by the 'truncating' methodology
        }
        header_on_separator: false # show header text on separator/border line
        # abbreviated_row_count: 10 # limit data rows from top and bottom after reaching a set point
    }

    error_style: "fancy" # "fancy" or "plain" for screen reader-friendly error messages

    # datetime_format determines what a datetime rendered in the shell would look like.
    # Behavior without this configuration point will be to "humanize" the datetime display,
    # showing something like "a day ago."
    datetime_format: {
        # normal: '%a, %d %b %Y %H:%M:%S %z'    # shows up in displays of variables or other datetime's outside of tables
        # table: '%m/%d/%y %I:%M:%S%p'          # generally shows up in tabular outputs such as ls. commenting this out will change it to the default human readable datetime format
    }

    explore: {
        status_bar_background: { fg: "#1D1F21", bg: "#C4C9C6" },
        command_bar_text: { fg: "#C4C9C6" },
        highlight: { fg: "black", bg: "yellow" },
        status: {
            error: { fg: "white", bg: "red" },
            warn: {}
            info: {}
        },
        table: {
            split_line: { fg: "#404040" },
            selected_cell: { bg: light_blue },
            selected_row: {},
            selected_column: {},
        },
    }

    history: {
        max_size: 100_000 # Session has to be reloaded for this to take effect
        sync_on_enter: true # Enable to share history between multiple sessions, else you have to close the session to write history to file
        file_format: "HISTORY_FILE_FORMAT" # "sqlite" or "plaintext"
        isolation: true # only available with sqlite file_format. true enables history isolation, false disables it. true will allow the history to be isolated to the current session using up/down arrows. false will allow the history to be shared across all sessions.
    }

    completions: {
        case_sensitive: false # set to true to enable case-sensitive completions
        quick: true    # set this to false to prevent auto-selecting completions when only one remains
        partial: true    # set this to false to prevent partial filling of the prompt
        algorithm: "substring"    # prefix, substring, or fuzzy
        external: {
            enable: true # set to false to prevent nushell looking into $env.PATH to find more suggestions, `false` recommended for WSL users as this look up may be very slow
            max_results: 100 # Increased for better coverage with improved carapace
            completer: $external_completer
        }
        use_ls_colors: false # disable LS_COLORS to prevent theme conflicts in completions
    }

    # filesize options have been moved to other configuration sections in newer nushell versions

    cursor_shape: {
        emacs: blink_line # Use blinking line for better visibility
        vi_insert: blink_block # Use blinking block for better visibility in insert mode
        vi_normal: blink_underscore # Use blinking underscore for better visibility in normal mode
    }

    # Static default theme - will be updated after config load
    color_config: $dark_theme
    footer_mode: 25 # always, never, number_of_rows, auto
    float_precision: 2 # the precision for displaying floats in tables
    buffer_editor: "hx" # use emacsclient in terminal for buffer edits
    use_ansi_coloring: true
    bracketed_paste: true # enable bracketed paste, currently useless on windows
    edit_mode: vi # emacs, vi
    shell_integration: {
        # osc2 abbreviates the path if in the home_dir, sets the tab/window title, shows the running command in the tab/window title
        osc2: true
        # osc7 is a way to communicate the path to the terminal, this is helpful for spawning new tabs in the same directory
        osc7: true
        # osc8 is also implemented as the deprecated setting ls.show_clickable_links, it shows clickable links in ls output if your terminal supports it. show_clickable_links is deprecated in favor of osc8
        osc8: true
        # osc9_9 is from ConEmu and is starting to get wider support. It's similar to osc7 in that it communicates the path to the terminal
        osc9_9: false
        # osc133 is several escapes invented by Final Term which include the supported ones below.
        # 133;A - Mark prompt start
        # 133;B - Mark prompt end
        # 133;C - Mark pre-execution
        # 133;D;exit - Mark execution finished with exit code
        # This is used to enable terminals to know where the prompt is, the command is, where the command finishes, and where the output of the command is
        osc133: true
        # osc633 is closely related to osc133 but only exists in visual studio code (vscode) and supports their shell integration features
        # 633;A - Mark prompt start
        # 633;B - Mark prompt end
        # 633;C - Mark pre-execution
        # 633;D;exit - Mark execution finished with exit code
        # 633;E - NOT IMPLEMENTED - Explicitly set the command line with an optional nonce
        # 633;P;Cwd=<path> - Mark the current working directory and communicate it to the terminal
        # and also helps with the run recent menu in vscode
        osc633: true
        # reset_application_mode is escape \x1b[?1l and was added to help ssh work better
        reset_application_mode: true
    }
    render_right_prompt_on_last_line: false # true or false to enable or disable right prompt to be rendered on last line of the prompt.
    use_kitty_protocol: true # enables keyboard enhancement protocol implemented by kitty console, only if your terminal support this.
    highlight_resolved_externals: false # true enables highlighting of external commands in the repl resolved by which.
    recursion_limit: 50 # the maximum number of times nushell allows recursion before stopping it

    plugins: {} # Per-plugin configuration. See https://www.nushell.sh/contributor-book/plugins.html#configuration.

    plugin_gc: {
        # Configuration for plugin garbage collection
        default: {
            enabled: true # true to enable stopping of inactive plugins
            stop_after: 10sec # how long to wait after a plugin is inactive to stop it
        }
        plugins: {
            # alternate configuration for specific plugins, by name, for example:
            #
            # gstat: {
            #     enabled: false
            # }
        }
    }

    hooks: {
        pre_prompt: [
            # Ensure cursor visibility is restored (fixes cursor disappearing in Zellij tabs)
            { ansi cursor_on | print -n }
        ]
        pre_execution: [{ null }] # run before the repl input is run
        env_change: {
            PWD: [{|before, after| null }] # run if the PWD environment is different since the last repl input
        }
        display_output: "if (term size).columns >= 100 { table -e } else { table }" # run to display the output of a pipeline
        command_not_found: { null } # return an error message when a command is not found
    }

    menus: [
        # Configuration for default nushell menus
        # Note the lack of source parameter
        {
            name: completion_menu
            only_buffer_difference: false
            marker: "| "
            type: {
                layout: columnar
                columns: 4
                col_width: 20     # Optional value. If missing all the screen width is used to calculate column width
                col_padding: 2
            }
            style: {
                text: green
                selected_text: { attr: r }
                description_text: yellow
                match_text: { attr: u }
                selected_match_text: { attr: ur }
            }
        }
        {
            name: ide_completion_menu
            only_buffer_difference: false
            marker: "| "
            type: {
                layout: ide
                min_completion_width: 0,
                max_completion_width: 50,
                max_completion_height: 10, # will be limited by the available lines in the terminal
                padding: 0,
                border: true,
                cursor_offset: 0,
                description_mode: "prefer_right"
                min_description_width: 0
                max_description_width: 50
                max_description_height: 10
                description_offset: 1
                # If true, the cursor pos will be corrected, so the suggestions match up with the typed text
                #
                # C:\> str
                #      str join
                #      str trim
                #      str split
                correct_cursor_pos: false
            }
            style: {
                text: green
                selected_text: { attr: r }
                description_text: yellow
                match_text: { attr: u }
                selected_match_text: { attr: ur }
            }
        }
        {
            name: history_menu
            only_buffer_difference: true
            marker: "? "
            type: {
                layout: list
                page_size: 10
            }
            style: {
                text: green
                selected_text: green_reverse
                description_text: yellow
            }
        }
        {
            name: help_menu
            only_buffer_difference: true
            marker: "? "
            type: {
                layout: description
                columns: 4
                col_width: 20     # Optional value. If missing all the screen width is used to calculate column width
                col_padding: 2
                selection_rows: 4
                description_rows: 10
            }
            style: {
                text: green
                selected_text: green_reverse
                description_text: yellow
            }
        }
    ]

    keybindings: [
        {
            name: completion_menu
            modifier: none
            keycode: tab
            mode: [emacs vi_normal vi_insert]
            event: {
                until: [
                    { send: menu name: completion_menu }
                    { send: menunext }
                    { edit: complete }
                ]
            }
        }
        {
            name: ide_completion_menu
            modifier: control
            keycode: char_n
            mode: [emacs vi_normal vi_insert]
            event: {
                until: [
                    { send: menu name: ide_completion_menu }
                    { send: menunext }
                    { edit: complete }
                ]
            }
        }
        {
            name: history_menu
            modifier: control
            keycode: char_r
            mode: [emacs, vi_insert, vi_normal]
            event: { send: menu name: history_menu }
        }
        {
            name: help_menu
            modifier: none
            keycode: f1
            mode: [emacs, vi_insert, vi_normal]
            event: { send: menu name: help_menu }
        }
        {
            name: completion_previous_menu
            modifier: shift
            keycode: backtab
            mode: [emacs, vi_normal, vi_insert]
            event: { send: menuprevious }
        }
        {
            name: next_page_menu
            modifier: control
            keycode: char_x
            mode: emacs
            event: { send: menupagenext }
        }
        {
            name: undo_or_previous_page_menu
            modifier: control
            keycode: char_z
            mode: emacs
            event: {
                until: [
                    { send: menupageprevious }
                    { edit: undo }
                ]
            }
        }
        {
            name: escape
            modifier: none
            keycode: escape
            mode: [emacs, vi_normal, vi_insert]
            event: { send: esc }    # NOTE: does not appear to work
        }
        {
            name: cancel_command
            modifier: control
            keycode: char_c
            mode: [emacs, vi_normal, vi_insert]
            event: { send: ctrlc }
        }
        {
            name: quit_shell
            modifier: control
            keycode: char_d
            mode: [emacs, vi_normal, vi_insert]
            event: { send: ctrld }
        }
        {
            name: clear_screen
            modifier: control
            keycode: char_l
            mode: [emacs, vi_normal, vi_insert]
            event: { send: clearscreen }
        }
        {
            name: search_history
            modifier: control
            keycode: char_q
            mode: [emacs, vi_normal, vi_insert]
            event: { send: searchhistory }
        }
        {
            name: open_command_editor
            modifier: control
            keycode: char_o
            mode: [emacs, vi_normal, vi_insert]
            event: { send: openeditor }
        }
        {
            name: move_up
            modifier: none
            keycode: up
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: menuup }
                    { send: up }
                ]
            }
        }
        {
            name: move_down
            modifier: none
            keycode: down
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: menudown }
                    { send: down }
                ]
            }
        }
        {
            name: move_left
            modifier: none
            keycode: left
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: menuleft }
                    { send: left }
                ]
            }
        }
        {
            name: move_right_or_take_history_hint
            modifier: none
            keycode: right
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: historyhintcomplete }
                    { send: menuright }
                    { send: right }
                ]
            }
        }
        {
            name: move_one_word_left
            modifier: control
            keycode: left
            mode: [emacs, vi_normal, vi_insert]
            event: { edit: movewordleft }
        }
        {
            name: move_one_word_right_or_take_history_hint
            modifier: control
            keycode: right
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: historyhintwordcomplete }
                    { edit: movewordright }
                ]
            }
        }
        {
            name: move_to_line_start
            modifier: none
            keycode: home
            mode: [emacs, vi_normal, vi_insert]
            event: { edit: movetolinestart }
        }
        {
            name: move_to_line_start
            modifier: control
            keycode: char_a
            mode: [emacs, vi_normal, vi_insert]
            event: { edit: movetolinestart }
        }
        {
            name: move_to_line_end_or_take_history_hint
            modifier: none
            keycode: end
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: historyhintcomplete }
                    { edit: movetolineend }
                ]
            }
        }
        {
            name: move_to_line_end_or_take_history_hint
            modifier: control
            keycode: char_e
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: historyhintcomplete }
                    { edit: movetolineend }
                ]
            }
        }
        {
            name: move_to_line_start
            modifier: control
            keycode: home
            mode: [emacs, vi_normal, vi_insert]
            event: { edit: movetolinestart }
        }
        {
            name: move_to_line_end
            modifier: control
            keycode: end
            mode: [emacs, vi_normal, vi_insert]
            event: { edit: movetolineend }
        }
        {
            name: move_up
            modifier: control
            keycode: char_p
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: menuup }
                    { send: up }
                ]
            }
        }
        {
            name: move_down
            modifier: control
            keycode: char_t
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: menudown }
                    { send: down }
                ]
            }
        }
        {
            name: delete_one_character_backward
            modifier: none
            keycode: backspace
            mode: [emacs, vi_insert]
            event: { edit: backspace }
        }
        {
            name: delete_one_word_backward
            modifier: control
            keycode: backspace
            mode: [emacs, vi_insert]
            event: { edit: backspaceword }
        }
        {
            name: delete_one_character_forward
            modifier: none
            keycode: delete
            mode: [emacs, vi_insert]
            event: { edit: delete }
        }
        {
            name: delete_one_character_forward
            modifier: control
            keycode: delete
            mode: [emacs, vi_insert]
            event: { edit: delete }
        }
        {
            name: delete_one_character_backward
            modifier: control
            keycode: char_h
            mode: [emacs, vi_insert]
            event: { edit: backspace }
        }
        {
            name: delete_one_word_backward
            modifier: control
            keycode: char_w
            mode: [emacs, vi_insert]
            event: { edit: backspaceword }
        }
        {
            name: move_left
            modifier: none
            keycode: backspace
            mode: vi_normal
            event: { edit: moveleft }
        }
        {
            name: newline_or_run_command
            modifier: none
            keycode: enter
            mode: emacs
            event: { send: enter }
        }
        {
            name: move_left
            modifier: control
            keycode: char_b
            mode: emacs
            event: {
                until: [
                    { send: menuleft }
                    { send: left }
                ]
            }
        }
        {
            name: move_right_or_take_history_hint
            modifier: control
            keycode: char_f
            mode: emacs
            event: {
                until: [
                    { send: historyhintcomplete }
                    { send: menuright }
                    { send: right }
                ]
            }
        }
        {
            name: redo_change
            modifier: control
            keycode: char_g
            mode: emacs
            event: { edit: redo }
        }
        {
            name: undo_change
            modifier: control
            keycode: char_z
            mode: emacs
            event: { edit: undo }
        }
        {
            name: paste_before
            modifier: control
            keycode: char_y
            mode: emacs
            event: { edit: pastecutbufferbefore }
        }
        {
            name: cut_word_left
            modifier: control
            keycode: char_w
            mode: emacs
            event: { edit: cutwordleft }
        }
        {
            name: cut_line_to_end
            modifier: control
            keycode: char_k
            mode: emacs
            event: { edit: cuttoend }
        }
        {
            name: cut_line_from_start
            modifier: control
            keycode: char_u
            mode: emacs
            event: { edit: cutfromstart }
        }
        {
            name: swap_graphemes
            modifier: control
            keycode: char_t
            mode: emacs
            event: { edit: swapgraphemes }
        }
        {
            name: move_one_word_left
            modifier: alt
            keycode: left
            mode: emacs
            event: { edit: movewordleft }
        }
        {
            name: move_one_word_right_or_take_history_hint
            modifier: alt
            keycode: right
            mode: emacs
            event: {
                until: [
                    { send: historyhintwordcomplete }
                    { edit: movewordright }
                ]
            }
        }
        {
            name: move_one_word_left
            modifier: alt
            keycode: char_b
            mode: emacs
            event: { edit: movewordleft }
        }
        {
            name: move_one_word_right_or_take_history_hint
            modifier: alt
            keycode: char_f
            mode: emacs
            event: {
                until: [
                    { send: historyhintwordcomplete }
                    { edit: movewordright }
                ]
            }
        }
        {
            name: delete_one_word_forward
            modifier: alt
            keycode: delete
            mode: emacs
            event: { edit: deleteword }
        }
        {
            name: delete_one_word_backward
            modifier: alt
            keycode: backspace
            mode: emacs
            event: { edit: backspaceword }
        }
        {
            name: delete_one_word_backward
            modifier: alt
            keycode: char_m
            mode: emacs
            event: { edit: backspaceword }
        }
        {
            name: cut_word_to_right
            modifier: alt
            keycode: char_d
            mode: emacs
            event: { edit: cutwordright }
        }
        {
            name: upper_case_word
            modifier: alt
            keycode: char_u
            mode: emacs
            event: { edit: uppercaseword }
        }
        {
            name: lower_case_word
            modifier: alt
            keycode: char_l
            mode: emacs
            event: { edit: lowercaseword }
        }
        {
            name: capitalize_char
            modifier: alt
            keycode: char_c
            mode: emacs
            event: { edit: capitalizechar }
        }
        # The following bindings with `*system` events require that Nushell has
        # been compiled with the `system-clipboard` feature.
        # This should be the case for Windows, macOS, and most Linux distributions
        # Not available for example on Android (termux)
        # If you want to use the system clipboard for visual selection or to
        # paste directly, uncomment the respective lines and replace the version
        # using the internal clipboard.
        {
            name: copy_selection
            modifier: control_shift
            keycode: char_c
            mode: emacs
            event: { edit: copyselection }
            # event: { edit: copyselectionsystem }
        }
        {
            name: cut_selection
            modifier: control_shift
            keycode: char_x
            mode: emacs
            event: { edit: cutselection }
            # event: { edit: cutselectionsystem }
        }
        # {
        #     name: paste_system
        #     modifier: control_shift
        #     keycode: char_v
        #     mode: emacs
        #     event: { edit: pastesystem }
        # }
        {
            name: select_all
            modifier: control_shift
            keycode: char_a
            mode: emacs
            event: { edit: selectall }
        }
        {
            name: claude_code_newline
            modifier: shift
            keycode: enter
            mode: [emacs, vi_normal, vi_insert]
            event: { edit:  InsertNewline }
        }
    ]
}

# set tab title in terminal
def "ansi title" [title: string] {
  ansi -o $"0;($title)"
}

# run nix develop with nu shell
def "nix-develop-nu" [] {
    nix develop --command nu
}

# ssh with nu as remote shell
def "ssh-nu" [host] {
    ssh -t $host bash --login -c nu
}

# mosh with nu as remote shell
def "mosh-nu" [host] {
    mosh -- $host bash --login -c nu
}

# search in nixpkgs
def "nix-search" [search_term: string] {
    nix search --json nixpkgs $search_term | from json | transpose package spec | each {|it| { package: $it.package ...$it.spec } }
}

def "create-language-config" [target_triple: string] {
    if not (".helix" | path exists) {
        mkdir .helix
    }
    let language_config = {
        language-server: {
            rust-analyzer: {
                config: {
                    cargo: {
                        target: $target_triple
                    }
                }
            }
        }
    }
    $language_config | to toml out> .helix/languages.toml
}

def "remove-language-config" [] {
    rm .helix/languages.toml
}

# start Helix with given target
def "hx-for-target" [
    target_triple: string
    ...params: string
] {
    create-language-config $target_triple
    ^hx ...$params
    remove-language-config
}

# start Helix with Windows rust-analyzer
def "hx-win" [...params: string] {
    hx-for-target aarch64-pc-windows-msvc ...$params
}

# start Helix with MacOS rust-analyzer
def "hx-mac" [...params: string] {
    hx-for-target aarch64-apple-darwin ...$params
}

# use bash-env as a module rather than plugin
use NIX_BASH_ENV_NU_MODULE

def --env "reload-hm-session-vars" [] {
    __HM_SESS_VARS_SOURCED="" bash-env ~/.nix-profile/etc/profile.d/hm-session-vars.sh | load-env
}

def --env "home-manager-switch" [] {
    home-manager switch -v --flake $env.HOME_MANAGER_FLAKE_REF_ATTR
    # aarggghh!!! source $nu.config-path
    source $nu.env-path
    reload-hm-session-vars
    print "need to reload Nu config"
}

use std
use std/dirs

# Mise (rtx) integration - manual configuration
# The mise module automatically initializes on load via export-env
use ~/.config/nushell/mise.nu

# opam (OCaml Package Manager) integration
# Initializes opam environment at shell startup
use ~/.config/nushell/opam.nu *

# Utility shortcuts/aliases
alias search = rg -p --glob '!node_modules/*'
alias diff = difft

# Pixi environment with graph-tool (conda-forge + PyPI)
# Usage: pixi-gt shell, pixi-gt run python, etc.
def "pixi-gt" [cmd: string, ...args] {
    pixi $cmd --manifest-path ~/darwin-config/python-env/pixi.toml ...$args
}

# Quick access to xonsh shell via pixi environment
alias xsh = pixi-gt run xonsh

$env.EDITOR = "nvim"
$env.VISUAL = "zed --wait"
# Do not allow emacsclient to auto-start a background daemon
$env.ALTERNATE_EDITOR = "false"

# Terminal and editor shortcuts
alias tg  = ^$env.EDITOR ~/.config/ghostty/config
alias tgg = ^$env.EDITOR ~/.config/ghostty/overrides.conf
alias nnc = ^$env.EDITOR ~/darwin-config/modules/nushell/config.nu
alias nne = ^$env.EDITOR ~/darwin-config/modules/nushell/env.nu
alias gdocs = ghostty +show-config --default --docs

# Git shortcuts
def gp [] {
    git fetch --all -p
    git pull
    git submodule update --recursive
}

# Nix shortcuts - enhanced with -v flag support (nushell-native flags)
def nb [--verbose(-v) ...args] {
    # Also accept positional "v"/"verbose" for convenience (zsh muscle memory)
    let v_positional = ($args | any {|a| $a == "v" or $a == "verbose"})
    let passthrough = if $v_positional { $args | where {|a| $a != "v" and $a != "verbose"} } else { $args }

    dirs add ~/darwin-config

    if ($verbose or $v_positional) {
        nix run .#build -- --verbose ...$passthrough
    } else {
        nix run .#build -- ...$passthrough
    }

    dirs drop
}

# ns function - nushell-native implementation with ghostty/zellij compatibility
# Enhanced with -v flag support for verbose output
def "ns" [--verbose(-v) ...args] {
    # Also accept positional "v"/"verbose" for convenience
    let v_positional = ($args | any {|a| $a == "v" or $a == "verbose"})
    let filtered_args = if $v_positional { $args | where {|a| $a != "v" and $a != "verbose"} } else { $args }
    # Colors for output
    let GREEN = (ansi green_bold)
    let YELLOW = (ansi yellow_bold)
    let BLUE = (ansi blue_bold)
    let RED = (ansi red_bold)
    let NC = (ansi reset)

    # Helper functions
    let detect_ghostty = {
        # Method 1: Force detection for testing
        if ($env.FORCE_GHOSTTY_DETECTION? | default "0") == "1" {
            return true
        }

        # Method 2: Inspect terminal metadata
        let term_program = ($env.TERM_PROGRAM? | default "" | str downcase)
        if $term_program == "ghostty" {
            return true
        }

        let term_value = ($env.TERM? | default "" | str downcase)
        if ($term_value | str contains "ghostty") {
            return true
        }

        # Method 3: Check for ghostty-specific environment variables (fallback)
        if ($env.GHOSTTY_RESOURCES_DIR? | default "" | str length) > 0 or ($env.GHOSTTY_CONFIG_PATH? | default "" | str length) > 0 {
            return true
        }

        # Method 4: Manual hint file (for testing/troubleshooting)
        let hint_file = ($env.HOME | path join ".cache" "ghostty_hint")
        if ($hint_file | path exists) {
            let hint_time = (try { open $hint_file | into int } catch { 0 })
            let current_time = (date now | format date "%s" | into int)
            let time_diff = ($current_time - $hint_time)

            # If hint file is less than 30 minutes old, assume ghostty
            if $time_diff < 1800 {
                return true
            }
        }

        # Not ghostty
        false
    }

    # Check for zellij session
    let in_zellij = ($env.ZELLIJ? | default "" | str length) > 0 or ($env.ZELLIJ_SESSION_NAME? | default "" | str length) > 0

    # Assume Apple Silicon only
    let system_type = "aarch64-darwin"

    # Set NIXPKGS_ALLOW_UNFREE
    $env.NIXPKGS_ALLOW_UNFREE = "1"

    # Check if we're in ghostty
    if (do $detect_ghostty) {
        print $"($BLUE)Detected ghostty terminal - enabling safe mode($NC)"

        if $in_zellij {
            print $"($BLUE)Running in zellij session($NC)"
        }

        print $"($YELLOW)Using ghostty-safe mode for nix build-switch...($NC)"
        print $"($YELLOW)Current session will be preserved during theme switching...($NC)"

        # Set environment variables to prevent theme switcher from killing Zellij sessions
        $env.GHOSTTY_SAFE_MODE = "1"
        $env.NUSHELL_NIX_BUILD = "true"

        # In zellij, use a simpler approach to avoid process conflicts
        if $in_zellij {
            print $"($YELLOW)Using zellij-safe direct execution...($NC)"

            # Change to the correct directory
            dirs add ~/darwin-config

            # Run build-switch directly without nohup to avoid zellij conflicts
            print $"($YELLOW)Running nix build-switch directly \(zellij-safe mode\)...($NC)"
            try {
                if $verbose {
                    if ($filtered_args | length) > 0 {
                        nix run .#build-switch -- --verbose ...$filtered_args
                    } else {
                        nix run .#build-switch -- --verbose
                    }
                } else {
                    if ($filtered_args | length) > 0 {
                        nix run .#build-switch -- ...$filtered_args
                    } else {
                        nix run .#build-switch --
                    }
                }
                print $"($GREEN)Switch to new generation complete!($NC)"
                print $"($GREEN)✅ Nix build-switch completed successfully!($NC)"
            } catch { |e|
                print $"($RED)Build or switch failed: ($e.msg)($NC)"
                dirs drop
                return 1
            }
            dirs drop
        } else {
            # Not in zellij, use the background process approach
            print $"($YELLOW)Using background process approach...($NC)"
            print $"($YELLOW)Note: This may cause the terminal to close if ghostty theme changes occur($NC)"

            # Change to correct directory
            dirs add ~/darwin-config

            try {
                print $"($YELLOW)Building system configuration...($NC)"

                if $verbose {
                    if ($filtered_args | length) > 0 {
                        nix run .#build-switch -- --verbose ...$filtered_args
                    } else {
                        nix run .#build-switch -- --verbose
                    }
                } else {
                    if ($filtered_args | length) > 0 {
                        nix run .#build-switch -- ...$filtered_args
                    } else {
                        nix run .#build-switch --
                    }
                }

                print $"($GREEN)Switch to new generation complete!($NC)"
            } catch { |e|
                print $"($RED)Build or switch failed: ($e.msg)($NC)"
                dirs drop
                return 1
            }
            dirs drop
        }
    } else {
        # Not in ghostty, use the normal method (same as original ns alias)
        dirs add ~/darwin-config

        print $"($YELLOW)Running nix build-switch...($NC)"
        try {
            if $verbose {
                if ($filtered_args | length) > 0 {
                    nix run .#build-switch -- --verbose ...$filtered_args
                } else {
                    nix run .#build-switch -- --verbose
                }
            } else {
                if ($filtered_args | length) > 0 {
                    nix run .#build-switch -- ...$filtered_args
                } else {
                    nix run .#build-switch --
                }
            }

            print $"($GREEN)Switch to new generation complete!($NC)"
        } catch { |e|
            print $"($RED)Build or switch failed: ($e.msg)($NC)"
            dirs drop
            return 1
        }
        dirs drop
    }
}

# Original complex nushell ns function, kept for reference/fallback
# Use 'ns-nushell' if you specifically want the old nushell behavior
def "ns-nushell" [] {
    dirs add ~/darwin-config

    # Check if we're in a Zellij session and handle it gracefully
    let in_zellij = ($env.ZELLIJ? | default "" | str length) > 0
    let saved_session_name = $env.ZELLIJ_SESSION_NAME? | default ""

    # Get list of ALL current sessions to protect them during build
    let pre_build_sessions = if $in_zellij {
        try {
            (do { zellij list-sessions } | complete | get stdout | lines | where {|line| $line != "" and not ($line | str contains "No active sessions")})
        } catch {
            []
        }
    } else {
        []
    }

    if $in_zellij {
        print $"🔄 Detected running inside Zellij session: ($saved_session_name)"
        print "   Pre-build sessions detected:"
        for session_line in $pre_build_sessions {
            let session_name = ($session_line | split row " " | first)
            print $"     - ($session_name)"
        }
        print "   Exiting Zellij gracefully before Nix rebuild to prevent interruption..."

        # Exit Zellij cleanly - this will return us to the parent shell (nushell in Ghostty)
        try {
            # Use the correct zellij command to close the current session
            ^zellij action close-session
        } catch {
            print "⚠️  Could not exit Zellij gracefully, continuing anyway..."
        }

        # Wait a moment for the exit to complete
        sleep 1sec
    }

    # Now run the build process outside of Zellij
    print "🚀 Running Nix build-switch outside of Zellij..."
    print "   ⚠️  Note: Build process may kill Zellij sessions as part of system updates."
    print "   This is expected and why we exited gracefully first."

    # Set environment variable to signal this is a controlled build
    with-env {NUSHELL_NIX_BUILD: "true"} {
        nix run .#build-switch
    }
    dirs drop

    # Temporary debugging: pause to confirm completion
    print "\n✅ Nix build-switch completed successfully!"
    print "🔍 Press any key to continue..."
    input

    # Check what sessions survived the build
    let post_build_sessions = try {
        (do { zellij list-sessions } | complete | get stdout | lines | where {|line| $line != "" and not ($line | str contains "No active sessions")})
    } catch {
        []
    }

    if ($post_build_sessions | length) > 0 {
        print "\n🔍 Sessions that survived the build:"
        for session_line in $post_build_sessions {
            let session_name = ($session_line | split row " " | first)
            print $"   - ($session_name)"
        }
    } else {
        print "\n📋 No Zellij sessions survived the build (this is expected)."
    }

    # If we were originally in Zellij, offer to restart it
    if $in_zellij {
        print "\n🔄 Build complete! Would you like to restart Zellij?"
        let restart_choice = (input "Type 'y' to restart Zellij, or any other key to stay in nushell: ")

        if ($restart_choice | str downcase) == "y" {
            # Check if the original session still exists
            let session_exists = ($post_build_sessions | any {|line| ($line | str contains $saved_session_name)})

            if $session_exists and ($saved_session_name | str length) > 0 {
                print $"🚀 Original session '($saved_session_name)' survived! Reattaching..."
                try {
                    zellij attach $saved_session_name
                } catch {
                    print $"⚠️  Could not reattach to '($saved_session_name)', creating new session..."
                    zellij attach --create
                }
            } else {
                if ($saved_session_name | str length) > 0 {
                    print $"🔄 Original session '($saved_session_name)' was cleaned up during build."
                }
                print "🚀 Starting fresh Zellij session..."
                zellij attach --create
            }
        } else {
            print "👍 Staying in nushell. Run 'zt <theme>' when ready to launch Zellij."
        }
    }
}

# Emacs daemon is now managed by home-manager service
# No need for manual daemon management
alias pke = pkill -9 Emacs

# Terminal Emacs function - start daemon with: emacs --daemon
def "t" [...args] {
    # Launch emacsclient with zsh as SHELL for POSIX compatibility
    # Ensure Emacs can find ghostty terminfo
    let term_env = if ($env.TERM? | default "") == "xterm-ghostty" {
        {
            SHELL: "/bin/zsh",
            TERMINFO: $"($env.HOME)/.terminfo",
            TERMINFO_DIRS: $"($env.HOME)/.terminfo:/usr/share/terminfo"
        }
    } else {
        {SHELL: "/bin/zsh"}
    }

    with-env $term_env {
        ^/opt/homebrew/bin/emacsclient -nw ...$args
    }
}

# GUI Emacs client function - start daemon with: emacs --daemon
def "e" [...args] {
    # Launch emacsclient with zsh as SHELL for POSIX compatibility
    with-env {SHELL: "/bin/zsh"} {
        ^/opt/homebrew/bin/emacsclient -nc ...$args
    }
}

alias tt = with-env {SHELL: "/bin/zsh"} { ^/opt/homebrew/bin/emacs -nw }
# Start Emacs in background
def "et" [tag?: string] {
    job spawn -t ($tag | default 'emacs') {
        with-env {SHELL: "/bin/zsh"} { ^/opt/homebrew/bin/emacs }
    }
}

def "ke" [tag_to_kill?: string] {
    job list | where tag == ($tag_to_kill | default 'emacs') | each { job kill $in.id }
}

# lem
def "lt" [...args] {
    let term_env = if ($env.TERM? | default "") == "xterm-ghostty" {
        {
            TERMINFO: $"($env.HOME)/.terminfo",
            TERMINFO_DIRS: $"($env.HOME)/.terminfo:/usr/share/terminfo",
            TERM: "xterm-256color"
        }
    } else { {} }

    with-env $term_env {
      ^lem -i ncurses ...$args
    }
}

def "lg" [...args] {
    let term_env = if ($env.TERM? | default "") == "xterm-ghostty" {
        {
            TERMINFO: $"($env.HOME)/.terminfo",
            TERMINFO_DIRS: $"($env.HOME)/.terminfo:/usr/share/terminfo",
            TERM: "xterm-256color"
        }
    } else { {} }

    with-env $term_env {
        ^lem -i sdl2 ...$args
    }

    print -n (ansi reset)
    ^tput reset
}

def --env y [...args] {
	let tmp = (mktemp -t "yazi-cwd.XXXXXX")
	yazi ...$args --cwd-file $tmp
	let cwd = (open $tmp)
	if $cwd != "" and $cwd != $env.PWD {
		cd $cwd
	}
	rm -fp $tmp
}

# Dynamic theme application function
def --env "apply-theme" [] {
    if ($env.NUSHELL_THEME? | default "dark") == "light" {
        $env.config.color_config = $light_theme
    } else {
        $env.config.color_config = $dark_theme
    }
}

# Apply theme immediately after config is loaded
apply-theme

# Auto-launch Zellij when starting nushell in Ghostty (opt-in via NS_AUTO_ZELLIJ)
let auto_zellij_pref = ($env.NS_AUTO_ZELLIJ? | default "" | str downcase)
let auto_launch_zellij = match $auto_zellij_pref {
    "1" => true
    "true" => true
    "yes" => true
    "on" => true
    _ => false
}

if $auto_launch_zellij and ($env.TERM_PROGRAM? | default "" | str contains "ghostty") and ($env.ZELLIJ? | default "" | is-empty) {
    # We're in Ghostty and not already in Zellij - auto-launch Zellij
    print "🚀 Auto-launching Zellij in Ghostty..."

    # Launch Zellij with current theme, but don't exit nushell when Zellij exits
    try {
        zellij attach --create
    } catch {
        print "⚠️  Could not auto-launch Zellij, continuing with nushell..."
    }

    # When Zellij exits, we return here to nushell (Ghostty stays alive)
    print "\n👋 Zellij session ended. You're back in nushell."
    print "💡 Run 'zt <theme>' to launch Zellij again with a specific theme."
}

# Smart Zellij launcher with manual theme switching - handles Ghostty integration
# Usage: zt [theme_name] [--session session_name]
def "zt" [
    theme?: string                    # Explicit theme name (required)
    --session (-s): string           # Optional session name
    --quiet (-q)                     # Suppress informational output
    --force-zsh                      # Force using zsh intermediary (for troubleshooting)
    --force-restart                  # Force restart even when in Ghostty-managed Zellij
    ...args                          # Additional zellij arguments
] {
    # Helper function for logging
    let log = {|msg| if not $quiet { print $msg }}

    # Require explicit theme - no more automatic detection
    if ($theme == null) {
        print "❌ Theme name is required. Use 'zt-themes' to see available themes."
        print "Example: zt catppuccin-macchiato"
        return 1
    }

    do $log $"🎯 Setting theme: ($theme)"

    # -----------------------------------------------------
    # 1. Detect if we're inside a Zellij session
    # -----------------------------------------------------
    let in_zellij = ($env.ZELLIJ? | default "" | str length) > 0
    let current_session = $env.ZELLIJ_SESSION_NAME? | default ""

    if $in_zellij and not $force_restart {
        do $log "🔍 Detected running inside Zellij session: ($current_session)"
        do $log "   Using in-place theme change to avoid killing Ghostty..."

        # -----------------------------------------------------
        # 2. Set theme using theme manager (in-place)
        # -----------------------------------------------------
        try {
            let theme_manager_result = (do { zellij-theme-manager set $theme } | complete)
            if $theme_manager_result.exit_code == 0 {
                do $log $"🎨 Set zellij theme to: ($theme)"

                # Try to reload config without killing the session
                do $log "🔄 Attempting to reload Zellij configuration..."
                try {
                    # Try using Zellij's reload-config action if available
                    let reload_result = (do { ^zellij action reload-config } | complete)
                    if $reload_result.exit_code == 0 {
                        do $log "✅ Successfully reloaded Zellij configuration!"
                        print $"\n🎆 Theme changed to ($theme)! New theme should be visible."
                    } else {
                        # Fallback: just clear screen to help show theme change
                        ^zellij action write-chars "clear" | complete | null
                        ^zellij action write-chars "" | complete | null  # Send enter
                        do $log "✅ Theme applied! You may need to open a new pane to see full changes."
                        print $"\n🎆 Theme changed to ($theme)! Try opening a new pane (Ctrl+p + n) to see the new theme."
                    }
                } catch { |e|
                    do $log $"⚠️  Could not reload config automatically: ($e.msg)"
                    print $"\n📝 Theme updated! Restart Zellij manually or run 'zt ($theme) --force-restart' to see changes."
                }
            } else {
                print $"❌ Theme manager failed: ($theme_manager_result.stderr)"
                return 1
            }
        } catch { |e|
            print $"❌ Failed to set theme: ($e.msg)"
            return 1
        }

        return 0
    }

    # -----------------------------------------------------
    # 3. Handle external launch or forced restart
    # -----------------------------------------------------

    # Get list of existing sessions with more detailed info
    let existing_sessions_raw = try {
        (do { zellij list-sessions } | complete | get stdout | lines | where {|line| $line != "" and not ($line | str contains "No active sessions")})
    } catch {
        []
    }

    # Parse session names from the list (extract names before the bracket)
    let existing_sessions = ($existing_sessions_raw | each {|line|
        let parts = ($line | split row " " | first)
        $parts
    })

    if ($existing_sessions | length) > 0 {
        if $in_zellij and $force_restart {
            do $log "⚠️  Force restart requested - this will terminate the current Zellij session!"
            print "\n🚨 Warning: This will close Ghostty if it's managing this Zellij session."
            print "Press Ctrl+C to cancel, or Enter to continue..."
            input

            # When force-restarting from within a session, kill everything
            try {
                do { zellij kill-all-sessions --yes } | complete | null
                do $log "   ✅ Force-killed all sessions including current one"
            } catch {
                do $log "   ⚠️  Some sessions may not have been killed"
            }
        } else {
            # When NOT inside Zellij, be more careful about session management
            do $log $"🔄 Found ($existing_sessions | length) existing Zellij sessions:"
            for session in $existing_sessions {
                do $log $"   - ($session)"
            }

            # Only kill sessions if we're launching a new one
            if ($session == null) {
                do $log "   Cleaning up existing sessions for fresh start..."
                try {
                    for session_name in $existing_sessions {
                        try {
                            do { zellij kill-session $session_name } | complete | null
                            do $log $"   ✅ Killed session: ($session_name)"
                        } catch {
                            do $log $"   ⚠️  Could not kill session: ($session_name) (may be attached elsewhere)"
                        }
                    }
                } catch {
                    do $log "   ⚠️  Some sessions could not be terminated"
                }
            } else {
                do $log $"   Keeping existing sessions, will use/create session: ($session)"
            }
        }

        # Wait a moment for cleanup
        sleep 500ms
    }

    # -----------------------------------------------------
    # 4. Set theme using theme manager
    # -----------------------------------------------------
    try {
        let theme_manager_result = (do { zellij-theme-manager set $theme } | complete)
        if $theme_manager_result.exit_code == 0 {
            do $log $"🎨 Set zellij theme to: ($theme)"
        } else {
            print $"❌ Theme manager failed: ($theme_manager_result.stderr)"
            return 1
        }
    } catch { |e|
        print $"❌ Failed to set theme: ($e.msg)"
        return 1
    }

    # -----------------------------------------------------
    # 5. Launch Zellij with direct nushell execution
    # -----------------------------------------------------
    if ($session != null) {
        do $log $"📝 Using session name: ($session)"
        do $log $"🚀 Launching: zellij --session ($session)"
    } else {
        do $log $"🚀 Launching: zellij attach --create"
    }

    # Choose execution method
    if $force_zsh {
        do $log "🔧 Using zsh intermediary as requested via --force-zsh..."
        let cmd_parts = if ($session != null) {
            ["zellij" "--session" $session] | append $args
        } else {
            ["zellij" "attach" "--create"] | append $args
        }
        let full_cmd = ($cmd_parts | str join " ")
        ^/bin/zsh -l -c $full_cmd
    } else {
        # Direct nushell execution
        if ($session != null) {
            if ($args | length) > 0 {
                ^zellij --session $session ...$args
            } else {
                ^zellij --session $session
            }
        } else {
            if ($args | length) > 0 {
                ^zellij attach --create ...$args
            } else {
                ^zellij attach --create
            }
        }
    }
}

# Aliases and helper functions for zellij theme management
# Quick theme switching functions
def "zt-light" [...args] {
    zt "catppuccin_latte" ...$args
}

def "zt-dark" [...args] {
    zt "catppuccin-macchiato" ...$args
}

# List available zellij themes
def "zt-themes" [] {
    zellij-theme-manager list
}

# Show current theme status
def "zt-status" [] {
    zellij-theme-manager status
}

# Override prompt for Claude Code terminal (which doesn't render truecolor properly)
# This must run after starship init to override it
if ($env.CLAUDECODE? | default "" | str length) > 0 {
    # Use a simple prompt for Claude Code
    # Shows: username@hostname current_dir >
    $env.PROMPT_COMMAND = {||
        let user = (whoami)
        let host = (hostname | str trim)
        let dir = ($env.PWD | str replace $env.HOME "~")
        $"(ansi green)($user)(ansi reset)@(ansi blue)($host)(ansi reset) (ansi cyan)($dir)(ansi reset) > "
    }
    $env.PROMPT_COMMAND_RIGHT = {|| "" }
    $env.PROMPT_INDICATOR = ""
    $env.PROMPT_INDICATOR_VI_INSERT = ""
    $env.PROMPT_INDICATOR_VI_NORMAL = ""
    $env.PROMPT_MULTILINE_INDICATOR = ""
}

# Final PATH cleanup - remove duplicates after all integrations have loaded
$env.PATH = ($env.PATH | uniq)

source ~/.local/share/atuin/init.nu

# YAZELIX START v4 - Yazelix managed configuration (do not modify this comment)
# delete this whole section to re-generate the config, if needed
source "~/.config/yazelix/nushell/config/config.nu"
use ~/.config/yazelix/nushell/scripts/core/yazelix.nu *
# YAZELIX END v4 - Yazelix managed configuration (do not modify this comment)

alias yzh = yzx launch --here
alias avante = nvim -c 'lua vim.defer_fn(function()require("avante.api").zen_mode()end, 100)'
