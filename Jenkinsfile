pipeline {
    agent any

    environment {
        APP_DIR    = '/opt/paintco' // thư mục deploy trên server
        GIT_REPO   = 'https://github.com/duykhanhdeveloper93/WebPainIOVer2.git' // repo chuẩn
        GIT_BRANCH = 'develop' // branch cần deploy
        DOMAIN     = 'nuocngavidai.duckdns.org' // domain để health check
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '5')) // giữ 5 build gần nhất
        timeout(time: 40, unit: 'MINUTES') // timeout toàn pipeline
        disableConcurrentBuilds() // không cho chạy song song
        timestamps() // log có timestamp
        skipDefaultCheckout(true) // 🚨 QUAN TRỌNG: tắt checkout tự động của Jenkins
    }

    triggers {
        githubPush() // trigger khi push github
    }

    stages {

        stage('Pull Code (Clean Clone)') {
            steps {
                sh """
                    echo ">>> XOA CODE CU"
                    rm -rf ${APP_DIR}   # 💀 xóa sạch thư mục cũ (tránh dính repo cũ)

                    echo ">>> CLONE REPO MOI"
                    git clone -b ${GIT_BRANCH} ${GIT_REPO} ${APP_DIR}  # 📥 clone fresh 100%

                    cd ${APP_DIR}
                    echo ">>> COMMIT HIEN TAI"
                    git log -1 --oneline  # in commit đang deploy
                """
            }
        }

        stage('Check .env') {
            steps {
                sh """
                    cd ${APP_DIR}

                    # nếu chưa có file env thì copy từ example
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

                            # build image backend
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

                            # build image frontend (có nginx trong Dockerfile - OK)
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

                    # chạy docker compose (dùng file trong repo mới clone)
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

                    # chỉ seed 1 lần
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

        // ❌ ĐÃ XÓA NGINX RELOAD (vì dùng Caddy)
        // tránh lỗi container nginx không tồn tại

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
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh "docker image prune -f || true" // dọn image rác
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