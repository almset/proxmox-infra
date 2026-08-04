#!/usr/bin/env bash
set -euo pipefail

ENV=${1:-linux}
ACTION=${2:-apply}

case "$ACTION" in
    init)
        make init ENV="$ENV"
        ;;
    plan)
        make plan ENV="$ENV"
        ;;
    apply)
        make init ENV="$ENV"
        make plan ENV="$ENV"
        make apply ENV="$ENV"
        ;;
    output)
        make output ENV="$ENV"
	;;
    json)
        make json ENV="$ENV" 
        ;;
    state)
        make state ENV="$ENV" 
        ;;
    destroy)
        make destroy ENV="$ENV"
        ;;
    inv)
        make inv
        ;;
    test)
        make inv
        ;;
 
    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac
