#! /usr/bin/env bash

REGION=us-west-2
USER=mikakalathil
CLUSTER=elixir-services
SERVICE=elon-bot-service
DOCKER_IMAGE=elon_bot
ECR_URL=460318404978.dkr.ecr.us-west-2.amazonaws.com
ECR_REPO=$ECR_URL/$DOCKER_IMAGE

function active-tasks() {
  aws ecs list-tasks \
    --profile=$USER \
    --cluster=$CLUSTER \
    --region=$REGION \
  | pcregrep -Mo ": \[\K[^]]*" \
  | awk '{print $1}' \
  | sed '/^$/d' \
  | sed 's/,//' \
  | xargs -n1 \
  | sed -E 's/^.+task\/(.*)/\1/'
}

function stop-active-tasks() {
  ACTIVE_TASKS=$(active-tasks)
  echo "Killing active tasks $ACTIVE_TASKS..."
  IFS='
  '
  for TASK in $ACTIVE_TASKS
  do
    aws ecs stop-task \
      --profile=$USER \
      --cluster=$CLUSTER \
      --region=$REGION \
      --task=$TASK > /dev/null
  done
}

function update-service-with-new-deployment() {
  echo "Deploying $SERVICE in $REGION on $CLUSTER..."
  aws ecs update-service \
    --profile=$USER \
    --region=$REGION \
    --cluster=$CLUSTER \
    --service=$SERVICE \
    --force-new-deployment > /dev/null
  echo "Deployment ran"
}

function build-docker-image() {
  docker build -t $DOCKER_IMAGE -f Dockerfile . &&
  docker tag $DOCKER_IMAGE:latest $ECR_REPO:latest &&
  aws ecr get-login-password --region $REGION --profile $USER | docker login --username AWS --password-stdin $ECR_URL &&
  docker push $ECR_REPO:latest
}

build-docker-image && stop-active-tasks && update-service-with-new-deployment
