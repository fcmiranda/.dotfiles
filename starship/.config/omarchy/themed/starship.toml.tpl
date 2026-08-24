"$schema" = 'https://starship.rs/config-schema.json'

format = """
[](color_os)\
$os\
[](bg:color_dir fg:color_os)\
$directory\
[](fg:color_dir bg:color_git)\
$git_branch\
$git_status\
[](fg:color_git bg:color_lang)\
$c\
$cpp\
$rust\
$golang\
$nodejs\
$php\
$java\
$kotlin\
$haskell\
$python\
$custom\
$line_break\
$character"""

palette = 'omarchy_theme'

[palettes.omarchy_theme]
color_background = '{{ background }}'
color_foreground = '{{ foreground }}'
color_comment = '{{ muted }}'
color_os = '{{ lighter_background }}'
color_dir = '{{ blue }}'
color_git = '{{ bright_magenta }}'
color_lang = '{{ green }}'
color_text_vim_mode = '{{ background }}'
color_vim_insert = '{{ green }}'
color_vim_normal = '{{ blue }}'
color_vim_visual = '{{ magenta }}'

[os]
disabled = false
style = "bg:color_os fg:color_foreground"
format = '[󱐌 ]($style)'

[os.symbols]
Windows = "󰍲"
Ubuntu = "󰕈"
SUSE = ""
Raspbian = "󰐿"
Mint = "󰣭"
Macos = "󰀵"
Manjaro = ""
Linux = "󰌽"
Gentoo = "󰣨"
Fedora = "󰣛"
Alpine = ""
Amazon = ""
Android = ""
Arch = "󰣇"
Artix = "󰣇"
EndeavourOS = ""
CentOS = ""
Debian = "󰣚"
Redhat = "󱄛"
RedHatEnterprise = "󱄛"
Pop = ""

[username]
show_always = true
style_user = "bg:color_lang fg:color_background"
style_root = "bg:color_lang fg:color_os"
format = '[ $user ]($style)'

[directory]
style = "fg:color_background bg:color_dir"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
"Documents" = "󰈙"
"Downloads" = ""
"Music" = "󰝚 "
"Pictures" = ""
"dev" = "󰲋"

[git_branch]
symbol = ""
style = "fg:color_background bg:color_git"
format = '[[ $symbol $branch ]($style)]($style)'

[git_status]
style = "fg:color_background bg:color_git"
format = '[[($all_status$ahead_behind )]($style)]($style)'

[nodejs]
symbol = ""
style = "fg:color_background bg:color_lang"
format = '[[ $symbol( $version) ]($style)]($style)'

[c]
symbol = " "
style = "fg:color_background bg:color_lang"
format = '[[ $symbol( $version) ]($style)]($style)'

[cpp]
symbol = " "
style = "fg:color_background bg:color_lang"
format = '[[ $symbol( $version) ]($style)]($style)'

[rust]
symbol = ""
style = "fg:color_background bg:color_lang"
format = '[[ $symbol( $version) ]($style)]($style)'

[golang]
symbol = ""
style = "fg:color_background bg:color_lang"
format = '[[ $symbol( $version) ]($style)]($style)'

[php]
symbol = ""
style = "fg:color_background bg:color_lang"
format = '[[ $symbol( $version) ]($style)]($style)'

[java]
symbol = ""
style = "fg:color_background bg:color_lang"
format = '[[ $symbol( $version) ]($style)]($style)'

[kotlin]
symbol = ""
style = "fg:color_background bg:color_lang"
format = '[[ $symbol( $version) ]($style)]($style)'

[haskell]
symbol = ""
style = "fg:color_background bg:color_lang"
format = '[[ $symbol( $version) ]($style)]($style)'

[python]
symbol = ""
style = "fg:color_background bg:color_lang"
format = '[[ $symbol( $version) ]($style)]($style)'


[time]
disabled = false
time_format = "%R"
style = "bg:color_background"
format = '[[  $time ](fg:color_foreground bg:color_background)]($style)'

[line_break]
disabled = false

[custom.zvm_visual_arrow_before]
command = 'echo '
when = 'case "$ZVM_MODE" in v|vl) exit 0;; *) exit 1;; esac'
style = 'bg:color_vim_visual fg:color_lang'
format = '[$output]($style)'

[custom.zvm_visual]
command = 'echo visual'
when = 'case "$ZVM_MODE" in v|vl) exit 0;; *) exit 1;; esac'
style = 'inverted bg:color_text_vim_mode fg:color_vim_visual'
format = '[ $output]($style)'

[custom.zvm_visual_arrow_after]
command = 'echo  '
when = 'case "$ZVM_MODE" in v|vl) exit 0;; *) exit 1;; esac'
style = 'fg:color_vim_visual'
format = '[$output]($style) '

[custom.zvm_normal_arrow_before]
command = 'echo '
when = 'case "$ZVM_MODE" in n) exit 0;; *) exit 1;; esac'
style = 'bg:color_vim_normal fg:color_lang'
format = '[$output]($style)'

[custom.zvm_replace]
command = 'echo normal'
when = 'case "$ZVM_MODE" in r) exit 0;; *) exit 1;; esac'
style = 'inverted bg:color_text_vim_mode fg:color_lang'
format = '[ $output]($style)'

[custom.zvm_normal]
command = 'echo normal'
when = 'case "$ZVM_MODE" in n) exit 0;; *) exit 1;; esac'
style = 'inverted bg:color_text_vim_mode fg:color_vim_normal'
format = '[ $output]($style)'

[custom.zvm_normal_arrow_after]
command = 'echo  '
when = 'case "$ZVM_MODE" in n) exit 0;; *) exit 1;; esac'
style = 'fg:color_vim_normal'
format = '[$output]($style) '

[custom.zvm_insert_ok_arrow_before]
command = 'echo '
when = '[ "${ZVM_MODE:-}" = "i" ] && [ "${STARSHIP_CMD_STATUS:-0}" -eq 0 ]'
style = 'bg:color_vim_insert fg:color_lang'
format = '[$output]($style)'

[custom.zvm_insert_ok]
command = 'echo insert'
when = '[ "${ZVM_MODE:-}" = "i" ] && [ "${STARSHIP_CMD_STATUS:-0}" -eq 0 ]'
style = 'inverted bg:color_text_vim_mode fg:color_vim_insert'
format = '[ $output]($style)'

[custom.zvm_insert_err]
command = 'echo insert'
when = '[ "${ZVM_MODE:-}" = "i" ] && [ "${STARSHIP_CMD_STATUS:-0}" -ne 0 ]'
style = 'inverted bg:color_text_vim_mode fg:color_os'
format = '[ $output]($style)'

[custom.zvm_insert_ok_arrow_after]
command = 'echo  '
when = '[ "${ZVM_MODE:-}" = "i" ] && [ "${STARSHIP_CMD_STATUS:-0}" -eq 0 ]'
style = 'fg:color_vim_insert'
format = '[$output]($style) '

[character]
success_symbol = ""
error_symbol = ""
vimcmd_symbol = ""