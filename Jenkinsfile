pipeline {
    agent any

    environment {
        DOCKER_HUB = "jackedcoder"
        BACKEND_IMAGE = "${DOCKER_HUB}/node-backend:latest"
        FRONTEND_IMAGE = "${DOCKER_HUB}/ang-frontend:latest"
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
                    sh 'docker compose build --no-cache'
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

        stage('Deploy MySQL Resources') {
            steps {
                sh '''
                kubectl apply -f deployment/mysql-secret.yml
                kubectl apply -f deployment/mysql-pvc.yml
                kubectl apply -f deployment/mysql-service.yml
                kubectl apply -f deployment/mysql-statefulset.yml
                '''
            }
        }

        stage('Deploy Backend') {
            steps {
                sh '''
                kubectl apply -f deployment/backend-deployment.yml
                kubectl apply -f deployment/backend-service.yml
                '''
            }
        }

        stage('Deploy Frontend') {
            steps {
                sh '''
                kubectl apply -f deployment/frontend-deployment.yml
                kubectl apply -f deployment/frontend-service.yml
                '''
            }
        }

        stage('Deploy Ingress') {
            steps {
                sh '''
                kubectl apply -f deployment/ingress.yml
                '''
            }
        }

        stage('Restart Deployments') {
            steps {
                sh '''
                kubectl rollout restart deployment backend-deployment -n mean-app
                kubectl rollout restart deployment frontend-deployment -n mean-app
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