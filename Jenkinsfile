pipeline {
    agent any

    environment {
        MYSQL_ROOT_PASSWORD = credentials('MYSQL_ROOT_PASSWORD')
        MYSQL_DATABASE      = credentials('MYSQL_DATABASE')
        MYSQL_USER          = credentials('MYSQL_USER')
        MYSQL_PASSWORD      = credentials('MYSQL_PASSWORD')
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Pulling latest code from GitHub..."
                checkout scm
            }
        }

        stage('Create .env') {
            steps {
                echo "Creating .env file from Jenkins credentials..."
                sh '''
                    cat > .env <<EOF
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE=${MYSQL_DATABASE}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
DB_HOST=db
DB_PORT=3306
DB_NAME=${MYSQL_DATABASE}
DB_USER=${MYSQL_USER}
DB_PASSWORD=${MYSQL_PASSWORD}
NODE_ENV=production
PORT=3000
EOF
                    echo ".env created successfully"
                '''
            }
        }

        stage('Stop Old Containers') {
            steps {
                echo "Bringing down old containers if running..."
                    sh 'docker compose --remove-orphans || true'
            }
        }
        
        stage('Build Docker Images') {
            steps {
                echo "Building frontend and backend images..."
                    sh 'docker compose build --no-cache'
            }
        }

        stage('Start Containers') {
            steps {
                echo "Starting all containers..."
                    sh 'docker compose up -d'
            }
        }

        stage('Verify Running') {
            steps {
                echo "Waiting for containers to stabilize..."
                    sh '''
                        echo "=== Container Status ==="
                        docker compose ps
                    '''
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful! App is live!"
        }
        failure {
            echo "❌ Deployment failed. Bringing containers down..."
                sh 'docker compose || true'
        }
        always {
            echo "Build #${env.BUILD_NUMBER} finished."
        }
    }
}
