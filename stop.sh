#!/usr/bin/env bash

aws configure set region eu-west-3

apt-get install jq -y

# delete DNS record set
HOSTED_ZONE_ID=Z1ER99FRFTTS38
URL=$CI_COMMIT_SHORT_SHA.sablin.de

# get DNSName
eval DNS_NAME=$(aws route53 list-resource-record-sets --hosted-zone-id Z1ER99FRFTTS38 --query "ResourceRecordSets[?Name == '$URL.']" | jq -c '.[0].AliasTarget.DNSName')

JSON_FILE=`mktemp`

(
cat <<EOF
{
    "Comment": "Deleting Alias resource record sets in Route 53",
    "Changes": [{
               "Action": "DELETE",
               "ResourceRecordSet": {
                           "Name": "$URL",
                           "Type": "A",
                           "AliasTarget":{
                                   "HostedZoneId": "Z3Q77PNBQS71R4",
                                   "DNSName": "$DNS_NAME",
                                   "EvaluateTargetHealth": false
                             }}
                         }]
}
EOF
) > $JSON_FILE

aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch file://$JSON_FILE

# delete load balancer
echo "delete load balancer App-LB-$CI_COMMIT_SHORT_SHA..."
eval LB_ARN=$(aws elbv2 describe-load-balancers --names "App-LB-$CI_COMMIT_SHORT_SHA" | jq -c '.LoadBalancers[0].LoadBalancerArn')
aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN

# delete services
echo "delete service service-app-$CI_COMMIT_SHORT_SHA ..."
aws ecs delete-service --service service-app-$CI_COMMIT_SHORT_SHA --cluster cluster-reddit --force

# delete target group
echo "delete target group Test-tg-$CI_COMMIT_SHORT_SHA ..."
eval TG_ARN=$(aws elbv2 describe-target-groups --names Test-tg-$CI_COMMIT_SHORT_SHA | jq -c '.TargetGroups[0].TargetGroupArn')
echo "TB_ARN: $TG_ARN"
aws elbv2 delete-target-group --target-group-arn $TG_ARN
if [ $? -ne 0 ]
then
echo -e "date : Error occurs while deleting target group... "
fi



