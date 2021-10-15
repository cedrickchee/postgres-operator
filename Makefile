# ============================================================================ #
# HELPERS
# ============================================================================ #

## help: print this help message
help:
	@echo "Usage:"
	@sed -n "s/^##//p" ${MAKEFILE_LIST} | column -t -s ":" | sed -e "s/^/ /"

confirm:
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]

# ============================================================================ #
# DEVELOPMENT
# ============================================================================ #

## k3d/registry: create a customized k3d-managed registries
k3d/registry: confirm
	k3d registry create myregistry.localhost --port 12345

## k8s/cluster/up: create k8s cluster using k3d
k8s/cluster/up: confirm, k3d/registry
	k3d cluster create --config ./k3d_config.yaml

## run/api: run the cmd/api application
run/api:
	# go run ./cmd/api -db-dsn=${SKEL_DB_DSN}
	echo 'TODO'

.PHONY: help, confirm, k8s/cluster/up, run/api
