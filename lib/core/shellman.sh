#!/bin/bash

## @file doxyman
## @brief generates man pages for library functions

## @desc This script lets you write some doxygen documentation in your
## library files and uses doxygen to parse them and generate a man page.
## The idea is to generate man pages for each file in your library.
##
## As you cannot use /** to comment a line in a
## shell script, you will have to use ## instead.
## A line beginning with more than 2 consecutive # will not be
## recognize as a documentation line.
##
## For example, if you have a library file include.sh containing a function
## called include, you can write above this function the following lines:
##
##     ## @fn int include (filename)
##     ## @brief Includes content of a library file in the current shell
##     ## @param $1 Names of library files to include
##     ## @return Code: 1 (and exits if subshell) if no args or error while including contents, 0 otherwise
##     ## @return Echo: message on stderr if return code 1
##
## The @fn line is optionnal but it lets you give a more precise prototype.
##
## If the shellm variable is defined in your
## current shell, the generated man page will be moved into the
## $shellm/man/man3 directory. You will then be able to type
## 'man include' to see the man page.

## @author Timothée Mazzucotelli <timothee.mazzucotelli@gmail.com>
## @package doxygen grep sed coreutils
## @env shellm Root directory of the shellm structure
## @seealso doxygen shelp
## @todo rajouter quand même le traitement de la balise package (et todo?)
## @todo reprendre le fonctionnement de shelp et l'appliquer ici (plus besoin de doxygen)

include message.sh
include check.sh
include usage.sh

check; [ $# -eq 0 ] && usage

isComment()              {
  echo "$1" | grep -q -e '^##[^#].*$' -e '^##$'
}

isCommentWithBalise()    {
  echo "$line" | grep -iq '^##[ ]*@[a-z]* .*$'
}

isFunction()             {
  (echo "$1" | grep -iq '^[a-z_]\w*[ ]*()[ ]*[{]') ||
    (echo "$1" | grep -iq 'function [ ]*[a-z_]\w* [{]')
}

isFnBalise()             {
  echo "$1" | grep -iq ' @fn '
}

getPrototype()           {
  echo "$1{}" | sed 's/^##[ ]*@fn //'
}

getFunctionName()        {
  echo "$1"                |\
  sed 's/^[ ]*function //' |\
  sed 's/[ ]*[{]//'        |\
  grep -io '^\w*'
}

getFunctionNameFromDoc() {
  echo "$1"         |\
  sed 's/[ ]*(.*//' |\
  sed 's/^.* //'
}

addFunctionToList()      {
  FN_LIST="$(getFunctionNameFromDoc "$1") $FN_LIST"
}

functionListed()         {
  echo "$FN_LIST" | grep -q "$(getFunctionName "$1")"
}

replaceOpen()            {
  echo "$1" | sed 's/^##[ ]*@/\/\*\* @/'
}

replaceMiddle()          {
  echo "$1" | sed 's/^##[ ]*/ \*  /'
}

replaceFunction()        {
  echo "int $(getFunctionName "$1")() {}"
}

progress()               {
  local val=$(( ($1*100)/$2 ))
  printf "\rParsing %-25s: %d%%" "$FILE" "$val" >&2
}

filter()                 {
    local FILTER1='^[ ]*[a-z_]\w*[ ]*([ ]*)[ ]*[{].*$'
    local FILTER2='^[ ]*function [a-z_]\w*[ ]*[{].*$'
    local FILTER3='^[ ]*##[ ]*.*$'
    local FILTER4='^[ ]*$'
    local FILTER
    /bin/cat "$1" | expand -t2 | /bin/grep -ie "$FILTER1" -e "$FILTER2" -e "$FILTER3" -e "$FILTER4"
}

parser()                 {
  # FIXME: can be optimized with //! instead of opening and closing /* * */
  local OPENED=false FN_LIST i=0
  while read line; do
    if isFunction "$line"; then
      $OPENED && { echo " */"; OPENED=false; }
      functionListed "$line" || replaceFunction "$line"
    elif isCommentWithBalise "$line"; then
      if $OPENED; then
        replaceMiddle "$line"
      else
        if isFnBalise "$line"; then
          getPrototype "$line"
          addFunctionToList "$line"
        fi
        replaceOpen "$line"
        OPENED=true
      fi
    elif isComment "$line"; then
      $OPENED && replaceMiddle "$line"
    else
      $OPENED && { echo " */"; OPENED=false; }
    fi
    progress $((++i)) $1 >&2
  done
  echo -n ". " >&2
  $OPENED && echo " */"
}

doxconf()                {
  echo "PROJECT_NAME = \"$FILE\""
  echo "INPUT = /tmp/$FILE"
  echo "GENERATE_MAN = YES"
  echo "GENERATE_HTML = NO"
  echo "GENERATE_LATEX = NO"
  echo "WARNINGS = NO"
  echo "WARN_IF_DOC_ERROR = NO"
  echo "WARN_IF_UNDOCUMENTED = NO"
  echo "FULL_PATH_NAMES = NO"
  echo "OUTPUT_DIRECTORY = /tmp"
}

main()                   {
  case $1 in
    ## @option -h, --help
    ## Print this help and exit
    -h|--help) shelp -t "$0"; exit 0 ;;
  esac

  [ ! -f "$1" ] && die "doxyman: $1: no such file or directory"
  local FILE LEN FILTERED
  while [ $# -ne 0 ]; do
    FILE="$(basename "$1")"
    FILTERED=$(filter "$1")
    LEN=$(echo "$FILTERED" | wc -l)
    echo "$FILTERED" | parser $LEN > "/tmp/$FILE"
    doxygen -g /tmp/doxyfile > /dev/null
    doxconf >> /tmp/doxyfile
    printf "Generating man page... "
    doxygen /tmp/doxyfile > /dev/null
    echo "done"
    /bin/rm "/tmp/$FILE" /tmp/doxyfile
    shift
  done
  /bin/rm /tmp/man/man3/_tmp_.3
  if [ -n "$shellm" ]; then
    echo -n "Moving manpage(s) to $shellm/man/man3... "
    for FILE in /tmp/man/man3/*.3; do
      [ ! -f "$FILE" ] && break
      chmod 664 "$FILE"
      /bin/mv "$FILE" "$shellm/man/man3/$(basename "${FILE%%.*}").3"
    done
    echo "done"
    echo -n "Cleaning up... "
    /bin/rm -rf /tmp/man
    echo "done"
  else
    echo "Manpage(s) are in /tmp/man/man3"
  fi
}

## @synopsis FILE [FILE...]
main "$@"














































#!/bin/bash

## @file shelp
## @brief parser for shell script documentation, generates POD/MAN/TEXT documentation
## @package perl
## @depends shelp
## @todo add 'todo' and 'section' tags handlers
## @seealso doxyman
## @author Timothée Mazzucotelli <timothee.mazzucotelli@gmail.com>

### Balises doc
#
# Les balises marquées d'un + peuvent être répétées
#
#    @file FILE suivi de @brief ...
#    +@package PKG... pour définir les paquets nécessaires au bon fonctionnement
#    +@depends DEP... pour définir les programmes requis
#        ne pouvant être trouvés dans des paquets
#    +@synopsis USAGE pour définir une façon d'utiliser le script
#    @desc DESC pour la description détaillée
#    +@option OPTS
#    DEF pour définir une option (short et long) et sa définition
#    +@example CMD_LINE
#    DEF pour définir un example (ligne de commande + explication)
#    +@env VAR
#    DEF pour définir une variable d'environnement utilisée et sa description
#    +@files FILE
#    DEF pour définir un fichier utilisé et sa description
#    +@exit CODE DEF pour définir une valeur de retour et sa description
#    +@author AUTHOR EMAIL pour définir un auteur accompagné d'une adresse mail
#    @date DATE pour définir la date d'écriture du script
#    @license LICENSE pour définir la license d'utilisation
#    @version VERSION pour le numéro de version actuel
#    +@note NOTE pour définir une note (+ permet de les séparer dans le script)
#    +@bug BUG pour définir un bug non résolu/résolvable
#    +@seealso NOM pour référencer une autre documentation en rapport avec celle-ci
#    +@section SECTION pour définir un nouveau bloc avec le nom SECTION
#        Les balises @section peuvent être combinées pour créer des sous-sections
#

### Balises POD
# B: gras
# I: italique
# C: code
#     C<< if($a > $b) >>
# F: fichier (italique)
# S: texte qui ne sera pas coupé (pas de mise à la ligne)
# L: lien vers une autre page de man
#     L<texte|nom>: autre doc
#     L<texte|nom/section>: autre doc + section
#     L<texte|nom/"section">: pareil
#     L<texte|/"section"> ou L<texte|/section> ou L<texte|"section">
#         ce doc, autre section
#      L<http://perl.developpez.com> : vers un site web
# E<entité html>

### Options du script
#
# Pour afficher l'aide d'un script, on garde la description, les options, les examples
# On peut choisir de laisser le script organiser les blocs, de garder l'ordre du fichier,
#     ou de fournir une chaine de format pour la présentation de la page de manuel
# On peut choisir de filtrer les blocs générés pour la page de manuel (pkg, depends...)
# On peut choisir de générer la doc POD ou MAN (toujours affichée sur stdout)
# On peut aussi demander à ce que la page de man soit générée directement dans
#    $shellm/man/man1

include message.sh
include usage.sh

[ $# -eq 0 ] && usage

PROGRESS=0

default_order=(
    'file' 'brief' 'package' 'depends'
    'synopsis' 'desc' 'option' 'example'
    'env' 'files' 'exit' 'author'
    'date' 'license' 'version' 'note'
    'bug' 'seealso' 'section'
)

progress() {
    [ $PROGRESS -eq 0 ] && return
    local val=$(( ($1*100)/$2 ))
    [ -z "$FILE" ] && FILE=${SCRIPT##*/}
    printf "\rParsing %-25s: %d%%" "$FILE"  "$val" >&2
}

filter() {
    local FILTER1='^[ ]*##[ ]*.*$'
    local FILTER2='^[ ]*$'
    /bin/cat "$1" | expand                       |\
        /bin/grep -i -e "$FILTER1" -e "$FILTER2" |\
        uniq | sed 's/^ *## //g;s/^ *##$//g'
    echo "@END"
}

splitTwoDoc() {
    local word1=${3%% *}
    eval $11[\$$2]=$word1
    [ "$word1" != "$3" ] && eval $12[\$$2]=\${3#* }
}

caseLine() {
    progress $((++i)) $LEN
    case "$1" in
        '@file '*) FILE=${1#@file } ;;
        '@brief '*)
            BRIEF=${1#@brief }
            while read LINE; do
                [[ "$LINE" = @* ]] && { caseLine "$LINE"; break; }
                BRIEF="$(echo "$BRIEF\n$LINE")"
                progress $((++i)) $LEN
            done
        ;;
        '@package '*) PACKAGE="$PACKAGE ${1#@package }" ;;
        '@depends '*) DEPENDS="$DEPENDS ${1#@depends }" ;;
        '@synopsis '*)
            SYN1[$synopsis]=${1#@synopsis }
            while read LINE; do
                [[ "$LINE" = @* ]] && { let synopsis++; caseLine "$LINE"; break; }
                SYN2[$synopsis]="$(echo -n "${SYN2[$synopsis]}$LINE\n")"
                progress $((++i)) $LEN
            done
        ;;
        '@desc '*)
            DESC=${1#@desc }
            NL=0
            while read LINE; do
                [[ "$LINE" = @* ]] && { caseLine "$LINE"; break; }
                if [[ "$LINE" = "    "* ]]; then
                    DESC="$DESC\n$LINE"
                elif [[ "$LINE" = "" ]]; then
                    DESC="$DESC\n\n"
                    NL=1
                else
                    [ $NL -eq 1 ] && { DESC="${DESC}${LINE}"; NL=0; } ||
                        DESC="$DESC $LINE"
                fi
                progress $((++i)) $LEN
            done
        ;;
        '@option '*)
            OPT1[$option]=${1#@option }
            while read LINE; do
                [[ "$LINE" = @* ]] && { let option++; caseLine "$LINE"; break; }
                OPT2[$option]="$(echo -n "${OPT2[$option]}$LINE\n")"
                progress $((++i)) $LEN
            done
        ;;
        '@example '*)
            EXA1[$example]=${1#@example }
            while read LINE; do
                [[ "$LINE" = @* ]] && { let example++; caseLine "$LINE"; break; }
                EXA2[$example]="$(echo -n "${EXA2[$example]}$LINE\n")"
                progress $((++i)) $LEN
            done
        ;;
        '@env '*)
            splitTwoDoc ENV env "${1#@env }"
            while read LINE; do
                [[ "$LINE" = @* ]] && { let env++; caseLine "$LINE"; break; }
                ENV2[$env]="$(echo -n "${ENV2[$env]}$LINE\n")"
                progress $((++i)) $LEN
            done
        ;;
        '@files '*)
            splitTwoDoc FIL file "${1#@file }"
            while read LINE; do
                [[ "$LINE" = @* ]] && { let file++; caseLine "$LINE"; break; }
                FIL2[$file]="$(echo -n "${FIL2[$file]}$LINE\n")"
                progress $((++i)) $LEN
            done
        ;;
        '@exit '*)
            splitTwoDoc EXI exit "${1#@exit }"
            while read LINE; do
                [[ "$LINE" = @* ]] && { let exit++; caseLine "$LINE"; break; }
                EXI2[$exit]="$(echo -n "${EXI2[$exit]}$LINE\n")"
                progress $((++i)) $LEN
            done
        ;;
        '@author '*)
            AUTHOR[$author]=${1#@author }
            let author++
        ;;
        '@date '*) DATE=${1#@date } ;;
        '@license '*)
            LICENSE=${1#@license }
            while read LINE; do
                [[ "$LINE" = @* ]] && { caseLine "$LINE"; break; }
                LICENSE="$(echo "$LICENSE\n$LINE")"
                progress $((++i)) $LEN
            done
        ;;
        '@version '*) VERSION=${1#@version } ;;
        '@note '*)
            NOTE[$note]=${1#@note }
            while read LINE; do
                [[ "$LINE" = @* ]] && { let note++; caseLine "$LINE"; break; }
                NOTE[$note]="$(echo "${NOTE[$note]}\n$LINE")"
                progress $((++i)) $LEN
            done
        ;;
        '@bug '*)
            BUG[$bug]=${1#@bug }
            while read LINE; do
                [[ "$LINE" = @* ]] && { let bug++; caseLine "$LINE"; break; }
                BUG[$bug]="$(echo "${BUG[$bug]}\n$LINE")"
                progress $((++i)) $LEN
            done
        ;;
        '@seealso '*) SEEALSO="$SEEALSO ${1#@seealso }" ;;
        '@section '*)
            SECTION1[$section]=${1#@section }
            while read LINE; do
                [[ "$LINE" = @* ]] && { let section++; caseLine "$LINE"; break; }
                SECTION2[$section]="$(echo -n "${SECTION2[$section]}$LINE\n")"
                progress $((++i)) $LEN
            done
        ;;
    esac
}

outpodSingle() {
    echo "=head1 $1"; echo
    echo -e "$2"; echo
}

outpodSingleList() {
    echo "=head1 $1"; echo
    echo -e "$2" | sed 's/^ *//;s/ /, /g'; echo
}

outpodSingleListWithLinks() {
    # fonction obsolète pour man page
    local w
    echo "=head1 $1"; shift; echo
    for w; do
        echo -n "L<$w|$w>, "
    done | sed 's/, $//'; echo; echo
}

outpodList() {
    local x=0
    echo "=head1 $1"; echo
    while [ $x -ne $2 ]; do
        printf ' '; eval echo -e "\${$3[$x]}"
        let x++
    done
    echo
}

outpodListWithNL() {
    local x=0
    echo "=head1 $1"; echo
    while [ $x -ne $2 ]; do
        eval echo -e "\${$3[$x]}"; echo
        let x++
    done
}

outpodDouble() {
    local x=0
    echo "=head1 $1"; echo
    echo "=over 4"; echo
    while [ $x -ne $2 ]; do
        eval echo "=item B\<\${$31[$x]}\>"; echo
        eval echo -e "\${$32[$x]}"; echo
        let x++
    done
    echo "=back"; echo
}

outpodSynopsis() {
    local x=0
    echo "=head1 $1"; echo
    echo "=over 4"; echo
    while [ $x -ne $2 ]; do
        eval echo "=item B\<$FILE\> \${$31[$x]}"; echo
        eval echo -e "\${$32[$x]}"; echo
        let x++
    done
    echo "=back"; echo
}

outputPOD() {
    local x=0
    echo -e "=encoding utf-8\n\n=pod\n"

    [ -n "$FILE"      ] && outpodSingle NAME "$FILE - $BRIEF"
    #~ [ -n "$PACKAGE"   ] && outpodSingleList "REQUIRED PACKAGES" "$PACKAGE"
    #~ [ -n "$DEPENDS"   ] && outpodSingleList "REQUIRED EXECUTABLES" "$DEPENDS"
    [ $synopsis -gt 0 ] && outpodSynopsis "SYNOPSIS" $synopsis SYN
    [ -n "$DESC"      ] && outpodSingle "DESCRIPTION" "$DESC"
    [ $option -gt 0   ] && outpodDouble "OPTIONS" $option OPT
    [ $example -gt 0  ] && outpodDouble "EXAMPLES" $example EXA
    [ $env -gt 0      ] && outpodDouble "ENVIRONMENT VARIABLES" $env ENV
    [ $file -gt 0     ] && outpodDouble "FILES" $file FIL
    [ $exit -gt 0     ] && outpodDouble "EXIT STATUS" $exit EXI
    [ $author -gt 0   ] && outpodList "AUTHORS" $author AUTHOR
    [ -n "$DATE"      ] && outpodSingle "DATE" "$DATE"
    [ -n "$LICENSE"   ] && outpodSingle "COPYRIGHT" "$LICENSE"
    [ -n "$VERSION"   ] && outpodSingle "VERSION" "$VERSION"
    [ $note -gt 0     ] && outpodListWithNL "NOTES" $note NOTE
    [ $bug -gt 0      ] && outpodListWithNL "BUGS" $bug BUG
    [ -n "$SEEALSO"   ] && outpodSingleListWithLinks "SEE ALSO" $SEEALSO

    echo "=cut"; echo
}

outputMAN() {
    outputPOD | pod2man -n "${SCRIPT##*/}"
}

manToShellM() {
    printf ". Generating man page... "
    outputMAN > "$shellm/man/man1/${SCRIPT##*/}.1"
    echo "done"
}

outputHelp() {
    local x c=$(tput cols)
    usage "$SCRIPT"; echo
    echo -e "$DESC" | fmt -scw $c
    if [ $option -gt 0 ]; then
        x=0
        echo "Options:"
        while [ $x -lt $option ]; do
            echo "  ${OPT1[$x]}"
            [ -n "${OPT2[$x]}" ] && \
                echo "      ${OPT2[$x]}" |\
                sed 's/\\n\\n/\\0/g;s/\\n/ /g;s/\\0/\n\n      /g' |\
                fmt -w $c
            echo
            let x++
        done
    fi
    if [ $example -gt 0 ]; then
        x=0
        echo "Examples:"
        while [ $x -ne $example ]; do
            echo "  ${EXA1[$x]}"
            [ -n "${EXA2[$x]}" ] && \
                echo "      ${EXA2[$x]}" |\
                sed 's/\\n\\n/\\0/g;s/\\n/ /g;s/\\0/\n\n      /g' |\
                fmt -w $c
            let x++
        done
    fi
}

parse() {
    local LINE OLD_IFS=$IFS IFS='' i=0
    filter "$1" > /tmp/shelp-parsing
    local LEN=$(cat /tmp/shelp-parsing | wc -l)

    while read LINE; do
        caseLine "$LINE"
    done < /tmp/shelp-parsing
    /bin/rm /tmp/shelp-parsing

    IFS=$OLD_IFS
}

main() {
    local SCRIPT OPTION=c

    while [ $# -ne 0 ]; do
        case $1 in
            ## @option -p, --pod
            ## Output POD documentation on stdout
            '-p'|'--pod') OPTION=p ;;
            ## @option -m, --man
            ## Output MAN documentation on stdout
            '-m'|'--man') OPTION=m ;;
            ## @option -s, --shellm
            ## Output MAN documentation in shellm/man/man1/FILE
            '-s'|'--shellm') OPTION=s; PROGRESS=1 ;;
            ## @option -t, --text
            ## Outputs help text on stdout (synopsis, description, options, examples)
            '-t'|'--text') OPTION=t ;;
            ## @option -h, --help
            ## Print this help and exit
            '-h'|'--help') shelp -t "$0"; exit 0 ;;
            *) [ -f "$1" ] && SCRIPT="$1" ||
                die "shelp: $1: no such regular file" ;;
        esac
        shift
    done

    [ -z "$SCRIPT" ] && die "You must give a file as argument"

    local SECTION1 SECTION2
    local FILE PACKAGE DEPENDS AUTHOR DATE
    local VERSION SEEALSO BRIEF SYN1 SYN2 BUG
    local DESC OPT1 OPT2 EXA1 EXA2 ENV1 ENV2
    local FIL1 FIL2 EXI1 EXI2 LICENSE NOTE

    local author=0 synopsis=0
    local option=0 example=0
    local note=0 file=0 exit=0
    local env=0 bug=0 section=0

    parse "$SCRIPT"

    case $OPTION in
        'p') outputPOD ;;
        'm') outputMAN ;;
        's') manToShellM ;;
        't') outputHelp | uniq ;;
    esac
}

## @synopsis [-pmst] FILE
main "$@"
