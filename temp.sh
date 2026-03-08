#!/bin/bash


lower_environment="dev"
higher_environment="dev"

echo "Checking for drift between ${{ inputs.branch }} and ${{ inputs.higher_branch }} for environment: $environment"

check_module_status() {
local changes_modules_to_check="$1"
local environment="$2"
for module in $(echo "$modules_changed" | jq -r '.[].path' | grep "$environment" ); do
    if [ -d "$module" ]; then

        echo "Module $module exists. Planning module: $module"
        terragrunt run --all --json-out-dir /tmp/$environment/json plan --working-dir "$module" -out-dir /tmp/tfplan

        grab_json_body=$(jq -r '.resource_changes[] | select(.change.actions | index("no-op") | not) | "\(.address) → actions: \(.change.actions | join(", "))" ' /tmp/$environment/json/tfplan.json)    
        
        # get all the actions from the tfplan json and loop through them, if any of them are not no-op then we have drift
        actions=$( jq -r '.resource_changes[].change.actions' /tmp/$environment/json/tfplan.json) 
        echo $actions
        for action in $( echo $actions | jq -r '.[]'); do
            if [[ "$action" == "no-op" ]]; then
                echo $action
                echo "No changes for module: $module"
            else
                #DRIFT DETECTED
                echo $action
                echo "Changes detected for module: $module"
                echo "Resources with changes: $grab_json_body"
                return 1
            fi
        done
    else
        echo "Module $module does not exist in higher environment. Skipping validation."
        continue
    fi
done
}


git checkout ${{ inputs.branch }}

# locates the modules that has been changed in the lower environment
# this is to check if there is any drift for the changed modules
modules_changed=$(terragrunt find --filter-affected --format json | jq .)

## chec if modules are changing in the lower environment, if not then we can skip the drift detection as there is no change to the infrastructure
if [ -z "$modules_changed" ] || [ "$modules_changed" == "[]" ]; then
    echo "No changes detected in the lower environment. Skipping drift detection."
    exit 0
else
    echo "cheking plan for modules in $lower_environment"
    if check_module_status "$modules_changed" "$lower_environment"; then
        echo "No changes detected in the lower environment. Skipping drift detection."
        exit 0
    else
        echo "Changes detected in the lower environment. Checking for drift in higher environment."

        echo "Modules changed: $modules_changed"

        git checkout ${{ inputs.higher_branch }}

        echo "Checking drift for modules: $modules_changed"
        
        terragrunt run --all init
        if check_module_status "$modules_changed" "$higher_environment"; then
            echo "No drift detected"
        else
            echo "Drift detected between ${{ inputs.branch }} and ${{ inputs.higher_branch }} for environment: $environment"
            exit 1
        fi
    fi
fi