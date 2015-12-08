#!/bin/bash

function print_help
{
        echo "USAGE:"
        echo "  ./latex-beautifier -f LATEX-FILE [-f LATEX-FILE]... [-b] [-p N] | -h"
        echo "OPTIONS:"
        echo "  -f LATEX-FILE               latex file which should be formatted"
        echo "  -b                          make backup for environment blocks"
        echo "  -p N                        number of spaces that should be preserved"
        echo "  -s                          use shallow formatting (no indents, except environments!) "
        echo "  -h                          print the help text"
        echo "ARGUMENTS:"
        echo "  LATEX-FILE                  file with .tex ending"
        echo "  N                           unsigned numeric value"
}


source_dir="$(dirname "$(readlink -f "$0")")"

if [ ! -e "$source_dir/latex-beautifier.awk" ]; then
        echo "no awk file found!" >&2
        exit 1
fi 

if [ ! -e "$source_dir/latex-beautifier.rc" ]; then
        echo "no rc file found!" >&2
        exit 1
fi

source "$source_dir/latex-beautifier.rc"

if [ $# -eq 0 ]; then
        print_help
        exit 1
else
        latex_files=""
        cnt_latex_files=0
        use_env_buffer=0
        dlt_empty_lines=0
        prv_empty_lines=0
        shallow_formatting=0

        while getopts ":f:bp:sh" opt $*; do
                case $opt in
                        f)
                                latex_files="$latex_files $OPTARG"
                                let "cnt_latex_files+=1"
                                ;;
                        b)
                                use_env_buffer=1
                                ;;
                        p)
                                if numeric "$OPTARG"; then
                                        dlt_empty_lines=1
                                        prv_empty_lines=$OPTARG
                                else
                                        echo "use numeric value for -p option!" >&2
                                        exit 1
                                fi
                                ;;
                        s)
                                shallow_formatting=1
                                ;;
                        h)
                                print_help
                                exit 0
                                ;;
                        *)
                                echo "invalid option: -$OPTARG" >&2
                                exit 1
                esac
        done

        if [ $cnt_latex_files -eq 0 ]; then
                echo "no latex files defined!" >&2
                exit 1
        else
                latex_files="$(echo $latex_files | xargs)"

                if [ $cnt_latex_files -eq 1 ]; then
                        if ! valid_latex_file "$latex_files"; then
                                echo "no valid latex file ($latex_files)!" >&2
                                exit 1
                        else
                                cat "$latex_files" | awk -v _use_env_buffer=$use_env_buffer \
                                        -v _dlt_empty_lines=$dlt_empty_lines \
                                        -v _prv_empty_lines=$prv_empty_lines \
                                        -v _shallow_formatting=$shallow_formatting \
                                        -f "$source_dir/latex-beautifier.awk"
                        fi
                else
                        cnt_fails=0
                        for file in $latex_files; do
                                if ! valid_latex_file "$file"; then 
                                        echo "no valid latex file ($file)!" >&2
                                        let "cnt_fails+=1"
                                else
                                        # run following block in background
                                        {
                                                if mv "$file" "${file}.bak"; then
                                                        cat "${file}.bak" | awk -v _use_env_buffer=$use_env_buffer \
                                                                -v _dlt_empty_lines=$dlt_empty_lines \
                                                                -v _prv_empty_lines=$prv_empty_lines \
                                                                -v _shallow_formatting=$shallow_formatting \
                                                                -f "$source_dir/latex-beautifier.awk" > "$file"
                                                fi
                                        } &
                                fi
                        done

                        if [ $cnt_fails -eq $cnt_latex_files ]; then
                                exit 1
                        else
                                wait
                                exit 0
                        fi
                fi
        fi
fi

