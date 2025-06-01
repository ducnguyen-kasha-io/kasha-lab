#!/bin/bash

# Fetch the health JSON
INFO=$(curl -s https://api-gateway.kasha.io/health | jq '.info')

# Loop through each service in the .info object and output YAML
echo "$INFO" | jq -r '
  to_entries[] |
  "          - name: kasha_service
            path: '\''{.details.\(.key)}'\''
            type: object
            labels:
              service: '\''\(.key)'\''
            values:
              health: '\''{.value}'\''"'