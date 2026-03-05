#!/bin/bash

environment="dev"

modules_changed=$(terragrunt find --filter-affected --format json | jq .)

for module in $(echo "$modules_changed" | jq -r '.[].path' | grep "$environment" ); do
    echo "Planning module: $module"
  #terragrunt run --all plan --working-dir "$module"
done