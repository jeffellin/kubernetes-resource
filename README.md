# pks-resource

A PKS resource for applying updates to a kubernetes cluster

## Versions

Initial Release 1.0.0
  * PKS CLI version: 1.4.0-build.194
  * Helm Client: v2.12.1

## Source Configuration

### cluster configs

- `pks_endpoint`: The address and port of the API server for PKS.
- `pks_user`: Username to authenticate to PKS API.
- `pks_password`: Password to authenticate to PKS API.
- `pks_cluster`: Name of the cluster to deploy to.
- `namespace`: *Optional.* The namespace scope. Defaults to `default`. If set along with `kubeconfig`, `namespace` will override the namespace in the current-context
- `certificate_authority`: *TODO.* A certificate file for the certificate authority. Currently ssl validation is disabled when talking to the PKS API endpoint.
    ```yaml
    certificate_authority: |
        -----BEGIN CERTIFICATE-----
        ...
        -----END CERTIFICATE-----
    ```
- `insecure_skip_tls_verify`: *TODO.* If true, the API server's certificate will not be checked for validity. This will make your HTTPS connections insecure. Defaults to `false`. Currently always skips validation.

## Behavior

### `check`: Do nothing.

### `in`: Do nothing.

### `out`: Control the Kubernetes cluster.

Control the Kubernetes cluster like `kubectl apply`, `kubectl delete`, `kubectl label` and so on.

#### Parameters

- `kubectl`: *Required.* Specify the operation that you want to perform on one or more resources, for example `apply`, `delete`, `label`.
- `context`: *Optional.* The context to use when specifying a `kubeconfig` or `kubeconfig_file`
- `wait_until_ready`: *Optional.* The number of seconds that waits until all pods are ready. 0 means don't wait. Defaults to `30`.
- `wait_until_ready_interval`: *Optional.* The interval (sec) on which to check whether all pods are ready. Defaults to `3`.
- `wait_until_ready_selector`: *Optional.* [A label selector](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors) to identify a set of pods which to check whether those are ready. Defaults to every pods in the namespace.
- `namespace`: *Optional.* The namespace scope. It will override the namespace in other params and source configuration.

## Example

```yaml
resource_types:
- name: kubernetes
  type: docker-image
  source:
    repository: ellinj/pks-resource
    tag: "latest"

resources:
- name: kubernetes-production
  type: kubernetes
  source:
    pks_endpoint: ((PKS_ENDPOINT))
    pks_user: ((PKS_USER))
    pks_password: ((PKS_PASSWORD))
    pks_cluster: ((PKS_CLUSTER))
    namespace: production
- name: my-app
  type: git
  source:
    ...

jobs:
- name: kubernetes-deploy-production
  plan:
  - get: my-app
    trigger: true
  - put: kubernetes-production
    params:
      kubectl: apply -f my-app/k8s -f my-app/k8s/production
      wait_until_ready_selector: app=myapp
```

### Force update deployment

```yaml
jobs:
- name: force-update-deployment
  serial: true
  plan:
  - put: mycluster
    params:
      kubectl: |
        patch deploy nginx -p '{"spec":{"template":{"metadata":{"labels":{"updated_at":"'$(date +%s)'"}}}}}'
      wait_until_ready_selector: run=nginx
```


## License

This software is released under the MIT License.
