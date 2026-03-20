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
        skipDefaultCheckout(true)
    }

    triggers {
        githubPush()
    }

    stages {

        stage('Pull Code (Smart Update)') {
            steps {
                sh """
                    echo ">>> CHECK REPO"

                    # Nếu chưa có repo → clone
                    if [ ! -d "${APP_DIR}/.git" ]; then
                        echo ">>> CLONE LAN DAU"
                        mkdir -p ${APP_DIR}
                        git clone -b ${GIT_BRANCH} ${GIT_REPO} ${APP_DIR}
                    else
                        echo ">>> UPDATE CODE"
                        cd ${APP_DIR}

                        # reset sạch về repo
                        git fetch origin ${GIT_BRANCH}
                        git reset --hard origin/${GIT_BRANCH}

                        # xóa file rác (NHƯNG giữ .env và uploads)
                        git clean -fd \
                          -e .env.production \
                          -e uploads \
                          -e node_modules
                    fi

                    cd ${APP_DIR}
                    echo ">>> COMMIT HIEN TAI"
                    git log -1 --oneline
                """
            }
        }

        stage('Check .env') {
            steps {
                sh """
                    cd ${APP_DIR}

                    if [ ! -f ".env.production" ]; then
                        cp .env.production.example .env.production
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

                    echo ">>> START DOCKER COMPOSE"

                    docker compose \
                      --env-file .env.production \
                      up -d --build --remove-orphans

                    echo ">>> CONTAINERS STATUS"
                    docker compose ps
                """
            }
        }

        stage('Seed DB') {
            steps {
                sh """
                    cd ${APP_DIR}

                    if [ ! -f ".seeded" ]; then
                        echo "Seeding database..."
                        sleep 10

                        docker compose \
                          --env-file .env.production \
                          exec -T backend node dist/database/seed.js

                        touch .seeded
                        echo "Seed OK"
                    else
                        echo "Da seed roi, bo qua"
                    fi
                """
            }
        }

        stage('Health Check') {
            steps {
                script {
                    sleep(10)

                    def status = sh(
                        script: "curl -sk -o /dev/null -w '%{http_code}' https://${DOMAIN}/api/v1/products 2>/dev/null || echo 000",
                        returnStdout: true
                    ).trim()

                    echo "Health Check: HTTP ${status}"

                    if (status == '200') {
                        echo "✅ DEPLOY THANH CONG: https://${DOMAIN}"
                    } else {
                        sh "docker compose logs --tail=20 backend || true"
                        error("Health check failed")
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
            echo "✅ Build #${BUILD_NUMBER} OK → https://${DOMAIN}"
        }
        failure {
            sh "docker compose logs --tail=30 || true"
            echo "❌ Build #${BUILD_NUMBER} FAILED"
        }
    }
}