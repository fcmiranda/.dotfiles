"$schema" = 'https://starship.rs/config-schema.json'

format = """
[](color_purple)\
$os\
[](bg:color_mid_blue fg:color_purple)\
$directory\
[](fg:color_mid_blue bg:color_blue)\
$git_branch\
$git_status\
[](fg:color_blue bg:color_purple)\
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
[](fg:color_purple bg:color_mid_blue)\
$docker_context\
$conda\
$pixi\
$custom\
$line_break\
$character"""

palette = 'omarchy_theme'

[palettes.omarchy_theme]
color_bg = '{{ background }}'
color_foreground = '{{ foreground }}'
color_comment = '{{ color8 }}'
color_red = '{{ color1 }}'
color_blue = '{{ color4 }}'
color_mid_blue = '{{ color6 }}'
color_purple = '{{ color5 }}'
color_vim_insert = '{{ color2 }}'
color_vim_normal = '{{ color4 }}'
color_vim_visual = '{{ color3 }}'

[os]
disabled = false
style = "bg:color_purple fg:color_bg"
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
style_user = "bg:color_purple fg:color_bg"
style_root = "bg:color_purple fg:color_red"
format = '[ $user ]($style)'

[directory]
style = "fg:color_bg bg:color_mid_blue"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music" = "󰝚 "
"Pictures" = " "
"Developer" = "󰲋 "

[git_branch]
symbol = ""
style = "bg:color_blue"
format = '[[ $symbol $branch ](fg:color_bg bg:color_blue)]($style)'

[git_status]
style = "bg:color_blue"
format = '[[($all_status$ahead_behind )](fg:color_bg bg:color_blue)]($style)'

[nodejs]
symbol = ""
style = "bg:color_purple"
format = '[[ $symbol( $version) ](fg:color_bg bg:color_purple)]($style)'

[c]
symbol = " "
style = "bg:color_purple"
format = '[[ $symbol( $version) ](fg:color_bg bg:color_purple)]($style)'

[cpp]
symbol = " "
style = "bg:color_purple"
format = '[[ $symbol( $version) ](fg:color_bg bg:color_purple)]($style)'

[rust]
symbol = ""
style = "bg:color_purple"
format = '[[ $symbol( $version) ](fg:color_bg bg:color_purple)]($style)'

[golang]
symbol = ""
style = "bg:color_purple"
format = '[[ $symbol( $version) ](fg:color_bg bg:color_purple)]($style)'

[php]
symbol = ""
style = "bg:color_purple"
format = '[[ $symbol( $version) ](fg:color_bg bg:color_purple)]($style)'

[java]
symbol = ""
style = "bg:color_purple"
format = '[[ $symbol( $version) ](fg:color_bg bg:color_purple)]($style)'

[kotlin]
symbol = ""
style = "bg:color_purple"
format = '[[ $symbol( $version) ](fg:color_bg bg:color_purple)]($style)'

[haskell]
symbol = ""
style = "bg:color_purple"
format = '[[ $symbol( $version) ](fg:color_bg bg:color_purple)]($style)'

[python]
symbol = ""
style = "bg:color_purple"
format = '[[ $symbol( $version) ](fg:color_bg bg:color_purple)]($style)'

[docker_context]
symbol = ""
style = "bg:color_mid_blue"
format = '[[ $symbol( $context) ](fg:color_bg bg:color_mid_blue)]($style)'

[conda]
symbol = ""
style = "bg:color_mid_blue"
format = '[[ $symbol( $environment) ](fg:color_bg bg:color_mid_blue)]($style)'

[pixi]
style = "bg:color_mid_blue"
format = '[[ $symbol( $version)( $environment) ](fg:color_bg bg:color_mid_blue)]($style)'

[time]
disabled = false
time_format = "%R"
style = "bg:color_bg"
format = '[[  $time ](fg:color_foreground bg:color_bg)]($style)'

[line_break]
disabled = false

[custom.zvm_visual_arrow_before]
command = 'echo '
when = 'case "$ZVM_MODE" in v|vl) exit 0;; *) exit 1;; esac'
style = 'bg:color_vim_visual fg:color_mid_blue'
format = '[$output]($style)'

[custom.zvm_visual]
command = 'echo visual'
when = 'case "$ZVM_MODE" in v|vl) exit 0;; *) exit 1;; esac'
style = 'inverted bg:transparent fg:color_vim_visual'
format = '[ $output]($style)'

[custom.zvm_visual_arrow_after]
command = 'echo  '
when = 'case "$ZVM_MODE" in v|vl) exit 0;; *) exit 1;; esac'
style = 'fg:color_vim_visual'
format = '[$output]($style) '

[custom.zvm_normal_arrow_before]
command = 'echo '
when = 'case "$ZVM_MODE" in n) exit 0;; *) exit 1;; esac'
style = 'bg:color_vim_normal fg:color_mid_blue'
format = '[$output]($style)'

[custom.zvm_replace]
command = 'echo normal'
when = 'case "$ZVM_MODE" in r) exit 0;; *) exit 1;; esac'
style = 'inverted bg:transparent fg:color_mid_blue'
format = '[ $output]($style)'

[custom.zvm_normal]
command = 'echo normal'
when = 'case "$ZVM_MODE" in n) exit 0;; *) exit 1;; esac'
style = 'inverted bg:transparent fg:color_vim_normal'
format = '[ $output]($style)'

[custom.zvm_normal_arrow_after]
command = 'echo  '
when = 'case "$ZVM_MODE" in n) exit 0;; *) exit 1;; esac'
style = 'fg:color_vim_normal'
format = '[$output]($style) '

[custom.zvm_insert_ok_arrow_before]
command = 'echo '
when = '[ "${ZVM_MODE:-}" = "i" ] && [ "${STARSHIP_CMD_STATUS:-0}" -eq 0 ]'
style = 'bg:color_vim_insert fg:color_mid_blue'
format = '[$output]($style)'

[custom.zvm_insert_ok]
command = 'echo insert'
when = '[ "${ZVM_MODE:-}" = "i" ] && [ "${STARSHIP_CMD_STATUS:-0}" -eq 0 ]'
style = 'inverted bg:transparent fg:color_vim_insert'
format = '[ $output]($style)'

[custom.zvm_insert_err]
command = 'echo insert'
when = '[ "${ZVM_MODE:-}" = "i" ] && [ "${STARSHIP_CMD_STATUS:-0}" -ne 0 ]'
style = 'inverted bg:transparent fg:color_red'
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