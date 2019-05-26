#!/usr/bin/env bash

aws configure set region eu-west-3

apt-get install jq -y

eval TARGET_GROUP_ARN=$(aws elbv2 create-target-group --name Test-tg-$CI_COMMIT_SHORT_SHA --protocol HTTP --port 80 --vpc-id vpc-060e5cc464cd74d72 | jq -c '.TargetGroups[0].TargetGroupArn')

# create load balancer: get LOAD_BALANCER_ARN and DNS_NAME
read LOAD_BALANCER_ARN DNS_NAME <<< $(aws elbv2 create-load-balancer --name App-LB-$CI_COMMIT_SHORT_SHA --type application --subnets subnet-05349e5e055408210 subnet-06357c0e76a089427 | jq -r '.LoadBalancers[0] | "\(.LoadBalancerArn) \(.DNSName)"')

# create task definition
sed -i 's/<IMAGE_TAG>/'"$CI_COMMIT_SHORT_SHA"'/g' task-def.json
aws ecs register-task-definition --cli-input-json file://task-def.json

# add listener to lb: needs lb arn and target goup arn
aws elbv2 create-listener --load-balancer-arn $LOAD_BALANCER_ARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN

# create-service
aws ecs create-service \
    --cluster cluster-reddit \
    --service-name service-app-$CI_COMMIT_SHORT_SHA \
    --task-definition reddit_app:5 \
    --desired-count 1 \
    --role ecsServiceRole \
    --load-balancers targetGroupArn=$TARGET_GROUP_ARN,containerName=reddit,containerPort=9292

# create record set for Route53
sed -i 's/<URL>/'"$CI_COMMIT_SHORT_SHA.sablin.de"'/g' templ-r53.json
sed -i 's/<LOAD_BALANCER_NAME>/'"$DNS_NAME"'/g' templ-r53.json

aws route53 change-resource-record-sets --hosted-zone-id Z1ER99FRFTTS38 --change-batch file://templ-r53.json

