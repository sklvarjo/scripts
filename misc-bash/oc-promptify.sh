#!/bin/bash

# when the server logs you out, the oc succeeds but the username is the following line
#
#error: You must be logged in to the server (Unauthorized)
#Return code: 0
#
# but if you yourself logout oc gives return code 1 did not succeed
#
#Error from server (Forbidden): users.user.openshift.io "~" is forbidden: User "system:anonymous" cannot get resource "users" in API group "user.openshift.io" at the cluster scope
#Return code: 1

__oc_prompt() 
{
    # oc whoami
    local USER=$(oc whoami)
    echo $?
    if [[ ! -z $USER ]]; then 
        local CONTEXT=$(oc project -q)
        if [[ -n "$CONTEXT" ]]; then
            echo "(oc: ${CONTEXT})"
        fi
    fi
}
