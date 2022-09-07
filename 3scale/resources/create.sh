#!/bin/bash
PRODUCT_SYSNAME="springproduct1"
APPPLAN_SYSNAME="springappplan1"
APP_SYSNAME="springapp1"
ORG_NAME="Developer"
METHOD_SYSNAME="springmethod1"

BASE_URL="https://$ADMIN_PORTAL_HOSTNAME/admin/api"
GET_TOKEN=".json?access_token=$THREESCALE_TOKEN"

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
PRODUCT_ID=$(curl -skf "$BASE_URL/services$GET_TOKEN" | cleanup_list | filter_prod | filter_id)
echo "PRODUCT_ID: $PRODUCT_ID"

#? APPLICATION PLAN
APPPLAN_ID=$(curl -skf "$BASE_URL/services/$PRODUCT_ID/application_plans$GET_TOKEN" | cleanup_list | filter_appplan | filter_id)
if [ -z "$APPPLAN_ID" ]
  then
    echo "creating app plan"
    curl -skf -X POST "$BASE_URL/services/$PRODUCT_ID/application_plans.json" \
      --data-urlencode "name=spring-hello-plan" --data-urlencode "system_name=$APPPLAN_SYSNAME" \
      --data-urlencode "access_token=$THREESCALE_TOKEN" --data-urlencode "service_id=$PRODUCT_ID" | cleanup_item
    APPPLAN_ID=$(curl -skf "$BASE_URL/services/$PRODUCT_ID/application_plans$GET_TOKEN" | cleanup_list | filter_appplan | filter_id)
fi
echo "APPPLAN_ID: $APPPLAN_ID"

#? ACCOUNT
ACCOUNT_ID=$(curl -skf "$BASE_URL/accounts$GET_TOKEN" | cleanup_list | filter_account | filter_id)
echo "ACCOUNT_ID: $ACCOUNT_ID"

#? APPLICATION
APP_ID=$(curl -skf "$BASE_URL/applications$GET_TOKEN&plan_id=$APPPLAN_ID" | cleanup_list | jq .[0] | filter_id)
if [ -z "$APP_ID" ] || [ "$APP_ID" == "null" ]
  then
    echo "creating app"
    curl -skf -X POST "$BASE_URL/accounts/$ACCOUNT_ID/applications.json" \
      --data-urlencode "access_token=$THREESCALE_TOKEN" \
      --data-urlencode "account_id=$ACCOUNT_ID" \
      --data-urlencode "plan_id=$APPPLAN_ID" \
      --data-urlencode "name=springhelloapp" \
      --data-urlencode "description=springhelloapp" | cleanup_item
    APP_ID=$(curl -skf "$BASE_URL/applications$GET_TOKEN&plan_id=$APPPLAN_ID" | cleanup_list | jq .[0] | filter_id)
fi
echo "APP_ID: $APP_ID"

#? METHOD
HITSMETRIC_ID=$(curl -skf "$BASE_URL/services/$PRODUCT_ID/metrics$GET_TOKEN" | cleanup_list | jq ".[] | select (.system_name | contains(\"hits\"))" | filter_id)
echo "HITSMETRIC_ID: $HITSMETRIC_ID"

METHOD_ID=$(curl -skf "$BASE_URL/services/$PRODUCT_ID/metrics/$HITSMETRIC_ID/methods$GET_TOKEN" | cleanup_list | filter_method | filter_id)
if [ -z "$METHOD_ID" ] || [ "$METHOD_ID" == "null" ]
  then
    echo "creating method"
    curl -skf -X POST "$BASE_URL/services/$PRODUCT_ID/metrics/$HITSMETRIC_ID/methods.json" \
      --data-urlencode "access_token=$THREESCALE_TOKEN" \
      --data-urlencode "service_id=$PRODUCT_ID" \
      --data-urlencode "metric_id=$HITSMETRIC_ID" \
      --data-urlencode "system_name=$METHOD_SYSNAME" \
      --data-urlencode "friendly_name=spring-hello-method" | cleanup_item
    METHOD_ID=$(curl -skf "$BASE_URL/services/$PRODUCT_ID/metrics/$HITSMETRIC_ID/methods$GET_TOKEN" | cleanup_list | filter_method | filter_id)
fi
echo "METHOD_ID: $METHOD_ID"

# #? MAPPING RULE
echo "creating map rule"
curl -skf -X POST "$BASE_URL/services/$PRODUCT_ID/proxy/mapping_rules.json" \
  --data-urlencode "access_token=$THREESCALE_TOKEN" \
  --data-urlencode "service_id=$PRODUCT_ID" \
  --data-urlencode "http_method=GET" \
  --data-urlencode "metric_id=$METHOD_ID" \
  --data-urlencode "pattern=/greeting" \
  --data-urlencode "delta=1" \
  --data-urlencode "position=0"  | cleanup_item