### Read .osc/$1 from current and previous dir
function _op() {
    for i in '.' '../'; do
        [ -r "${i}/.osc/${1}" ] && printf "%s\n" $(< ${i}/.osc/${1}) && return 0
    done
    return 1
}

### Print the project name from current or parent dir
function opr() {

    _op "_project"

}

### Print the package name from current or parent dir
function opk() {

    _op "_package"

}

### Print the project/pakage from current or parent dir
function opp {

    local _project _package
    _project=$(opr)
    _package=$(opk)

    if [[ -n "${_project}" && -n "${_package}" ]]; then
        printf "%s/%s\n" $(opr) $(opk)
        return 0
    fi
    return 1

}

# return a name of special file
# With second argument:
#   check if the given file exists in cwd and echo it
#   if not, the behave as withouth it
# Withouth:
#   1.) if no file exists, raise error
#   2.) if there's just one, echo him
#   3.) if there are multiple files
#      * return a .osc/_package.$EXT
#      * show a select dialog
function __get_special_file__() {
    local _special_name _special_file _c_special_file _special_ext
    
    _special_ext=${1}
    [ -z "${_special_ext}" ] && {
        echo "__get_special_file__: error, extension argument is mandatory"
        return 4
    }
    _special_name=${2%%.*}
    
    [ -n "${_special_name}" ] && [ -r "${_special_name}.${_special_ext}" ] && {
        echo ${_spec_name}.${_special_ext}
        return 0
    }
    
    _special_file=$(ls -1 *.${_special_ext})
    _c_special_file=$(ls -1 *.${_special_ext} | wc -l)
    
    case ${_c_special_file} in
        0)
            echo "No ${_special_ext} found" > /dev/stderr
            return 1
            ;;
        1)
            echo ${_special_file}
            return 0
            ;;
        *)
            if [ -r ".osc/_package" ]; then
                _special_name=$(opk).${_special_ext}
                [ -n "${_special_name}" ] && [ ! -r "${_special_name}" ] && {
                    echo "get_${_special_ext}: error '${_special_name}' not exists, osc project is probably corrupted"
                    return 2
                }
            else
                echo "Select spec to open"
                select SPEC in ${_special_file}; do
                    _special_name=${SPEC}
                done
            fi
            echo "${_special_name}"
            ;;
    esac
    
    echo "get_${_special_ext}: We should not reach this line"
    return 3
}

function get_spec() {
    __get_special_file__ "spec" "${@}"
}

function get_changes() {
    __get_special_file__ "changes" "${@}"
}

# auxiliary function opens the spec in editor
function __vs__() {

    local _editor _spec _ret
    _editor=${1}

    _spec=$(get_spec ${2})
    _ret=${?}

    if [ ${_ret} -eq 0 ]; then
        ${_editor} ${_spec}
    fi
    return ${_ret}
}

# open it in default EDITOR or vim
function vs() {
    __vs__ "${EDITOR:-vim}" "${@}"
}

# open it in gvim
function gvs() {
    __vs__ gvim "${@}"
}

# opens changes in less or default PAGER
function lc() {
    ${PAGER:-less} $(get_changes "${@}")
}

# opens changes in head
# TODO: the -n number handling
function hc() {
    head $(get_changes "${@}")
}

