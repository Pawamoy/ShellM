if ndef __CORE_FORMAT_SH; then
define __CORE_FORMAT_SH "format VAR"

## \usage format [OPTIONS...] [-- STRING...]
## \example format onblack lightgreen dim bold; echo SUCCESS!
## Bold, diminished, light-green foreground and black background
## \example format B lg U olu; echo INFO
## Bold, underline, dark-gray foreground and light-blue background

## \desc Available arguments to the 'format' function:
##
##     Foreground       |  Foreground (extended)
##     _________________|________________________________
##                      |
##     d,  default      |
##     b,  black        |  w,  white
##     r,  red          |  lr, lightred
##     g,  green        |  lG, lightgreen
##     y,  yellow       |  ly, lightyellow
##     u,  blue         |  lu, lightblue
##     m,  magenta      |  lm, lightmagenta
##     c,  cyan         |  lc, lightcyan
##     lg, lightgray    |  dg, darkgray
##
##     Background       |  Background (extended)
##     _________________|________________________________
##                      |
##     od,  ondefault   |
##     ob,  onblack     |  ow,  onwhite
##     or,  onred       |  olr, onlightred
##     og,  ongreen     |  olG, onlightgreen
##     oy,  onyellow    |  oly, onlightyellow
##     ou,  onblue      |  olu, onlightblue
##     om,  onmagenta   |  olm, onlightmagenta
##     oc,  oncyan      |  olc, onlightcyan
##     olg, onlightgray |  odg, ondarkgray
##
##     Style            |  Reset style
##     _________________|________________________________
##                      |
##                      |  R,      reset
##     B, bold          |  rb, RB, resetbold
##     D, dim           |  rd, RD, resetdim
##     U, underlin      |  ru, RU, resetunderline
##     K, blink         |  rk, RK, resetblink
##     I, invert        |  ri, RI, resetinvert
##     H, hidden        |  rh, RH, resethidden

## \note On linux terminals (tty), extended colors will
## be replaced by their 8-colors equivalent (white by lightgray).
## Also underline, dim and blink will have no effects.

if [ "${TERM}" = linux ]; then # 8 colors

  ## \fn format (args...)
  ## \brief Format the output with style and color (8)
  ## \param args Letters or complete names of style/colors.
  ## \out The formatting string without newline.
  format() {
    local esc='\e['
    local f="$esc"
    while [ $# -ne 0 ]; do
      case "$1" in
        # Foreground
        d|default) f=${f}\;39 ;;
        b|black) f=${f}\;30 ;;
        r|red) f=${f}\;31 ;;
        g|green) f=${f}\;32 ;;
        y|yellow) f=${f}\;33 ;;
        u|blue) f=${f}\;34 ;;
        m|magenta) f=${f}\;35 ;;
        c|cyan) f=${f}\;36 ;;
        lg|lightgray) f=${f}\;37 ;;

        # Foreground extended
        dg|darkgray) f=${f}\;30 ;;  # black
        lr|lightred) f=${f}\;31 ;;  # red
        lG|lightgreen) f=${f}\;32 ;;  # green
        ly|lightyellow) f=${f}\;33 ;;  # yellow
        lu|lightblue) f=${f}\;34 ;;  # blue
        lm|lightmagenta) f=${f}\;35 ;;  # magenta
        lc|lightcyan) f=${f}\;36 ;;  # cyan
        w|white) f=${f}\;37 ;;  # lightgray

        # Background
        od|ondefault) f=${f}\;49 ;;
        ob|onblack) f=${f}\;40 ;;
        or|onred) f=${f}\;41 ;;
        og|ongreen) f=${f}\;42 ;;
        oy|onyellow) f=${f}\;43 ;;
        ou|onblue) f=${f}\;44 ;;
        om|onmagenta) f=${f}\;45 ;;
        oc|oncyan) f=${f}\;46 ;;
        olg|onlightgray) f=${f}\;47 ;;

        # Background extended
        odg|ondarkgray) f=${f}\;40 ;;  # black
        olr|onlightred) f=${f}\;41 ;;  # red
        olG|onlightgreen) f=${f}\;42 ;;  # green
        oly|onlightyellow) f=${f}\;43 ;;  # yellow
        olu|onlightblue) f=${f}\;44 ;;  # blue
        olm|onlightmagenta) f=${f}\;45 ;;  # magenta
        olc|onlightcyan) f=${f}\;46 ;;  # cyan
        ow|onwhite) f=${f}\;47 ;;  # lightgray

        # Style
        B|bold) f=${f}\;1 ;;
        D|dim) ;; #f=${f}\;2 ;;
        U|underline) ;; #f=${f}\;4 ;;
        K|blink) ;; #f=${f}\;5 ;;
        I|invert) f=${f}\;7 ;;
        H|hidden) f=${f}\;8 ;;

        # Reset style
        R|reset) f=${f}\;0 ;;
        rb|RB|resetbold) f=${f}\;21 ;;
        rd|RD|resetdim) ;; #f=${f}\;22 ;;
        ru|RU|resetunderline) ;; #f=${f}\;24 ;;
        rk|RK|resetblink) ;; #f=${f}\;25 ;;
        ri|RI|resetinvert) f=${f}\;27 ;;
        rh|RH|resethidden) f=${f}\;28 ;;

        --) shift; break ;;
      esac
      shift
    done

    [ "$f" != "$esc" ] && echo -en "${f}m"

    if [ $# -ne 0 ]; then
      echo -n "$@"
      echo -en '\e[0m'
    fi
  }

else # 16 colors

  ## \fn format (args...)
  ## \brief Format the output with style and color (16)
  ## \param args Letters or complete names of style/colors.
  ## \out The formatting string without newline.
  format() {
    local f='\e['
    while [ $# -ne 0 ]; do
      case "$1" in
        # Foreground
        d|default) f=${f}\;39 ;;
        b|black) f=${f}\;30 ;;
        r|red) f=${f}\;31 ;;
        g|green) f=${f}\;32 ;;
        y|yellow) f=${f}\;33 ;;
        u|blue) f=${f}\;34 ;;
        m|magenta) f=${f}\;35 ;;
        c|cyan) f=${f}\;36 ;;
        lg|lightgray) f=${f}\;37 ;;

        # Foreground extended
        dg|darkgray) f=${f}\;90 ;;
        lr|lightred) f=${f}\;91 ;;
        lG|lightgreen) f=${f}\;92 ;;
        ly|lightyellow) f=${f}\;93 ;;
        lu|lightblue) f=${f}\;94 ;;
        lm|lightmagenta) f=${f}\;95 ;;
        lc|lightcyan) f=${f}\;96 ;;
        w|white) f=${f}\;97 ;;

        # Background
        od|ondefault) f=${f}\;49 ;;
        ob|onblack) f=${f}\;40 ;;
        or|onred) f=${f}\;41 ;;
        og|ongreen) f=${f}\;42 ;;
        oy|onyellow) f=${f}\;43 ;;
        ou|onblue) f=${f}\;44 ;;
        om|onmagenta) f=${f}\;45 ;;
        oc|oncyan) f=${f}\;46 ;;
        olg|onlightgray) f=${f}\;47 ;;

        # Background extended
        odg|ondarkgray) f=${f}\;100 ;;
        olr|onlightred) f=${f}\;101 ;;
        olG|onlightgreen) f=${f}\;102 ;;
        oly|onlightyellow) f=${f}\;103 ;;
        olu|onlightblue) f=${f}\;104 ;;
        olm|onlightmagenta) f=${f}\;105 ;;
        olc|onlightcyan) f=${f}\;106 ;;
        ow|onwhite) f=${f}\;107 ;;

        # Style
        B|bold) f=${f}\;1 ;;
        D|dim) f=${f}\;2 ;;
        U|underline) f=${f}\;4 ;;
        K|blink) f=${f}\;5 ;;
        I|invert) f=${f}\;7 ;;
        H|hidden) f=${f}\;8 ;;

        # Reset style
        R|reset) f=${f}\;0 ;;
        rb|RB|resetbold) f=${f}\;21 ;;
        rd|RD|resetdim) f=${f}\;22 ;;
        ru|RU|resetunderline) f=${f}\;24 ;;
        rk|RK|resetblink) f=${f}\;25 ;;
        ri|RI|resetinvert) f=${f}\;27 ;;
        rh|RH|resethidden) f=${f}\;28 ;;

        --) shift; break ;;
      esac
      shift
    done

    [ "$f" != "$esc" ] && echo -en "${f}m"

    if [ $# -ne 0 ]; then
      echo -n "$@"
      echo -en '\e[0m'
    fi
  }

fi

fi # __CORE_FORMAT_SH
