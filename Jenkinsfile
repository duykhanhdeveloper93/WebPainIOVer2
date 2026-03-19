pipeline {
    agent any

    environment {
        APP_DIR    = '/opt/paintco'
        GIT_REPO   = 'https://github.com/duykhanhdeveloper93/WebPainIOVer2.git'
        GIT_BRANCH = 'develop'
        DOMAIN     = 'nuocngavidai.duckdns.org'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
        timeout(time: 40, unit: 'MINUTES')
        disableConcurrentBuilds()
        timestamps()
    }

    triggers {
        githubPush()
    }

    stages {

        stage('Pull Code') {
            steps {
                sh """
                    if [ -d "${APP_DIR}/.git" ]; then
                        cd ${APP_DIR}
                        git fetch origin ${GIT_BRANCH}
                        git reset --hard origin/${GIT_BRANCH}
                    else
                        git clone -b ${GIT_BRANCH} ${GIT_REPO} ${APP_DIR}
                    fi
                    cd ${APP_DIR} && git log -1 --oneline
                """
            }
        }

        stage('Check .env') {
            steps {
                sh """
                    if [ ! -f "${APP_DIR}/.env.production" ]; then
                        cp ${APP_DIR}/.env.production.example ${APP_DIR}/.env.production
                        echo "WARN: Tao .env.production tu example - can kiem tra lai!"
                    fi
                    echo "ENV: OK"
                """
            }
        }

        stage('Build Images') {
            parallel {
                stage('Backend') {
                    steps {
                        sh """
                            cd ${APP_DIR}
                            docker build \
                              -t paintco-backend:${BUILD_NUMBER} \
                              -t paintco-backend:latest \
                              --cache-from paintco-backend:latest \
                              ./backend/
                        """
                    }
                }
                stage('Frontend') {
                    steps {
                        sh """
                            cd ${APP_DIR}
                            docker build \
                              -t paintco-frontend:${BUILD_NUMBER} \
                              -t paintco-frontend:latest \
                              --cache-from paintco-frontend:latest \
                              ./frontend/
                        """
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                sh """
                    cd ${APP_DIR}

                    # Check https.conf ton tai chua (da co cert chua)
                    if [ -f "${APP_DIR}/nginx/conf.d/https.conf" ]; then
                        echo "HTTPS mode"
                    else
                        echo "HTTP mode (chua co SSL cert)"
                    fi

                    docker compose \
                      --env-file ${APP_DIR}/.env.production \
                      up -d --build --remove-orphans

                    echo "Containers started"
                    docker compose ps
                """
            }
        }

        stage('Seed DB') {
            steps {
                sh """
                    if [ ! -f "${APP_DIR}/.seeded" ]; then
                        echo "Seeding database..."
                        sleep 25
                        docker compose \
                          --env-file ${APP_DIR}/.env.production \
                          exec -T backend node dist/database/seed.js
                        touch ${APP_DIR}/.seeded
                        echo "Seed OK"
                    else
                        echo "Da seed roi, bo qua"
                    fi
                """
            }
        }

        stage('Reload Nginx') {
            steps {
                sh """
                    docker compose exec -T nginx nginx -s reload 2>/dev/null \
                      && echo "Nginx reloaded" \
                      || echo "Nginx chua chay hoac khong can reload"
                """
            }
        }

        stage('Health Check') {
            steps {
                script {
                    sleep(10)
                    def status = sh(
                        script: "curl -sk -o /dev/null -w '%{http_code}' https://${DOMAIN}/api/v1/products 2>/dev/null || curl -s -o /dev/null -w '%{http_code}' http://localhost/api/v1/products 2>/dev/null || echo 000",
                        returnStdout: true
                    ).trim()
                    echo "Health Check: HTTP ${status}"
                    if (status == '200') {
                        echo "✅ DEPLOY THANH CONG: https://${DOMAIN}"
                    } else {
                        sh "docker compose logs --tail=20 backend || true"
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh "docker image prune -f || true"
            }
        }
    }

    post {
        success {
            echo "✅ Build #${BUILD_NUMBER} OK → https://nuocngavidai.duckdns.org"
        }
        failure {
            sh "docker compose logs --tail=30 || true"
            echo "❌ Build #${BUILD_NUMBER} FAILED"
        }
    }
}
