#!/bin/bash
set -euo pipefail

# First phase: build cluster
tofu apply -target=module.digitalocean -target=module.k0sctl -auto-approve

# Second phase: deploy workloads through Helm
tofu apply -target=module.flux_operator -target=module.infrastructure -auto-approve

# Final phase: apply all remaining resources
tofu apply -auto-approve