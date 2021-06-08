#!/bin/bash
. lib/parse_yaml.sh

# by dedault work on projects NGC's
type=ngc
list=0
playbook=playbooks/playbook.yml

usage() 
{ 
    echo "Usage: $0  [-t internal|monitoring|ngc (default:ngc) ] [-n STACK_NAME] [-s SERVICE|all] -e ENVIRONMENT" 1>&2; 
    echo ""
    display_stacknames_list
exit 1; 
}



ansible_command () {
    inventory=configs/${environement}/inventory.yml
    username=ngc
    if [[ $environement -eq vm-local ]]
    then
        inventory=.vagrant/provisionners/ansible/inventory/vagrant_ansible_inventory
        username=debian
    fi
    

    ansible-playbook -i ${inventory}   -u ${username}  -e "ansible_python_interpreter=/usr/bin/python3" ${playbook}
}


llod () {
  printf "    "  
  ls -l   "$@"  | grep "^d" | awk '{printf ("  %s",$9)}'
  printf "\n"
}
function display_internal_stack_list()
{
    
    if [[ $environment == "vm-local" ]]
    then
        printf "    TYPE "internal" (only local):\n"
        llod ${CURRENT_DIRECTORY}/../playbooks/roles
        
    else
        printf "    TYPE \"internal\":\n"
        printf "      traefik\n"
    fi

}

function display_stacknames_list()
{
    printf "  List of stacks name allowed:\n"
    if [[ $type -eq 'internal' ]]
    then
        display_internal_stack_list 
    fi
    if [[  $type -eq 'ngc' ]]
    then
       printf "    TYPE \"ngc\" :\n"
       llod ${CURRENT_DIRECTORY}/../playbooks/ngc/
    fi
    if [[ $type -eq 'monitoring' ]]
    then
        printf "    TYPE \"monitoring\" :\n"
        llod ${CURRENT_DIRECTORY}/../playbooks/monitoring/roles
    fi
}

function deploy_all_monitoring(){
    echo "deploy all monitoring stack"
    playbook=playbooks/monitoring/monitoring.yml
    ansible_command
}

function no_directory() {
    echo "not found directory : $1 "
    exit 1
}
CURRENT_DIRECTORY=$(pwd)

if [[ $# -eq 0  ]]; then
 usage
fi


 #[VERSION] [TYPE internal|monitoring|ngc] [STACK_NAME] [SERVICE] [ENVIRONMENT]
while getopts t:n:s:e: flag
do
    case $flag in
        
        t) type=${OPTARG}
            if [[ type -eq "internal" ]] 
            then
                type="."
            fi
        ;;
        n) stack_name=${OPTARG};;
        s) service=${OPTARG};;
        e) environment=${OPTARG};;
        h|?) usage
        ;;
    esac
done

if [[ $1 -eq 'list' ]] 
then
    display_stacknames_list 
fi

if [[ $stack_name -eq 'monitoring' && $service -eq '' && $stack_name -eq '' ]]
then
    deploy_all_monitoring
else
    # STACK must be an directory in playbooks directory
    if [[ -d "${CURRENT_DIRECTORY}/playbooks/${stack_name}" ]]
        then
        no_directory ${CURRENT_DIRECTORY}/playbooks/${stack_name}
    else
        docker_compose_file="${CURRENT_DIRECTORY}/playbooks/${type}/${stack_name}/roles/${stack_name}/templates/${stack_name}-compose.yml"

        eval $(parse_yaml ${docker_compose_file}, "${stack_name}_")
        echo ${stack_name}_services_${service}

    fi
fi




