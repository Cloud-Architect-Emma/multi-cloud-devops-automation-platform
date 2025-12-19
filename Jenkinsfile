pipeline {
    agent {
        docker {
            image 'hashicorp/terraform:latest'  // Use Docker for Terraform; ensures it's available
            args '-u root'  // Run as root if needed for permissions
        }
    }

    environment {
        // Global env vars if needed
        TF_VERSION = '1.5.0'
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
                        sh 'terraform init'
                        sh 'terraform validate'  // Added: Check syntax
                        sh 'terraform plan -out=tfplan'  // Added: Generate plan file
                    }
                }
            }
        }

        stage('AWS Terraform Apply') {
            steps {
                withAWS(credentials: 'aws-terraform', region: 'us-east-1') {
                    dir('infrastructure-live/aws') {
                        sh 'terraform apply -auto-approve tfplan'  // Use plan file for safety
                    }
                }
            }
        }

        stage('Azure Terraform Init & Plan') {
            steps {
                withCredentials([
                    file(credentialsId: 'azure-credentials.json', variable: 'AZURE_CRED_FILE')
                ]) {
                    dir('infrastructure-live/azure') {
                        // Set Azure env vars from the JSON file (assuming it's a service principal JSON)
                        sh '''
                            export ARM_CLIENT_ID=$(jq -r .clientId $AZURE_CRED_FILE)
                            export ARM_CLIENT_SECRET=$(jq -r .clientSecret $AZURE_CRED_FILE)
                            export ARM_SUBSCRIPTION_ID=$(jq -r .subscriptionId $AZURE_CRED_FILE)
                            export ARM_TENANT_ID=$(jq -r .tenantId $AZURE_CRED_FILE)
                            terraform init
                            terraform validate
                            terraform plan -out=tfplan
                        '''
                    }
                }
            }
        }

        stage('Azure Terraform Apply') {
            steps {
                withCredentials([
                    file(credentialsId: 'azure-credentials.json', variable: 'AZURE_CRED_FILE')
                ]) {
                    dir('infrastructure-live/azure') {
                        sh '''
                            export ARM_CLIENT_ID=$(jq -r .clientId $AZURE_CRED_FILE)
                            export ARM_CLIENT_SECRET=$(jq -r .clientSecret $AZURE_CRED_FILE)
                            export ARM_SUBSCRIPTION_ID=$(jq -r .subscriptionId $AZURE_CRED_FILE)
                            export ARM_TENANT_ID=$(jq -r .tenantId $AZURE_CRED_FILE)
                            terraform apply -auto-approve tfplan
                        '''
                    }
                }
            }
        }

        stage('GCP Terraform Init & Plan') {
            steps {
                withCredentials([
                    file(credentialsId: 'service-account', variable: 'GOOGLE_CREDENTIALS')
                ]) {
                    dir('infrastructure-live/gcp') {
                        sh '''
                            export GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_CREDENTIALS
                            terraform init
                            terraform validate
                            terraform plan -out=tfplan
                        '''
                    }
                }
            }
        }

        stage('GCP Terraform Apply') {
            steps {
                withCredentials([
                    file(credentialsId: 'service-account', variable: 'GOOGLE_CREDENTIALS')
                ]) {
                    dir('infrastructure-live/gcp') {
                        sh '''
                            export GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_CREDENTIALS
                            terraform apply -auto-approve tfplan
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            // Archive state files for debugging
            archiveArtifacts artifacts: '**/*.tfstate, **/tfplan', allowEmptyArchive: true
        }
        failure {
            // Optional: Notify or rollback (e.g., send email or Slack)
            echo 'Pipeline failed. Check logs and consider manual rollback.'
        }
        success {
            echo 'Infrastructure deployed successfully!'
        }
    }
}