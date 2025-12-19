pipeline {
    agent any

    triggers {
        githubPush()
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        ARGOCD_SERVER = 'https://argocd.example.com'
        DOCKER_IMAGE = "emma2323/multi-cloud-app:${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init & Plan') {
            parallel {

                stage('AWS Terraform') {
                    steps {
                        withCredentials([
                            string(credentialsId: 'access-key', variable: 'AWS_ACCESS_KEY_ID'),
                            string(credentialsId: 'secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                        ]) {
                            dir('infrastructure-live/aws') {
                                sh '''
                                  terraform init
                                  terraform validate
                                  terraform plan -out=tfplan
                                '''
                            }
                        }
                    }
                }

                stage('Azure Terraform') {
                    steps {
                        withCredentials([
                            file(credentialsId: 'azure-credentials.json', variable: 'AZURE_AUTH')
                        ]) {
                            dir('infrastructure-live/azure') {
                                sh '''
                                  export ARM_USE_MSI=false
                                  export ARM_CLIENT_ID=$(jq -r .clientId $AZURE_AUTH)
                                  export ARM_CLIENT_SECRET=$(jq -r .clientSecret $AZURE_AUTH)
                                  export ARM_SUBSCRIPTION_ID=$(jq -r .subscriptionId $AZURE_AUTH)
                                  export ARM_TENANT_ID=$(jq -r .tenantId $AZURE_AUTH)

                                  terraform init
                                  terraform validate
                                  terraform plan -out=tfplan
                                '''
                            }
                        }
                    }
                }

                stage('GCP Terraform') {
                    steps {
                        withCredentials([
                            file(credentialsId: 'service-account', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                        ]) {
                            dir('infrastructure-live/gcp') {
                                sh '''
                                  terraform init
                                  terraform validate
                                  terraform plan -out=tfplan
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                branch 'main'
            }
            parallel {

                stage('AWS Apply') {
                    steps {
                        dir('infrastructure-live/aws') {
                            sh 'terraform apply -auto-approve tfplan'
                        }
                    }
                }

                stage('Azure Apply') {
                    steps {
                        dir('infrastructure-live/azure') {
                            sh 'terraform apply -auto-approve tfplan'
                        }
                    }
                }

                stage('GCP Apply') {
                    steps {
                        dir('infrastructure-live/gcp') {
                            sh 'terraform apply -auto-approve tfplan'
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.withRegistry('', 'dockerhub') {
                        sh "docker build -t ${DOCKER_IMAGE} ."
                        sh "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh """
                  trivy image \
                  --severity CRITICAL,HIGH \
                  --exit-code 1 \
                  ${DOCKER_IMAGE}
                """
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'sonarQube-token',
                        usernameVariable: 'SONAR_USER',
                        passwordVariable: 'SONAR_TOKEN'
                    )
                ]) {
                    sh '''
                      sonar-scanner \
                      -Dsonar.login=$SONAR_TOKEN
                    '''
                }
            }
        }

        stage('Deploy via ArgoCD') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'AgroCD',
                        usernameVariable: 'ARGO_USER',
                        passwordVariable: 'ARGO_PASS'
                    )
                ]) {
                    sh '''
                      argocd login $ARGOCD_SERVER \
                        --username $ARGO_USER \
                        --password $ARGO_PASS \
                        --insecure

                      for cluster in aws azure gcp; do
                        argocd app sync app-$cluster --prune
                      done
                    '''
                }
            }
        }
    }

    post {
        failure {
            withCredentials([
                usernamePassword(
                    credentialsId: 'AgroCD',
                    usernameVariable: 'ARGO_USER',
                    passwordVariable: 'ARGO_PASS'
                )
            ]) {
                sh '''
                  argocd login $ARGOCD_SERVER \
                    --username $ARGO_USER \
                    --password $ARGO_PASS \
                    --insecure

                  for cluster in aws azure gcp; do
                    argocd app rollback app-$cluster
                  done
                '''
            }
        }
    }
}
