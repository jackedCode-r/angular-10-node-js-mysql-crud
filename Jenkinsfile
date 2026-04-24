pipeline {
    agent any

    environment {
        APP_NAME        = "my-project"
        FRONTEND_IMAGE  = "angular_frontend"
        BACKEND_IMAGE   = "node_backend"

        // Injected from Jenkins credentials (never hardcoded)
        MYSQL_ROOT_PASSWORD = credentials('MYSQL_ROOT_PASSWORD')
        MYSQL_PASSWORD      = credentials('MYSQL_PASSWORD')
        MYSQL_USER          = credentials('MYSQL_USER')
        MYSQL_DATABASE      = credentials('MYSQL_DATABASE')
    }

    options {
        // Keep only last 5 builds to save disk space
        buildDiscarder(logRotator(numToKeepStr: '5'))
        // Fail if pipeline runs more than 20 mins
        timeout(time: 20, unit: 'MINUTES')
        // Don't run same pipeline in parallel
        disableConcurrentBuilds()
    }

    stages {

        // ─────────────────────────────────────────
        stage('Checkout') {
        // ─────────────────────────────────────────
            steps {
                echo "Checking out code from GitHub..."
                checkout scm
            }
        }

        // ─────────────────────────────────────────
        stage('Verify Tools') {
        // ─────────────────────────────────────────
            steps {
                sh '''
                    echo "=== Verifying installed tools ==="
                    docker --version
                    docker-compose --version
                    git --version
                '''
            }
        }

        // ─────────────────────────────────────────
        stage('Create .env File') {
        // ─────────────────────────────────────────
            steps {
                echo "Generating .env file from Jenkins credentials..."
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
                    echo ".env file created successfully"
                '''
            }
        }

        // ─────────────────────────────────────────
        stage('Build Docker Images') {
        // ─────────────────────────────────────────
            steps {
                echo "Building Docker images..."
                sh '''
                    docker-compose build --no-cache
                '''
            }
        }

        // ─────────────────────────────────────────
        stage('Stop Old Containers') {
        // ─────────────────────────────────────────
            steps {
                echo "Stopping and removing old containers..."
                sh '''
                    docker-compose down --remove-orphans || true
                '''
            }
        }

        // ─────────────────────────────────────────
        stage('Run New Containers') {
        // ─────────────────────────────────────────
            steps {
                echo "Starting all containers..."
                sh '''
                    docker-compose up -d
                '''
            }
        }

        // ─────────────────────────────────────────
        stage('Health Check') {
        // ─────────────────────────────────────────
            steps {
                echo "Waiting for services to be ready..."
                sh '''
                    sleep 20

                    echo "=== Checking running containers ==="
                    docker-compose ps

                    echo "=== Checking frontend ==="
                    curl -f http://localhost:80 || exit 1

                    echo "=== Checking backend ==="
                    curl -f http://localhost:3000/health || exit 1

                    echo "All services are healthy!"
                '''
            }
        }

        // ─────────────────────────────────────────
        stage('Cleanup') {
        // ─────────────────────────────────────────
            steps {
                echo "Cleaning up unused Docker resources..."
                sh '''
                    docker image prune -f
                    docker volume prune -f
                '''
            }
        }
    }

    // ─────────────────────────────────────────
    post {
    // ─────────────────────────────────────────
        success {
            echo """
            ✅ DEPLOYMENT SUCCESSFUL
            App is live at: http://${env.EC2_PUBLIC_IP}
            Build: #${env.BUILD_NUMBER}
            Branch: ${env.GIT_BRANCH}
            """
        }
        failure {
            echo """
            ❌ DEPLOYMENT FAILED
            Build: #${env.BUILD_NUMBER}
            Check logs above for errors.
            """
            // Optionally rollback
            sh 'docker-compose down || true'
        }
        always {
            // Clean workspace after every build
            cleanWs()
        }
    }
}
