#!/bin/sh

# Use ASCII instead of system language to speed things up
export LC_ALL=C

# Set environment variables for subshell
setenv() {
    set -e #Exit if any subcommand or pipeline returns a non-zero status.
    set -u #Exit if script try to use an uninitialised variable
    set -x #Print each command right before it is executed

}

cleanup() {
    # Save exit code from possibly failed subscript
    exitcode=$? 
    
    # Execute your cleanup code
    [ -f "cleanup.sh" ] && ( setenv; . "./cleanup.sh" )

    # Report error and return exit code from subshell
    [ "$inloop" = "true" ] && echo "error in: $subscript" && exit $exitcode
}

onexit() {
    cleanup
    exit 0
}

prompt_before_run() {
    while true; do
        read -p "Do you wish run $subscript? " yn
        case $yn in
            [Yy]* ) run_subscript; break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

run_subscript() {
    ( setenv ;. "./$subscript" ) 
}
    
# Trap Exit from the shell
trap onexit EXIT

# Trap interrupt and terminate
trap cleanup INT TERM


# Find basename for self
self=$(basename "$0")

# Get arguments
interactive="true"
while getopts ":y" o; do
    case "${o}" in
        y)
            interactive="false";;
    esac
done
shift $((OPTIND-1))

# Source each script (*.sh) found in current folder
inloop="true"
set -e #Exit if any subcommand or pipeline returns a non-zero status.
for subscript in *.sh; do
    [ -f "$subscript" ] || continue #check file exist
    [ "$subscript" != "$self" ] || continue #don't source self
    [ "$subscript" != "cleanup.sh" ] || continue #don't source cleanup in loop
    
    if  [ "$interactive" = "true" ]
    then
        prompt_before_run
    else
        run_subscript
    fi
    
done
inloop="false"
