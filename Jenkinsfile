pipeline {
    agent any

    triggers {
        githubPush()
    }

    options {
        timestamps()
    }

    environment {
        AWS_REGION = 'us-east-1'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init (AWS)') {
            steps {
                dir('infrastructure-live/aws') {
                    withAWS(credentials: 'aws-terraform', region: "${AWS_REGION}") {
                        bat 'terraform --version'
                        bat 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Plan (AWS)') {
            steps {
                dir('infrastructure-live/aws') {
                    withAWS(credentials: 'aws-terraform', region: "${AWS_REGION}") {
                        bat 'terraform plan'
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'AWS Terraform pipeline completed successfully'
        }
        failure {
            echo 'AWS Terraform pipeline failed'
        }
    }
}
