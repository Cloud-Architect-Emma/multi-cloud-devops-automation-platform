pipeline {
    agent any

    triggers {
        githubPush()
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        AWS_REGION = "us-east-1"
        IMAGE_NAME = "emma2323/multi-cloud-app"
        IMAGE_TAG  = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/Cloud-Architect-Emma/Cloud-Architect-Emma-multi-cloud-devops-automation-platform.git',
                        credentialsId: 'a9acd7c0-1c8a-4253-96f4-641ff8efea02'
                    ]]
                ])
            }
        }

        stage('Terraform Init & Plan') {
            parallel {

                stage('AWS Terraform') {
                    steps {
                        dir('infrastructure-live/aws') {
                            withAWS(credentials: 'aws-terraform', region: "${AWS_REGION}") {
                                bat 'terraform init'
                                bat 'terraform plan'
                            }
                        }
                    }
                }

                stage('Azure Terraform') {
                    steps {
                        dir('infrastructure-live/azure') {
                            withCredentials([file(
                                credentialsId: 'azure-credentials.json',
                                variable: 'ARM_AUTH_FILE'
                            )]) {
                                bat '''
                                set ARM_USE_MSI=false
                                set ARM_AUTH_FILE=%ARM_AUTH_FILE%
                                terraform init
                                terraform plan
                                '''
                            }
                        }
                    }
                }

                stage('GCP Terraform') {
                    steps {
                        dir('infrastructure-live/gcp') {
                            withCredentials([file(
                                credentialsId: 'service-account',
                                variable: 'GOOGLE_APPLICATION_CREDENTIALS'
                            )]) {
                                bat 'terraform init'
                                bat 'terraform plan'
                            }
                        }
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when { branch 'main' }
            parallel {

                stage('AWS Apply') {
                    steps {
                        dir('infrastructure-live/aws') {
                            withAWS(credentials: 'aws-terraform', region: "${AWS_REGION}") {
                                bat 'terraform apply -auto-approve'
                            }
                        }
                    }
                }

                stage('Azure Apply') {
                    steps {
                        dir('infrastructure-live/azure') {
                            withCredentials([file(
                                credentialsId: 'azure-credentials.json',
                                variable: 'ARM_AUTH_FILE'
                            )]) {
                                bat 'terraform apply -auto-approve'
                            }
                        }
                    }
                }

                stage('GCP Apply') {
                    steps {
                        dir('infrastructure-live/gcp') {
                            withCredentials([file(
                                credentialsId: 'service-account',
                                variable: 'GOOGLE_APPLICATION_CREDENTIALS'
                            )]) {
                                bat 'terraform apply -auto-approve'
                            }
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('app') {
                    bat 'docker build -t %IMAGE_NAME%:%IMAGE_TAG% .'
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                bat 'trivy image --severity HIGH,CRITICAL --exit-code 1 %IMAGE_NAME%:%IMAGE_TAG%'
            }
        }

        stage('Push Image to DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    bat '''
                    echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin
                    docker push %IMAGE_NAME%:%IMAGE_TAG%
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'sonarQube-token',
                    usernameVariable: 'SONAR_USER',
                    passwordVariable: 'SONAR_PASS'
                )]) {
                    bat '''
                    sonar-scanner ^
                      -Dsonar.login=%SONAR_USER% ^
                      -Dsonar.password=%SONAR_PASS%
                    '''
                }
            }
        }

        stage('Deploy via ArgoCD') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'AgroCD',
                    usernameVariable: 'ARGOCD_USERNAME',
                    passwordVariable: 'ARGOCD_PASSWORD'
                )]) {
                    bat '''
                    argocd login argocd.example.com ^
                      --username %ARGOCD_USERNAME% ^
                      --password %ARGOCD_PASSWORD% ^
                      --insecure

                    argocd app sync multi-cloud-app
                    '''
                }
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed — ArgoCD rollback recommended'
        }
        success {
            echo 'Pipeline completed successfully'
        }
    }
}
