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

        shallow_formatting=_shallow_formatting

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
        # this block will only be executed if the current line starts with a
        # backslash

        # reset counter as soon as the current line isn't empty
        if (cnt_empty_lines > 0) cnt_empty_lines=0

        if (!shallow_formatting) {
                cur_sec=filter_sec(plain_line)

                if (cur_sec != "-") {
                        # current line is some sort of section. For instance \chapter,
                        # \section, \subsection etc.
                        if (cur_par_indent > 0) cur_par_indent=0

                        cur_sec_indent=abs_sec_indents[cur_sec]
                        cur_abs_indent=(cur_sec_indent + cur_par_indent + cur_rel_env_indent)

                        printf("%s%s\n", create_tabs(cur_abs_indent), plain_line)
                        next
                }

                cur_par=filter_par(plain_line)

                if (cur_par != "-") {
                        # current line is a [sub]paragraph
                        cur_par_indent=rel_par_indents[cur_par]
                        cur_abs_indent=(cur_sec_indent + cur_par_indent + cur_rel_env_indent)

                        printf("%s%s\n", create_tabs(cur_abs_indent), plain_line)
                        next
                }
        }

        cur_env=filter_env(plain_line)

        if (cur_env != "-") {
                if (cur_env == "begin") {
                        # current line is the beginning of an environment
                        printf("%s%s\n", create_tabs(cur_abs_indent), plain_line)
                        
                        # environments can be nested, hence add for each
                        # environment a further indent
                        cur_rel_env_indent+=rel_env_indent
                        cur_abs_indent=(cur_sec_indent + cur_par_indent + cur_rel_env_indent)

                        if (use_env_buffer) {
                                # store the following lines into a buffer
                                # whenever buffer-usage is enabled
                                ebl_env_buffer=1

                                env_buffer[cnt_env_buffer++]=$0
                        }
                } else {
                        # current line is the end of an environment

                        # due to \end the environment will be closed, thus
                        # remove the (another) indent
                        cur_rel_env_indent-=rel_env_indent
                        cur_abs_indent=(cur_sec_indent + cur_par_indent + cur_rel_env_indent)

                        printf("%s%s\n", create_tabs(cur_abs_indent), plain_line)

                        if (use_env_buffer) {
                                # store this line into the buffer and disable
                                # the further use of it
                                env_buffer[cnt_env_buffer++]=$0

                                if (cur_rel_env_indent == 0) {
                                        cnt_env_buffer=0
                                        ebl_env_buffer=0

                                        print_buffer(env_buffer, cnt_env_buffer)
                                }
                        }
                }
                next
        }

        printf("%s%s\n", create_tabs(cur_abs_indent), plain_line)
        
        # this code-line is very important, because within an environment the
        # lines can start with a backslash as well. For example \centering
        if (ebl_env_buffer) env_buffer[cnt_env_buffer++]=$0

        next
}

ebl_env_buffer {
        # if buffer is temporarily enabled store the lines in it
        env_buffer[cnt_env_buffer++]=$0
}

dlt_empty_lines {
        # this block will only be executed if the user enabled the removal of
        # redundant empty lines. Furthermore he can define the maximum number of
        # empty lines the program should preserve
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
