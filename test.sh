#!/usr/bin/env bash

#set -x

DIR=audit-logs
SLEEP1="sleep 10"
SLEEP2="sleep 5"
SLEEP3="sleep 20"

echo ">>> prepare"
oc delete project foobar
oc logout
rm -f audit-logs/*.json
$SLEEP2

echo ">>> empty login"
sudo tail -n0 -f /var/log/openshift/advanced-audit.log > $DIR/.empty-login-cli.json &
PROC=$!
oc login -u '' -p '' https://localhost:8443
$SLEEP1
sudo kill -9 $!
$SLEEP2
cat $DIR/.empty-login-cli.json | jq . > $DIR/empty-login-cli.json
rm -f $DIR/.empty-login-cli.json
$SLEEP2

echo ">>> login"
sudo tail -n0 -f /var/log/openshift/advanced-audit.log > $DIR/.login-cli.json &
PROC=$!
oc login -u developer -p developer https://localhost:8443
$SLEEP1
sudo kill -9 $!
$SLEEP2
cat $DIR/.login-cli.json | jq . > $DIR/login-cli.json
rm -f $DIR/.login-cli.json
$SLEEP2

echo ">>> new-project"
sudo tail -n0 -f /var/log/openshift/advanced-audit.log > $DIR/.new-project-cli.json &
PROC=$!
oc new-project foobar
$SLEEP1
sudo kill -9 $!
$SLEEP2
cat $DIR/.new-project-cli.json | jq . > $DIR/new-project-cli.json
rm -f $DIR/.new-project-cli.json
$SLEEP2

echo ">>> new-secret"
sudo tail -n0 -f /var/log/openshift/advanced-audit.log > $DIR/.new-secret-cli.json &
PROC=$!
oc create secret generic my-secret --from-literal=key1=supersecret --from-literal=key2=topsecret
$SLEEP1
sudo kill -9 $!
$SLEEP2
cat $DIR/.new-secret-cli.json | jq . > $DIR/new-secret-cli.json
rm -f $DIR/.new-secret-cli.json
$SLEEP2

echo ">>> delete-secret"
sudo tail -n0 -f /var/log/openshift/advanced-audit.log > $DIR/.delete-secret-cli.json &
PROC=$!
oc delete secret  my-secret
$SLEEP3
sudo kill -9 $!
$SLEEP2
cat $DIR/.delete-secret-cli.json | jq . > $DIR/delete-secret-cli.json
rm -f cat $DIR/.delete-secret-cli.json
$SLEEP2

echo ">>> create-sa"
sudo tail -n0 -f /var/log/openshift/advanced-audit.log > $DIR/.create-sa-cli.json &
PROC=$!
oc create sa abc-service-account
$SLEEP1
sudo kill -9 $!
$SLEEP2
cat $DIR/.create-sa-cli.json | jq . > $DIR/create-sa-cli.json
rm -f $DIR/.create-sa-cli.json
$SLEEP2

echo ">>> add-role"
sudo tail -n0 -f /var/log/openshift/advanced-audit.log > $DIR/.add-role-sa-cli.json &
PROC=$!
oc policy add-role-to-user view system:serviceaccount:$(oc project -q):abc-service-account
$SLEEP1
sudo kill -9 $!
$SLEEP2
cat $DIR/.add-role-sa-cli.json | jq . > $DIR/add-role-sa-cli.json
rm -f $DIR/.add-role-sa-cli.json
$SLEEP2

echo ">>> remove-role"
sudo tail -n0 -f /var/log/openshift/advanced-audit.log > $DIR/.remove-role-sa-cli.json &
PROC=$!
oc policy remove-role-from-user view system:serviceaccount:$(oc project -q):abc-service-account
$SLEEP3
sudo kill -9 $!
$SLEEP2
cat $DIR/.remove-role-sa-cli.json | jq . > $DIR/remove-role-sa-cli.json
rm -f $DIR/.remove-role-sa-cli.json
$SLEEP2

echo ">>> delete-sa"
sudo tail -n0 -f /var/log/openshift/advanced-audit.log > $DIR/.delete-sa-cli.json &
PROC=$!
oc delete sa abc-service-account
$SLEEP3
sudo kill -9 $!
$SLEEP2
cat $DIR/.delete-sa-cli.json | jq . > $DIR/delete-sa-cli.json
rm -f $DIR/.delete-sa-cli.json
$SLEEP2

echo ">>> delete-project"
sudo tail -n0 -f /var/log/openshift/advanced-audit.log > $DIR/.delete-project-cli.json &
PROC=$!
oc delete project foobar
sleep 60
sudo kill -9 $!
$SLEEP2
cat $DIR/.delete-project-cli.json | jq . > $DIR/delete-project-cli.json
rm -f $DIR/.delete-project-cli.json
$SLEEP2

echo ">>> logout"
sudo tail -n0 -f /var/log/openshift/advanced-audit.log > $DIR/.logout-cli.json &
PROC=$!
oc logout
$SLEEP1
sudo kill -9 $!
$SLEEP2
cat $DIR/.logout-cli.json | jq . > $DIR/logout-cli.json
rm -f cat $DIR/.logout-cli.json
