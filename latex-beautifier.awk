
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

function filter_sec(line)
{
        if (match(plain_line, /^\\part/)) {
                return "part"
        }
        
        if (match(plain_line, /^\\chapter/)) {
                return "chapter"
        }
        
        if (match(plain_line, /^\\section/)) {
                return "section"
        }
        
        if (match(plain_line, /^\\subsection/)) {
                return "subsection"
        }
        
        if (match(plain_line, /^\\subsubsection/)) {
                return "subsubsection"
        }
        
        if (match(plain_line, /^\\paragraph/)) {
                return "paragraph"
        }
        
        if (match(plain_line, /^\\subparagraph/)) {
                return "subparagraph"
        }

        return "-"
}

function filter_env(line)
{
        if (match(plain_line, /^\\begin/)) {
                return "begin"
        }

        if (match(plain_line, /^\\end/)) {
                return "end"
        }

        return "-"
}

function create_tabs(n)
{
        if (n > 0) {
                tabs=""
                for (i=0; i<n; i++) {
                       tabs=tabs "\t" 
                }
                return tabs
        }
        else {
                return ""
        }
}

BEGIN {
        #sec_indents["part"]=-1
        sec_indents["chapter"]=0
        sec_indents["section"]=1
        sec_indents["subsection"]=2
        sec_indents["subsubsection"]=3
        sec_indents["paragraph"]=4
        sec_indents["subparagraph"]=5

        env_indent=1

        cur_sec="-"
        cur_env="-"
        cur_sec_indent=0
        cur_env_indent=0
        cur_abs_indent=0

        plain_line=""
}

{
        plain_line=trim($0)
}

plain_line ~ /^\\/ {
        cur_sec=filter_sec(plain_line)

        if (cur_sec != "-") {
                cur_sec_indent=sec_indents[cur_sec]

                cur_abs_indent=cur_sec_indent + cur_env_indent

                printf("%s%s\n", create_tabs(cur_abs_indent), plain_line)
        }
        else {
                cur_env = filter_env(plain_line)

                if (cur_env != "-") {
                        if (cur_env == "begin") {
                                printf("%s%s\n", create_tabs(cur_abs_indent), plain_line)

                                cur_env_indent+=env_indent

                                cur_abs_indent=cur_sec_indent + cur_env_indent
                        }
                        else {
                                cur_env_indent-=env_indent

                                cur_abs_indent=cur_sec_indent + cur_env_indent

                                printf("%s%s\n", create_tabs(cur_abs_indent), plain_line)
                        }
                }
                else {
                        printf("%s%s\n", create_tabs(cur_abs_indent), plain_line)
                }
        }

        next
}

{
        printf("%s%s\n", create_tabs(cur_abs_indent), plain_line)

        next
}

END {
        #print(">> done <<")
}
