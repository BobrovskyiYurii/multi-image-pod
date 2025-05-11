#!/usr/bin/env bash

function isServiceRole() {
    local service_role_to_check="$1"
    local checker_regex="(^|\,)${service_role_to_check}($|\,)"
    local service_role_present=$( echo $SERVICE_ROLE | grep -E $checker_regex)

    if [[ -z ${service_role_present} ]] ; then
        echo "0"
    else
        echo "1"
    fi
}
