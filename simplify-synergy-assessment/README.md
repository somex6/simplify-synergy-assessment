# Simplify Technical Assessment 
## Introduction
This repository contains a Terraform project that provisions AWS virtual machine in a VPC and also an IAM user. It also contains a helm chart of a typical microservice called a web-app and the following describes steps taken in implementing the web-app helm deployment

## Requirements
- Helm client - Can be installed from CLI using the command: `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash`
- A kubernetes cluster connected to kubectl client

## Step By Step Process For Web-app Helm Deployment
1) Create New Github Repository: The repository where the web-app helm chart code will be stored is created and cloned using the command: `https://github.com/somex6/simplify-synergy-assessment.git`

2) Initialize a Helm Chart: After cloning the repository and cd into it, a basic Helm chart structure is generated by executing the following command: `helm create web-app`

3) Editing the Chart for the Web-App Service: 
- Navigating to web-app/templates folder and customize the Kubernetes Deployment, Service, Horizontal Pod Autoscaler, Ingress, Service Account configurations to suit the Web app configuration
- updating the web-app/values.yml file to allow customization of parameters

4) Debugging The Helm Chart: 
- To ensure the helm chart is configured correctly, this command is executed `helm template web-app . --debug`

5) Packaging and Pushing Helm Chart To AWS ECR:
- After a successful debugging, the following commands is run to package and push the helm chart to ECR:
  - Package the chart: `helm package web-app`
  - Authenticate Helm client to the Amazon ECR registry:
  `aws ecr get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com` 
  - Push the Helm chart: `helm push web-app-1.0.0.tgz oci://123456789.dkr.ecr.us-east-1.amazonaws.com`
  - Describe Helm chart: `aws ecr describe-images --repository-name web-app --region us-east-1`

6) Deploy Web-App Service Using Helm Chart Stored In AWS ECR:
- Authenticate to Amazon ECR: `aws ecr get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com`
- Install the web-app service: `helm install web-app oci://123456789.dkr.ecr.us-east-1.amazonaws.com/web-app --version 1.0.0`

7) Verify Deployment: 
- Running the following commands to verify web-app helm deployment: 
```
helm ls
kubectl get pods
kubectl get svc
```