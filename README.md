# Irysan Test

## Folders:
- irysan-terraform-aws: Deploy only the stack to use the service in ECS, we will see 3 folders:
* bootstrap: Basic stack for terraform (role, dynamodb, s3 for states)
* deployments: cloud stack with the environments folders, in this directory we could have different clouds / environments to deploy the stacks using modules
* modules: modules for terraform

- k8s: The manifests to deploy on kubernetes
- tests: python test folders
- gitlab-ci-templates: scripts for the gitlab pipeline, to use in each step as we need it. We could have this folder as a repository and include in each pipeline.

## How use
1. The first apply must be the boostrap, to create the basic infrastructure for terraform. We will define the VPC cidr, tags, global variables and we will create the dynamodb and s3 for the states in case that we don't use the terraform cloud and the role with admin permissions in aws.
2. We could create the resources in the deployments directory, in this case I created a folders for the vpc, an alb to expose the ecs service and the service that I want to deploy / create the stack.
3. We could run the pipeline in gitlab


## Gitlab pipeline
The pipeline gitlab-ci.yml is including the scripts with a reference for the steps, the idea is to have something modular, flexible to reuse the scripts in the pipeline steps.

