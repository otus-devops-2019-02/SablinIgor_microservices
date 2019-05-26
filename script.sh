#!/usr/bin/env bash

aws configure set region eu-west-3

apt-get install jq

#eval TARGET_GROUP_ARN=$(aws elbv2 create-target-group --name Test-tg-commit3 --protocol HTTP --port 80 --vpc-id vpc-060e5cc464cd74d72 | jq -c '.TargetGroups[0].TargetGroupArn')

# create load balancer: get LOAD_BALANCER_ARN and DNS_NAME
#read LOAD_BALANCER_ARN DNS_NAME <<< $(aws elbv2 create-load-balancer --name App-LB-Balancer-commit3 --type application --subnets subnet-05349e5e055408210 subnet-06357c0e76a089427 | jq -r '.LoadBalancers[0] | "\(.LoadBalancerArn) \(.DNSName)"')

# add listener to lb: needs lb arn and target goup arn
#aws elbv2 create-listener --load-balancer-arn $LOAD_BALANCER_ARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN

# create-service
#aws ecs create-service \
#    --cluster cluster-reddit \
#    --service-name service-app-commit3 \
#    --task-definition reddit_app:5 \
#    --desired-count 1 \
#    --role ecsServiceRole \
#    --load-balancers targetGroupArn=$TARGET_GROUP_ARN,containerName=reddit,containerPort=9292

# create record set for Route53
#aws route53 change-resource-record-sets --hosted-zone-id Z1ER99FRFTTS38 --change-batch file://sample-r53.json
