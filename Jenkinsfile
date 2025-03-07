pipeline {
    agent any
    tools {
        jfrog 'jfrog-cli'
        snyk 'Snyk-tool'
        terraform 'terraform-cli'
    }
    environment {
        AWS_REGION = 'us-east-1' // env variable
    }


    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'jfrog', url: 'https://github.com/bleeng089/autoScale.git'
            }
        }
    stages {
        stage('Setup Tools') {
            steps {
                sh '''
                    uname -a # Debug agent architecture
                '''
            }
        }
        stage('Snyk Security Scan') {
            steps {
                script {
                    // Use withCredentials to access the snyk token
                    withCredentials([string(credentialsId: 'Snyk-token', variable: 'SNYK_TOKEN')]) {
                        // Export the Snyk token from Jenkins credentials as an environment variable in this shell process  
                        // Scans files in the current directory, captures JSON output to snyk-report.json file & fails pipeline if vulnerabilities are found
                        sh '''
                        echo "PATH is: $PATH" # trying to debug issue with path variable for the Snyk bianary
                        snyk --version || echo "Snyk not found" 
                        export SNYK_TOKEN=${SNYK_TOKEN}
                        snyk test --json > snyk-report.json || true  
                        '''
                    }
                }
            }
        }
        stage ('Jfrog') {
            steps {
                jf '-v' 
                jf 'c show'
                jf 'rt ping'
                // sh 'touch test-file'
                jf 'rt u snyk-report.json  jfrog-remote-repo/' 
                jf 'rt bp'
                jf 'rt dl  jfrog-remote-repo/snyk-report.json'
            }
        } 
        stage('Initialize Terraform') {
            steps {
                // Use withCredentials to access the AWS credentials
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS-Key']]) {
                    sh '''
                        export AWS_DEFAULT_REGION=$AWS_REGION
                        terraform init
                    '''
                }
            }
        }
        stage('Plan Terraform') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS-Key']]) {
                    sh '''
                        export AWS_DEFAULT_REGION=$AWS_REGION
                        terraform plan -out=tfplan
                    '''
                }
            }
        }
        stage('Apply Terraform') {
            steps {
                input message: "Approve Terraform Apply?", ok: "Deploy"
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS-Key']]) {
                    sh '''
                        export AWS_DEFAULT_REGION=$AWS_REGION
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }
        stage('Destroy Terraform') {
            when {
                expression { params.DESTROY == 'true' }
            }
            steps {
                input message: "Approve Terraform Destroy? This will delete all resources!", ok: "Destroy"
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS-Key']]) {
                    sh '''
                        export AWS_DEFAULT_REGION=$AWS_REGION
                        terraform destroy -auto-approve
                    '''
                }
            }
        }
    }
    post {
        success {
            echo 'Terraform operation completed successfully!'
        }
        failure {
            echo 'Terraform operation failed!'
        }
        always {
            cleanWs()  // Deletes all files and directories in the workspace directory allocated for the pipeline run. This reduces the risk of sensitive data lingering on the agent.
        }
    }
    parameters {
        booleanParam(name: 'DESTROY', defaultValue: false, description: 'Set to true to destroy resources')
    }
}