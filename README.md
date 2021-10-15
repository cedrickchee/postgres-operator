# Kubernetes Postgres Operator

[Zalando Postgres Operator](https://github.com/zalando/postgres-operator)
creates and manages PostgreSQL clusters running in Kubernetes.

It delivers an easy to run highly-available PostgreSQL clusters on Kubernetes
powered by proven solutions "under the hood", such as:

- [Patroni](https://github.com/zalando/patroni) and
  [Spilo](https://github.com/zalando/spilo) for management,
- [WAL-G](https://github.com/wal-g/wal-g) for backups,
- [PgBouncer](https://github.com/pgbouncer/pgbouncer) as a connection pool.

This project is my notes doing the [Quickstart](https://postgres-operator.readthedocs.io/en/latest/quickstart/).

## Quickstart

This guide aims to give you a quick look and feel for using the Postgres
Operator on a local Kubernetes environment.

### Prerequisites

Since the Postgres Operator is designed for the Kubernetes (K8s) framework,
hence set it up first. For local tests I'm using [k3d](https://k3d.io/), which
allows creating multi-nodes K8s clusters running on Docker.

To interact with the K8s infrastructure install its CLI runtime
[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-curl).

This quickstart assumes that you have started minikube or created a local kind
cluster.

I created a new cluster using k3d (k3s wrapper).

```sh
$ make k8s/cluster/up
```

### Configuration Options

Configuring the Postgres Operator is only possible before deploying a new
Postgres cluster. This can work in two ways: via a ConfigMap or a custom
`OperatorConfiguration` object. More details on configuration can be found
[here](https://postgres-operator.readthedocs.io/en/latest/reference/operator_parameters/).

### Deployment options

The Postgres Operator can be deployed in the following ways:

- Manual deployment
- Kustomization
- Helm chart

#### Manual deployment setup

The Postgres Operator can be installed simply by applying yaml manifests. Note,
we provide the `/manifests` directory as an example only; you should consider
adjusting the manifests to your K8s environment (e.g. namespaces).

```sh
# First, clone the repository and change to the directory
git clone https://github.com/zalando/postgres-operator.git
cd postgres-operator

# apply the manifests in the following order
kubectl create -f manifests/configmap.yaml  # configuration
kubectl create -f manifests/operator-service-account-rbac.yaml  # identity and permissions
kubectl create -f manifests/postgres-operator.yaml  # deployment
kubectl create -f manifests/api-service.yaml  # operator API to be used by UI
```
