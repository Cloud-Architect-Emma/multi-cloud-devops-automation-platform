pipeline {
    agent any

    triggers {
        githubPush()
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'a9acd7c0-1c8a-4253-96f4-641ff8efea02',
                    url: 'https://github.com/Cloud-Architect-Emma/Cloud-Architect-Emma-multi-cloud-devops-automation-platform.git'
            }
        }

        stage('Terragrunt Init & Plan (AWS Dev)') {
            steps {
                withAWS(credentials: 'aws-terraform', region: 'us-east-1') {
                    dir('infrastructure-live/aws/dev/us-east-1') {
                        bat 'terragrunt run-all init'
                        bat 'terragrunt run-all plan'
                    }
                }
            }
        }

        stage('Approval') {
            steps {
                input message: 'Apply AWS DEV infrastructure?'
            }
        }

        stage('Terragrunt Apply (AWS Dev)') {
            steps {
                withAWS(credentials: 'aws-terraform', region: 'us-east-1') {
                    dir('infrastructure-live/aws/dev/us-east-1') {
                        bat 'terragrunt run-all apply --auto-approve'
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'AWS DEV infrastructure deployed successfully via Terragrunt'
        }
        failure {
            echo 'Pipeline failed — no partial apply'
        }
    }
}
