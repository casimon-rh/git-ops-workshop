#!/bin/bash
PRODUCT_SYSNAME="springproduct1"
APPPLAN_SYSNAME="springhello1"
APP_SYSNAME="spring-hello1"
ORG_NAME="Developer"
METHOD_SYSNAME="springhello1"

function cleanup_list () {
  jq 'to_entries | .[0].value | map(to_entries | .[0].value)'
}
function filter_id () {
  jq '.id'
}
function filter_prod () {
  jq ".[] | select (.system_name | contains(\"$PRODUCT_SYSNAME\"))"
}
function filter_appplan () {
  jq ".[] | select (.system_name | contains(\"$APPPLAN_SYSNAME\"))"
}
function filter_app () {
  jq ".[] | select (.service_id | contains(\"$PRODUCT_ID\"))"
}
function filter_account () {
  jq ".[] | select (.org_name | contains(\"$ORG_NAME\"))"
}
function filter_method () {
  jq ".[] | select (.system_name | contains(\"$METHOD_SYSNAME\"))"
}
function cleanup_item () {
    jq 'to_entries | .[0].value'
}
#? PRODUCT (Service)
PRODUCT_ID=$(curl -skf "https://$ADMIN_PORTAL_HOSTNAME/admin/api/services.json?access_token=$THREESCALE_TOKEN" | cleanup_list | filter_prod | filter_id)
echo "PRODUCT_ID: $PRODUCT_ID"

#? APPLICATION PLAN
APPPLAN_ID=$(curl -skf "https://$ADMIN_PORTAL_HOSTNAME/admin/api/services/$PRODUCT_ID/application_plans.json?access_token=$THREESCALE_TOKEN" | cleanup_list | filter_appplan | filter_id)
# echo "APPPLAN_ID: $APPPLAN_ID"
# APPPLAN_ID=$(curl -skf "https://$ADMIN_PORTAL_HOSTNAME/admin/api/services/$PRODUCT_ID/application_plans.json?access_token=$THREESCALE_TOKEN" | cleanup_list | filter_appplan | filter_id)
if [ -z "$APPPLAN_ID" ] || [ ! -n "$APPPLAN_ID" ]
  then
    curl -skf -X POST "https://$ADMIN_PORTAL_HOSTNAME/admin/api/services/$PRODUCT_ID/application_plans.json" \
      --data-urlencode "plan_name=spring-hello" --data-urlencode "system_name=springhello2" \
      --data-urlencode "access_token=$THREESCALE_TOKEN" --data-urlencode "state=published" | cleanup_item
  else
    echo "APPPLAN_ID: $APPPLAN_ID"
fi

#? ACCOUNT
ACCOUNT_ID=$(curl -skf "https://$ADMIN_PORTAL_HOSTNAME/admin/api/accounts.json?access_token=$THREESCALE_TOKEN" | cleanup_list | filter_account | filter_id)
echo "ACCOUNT_ID: $ACCOUNT_ID"

#? APPLICATION
APP_ID=$(curl -skf "https://$ADMIN_PORTAL_HOSTNAME/admin/api/applications.json?access_token=$THREESCALE_TOKEN&plan_id=$APPPLAN_ID" | cleanup_list | jq .[0] | filter_id)
if [ -z "$APP_ID" ] || [ ! -n "$APP_ID" ]
  then
    curl -skf -X POST "https://$ADMIN_PORTAL_HOSTNAME/admin/api/accounts/$ACCOUNT_ID/applications.json" \
      --data-urlencode "access_token=$THREESCALE_TOKEN" \
      --data-urlencode "plan_id=$APPPLAN_ID" \
      --data-urlencode "name=spring-hello3" \
      --data-urlencode "description=spring hello 3" | cleanup_item
  else
    echo "APP_ID: $APP_ID"
fi

#? METHOD
HITSMETRIC_ID=$(curl -skf "https://$ADMIN_PORTAL_HOSTNAME/admin/api/services/$PRODUCT_ID/metrics.json?access_token=$THREESCALE_TOKEN" | cleanup_list | jq ".[] | select (.system_name | contains(\"hits\"))" | filter_id)
echo "HITSMETRIC_ID: $HITSMETRIC_ID"
METHOD_ID=$(curl -skf "https://$ADMIN_PORTAL_HOSTNAME/admin/api/services/$PRODUCT_ID/metrics/$HITSMETRIC_ID/methods.json?access_token=$THREESCALE_TOKEN" | cleanup_list | filter_method | filter_id)
if [ -z "$METHOD_ID" ] || [ ! -n "$METHOD_ID" ]
  then
    curl -skf -X POST "https://$ADMIN_PORTAL_HOSTNAME/admin/api/services/$PRODUCT_ID/metrics/$HITSMETRIC_ID/methods.json" \
      --data-urlencode "access_token=$THREESCALE_TOKEN" \
      --data-urlencode "system_name=$METHOD_SYSNAME" \
      --data-urlencode "friendly_name=spring-hello3" \
      --data-urlencode "name=spring-hello3" | cleanup_item
  else
    echo "METHOD_ID: $METHOD_ID"
fi

#? MAPPING RULE
MARULE_ID=$(curl -skf "https://$ADMIN_PORTAL_HOSTNAME/admin/api/services/$PRODUCT_ID/proxy/mapping_rules.json?access_token=$THREESCALE_TOKEN&method_id=$METHOD_ID" | cleanup_list | jq '.[0]' | filter_id)
if [ -z "$MARULE_ID" ] || [ ! -n "$MARULE_ID" ]
  then
    curl -skf -X POST "https://$ADMIN_PORTAL_HOSTNAME/admin/api/services/$PRODUCT_ID/proxy/mapping_rules.json" \
      --data-urlencode "access_token=$THREESCALE_TOKEN" --data-urlencode "http_method=GET" \
      --data-urlencode "service_id=$PRODUCT_ID" --data-urlencode "metric_id=$METHOD_ID" \
      --data-urlencode "pattern=/greeting" --data-urlencode "delta=1" --data-urlencode "position=0"  | cleanup_item
  else
    echo "MARULE_ID: $MARULE_ID"
fi