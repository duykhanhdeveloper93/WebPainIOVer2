pipeline {
    agent any

    environment {
        APP_DIR = '/opt/paintco'
        GIT_REPO = 'https://github.com/duykhanhdeveloper93/WebPainIOVer2.git'
        GIT_BRANCH = 'develop'
        DOMAIN = 'nuocngavidai.duckdns.org'
    }

    stages {

        stage('Pull Code') {
            steps {
                sh """
                    if [ ! -d "${APP_DIR}/.git" ]; then
                        git clone -b ${GIT_BRANCH} ${GIT_REPO} ${APP_DIR}
                    else
                        cd ${APP_DIR}
                        git fetch origin ${GIT_BRANCH}
                        git reset --hard origin/${GIT_BRANCH}
                    fi
                """
            }
        }

        stage('Build') {
            steps {
                sh """
                    cd ${APP_DIR}
                    docker build -t paintco-backend ./backend
                    docker build -t paintco-frontend ./frontend
                """
            }
        }

        stage('Deploy') {
            steps {
                sh """
                    cd ${APP_DIR}
                    docker compose up -d --build --remove-orphans
                """
            }
        }

        stage('Fix DB') {
            steps {
                sh """
                    docker exec -i paintco_mysql mysql -uroot -prootpass2024 <<EOF
                    ALTER USER 'paintco'@'%' IDENTIFIED BY 'paintco123';
                    FLUSH PRIVILEGES;
EOF
                """
            }
        }

        stage('Init SSL') {
            steps {
                sh """
                    cd ${APP_DIR}
                    docker compose run --rm init-cert || true
                    docker exec paintco_nginx nginx -s reload || true
                """
            }
        }

        stage('Seed DB') {
            steps {
                sh """
                    cd ${APP_DIR}

                    if [ ! -f ".seeded" ]; then
                        sleep 10
                        docker compose exec -T backend node dist/database/seed.js

                        if [ $? -ne 0 ]; then
                            echo "Seed FAILED"
                            exit 1
                        fi

                        touch .seeded
                    fi
                """
            }
        }

        stage('Health Check') {
            steps {
                script {
                    sleep(10)
                    def status = sh(
                        script: "curl -sk -o /dev/null -w '%{http_code}' https://${DOMAIN}/api/v1/products || echo 000",
                        returnStdout: true
                    ).trim()

                    if (status != '200') {
                        sh "docker compose logs --tail=20 backend || true"
                        error("Deploy failed")
                    }
                }
            }
        }
    }
}