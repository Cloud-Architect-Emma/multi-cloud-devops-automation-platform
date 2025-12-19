pipeline {
    agent any
    environment {
        // GitHub token for checkout
        GITHUB_TOKEN = credentials('a9acd7c0-1c8a-4253-96f4-641ff8efea02')
    }
    options {
        timestamps()
        skipDefaultCheckout(true)
        timeout(time: 60, unit: 'MINUTES')
    }
    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: 'main']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [],
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
                        script {
                            try {
                                withCredentials([
                                    string(credentialsId: 'access-key', variable: 'AWS_ACCESS_KEY_ID'),
                                    string(credentialsId: 'secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                                ]) {
                                    dir('aws') {
                                        sh 'terraform init'
                                        sh 'terraform plan -out=tfplan'
                                    }
                                }
                            } catch (err) {
                                echo "AWS Terraform branch failed: ${err}"
                            }
                        }
                    }
                }

                stage('Azure Terraform') {
                    steps {
                        script {
                            try {
                                withCredentials([file(credentialsId: 'azure-credentials.json', variable: 'AZURE_CREDS')]) {
                                    dir('azure') {
                                        sh '''
                                        az login --service-principal --username $(jq -r .clientId < $AZURE_CREDS) \
                                        --password $(jq -r .clientSecret < $AZURE_CREDS) \
                                        --tenant $(jq -r .tenantId < $AZURE_CREDS)
                                        terraform init
                                        terraform plan -out=tfplan
                                        '''
                                    }
                                }
                            } catch (err) {
                                echo "Azure Terraform branch failed: ${err}"
                            }
                        }
                    }
                }

                stage('GCP Terraform') {
                    steps {
                        script {
                            try {
                                withCredentials([file(credentialsId: 'service-account.json', variable: 'GCP_CREDS')]) {
                                    dir('gcp') {
                                        sh 'gcloud auth activate-service-account --key-file=$GCP_CREDS'
                                        sh 'terraform init'
                                        sh 'terraform plan -out=tfplan'
                                    }
                                }
                            } catch (err) {
                                echo "GCP Terraform branch failed: ${err}"
                            }
                        }
                    }
                }
            }
        }

        stage('Terraform Apply') {
            parallel {
                stage('AWS Apply') {
                    steps {
                        script {
                            try {
                                withCredentials([
                                    string(credentialsId: 'access-key', variable: 'AWS_ACCESS_KEY_ID'),
                                    string(credentialsId: 'secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                                ]) {
                                    dir('aws') {
                                        sh 'terraform apply -auto-approve tfplan'
                                    }
                                }
                            } catch (err) {
                                echo "AWS Apply failed: ${err}"
                            }
                        }
                    }
                }

                stage('Azure Apply') {
                    steps {
                        script {
                            try {
                                withCredentials([file(credentialsId: 'azure-credentials.json', variable: 'AZURE_CREDS')]) {
                                    dir('azure') {
                                        sh 'terraform apply -auto-approve tfplan'
                                    }
                                }
                            } catch (err) {
                                echo "Azure Apply failed: ${err}"
                            }
                        }
                    }
                }

                stage('GCP Apply') {
                    steps {
                        script {
                            try {
                                withCredentials([file(credentialsId: 'service-account.json', variable: 'GCP_CREDS')]) {
                                    dir('gcp') {
                                        sh 'terraform apply -auto-approve tfplan'
                                    }
                                }
                            } catch (err) {
                                echo "GCP Apply failed: ${err}"
                            }
                        }
                    }
                }
            }
        }

        stage('Build, Scan & Push Docker Image') {
            steps {
                script {
                    try {
                        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                            sh '''
                            docker build -t emma2323/my-app:latest .
                            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                            docker push emma2323/my-app:latest
                            '''
                        }
                    } catch (err) {
                        echo "Docker build/push failed: ${err}"
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    try {
                        withCredentials([usernamePassword(credentialsId: 'sonarQube-token', usernameVariable: 'SONAR_USER', passwordVariable: 'SONAR_PASS')]) {
                            sh 'sonar-scanner -Dsonar.login=$SONAR_PASS'
                        }
                    } catch (err) {
                        echo "SonarQube analysis failed: ${err}"
                    }
                }
            }
        }

        stage('Deploy via ArgoCD') {
            steps {
                script {
                    try {
                        withCredentials([usernamePassword(credentialsId: 'AgroCD', usernameVariable: 'ARGO_USER', passwordVariable: 'ARGO_PASS')]) {
                            sh 'argocd login my-argocd-server --username $ARGO_USER --password $ARGO_PASS --insecure'
                            sh 'argocd app sync my-app'
                        }
                    } catch (err) {
                        echo "ArgoCD deployment failed: ${err}"
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished'
        }
        failure {
            echo 'Pipeline failed, check logs for errors'
        }
    }
}
