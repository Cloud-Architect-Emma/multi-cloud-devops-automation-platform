pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', 
                    credentialsId: 'a9acd7c0-1c8a-4253-96f4-641ff8efea02', 
                    url: 'https://github.com/Cloud-Architect-Emma/Cloud-Architect-Emma-multi-cloud-devops-automation-platform.git'
            }
        }

        stage('AWS Terraform Init & Plan') {
            steps {
                withAWS(credentials: 'aws-terraform', region: 'us-east-1') {
                    dir('infrastructure-live/aws') {
                        sh 'terraform init'
                        sh 'terraform plan'
                    }
                }
            }
        }

        stage('AWS Terraform Apply') {
            steps {
                withAWS(credentials: 'aws-terraform', region: 'us-east-1') {
                    dir('infrastructure-live/aws') {
                        sh 'terraform apply --auto-approve'
                    }
                }
            }
        }

        stage('Azure Terraform Init & Apply') {
            steps {
                withCredentials([
                    file(credentialsId: 'azure-credentials.json', variable: 'AZURE_CRED_FILE')
                ]) {
                    dir('infrastructure-live/azure') {
                        sh 'terraform init'
                        sh 'terraform apply --auto-approve'
                    }
                }
            }
        }

        stage('GCP Terraform Init & Apply') {
            steps {
                withCredentials([
                    file(credentialsId: 'service-account', variable: 'GOOGLE_CREDENTIALS')
                ]) {
                    dir('infrastructure-live/gcp') {
                        sh 'terraform init'
                        sh 'terraform apply --auto-approve'
                    }
                }
            }
        }
    }
}
