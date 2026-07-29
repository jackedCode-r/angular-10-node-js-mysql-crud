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

        stage('Create EKS Cluster') {
            steps {
                sh '''
                    if eksctl get cluster --name $CLUSTER_NAME --region $REGION 2>/dev/null; then
                        echo "Cluster already exists, skipping creation"
                    else
                        echo "Creating EKS Cluster..."
                        eksctl create cluster \
                            --name $CLUSTER_NAME \
                            --region $REGION \
                            --nodegroup-name mean-app-nodes \
                            --node-type t3.small \
                            --nodes 2 \
                            --nodes-min 1 \
                            --nodes-max 4 \
                            --managed
                    fi
                '''
            }
        }

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

        stage('Provision RDS') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'rds-db-creds',
                    usernameVariable: 'DB_USER',
                    passwordVariable: 'DB_PASS'
                )]) {
                    sh '''
                    if aws rds describe-db-instances --db-instance-identifier mean-app-db --region $REGION 2>/dev/null; then
                        echo "RDS instance already exists, skipping creation"
                    else
                        echo "Creating RDS instance..."
                        aws rds create-db-instance \
                            --db-instance-identifier mean-app-db \
                            --db-instance-class db.t3.micro \
                            --engine mysql \
                            --master-username $DB_USER \
                            --master-user-password $DB_PASS \
                            --allocated-storage 20 \
                            --backup-retention-period 1 \
                            --no-multi-az \
                            --publicly-accessible \
                            --region $REGION
                        aws rds wait db-instance-available --db-instance-identifier mean-app-db --region $REGION
                    fi
        
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

        stage('Deploy Ingress') {
            steps {
                sh '''
                kubectl apply -f deployment/ingress.yml -n $NAMESPACE
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
