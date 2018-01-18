# Openshift Advanced Audit

Advanced audit has been introduced into OpenShift 3.7 as tech preview. It looks like it will become the default in future versions, deprecating basic audit (which has no mechanisms for filtering etc).

3.7 Documentation links:
- https://docs.openshift.com/container-platform/3.7/install_config/master_node_configuration.html#master-node-config-advanced-audit
- https://v1-7.docs.kubernetes.io/docs/tasks/debug-application-cluster/audit/#advanced-audit

Latest Document links:
- https://docs.openshift.org/latest/install_config/master_node_configuration.html#master-node-config-advanced-audit
- https://kubernetes.io/docs/tasks/debug-application-cluster/audit/#advanced-audit

Advanced audit helps answer the questions:

- what happened?
- when did it happen?
- who initiated it?
- on what did it happen?
- where was it observed?
- from where was it initiated?
- to where was it going?

### Enable Advanced Audit

To enable advanced audit in OpenShift 3.7, edit `master-config.yaml` and restart OpenShift.

Read the docs for parameters

```
-- master-config.yaml

auditConfig:
  auditFilePath: "/var/log/openshift/advanced-audit.log"
  enabled: true
  logFormat: "json"
  maximumFileRetentionDays: 14
  maximumFileSizeMegabytes: 500
  maximumRetainedFiles: 5
  policyConfiguration: null
  policyFile: "audit-config.yaml"
  webHookKubeConfig: ""
  webHookMode: ""
```

### Audit Policy Configuration

Some of the documented examples are not great.

Audit policy defines rules about what events should be recorded and what data they should include.

When an event is processed, it’s compared against the list of rules `in order`.

The `first matching rule` sets the `audit level` of the event.

This is important as audit event levels are defined as:

- `None` - Do not log events that match this rule.
- `Metadata` - Log request metadata (requesting user, time stamp, resource, verb, etc.), but not request or response body. This is the same level as the one used in basic audit.
- `Request` - Log event metadata and request body, but not response body.
- `RequestResponse` - Log event metadata, request, and response bodie

So, it is likley you will have an audit policy tuned for your use cases.

Some good example policies to start with are:

```
-- Kube 1.8
https://github.com/kubernetes/kubernetes/blob/v1.8.0-beta.0/cluster/gce/gci/configure-helper.sh#L532
-- GCE default
https://github.com/kubernetes/kubernetes/blob/master/cluster/gce/gci/configure-helper.sh#L734
```

The audit policy file `audit-config.yaml` in this repo is a sensible starting point.

At a high level it enacts the following rules in top down order:

```
./audit-config.yaml

  # log request with empty user: authentication
  # don't log periodic master and controllers status checks and updates
  # don't log periodic nodes status checks and updates
  # don't log router watch
  # don't log these read-only URLs
  # don't log events requests
  # don't log HPA fetching metrics.
  # deletecollection calls can be large, don't log responses for expected namespace deletions
  # Secrets, ConfigMaps, and TokenReviews can contain sensitive & binary data, so only log at the Metadata level.
  # get repsonses can be large; skip them.
  # default level for known APIs
  # default level for all other requests.
```

The `metadata-only-audit-config.yaml` file is more basic and only logs at a basic level.

### Examples

The folder `./audit-logs` contains some generated audit logs from a `oc cluster up` lab (default admin, developer users) - see `./test.sh`

```
-- tests
oc login -u '' -p '' https://localhost:8443
sudo tail -f /var/log/openshift/advanced-audit.log | jq . >> empty-login-cli.json

oc login -u developer -p developer https://localhost:8443
sudo tail -f /var/log/openshift/advanced-audit.log | jq . >> login-cli.json

oc logout
sudo tail -f /var/log/openshift/advanced-audit.log | jq . >> logout-cli.json

oc new-project foobar
sudo tail -f /var/log/openshift/advanced-audit.log | jq . >> new-project-cli.json

oc delete project foobar
sudo tail -f /var/log/openshift/advanced-audit.log | jq . >> delete-project-cli.json

oc create secret generic my-secret --from-literal=key1=supersecret --from-literal=key2=topsecret
sudo tail -f /var/log/openshift/advanced-audit.log | jq . >> new-secret-cli.json

oc delete secret  my-secret
sudo tail -f /var/log/openshift/advanced-audit.log | jq . >> delete-secret-cli.json

oc create sa abc-service-account
sudo tail -f /var/log/openshift/advanced-audit.log | jq . >> create-sa-cli.json

oc policy add-role-to-user view system:serviceaccount:$(oc project -q):abc-service-account
sudo tail -f /var/log/openshift/advanced-audit.log | jq . >> add-role-sa-cli.json

oc policy remove-role-from-user view system:serviceaccount:$(oc project -q):abc-service-account
sudo tail -f /var/log/openshift/advanced-audit.log | jq . >> remove-role-sa-cli.json

oc delete sa abc-service-account
sudo tail -f /var/log/openshift/advanced-audit.log | jq . >> delete-sa-cli.json
```
