pipeline {
    agent any

    environment {
        DOMAIN = 'nuocngavidai.duckdns.org'
    }

    stages {

        //------------- Checkout
        stage('Pull Code') {
            steps {
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

        //------------- Build
        stage('Build') {
            steps {
                sh '''
                    docker build -t paintco-backend ./backend
                    docker build -t paintco-frontend ./frontend
                '''
            }
        }

        //------------- Deploy
        stage('Deploy') {
            steps {
                sh '''
                    docker compose down --remove-orphans || true
                    docker compose up -d --build
                    docker compose ps
                '''
            }
        }

        //------------- Fix DB (SAFE VERSION)
        stage('Fix DB') {
            steps {
                sh '''
                    echo "Check DB connection..."
                    docker compose exec -T backend node -e "
                        const mysql = require('mysql2/promise');
                        (async () => {
                            try {
                                const conn = await mysql.createConnection({
                                    host: 'mysql',
                                    user: 'paintco',
                                    password: 'paintco123',
                                    database: 'paintco_db'
                                });
                                console.log('DB OK');
                                await conn.end();
                            } catch (e) {
                                console.error('DB FAIL', e.message);
                                process.exit(1);
                            }
                        })();
                    "
                '''
            }
        }

        //------------- Init SSL
        stage('Init SSL') {
            steps {
                sh '''
                    docker compose run --rm init-cert || true
                    docker compose exec -T nginx nginx -s reload || true
                '''
            }
        }

        //------------- Seed DB
        stage('Seed DB') {
            steps {
                sh '''
                    if [ ! -f ".seeded" ]; then
                        echo "Seeding..."
                        sleep 10

                        docker compose exec -T backend node dist/database/seed.js

                        if [ $? -ne 0 ]; then
                            echo "Seed FAILED"
                            exit 1
                        fi

                        touch .seeded
                    else
                        echo "Already seeded"
                    fi
                '''
            }
        }

        //------------- Health Check
        stage('Health Check') {
            steps {
                script {
                    sleep(10)

                    def status = sh(
                        script: "curl -sk -o /dev/null -w '%{http_code}' https://${DOMAIN}/api/v1/products || echo 000",
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