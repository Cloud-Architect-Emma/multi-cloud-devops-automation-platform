pipeline {
    agent any

    options {
        timestamps()
    }

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
                        bat 'terraform init'
                        bat 'terraform plan'
                    }
                }
            }
        }

        stage('Approval') {
            steps {
                input message: 'Approve Terraform Apply?', ok: 'Apply'
            }
        }

        stage('AWS Terraform Apply') {
            steps {
                withAWS(credentials: 'aws-terraform', region: 'us-east-1') {
                    dir('infrastructure-live/aws') {
                        bat 'terraform apply --auto-approve'
                    }
                }
            }
        }

        stage('Azure Terraform Apply') {
            steps {
                withCredentials([
                    file(credentialsId: 'azure-credentials.json', variable: 'AZURE_AUTH')
                ]) {
                    dir('infrastructure-live/azure') {
                        bat '''
                        for /f "tokens=2 delims=:," %%a in ('findstr clientId %AZURE_AUTH%') do set ARM_CLIENT_ID=%%~a
                        for /f "tokens=2 delims=:," %%a in ('findstr clientSecret %AZURE_AUTH%') do set ARM_CLIENT_SECRET=%%~a
                        for /f "tokens=2 delims=:," %%a in ('findstr subscriptionId %AZURE_AUTH%') do set ARM_SUBSCRIPTION_ID=%%~a
                        for /f "tokens=2 delims=:," %%a in ('findstr tenantId %AZURE_AUTH%') do set ARM_TENANT_ID=%%~a

                        terraform init
                        terraform apply --auto-approve
                        '''
                    }
                }
            }
        }

        stage('GCP Terraform Apply') {
            steps {
                withCredentials([
                    file(credentialsId: 'service-account', variable: 'GOOGLE_APPLICATION_CREDENTIALS')
                ]) {
                    dir('infrastructure-live/gcp') {
                        bat 'terraform init'
                        bat 'terraform apply --auto-approve'
                    }
                }
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed'
        }
        success {
            echo 'Multi-cloud deployment successful'
        }
    }
}
