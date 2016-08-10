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
    local NEWLINE=0
    local ESC='\033['
    local F="${ESC}"
    while [ $# -ne 0 ]; do
      case "$1" in
        # Foreground
        d|default) F=$F\;39 ;;
        h|black) F=$F\;30 ;;
        r|red) F=$F\;31 ;;
        g|green) F=$F\;32 ;;
        y|yellow) F=$F\;33 ;;
        b|blue) F=$F\;34 ;;
        m|magenta) F=$F\;35 ;;
        c|cyan) F=$F\;36 ;;
        w|white) F=$F\;37 ;;

        # Foreground extended
        ik|intenseBlack) F=$F\;30 ;;  # black
        ir|intenseRed) F=$F\;31 ;;  # red
        iG|intenseGreen) F=$F\;32 ;;  # green
        iy|intenseYellow) F=$F\;33 ;;  # yellow
        ib|intenseBlue) F=$F\;34 ;;  # blue
        im|intenseMagenta) F=$F\;35 ;;  # magenta
        ic|intenseCyan) F=$F\;36 ;;  # cyan
        iw|intenseWhite) F=$F\;37 ;;  # white

        # Background
        od|onDefault) F=$F\;49 ;;
        ok|onBlack) F=$F\;40 ;;
        or|onRed) F=$F\;41 ;;
        og|onGreen) F=$F\;42 ;;
        oy|onYellow) F=$F\;43 ;;
        ob|onBlue) F=$F\;44 ;;
        om|onMagenta) F=$F\;45 ;;
        oc|onCyan) F=$F\;46 ;;
        ow|onWhite) F=$F\;47 ;;

        # Background extended
        oik|onIntenseBlack) F=$F\;40 ;;  # black
        oir|onIntenseRed) F=$F\;41 ;;  # red
        oiG|onIntenseGreen) F=$F\;42 ;;  # green
        oiy|onIntenseYellow) F=$F\;43 ;;  # yellow
        oib|onIntenseBlue) F=$F\;44 ;;  # blue
        oim|onIntenseMagenta) F=$F\;45 ;;  # magenta
        oic|onIntenseCyan) F=$F\;46 ;;  # cyan
        oiw|onIntenseWhite) F=$F\;47 ;;  # white

        # Style
        B|bold) F=$F\;1 ;;
        F|faint) ;; #F=$F\;2 ;;
        I|italic) ;; #F=$F\;3 ;;
        U|underline) ;; #F=$F\;4 ;;
        K|blink) ;; #F=$F\;5 ;;
        R|reverse) F=$F\;7 ;;
        H|hidden) F=$F\;8 ;;
        S|strike) F=$F\;9 ;;

        # Reset style
        ra|R|reset|resetAll) F=$F\;0 ;;
        rb|RB|resetBold) F=$F\;21 ;;
        rf|RF|resetFaint) ;; #F=$F\;22 ;;
        ri|RI|resetItalic) ;; #F=$F\;23 ;;
        ru|RU|resetUnderline) ;; #F=$F\;24 ;;
        rk|RK|resetBlink) ;; #F=$F\;25 ;;
        rr|RR|resetReverse) F=$F\;27 ;;
        rh|RH|resetHidden) F=$F\;28 ;;
        rs|RS|resetStrike) F=$F\;20 ;;

        # Extra
        nl|newLine) NEWLINE=1 ;;

        --) shift; break ;;
      esac
      shift
    done

    [ "$F" != "${ESC}" ] && echo -en "${F}m"

    if [ $# -ne 0 ]; then
      echo -en "$@"
      echo -en "${ESC}0m"
    fi

    if [ ${NEWLINE} -eq 1 ]; then
      echo ''
    fi
  }

else # 16 colors

  ## \fn format (args...)
  ## \brief Format the output with style and color (16)
  ## \param args Letters or complete names of style/colors.
  ## \out The formatting string without newline.
  format() {
    local NEWLINE=0
    local ESC='\033['
    local F="${ESC}"
    while [ $# -ne 0 ]; do
      case "$1" in
        # Foreground
        d|default) F=$F\;39 ;;
        k|black) F=$F\;30 ;;
        r|red) F=$F\;31 ;;
        g|green) F=$F\;32 ;;
        y|yellow) F=$F\;33 ;;
        b|blue) F=$F\;34 ;;
        m|magenta) F=$F\;35 ;;
        c|cyan) F=$F\;36 ;;
        w|white) F=$F\;37 ;;

        # Foreground extended
        ik|intenseBlack) F=$F\;90 ;;
        ir|intenseRed) F=$F\;91 ;;
        ig|intenseGreen) F=$F\;92 ;;
        iy|intenseYellow) F=$F\;93 ;;
        ib|intenseBlue) F=$F\;94 ;;
        im|intenseMagenta) F=$F\;95 ;;
        ic|intenseCyan) F=$F\;96 ;;
        iw|intenseWhite) F=$F\;97 ;;

        # Background
        od|onDefault) F=$F\;49 ;;
        ok|onBlack) F=$F\;40 ;;
        or|onRed) F=$F\;41 ;;
        og|onGreen) F=$F\;42 ;;
        oy|onYellow) F=$F\;43 ;;
        ob|onBlue) F=$F\;44 ;;
        om|onMagenta) F=$F\;45 ;;
        oc|onCyan) F=$F\;46 ;;
        ow|onWhite) F=$F\;47 ;;

        # Background extended
        oik|onIntenseBlack) F=$F\;100 ;;
        oir|onIntenseRed) F=$F\;101 ;;
        oig|onIntenseGreen) F=$F\;102 ;;
        oiy|onIntenseYellow) F=$F\;103 ;;
        oib|onIntenseBlue) F=$F\;104 ;;
        oim|onIntenseMagenta) F=$F\;105 ;;
        oic|onIntenseCyan) F=$F\;106 ;;
        oiw|onIntenseWhite) F=$F\;107 ;;

        # Style
        B|bold) F=$F\;1 ;;
        F|faint) F=$F\;2 ;;
        I|italic) F=$F\;3 ;;
        U|underline) F=$F\;4 ;;
        K|blink) F=$F\;5 ;;
        R|reverse) F=$F\;7 ;;
        H|hidden) F=$F\;8 ;;
        S|strike) F=$F\;9 ;;

        # Reset style
        ra|R|reset|resetAll) F=$F\;0 ;;
        rb|RB|resetBold) F=$F\;21 ;;
        rf|RD|resetFaint) F=$F\;22 ;;
        ri|RI|resetItalic) F=$F\;23 ;;
        ru|RU|resetUnderline) F=$F\;24 ;;
        rk|RK|resetBlink) F=$F\;25 ;;
        rr|RR|resetReverse) F=$F\;27 ;;
        rh|RH|resetHidden) F=$F\;28 ;;
        rs|RS|resetStrike) F=$F\;20 ;;

        # Extra
        nl|newLine) NEWLINE=1 ;;

        --) shift; break ;;
      esac
      shift
    done

    [ "$F" != "${ESC}" ] && echo -en "${F}m"

    if [ $# -ne 0 ]; then
      echo -en "$@"
      echo -en "${ESC}0m"
    fi

    if [ ${NEWLINE} -eq 1 ]; then
      echo ''
    fi
  }

fi

complete -W "
  d default
  k black r red g green y yellow b blue m magenta c cyan w white

  ik intenseBlack ir intenseRed ig intenseGreen iy intenseYellow
  ib intenseBlue im intenseMagenta ic intenseCyan iw intenseWhite

  od onDefault
  ok onBlack or onRed og onGreen oy onYellow ob onBlue om onMagenta oc onCyan ow onWhite

  oik onIntenseBlack oir onIntenseRed oig onIntenseGreen oiy onIntenseYellow
  oib onIntenseBlue oim onIntenseMagenta oic onIntenseCyan oiw onIntenseWhite

  B bold F faint I italic U underline K blink R reverse H hidden S strike

  nl newLine

  ra R reset resetAll
  rb RB resetBold rf RF resetFaint ri RI resetItalic ru RU resetUnderline
  rk RK resetBlink rr RR resetReverse rh RH resetHidden rs RS resetStrike" format

fi # __CORE_FORMAT_SH
