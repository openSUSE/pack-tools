#!/bin/bash

# checkout / or update fedora package including sources!
# TODO: branches handling
# 2010 Michal Vyskocil

function error() {
    printf "%s\n" "${@}" > /dev/stderr
}

function get_package() {
    local _package
    _package=${1}

    if [ -z "${_package}" ]; then
        error "get_package: first argument is mandatory!"
        return 1
    fi

    if [ -d ${_package}/.git ]; then
        error "get_package: .git directory already exists!"
        return 2
    fi

    git clone git://pkgs.fedoraproject.org/${_package} && \
    pushd ${_package} && \
    get_sources ${_package} && \
    popd
}

function update_package() {

    local _package
    _package=${1}

    if [ -z "${_package}" ]; then
        error "update_package: first argument is mandatory!"
        return 1
    fi
    
    if [ ! -d ${_package}/.git ]; then
        error "update_package: .git directory don't exists!"
        return 2
    fi

    pushd ${_package}
    git pull && \
    get_sources ${_package}
    popd

}

function get_sources() {
    
    local _package
    _package=${1}

    if [ -z "${_package}" ]; then
        error "get_sources: first argument is mandatory!"
        return 1
    fi


    if [ ! -r sources ]; then
        error "get_sources: Cannot read sources file"
        return 2
    fi

    cat sources | while read csum fname; do
        if [ -z "${csum}" -o -z "${fname}" ]; then
            error "get_sources: sources is corrupted"
            return 3
        fi
        url="http://pkgs.fedoraproject.org/repo/pkgs/"
        for module in *spec; do
            module=${module%%.spec}
            echo curl -H Pragma: -O -R -S --fail --show-error $url/$module/$fname/$csum/$fname
            curl -H Pragma: -O -R -S --fail --show-error $url/$module/$fname/$csum/$fname && break
            if [[ "$(md5sum $fname | cut -f 1 -d ' ')" != "${csum}" ]]; then
                error "get_sources: checksum of $fname does not match!"
                return 4
            fi
        done

    done

}

function main() {

    local _package
    _package=${1}
    
    if [ -z "${_package}" ]; then
        error "${0##*/}: first argument is mandatory!"
        return 1
    fi

    if [ -d ${_package}/.git ]; then
        update_package "${_package}"
    else
        get_package "${_package}"
    fi

}

main "${@}"
