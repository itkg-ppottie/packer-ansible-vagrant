#!/bin/bash
. lib/parse_yaml.sh

usage() { echo "Usage: $0  [-v VERSION] [-n STACK_NAME] [-s SERVICE] [-e ENVIRONMENT]" 1>&2; exit 1; }


function no_directory() {
    echo "not found directory : $1 "
    exit 1
}
CURRENT_DIRECTORY=$(pwd)


 #[VERSION] [TYPE system|monitoring|ngc|] [STACK_NAME] [SERVICE] [ENVIRONMENT]
while getopts v:t:n:s:e: flag
do
    case $flag in
        v) version=${OPTARG};;
        t) type=${OPTARG}
            if [[ type == "system" ]] 
            then
                type="."
            fi
        ;;
        n) stack_name=${OPTARG};;
        s) service=${OPTARG};;
        e) environment=${OPTARG};;
        ?) usage;;

    esac
done


# STACK must be an directory in playbooks directory
if [[ -d "${CURRENT_DIRECTORY}/playbooks/${stack_name}" ]]
    then
    no_directory ${CURRENT_DIRECTORY}/playbooks/${stack_name}
else
    docker_compose_file="${CURRENT_DIRECTORY}/playbooks/${type}/${stack_name}/roles/${stack_name}/templates/${stack-name}-compose.yml"

    eval $(parse_yaml ${docker_compose_file}, "${stack_name}_")
    echo ${stack_name}_services_${service}

fi

