pipeline {
    agent any

    triggers {
        githubPush()
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

        stage('Build & Deploy') {
            steps {
                sh '''
                    docker compose down --remove-orphans || true
                    docker compose up -d --build
                    docker compose ps
                '''
            }
        }

        stage('Seed DB') {
            steps {
                sh '''
                    if [ ! -f ".seeded" ]; then
                        echo "Seeding DB..."
                        sleep 10

                        docker compose exec -T backend node dist/database/seed.js || exit 1

                        touch .seeded
                    else
                        echo "Already seeded"
                    fi
                '''
            }
        }

        stage('Health Check') {
            steps {
                script {
                    sleep(10)

                    def status = sh(
                        script: "curl -sk -o /dev/null -w '%{http_code}' https://nuocngavidai.duckdns.org/api/v1/products || echo 000",
                        returnStdout: true
                    ).trim()

                    echo "Health: ${status}"

                    if (status != '200') {
                        sh "docker compose logs --tail=50 backend || true"
                        error("Deploy failed")
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ DEPLOY OK"
        }
        failure {
            echo "❌ DEPLOY FAIL"
        }
    }
}