###############################################################################
# Thanks to Jong Bor Lee - stackoverflow.com
#------------------------------------------------------------------------------
function ltrim(s)
{
        sub(/^[ \t\r\n]+/, "", s)
        return s
}

function rtrim(s)
{
        sub(/[ \t\r\n]+$/, "", s)
        return s
}

function trim(s)
{
        return rtrim(ltrim(s))
}
###############################################################################

###############################################################################
# Filter out the section name of a line.
###############################################################################
function filter_sec(line)
{
        if (match(line, /^\\part/)) return "part"
        
        if (match(line, /^\\chapter/)) return "chapter"
        
        if (match(line, /^\\section/)) return "section"
        
        if (match(line, /^\\subsection/)) return "subsection"
        
        if (match(line, /^\\subsubsection/)) return "subsubsection"
        
        return "-"
}

function filter_par(line)
{
        if (match(line, /^\\paragraph/)) return "paragraph"
        
        if (match(line, /^\\subparagraph/)) return "subparagraph"

        return "-"
}

###############################################################################
# Filter out the beginning or ending of the environment of a line.
###############################################################################
function filter_env(line)
{
        if (match(line, /^\\begin/)) return "begin"

        if (match(line, /^\\end/)) return "end"

        return "-"
}

###############################################################################
# Creates a certain amount of tabs depending on n.
###############################################################################
function create_tabs(n)
{
        if (n > 0) {
                tabs=""
                for (i=0; i<n; i++)
                        tabs=tabs "\t"

                return tabs
        } else {
                return ""
        }
}

###############################################################################
# Print the content of a buffer.
###############################################################################
function print_buffer(buffer, len)
{
        print("%===============================================================================")

        for (i=0; i<len; i++)
                print("%" buffer[i])

        print("%===============================================================================")
}

BEGIN {
        cur_sec="-"
        cur_par="-"
        cur_env="-"

        cur_sec_indent=0
        cur_par_indent=0
        cur_rel_env_indent=0
        cur_abs_indent=0

        env_buffer[0]=""
        cnt_env_buffer=0
        ebl_env_buffer=0
        use_env_buffer=_use_env_buffer

        cnt_empty_lines=0
        prv_empty_lines=_prv_empty_lines
        dlt_empty_lines=_dlt_empty_lines

        abs_sec_indents["part"]=0
        abs_sec_indents["chapter"]=0
        abs_sec_indents["section"]=1
        abs_sec_indents["subsection"]=2
        abs_sec_indents["subsubsection"]=3

        rel_par_indents["paragraph"]=1
        rel_par_indents["subparagraph"]=2

        rel_env_indent=1

        plain_line=""
}

{
        plain_line=trim($0)
}

plain_line ~ /^\\.+/ {
        cur_sec=filter_sec(plain_line)

        if (cur_sec != "-") {
                if (cur_par_indent > 0) cur_par_indent=0

                cur_sec_indent=abs_sec_indents[cur_sec]
                cur_abs_indent=(cur_sec_indent + cur_par_indent + cur_rel_env_indent)

                printf("%s%s\n", create_tabs(cur_abs_indent), plain_line)
        } else {
                cur_par=filter_par(plain_line)

                if (cur_par != "-") {
                        cur_par_indent=rel_par_indents[cur_par]
                        cur_abs_indent=(cur_sec_indent + cur_par_indent + cur_rel_env_indent)

                        printf("%s%s\n", create_tabs(cur_abs_indent), plain_line)
                } else {
                        cur_env=filter_env(plain_line)

                        if (cur_env != "-") {
                                if (cur_env == "begin") {
                                        printf("%s%s\n", create_tabs(cur_abs_indent), plain_line)

                                        cur_rel_env_indent+=rel_env_indent
                                        cur_abs_indent=(cur_sec_indent + cur_par_indent + cur_rel_env_indent)

                                        if (use_env_buffer) {
                                                ebl_env_buffer=1

                                                env_buffer[cnt_env_buffer++]=$0
                                        }
                                } else {
                                        cur_rel_env_indent-=rel_env_indent
                                        cur_abs_indent=(cur_sec_indent + cur_par_indent + cur_rel_env_indent)

                                        printf("%s%s\n", create_tabs(cur_abs_indent), plain_line)

                                        if (use_env_buffer) {
                                                env_buffer[cnt_env_buffer++]=$0

                                                if (cur_rel_env_indent == 0) {
                                                        ebl_env_buffer=0

                                                        print_buffer(env_buffer, cnt_env_buffer)

                                                        cnt_env_buffer=0
                                                }
                                        }
                                }
                        } else {
                                printf("%s%s\n", create_tabs(cur_abs_indent), plain_line)
                                
                                if (ebl_env_buffer) env_buffer[cnt_env_buffer++]=$0
                        }
                }
        }
        if (cnt_empty_lines > 0) cnt_empty_lines=0

        next
}

ebl_env_buffer {
        env_buffer[cnt_env_buffer++]=$0
}

dlt_empty_lines {
        if (length(plain_line) == 0) {
                cnt_empty_lines+=1

                if (cnt_empty_lines > prv_empty_lines) next
        } else {
                if (cnt_empty_lines > 0) cnt_empty_lines=0
        }
}

{
        printf("%s%s\n", create_tabs(cur_abs_indent), plain_line)
}

END {

}
