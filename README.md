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
# Please execute the script only from the root directory of this repo.

# First, clone the repository and change to the directory
$ git clone https://github.com/zalando/postgres-operator.git pgop

# apply the manifests in the following order
$ kubectl create -f pgop/manifests/configmap.yaml  # configuration
configmap/postgres-operator created

$ kubectl create -f pgop/manifests/operator-service-account-rbac.yaml  # identity and permissions
serviceaccount/postgres-operator created
clusterrole.rbac.authorization.k8s.io/postgres-operator created
clusterrolebinding.rbac.authorization.k8s.io/postgres-operator created
clusterrole.rbac.authorization.k8s.io/postgres-pod created

$ kubectl create -f pgop/manifests/postgres-operator.yaml  # deployment
deployment.apps/postgres-operator created

$ kubectl create -f pgop/manifests/api-service.yaml  # operator API to be used by UI
service/postgres-operator created
```

> There is a Kustomization manifest that combines the mentioned resources
> (except for the CRD) - it can be used with kubectl 1.14 or newer as easy as:
> `kubectl apply -k github.com/zalando/postgres-operator/manifests`

For convenience, they have automated starting the operator with minikube using
the `run_operator_locally` script. It applies the
[acid-minimal-cluster](pgop/manifests/minimal-postgres-manifest.yaml). manifest.

`$ ./pgop/run_operator_locally.sh`

#### Helm chart

Alternatively, the operator can be installed by using the provided
[Helm](https://helm.sh/) chart which saves you the manual steps. Clone this repo
and change directory to the repo root. With Helm v3 installed you should be able
to run:

```sh
$ helm install postgres-operator ./pgop/charts/postgres-operator
```

See the quickstart doc for more.

### Check if Postgres Operator is running

Starting the operator may take a few seconds. Check if the operator pod is
running before applying a Postgres cluster manifest.

```sh
# if you've created the operator using yaml manifests
$ kubectl get pod -l name=postgres-operator

# if you've created the operator using helm chart
$ kubectl get pod -l app.kubernetes.io/name=postgres-operator
```

If the operator doesn't get into `Running` state, either check the latest K8s
events of the deployment or pod with `kubectl describe` or inspect the operator
logs:

```sh
$ kubectl logs "$(kubectl get pod -l name=postgres-operator --output='name')"
```

### Deploy the operator UI

In the following paragraphs we describe how to access and manage PostgreSQL
clusters from the command line with kubectl. But it can also be done from the
browser-based [Postgres Operator UI](https://postgres-operator.readthedocs.io/en/latest/operator-ui/).
Before deploying the UI make sure the operator is running and its REST API is
reachable through a [K8s service](pgop/manifests/api-service.yaml). The URL to this API must be configured in the
[deployment manifest](https://postgres-operator.readthedocs.io/en/ui/manifests/deployment.yaml#L43)
of the UI.

To deploy the UI simply apply all its manifests files or use the UI helm chart:

```sh
# manual deployment
$ kubectl apply -f pgop/ui/manifests/
deployment.apps/postgres-operator-ui created
ingress.networking.k8s.io/postgres-operator-ui created
service/postgres-operator-ui created
serviceaccount/postgres-operator-ui created
clusterrole.rbac.authorization.k8s.io/postgres-operator-ui created
clusterrolebinding.rbac.authorization.k8s.io/postgres-operator-ui created
error: unable to recognize "pgop/ui/manifests/kustomization.yaml": no matches for kind "Kustomization" in version "kustomize.config.k8s.io/v1beta1"

# or kustomization
$ kubectl apply -k github.com/zalando/postgres-operator/ui/manifests

# or helm chart
$ helm install postgres-operator-ui ./charts/postgres-operator-ui
```

Like with the operator, check if the UI pod gets into `Running` state:

```sh
# if you've created the operator using yaml manifests
$ kubectl get pod -l name=postgres-operator-ui

# if you've created the operator using helm chart
$ kubectl get pod -l app.kubernetes.io/name=postgres-operator-ui
```

You can now access the web interface by port forwarding the UI pod (mind the
label selector) and enter `localhost:8081` in your browser:

```sh
$ kubectl port-forward svc/postgres-operator-ui 8081:80
Forwarding from 127.0.0.1:8081 -> 8081
Forwarding from [::1]:8081 -> 8081
Handling connection for 8081
```

```sh
$ curl -i localhost:8081
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Content-Length: 4699
Date: Fri, 15 Oct 2021 15:10:37 GMT

<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>PostgreSQL Operator UI</title>
...
</html>
```

Available option are explained in detail in the [UI docs](https://postgres-operator.readthedocs.io/en/latest/operator-ui/).

### Create a Postgres cluster

If the operator pod is running it listens to new events regarding `postgresql`
resources. Now, it's time to submit your first Postgres cluster manifest.

```sh
# create a Postgres cluster
$ kubectl create -f pgop/manifests/minimal-postgres-manifest.yaml
The postgresql "acid-minimal-cluster" is invalid: spec.postgresql.version: Unsupported value: "14": supported values: "9.3", "9.4", "9.5", "9.6", "10", "11", "12", "13"
# fix and retry

$ kubectl create -f pgop/manifests/minimal-postgres-manifest.yaml
postgresql.acid.zalan.do/acid-minimal-cluster created
```

After the cluster manifest is submitted and passed the validation, the operator
will create Service and Endpoint resources and a StatefulSet which spins up new
Pod(s) given the number of instances specified in the manifest. All resources
are named like the cluster. The database pods can be identified by their number
suffix, starting from `-0`. They run the
[Spilo](https://github.com/zalando/spilo) container image by Zalando. As for the
services and endpoints, there will be one for the master pod and another one for
all the replicas (`-repl` suffix). Check if all components are coming up. Use
the label `application=spilo` to filter and list the label `spilo-role` to see
who is currently the master.

```sh
# check the deployed cluster
$ kubectl get postgresql
NAME                   TEAM   VERSION   PODS   VOLUME   CPU-REQUEST   MEMORY-REQUEST   AGE     STATUS
acid-minimal-cluster   acid   13        2      1Gi                                     8m19s   Running

# check created database pods
$ kubectl get pods -l application=spilo -L spilo-role
NAME                     READY   STATUS    RESTARTS   AGE   SPILO-ROLE
acid-minimal-cluster-0   1/1     Running   0          21m   master
acid-minimal-cluster-1   1/1     Running   0          16m   replica

# check created service resources
$ kubectl get svc -l application=spilo -L spilo-role
NAME                          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE   SPILO-ROLE
acid-minimal-cluster          ClusterIP   10.43.66.169    <none>        5432/TCP   21m   master
acid-minimal-cluster-repl     ClusterIP   10.43.252.226   <none>        5432/TCP   21m   replica
acid-minimal-cluster-config   ClusterIP   None            <none>        <none>     17m
```

### Connect to the Postgres cluster via psql

You can create a port-forward on a database pod to connect to Postgres. See the
[user guide](https://postgres-operator.readthedocs.io/en/latest/user/#connect-to-postgresql)
for instructions. With minikube it's also easy to retrieve the connections
string from the K8s service that is pointing to the master pod:

```sh
$ export HOST_PORT=$(minikube service acid-minimal-cluster --url | sed 's,.*/,,')
$ export PGHOST=$(echo $HOST_PORT | cut -d: -f 1)
$ export PGPORT=$(echo $HOST_PORT | cut -d: -f 2)
```

Note: as I'm not using minikube, I follow the instructions mentioned in the user
guide (copied here):

> With a `port-forward` on one of the database pods (e.g. the master) you can
> connect to the PostgreSQL database from your machine. Use labels to filter for
> the master pod of our test cluster.

```sh
# get name of master pod of acid-minimal-cluster
$ export PGMASTER=$(kubectl get pods -o jsonpath={.items..metadata.name} -l application=spilo,cluster-name=acid-minimal-cluster,spilo-role=master -n default)

# set up port forward
$ kubectl port-forward $PGMASTER 6432:5432 -n default
Forwarding from 127.0.0.1:6432 -> 5432
Forwarding from [::1]:6432 -> 5432
Handling connection for 6432
```

**Sidenote:**

Another way to connect from your host to k8s service running in k3s pod.
See k3d doc: [exposing services](https://k3d.io/usage/guides/exposing_services/).

> Open another CLI and connect to the database using e.g. the psql client. When
> connecting with the `postgres` user read its password from the K8s secret which
> was generated when creating the `acid-minimal-cluster`. As non-encrypted
> connections are rejected by default set the SSL mode to `require`:

```sh
$ export PGPASSWORD=$(kubectl get secret postgres.acid-minimal-cluster.credentials.postgresql.acid.zalan.do -o 'jsonpath={.data.password}' | base64 -d)
$ export PGSSLMODE=require
$ psql -U postgres -h localhost -p 6432
psql (14.0 (Ubuntu 14.0-1.pgdg20.04+1), server 13.4 (Ubuntu 13.4-4.pgdg18.04+1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
...
postgres=#
```

**Sidenote:**

Check the _master_ database replication:

```sh
postgres=# select * from pg_stat_replication\x\g\x
Expanded display is on.
-[ RECORD 1 ]----+------------------------------
pid              | 2727
usesysid         | 16661
usename          | standby
application_name | acid-minimal-cluster-1
client_addr      | 10.42.0.14
client_hostname  | 
client_port      | 37126
backend_start    | 2021-10-16 09:40:29.651345+00
backend_xmin     | 
state            | streaming
sent_lsn         | 0/E0017B0
write_lsn        | 0/E0017B0
flush_lsn        | 0/E0017B0
replay_lsn       | 0/E0017B0
write_lag        | 
flush_lag        | 
replay_lag       | 
sync_priority    | 0
sync_state       | async
reply_time       | 2021-10-16 11:11:47.517085+00

Expanded display is off.
```

Check the _replica_ database replication:

```sh
postgres=# select * from pg_stat_wal_receiver\x\g\x
Expanded display is on.
-[ RECORD 1 ]---------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
pid                   | 1262
status                | streaming
receive_start_lsn     | 0/C000000
receive_start_tli     | 3
written_lsn           | 0/F000110
flushed_lsn           | 0/F000110
received_tli          | 3
last_msg_send_time    | 2021-10-16 11:21:09.534223+00
last_msg_receipt_time | 2021-10-16 11:21:09.534364+00
latest_end_lsn        | 0/F000110
latest_end_time       | 2021-10-16 11:12:08.207732+00
slot_name             | acid_minimal_cluster_1
sender_host           | 10.42.0.12
sender_port           | 5432
conninfo              | user=standby passfile=/run/postgresql/pgpass host=10.42.0.12 port=5432 sslmode=prefer application_name=acid-minimal-cluster-1 gssencmode=prefer channel_binding=prefer

Expanded display is off.
```

See this SO thread for more: https://stackoverflow.com/a/54164409/206570

### Delete a Postgres cluster

To delete a Postgres cluster simply delete the `postgresql` custom resource.

```sh
$ kubectl delete postgresql acid-minimal-cluster
postgresql.acid.zalan.do "acid-minimal-cluster" deleted
```

This should remove the associated StatefulSet, database Pods, Services and
Endpoints. The PersistentVolumes are released and the PodDisruptionBudget is
deleted. Secrets however are not deleted and backups will remain in place.

When deleting a cluster while it is still starting up or got stuck during that
phase it can [happen](https://github.com/zalando/postgres-operator/issues/551)
that the `postgresql` resource is deleted leaving orphaned components behind. This
can cause troubles when creating a new Postgres cluster. For a fresh setup you
can delete your local minikube or kind cluster and start again.
