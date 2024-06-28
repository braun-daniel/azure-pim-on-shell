#!/bin/bash
# This script is used to make PIM assignments

print_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Required parameters:
  --subscription, -s      Subscription ID or name (fuzzy search enabled)
  --resource-group, -g    Resource group name (fuzzy search enabled)

Optional parameters:
  --message, -m           Justification message
  --role, -r              Role name (default: Contributor)
  --time, -t              Duration (default: 8H). Format: 8H (hours) or 8M (minutes)
  --verbose, -v           Enable verbose output
  --help                  Show this help message
EOF
    exit 1
}

check_dependencies() {
    for cmd in curl az jq fzf; do
        if ! command -v $cmd &>/dev/null; then
            echo "$cmd is required but not installed. Exiting."
            exit 1
        fi
    done
}

validate_time() {
    if [[ ! $time =~ ^[0-9]+[HM]$ ]]; then
        echo "Invalid time format. Use nH (hours, max 8) or nM (minutes, min 5, max 60)"
        exit 1
    fi
    if [[ $time == *H ]]; then
        local hours=${time%H}
        if ((hours < 1 || hours > 8)); then
            echo "Invalid hour format. Use 1-8H."
            exit 1
        fi
    elif [[ $time == *M ]]; then
        local minutes=${time%M}
        if ((minutes < 5 || minutes > 60)); then
            echo "Invalid minute format. Use 5-60M."
            exit 1
        fi
    fi
}

parse_arguments() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -s|--subscription)
                subscription="$2"
                shift
                ;;
            -g|--resource-group)
                resource_group="$2"
                shift
                ;;
            -m|--message)
                message="$2"
                shift
                ;;
            -r|--role)
                role="$2"
                shift
                ;;
            -t|--time)
                time="$2"
                shift
                ;;
            -v|--verbose)
                verbose=true
                ;;
            --help)
                print_help
                ;;
            *)
                echo "Unknown parameter passed: $1"
                print_help
                ;;
        esac
        shift
    done
}

set_defaults() {
    role=${role:-"Contributor"}
    time=${time:-"8H"}
    verbose=${verbose:-false}
}

fuzzy_select_subscription() {
    subscription=$(az account list --query "[].{name:name, id:id}" -o tsv | fzf --prompt="Select Subscription: " | awk '{print $1}')
    if [[ -z "$subscription" ]]; then
        echo "No subscription selected. Exiting."
        exit 1
    fi
}

fuzzy_select_resource_group() {
    resource_group=$(az group list --query "[].name" -o tsv | fzf --prompt="Select Resource Group: ")
    if [[ -z "$resource_group" ]]; then
        echo "No resource group selected. Exiting."
        exit 1
    fi
}

convert_date() {
    local date="$1"
    local format="$2"
    if [[ $(uname) == "Darwin" ]]; then
        date -j -f "%Y-%m-%dT%H:%M:%S" "$date" +"$format"
    else
        date -d "$date" +"$format"
    fi
}

main() {
    check_dependencies
    parse_arguments "$@"
    set_defaults

    if [[ -z "$subscription" ]]; then
        fuzzy_select_subscription
    fi

    if [[ -z "$resource_group" ]]; then
        fuzzy_select_resource_group
    fi

    validate_time

    if [[ -z "$message" ]]; then
        read -p "Please provide a justification message: " message
        if [[ -z "$message" ]]; then
            echo "Justification message cannot be empty"
            exit 1
        fi
    fi

    user_object_id=$(az ad user list --filter "mail eq '$(az account show --query user.name -o tsv)'" --query "[0].id" -o tsv)
    start_date=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    guid=$(uuidgen | tr '[:upper:]' '[:lower:]')
    token=$(az account get-access-token --query accessToken -o tsv)
    subscription_id=$(az account list --query "[?id=='$subscription' || name=='$subscription'].id" -o tsv)

    role_eligibility_schedule_instances=$(curl -s -H "Authorization: Bearer $token" -X GET \
        "https://management.azure.com/subscriptions/${subscription_id}/resourceGroups/${resource_group}/providers/Microsoft.Authorization/roleEligibilityScheduleInstances?api-version=2020-10-01&\$filter=asTarget()")

    role_definition_id=$(jq -r --arg resource_group "$resource_group" --arg role "$role" \
        '.value[] | select(.properties.scope | endswith($resource_group)) | select(.properties.expandedProperties.roleDefinition.displayName == $role) | .properties.expandedProperties.roleDefinition.id' <<<"$role_eligibility_schedule_instances" | awk -F'/' '{print $NF}')

    justification="${message// /_}"
    data=$(cat <<EOF
{
    "Properties": {
        "RoleDefinitionId": "/subscriptions/${subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${role_definition_id}",
        "PrincipalId": "${user_object_id}",
        "RequestType": "SelfActivate",
        "Justification": "${justification}",
        "ScheduleInfo": {
            "StartDateTime": "${start_date}",
            "Expiration": {
                "Type": "AfterDuration",
                "EndDateTime": null,
                "Duration": "PT${time}"
            }
        }
    }
}
EOF
    )

    response=$(curl -s -H "Authorization: Bearer $token" -X PUT -H "Content-Type: application/json" -d "$data" \
        "https://management.azure.com/subscriptions/${subscription_id}/resourceGroups/${resource_group}/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/${guid}?api-version=2020-10-01")

    if [[ $(echo "$response" | jq -r '.error') != "null" ]]; then
        echo "Error: $(echo "$response" | jq -r '.error.message')"
        exit 1
    fi

    if [[ $(echo "$response" | jq -r '.properties.status') == "Provisioned" ]]; then
        start_date_time=$(echo "$response" | jq -r '.properties.scheduleInfo.startDateTime')
        end_date_time=$(convert_date "$start_date_time" +"%Y-%m-%dT%H:%M:%S.%3NZ + ${time//H/h} ${time//M/m} minutes")
        end_date_formatted=$(convert_date "$end_date_time" "%d.%m.%Y - %H:%M")
        start_date_formatted=$(convert_date "$start_date_time" "%d.%m.%Y - %H:%M")
        echo "PIM assignment active from $start_date_formatted to $end_date_formatted"
    else
        echo "An unknown error occurred."
    fi
}

main "$@"
