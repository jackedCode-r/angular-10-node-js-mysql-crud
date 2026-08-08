pipeline {
    agent any

    environment {
        DOCKER_HUB = "jackedcoder"
        IMAGE_TAG = "${BUILD_NUMBER}"
        BACKEND_IMAGE = "${DOCKER_HUB}/node-backend:${IMAGE_TAG}"
        FRONTEND_IMAGE = "${DOCKER_HUB}/ang-frontend:${IMAGE_TAG}"
        CLUSTER_NAME = "mean-app-cluster"
        REGION = "ap-south-1"
        NAMESPACE = "mean-app"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Pulling latest code from GitHub..."
                checkout scm
            }
        }
        
        stage('Build Docker Images') {
            steps {
                echo "Building frontend and backend images..."
                    sh 'docker build -t $BACKEND_IMAGE ./node-js-server'
                    sh 'docker build -t $FRONTEND_IMAGE ./angular-10-client'
            }
        }

        stage('DockerHub Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {

                    sh '''
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    '''
                }
            }
        }

        stage('Push Backend Image') {
            steps {
                sh 'docker push $BACKEND_IMAGE'
            }
        }

        stage('Push Frontend Image') {
            steps {
                sh 'docker push $FRONTEND_IMAGE'
            }
        }

        // stage('Create EKS Cluster') {
        //     steps {
        //         sh '''
        //             if eksctl get cluster --name $CLUSTER_NAME --region $REGION 2>/dev/null; then
        //                 echo "Cluster already exists, skipping creation"
        //             else
        //                 echo "Creating EKS Cluster..."
        //                 eksctl create cluster \
        //                     --name $CLUSTER_NAME \
        //                     --region $REGION \
        //                     --nodegroup-name mean-app-nodes \
        //                     --node-type t3.small \
        //                     --nodes 2 \
        //                     --nodes-min 1 \
        //                     --nodes-max 4 \
        //                     --managed
        //             fi
        //         '''
        //     }
        // }

        stage('Configure kubectl') {
            steps {
                sh 'aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME'
            }
        }

        stage('Create Namespace') {
            steps {
                sh '''
                    if kubectl get namespace $NAMESPACE 2>/dev/null; then
                        echo "Namespace already exists, skipping"
                    else
                        kubectl create namespace $NAMESPACE
                    fi
                '''
            }
        }

        stage('Update Kubernetes Manifests') {
            steps {
                sh '''
                sed -i "s|IMAGE_TAG|${BUILD_NUMBER}|g" deployment/backend-deployment.yml
                sed -i "s|IMAGE_TAG|${BUILD_NUMBER}|g" deployment/frontend-deployment.yml
                '''
            }
        }

        // stage('Install ALB Controller') {
        //     steps {
        //         sh '''
        //         eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --region $REGION --approve
        
        //         if aws iam get-policy --policy-arn arn:aws:iam::766691179872:policy/AWSLoadBalancerControllerIAMPolicy 2>/dev/null; then
        //             echo "IAM policy already exists, skipping creation"
        //         else
        //             curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json
        //             aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json
        //         fi
        
        //         eksctl create iamserviceaccount \
        //             --cluster=$CLUSTER_NAME \
        //             --namespace=kube-system \
        //             --name=aws-load-balancer-controller \
        //             --region $REGION \
        //             --attach-policy-arn=arn:aws:iam::766691179872:policy/AWSLoadBalancerControllerIAMPolicy \
        //             --override-existing-serviceaccounts \
        //             --approve
        
        //         cat <<EOF > extra-permissions.json
        //         {
        //           "Version": "2012-10-17",
        //           "Statement": [
        //             {
        //               "Effect": "Allow",
        //               "Action": ["elasticloadbalancing:DescribeListenerAttributes"],
        //               "Resource": "*"
        //             }
        //           ]
        //         }
        //         EOF
        
        //         ROLE_NAME=$(aws iam list-roles --query "Roles[?contains(RoleName, 'addon-iamserviceaccou')].RoleName" --output text)
        //         aws iam put-role-policy --role-name $ROLE_NAME --policy-name ALBExtraPermissions --policy-document file://extra-permissions.json
        
        //         if ! command -v helm &> /dev/null; then
        //             curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        //         fi
        
        //         helm repo add eks https://aws.github.io/eks-charts
        //         helm repo update
        
        //         VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)
        
        //         if helm status aws-load-balancer-controller -n kube-system 2>/dev/null; then
        //             echo "ALB controller already installed, skipping"
        //         else
        //             helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
        //                 -n kube-system \
        //                 --set clusterName=$CLUSTER_NAME \
        //                 --set serviceAccount.create=false \
        //                 --set serviceAccount.name=aws-load-balancer-controller \
        //                 --set region=$REGION \
        //                 --set vpcId=$VPC_ID
        //         fi
        
        //         kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=180s
        //         '''
        //     }
        // }

        stage('Create RDS Secret') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'rds-db-creds',
                    usernameVariable: 'DB_USER',
                    passwordVariable: 'DB_PASS'
                )]) {
                    sh '''
                    DB_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier mean-app-db --region $REGION --query "DBInstances[0].Endpoint.Address" --output text)

                    kubectl delete secret rds-secret -n $NAMESPACE --ignore-not-found
                    kubectl create secret generic rds-secret \
                        --from-literal=DB_HOST=$DB_ENDPOINT \
                        --from-literal=DB_USER=$DB_USER \
                        --from-literal=DB_PASSWORD=$DB_PASS \
                        --from-literal=DB_NAME=meanapp \
                        -n $NAMESPACE
                    '''
                }
            }
        }

        // stage('Provision RDS') {
        //     steps {
        //         withCredentials([usernamePassword(
        //             credentialsId: 'rds-db-creds',
        //             usernameVariable: 'DB_USER',
        //             passwordVariable: 'DB_PASS'
        //         )]) {
        //             sh '''
        //             if aws rds describe-db-instances --db-instance-identifier mean-app-db --region $REGION 2>/dev/null; then
        //                 echo "RDS instance already exists, skipping creation"
        //             else
        //                 echo "Creating RDS instance..."
        //                 aws rds create-db-instance \
        //                     --db-instance-identifier mean-app-db \
        //                     --db-instance-class db.t3.micro \
        //                     --engine mysql \
        //                     --master-username $DB_USER \
        //                     --master-user-password $DB_PASS \
        //                     --allocated-storage 20 \
        //                     --backup-retention-period 1 \
        //                     --no-multi-az \
        //                     --publicly-accessible \
        //                     --region $REGION
        //                 aws rds wait db-instance-available --db-instance-identifier mean-app-db --region $REGION
        //             fi
        
        //             DB_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier mean-app-db --region $REGION --query "DBInstances[0].Endpoint.Address" --output text)
        
        //             kubectl delete secret rds-secret -n $NAMESPACE --ignore-not-found
        //             kubectl create secret generic rds-secret \
        //                 --from-literal=DB_HOST=$DB_ENDPOINT \
        //                 --from-literal=DB_USER=$DB_USER \
        //                 --from-literal=DB_PASSWORD=$DB_PASS \
        //                 --from-literal=DB_NAME=meanapp \
        //                 -n $NAMESPACE
        //             '''
        //         }
        //     }
        // }

        stage('Deploy Backend') {
            steps {
                sh '''
                kubectl apply -f deployment/backend-deployment.yml -n $NAMESPACE
                kubectl apply -f deployment/backend-service.yml -n $NAMESPACE
                kubectl rollout status deployment/backend-deployment -n $NAMESPACE --timeout=300s
                '''
            }
        }

        stage('Deploy Frontend') {
            steps {
                sh '''
                kubectl apply -f deployment/frontend-deployment.yml -n $NAMESPACE
                kubectl apply -f deployment/frontend-service.yml -n $NAMESPACE
                kubectl rollout status deployment/frontend-deployment -n $NAMESPACE --timeout=300s
                '''
            }
        }

stage('Deploy ALB Controller') {
    steps {
        sh '''
ALB_ROLE_ARN="arn:aws:iam::766691179872:role/eks-alb-controller-role"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: ${ALB_ROLE_ARN}
EOF

helm repo add eks https://aws.github.io/eks-charts
helm repo update

VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)

if helm status aws-load-balancer-controller -n kube-system 2>/dev/null; then
    echo "ALB controller already installed, skipping"
else
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=$CLUSTER_NAME \
        --set serviceAccount.create=false \
        --set serviceAccount.name=aws-load-balancer-controller \
        --set region=$REGION \
        --set vpcId=$VPC_ID
fi

kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=180s
'''
    }
}

        stage('Deploy Ingress') {
            steps {
                sh '''
                kubectl apply -f deployment/ingress.yml -n $NAMESPACE
                '''
            }
        }

        stage('Get ALB URL') {
            steps {
                sh '''
                echo "Waiting for ALB to be provisioned..."
                for i in $(seq 1 20); do
                    ALB_DNS=$(kubectl get ingress mean-app-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
                    if [ -n "$ALB_DNS" ]; then
                        echo "Your app is live at: http://$ALB_DNS"
                        break
                    fi
                    echo "ALB not ready yet, retrying in 15s..."
                    sleep 15
                done
                '''
            }
        }

        stage('Restart Deployments') {
            steps {
                sh '''
                kubectl rollout restart deployment/backend-deployment -n $NAMESPACE
                kubectl rollout restart deployment/frontend-deployment -n $NAMESPACE
                '''
            }
        }

    }

    post {
        success {
            echo 'Pipeline executed successfully!'
        }

        failure {
            echo 'Pipeline failed!'
        }
    }
}
