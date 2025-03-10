pipeline {
    agent any
    tools {
        jfrog 'jfrog-cli'
        terraform 'terraform-cli'
    }
    environment {
        AWS_REGION = 'us-east-1' // env variable
        SONAR_HOST_URL = 'https://sonarcloud.io'
    }
    parameters {
        booleanParam(name: 'DESTROY', defaultValue: true, description: 'Set to true to destroy resources')
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'jfrog', url: 'https://github.com/bleeng089/autoScale.git'
            }
        }
        stage ('SonarQube Scanner') {
            steps {
                script {
                    def scannerHome = tool 'Install SonarScanner instance' // Name of SonarQube Scanner in Jenkins manage/configureTools
                    sh '''
                        ${scannerHome}/bin/sonar-scanner \
                        -Dsonar.projectKey=bleeng089 \
                        -Dsonar.organization=AWSUltramarine \
                        -Dsonar.host.url=${env.SONAR_HOST_URL} \
                        -Dsonar.login=${env.sonar-token} \
                        -Dsonar.report.export.path=sonar-report.json
                    ''' , returnStatus: true

                    if (scanStatus != 0) {
                        echo "SonarScanner detected issues, fetching details..."
                        def sonarIssues = sh(script: '''
                            curl -s -u ${env.sonar-token}: \
                            "https://sonarcloud.io/api/issues/search?componentKeys=bleeng089&severities=BLOCKER,CRITICAL&statuses=OPEN" | jq -r '.issues[].message' || echo "No issues found"
                        ''', returnStdout: true).trim()

                        if (!sonarIssues.contains("No issues found")) {
                            def issueDescription = """ 
                                **SonarCloud Security Issues:**
                                ${sonarIssues}
                            """.stripIndent()

                            echo issueDescription
                            error("Critical security issues found! Failing the build.")
                        } else {
                            echo "No critical or blocker issues found."
                        }
                        } else {
                        echo "SonarScanner completed successfully with no issues."
                        }
                    }
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
                            echo "Installing Snyk..."
                            curl -L https://github.com/snyk/snyk/releases/latest/download/snyk-linux -o /tmp/snyk
                            chmod +x /tmp/snyk
                            export PATH=$PATH:/tmp
                            /tmp/snyk --version || echo "Snyk install failed"
                            export SNYK_TOKEN=${SNYK_TOKEN}
                            /tmp/snyk iac test --json > snyk-report.json 
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
                jf 'rt u sonar-report.json  jfrog-remote-repo/' 
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
            when {
                expression { params.DESTROY == false }  // Only "terraform apply" if DESTROY parameter is false
            }
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
                expression { params.DESTROY == true } // Only "terraform destroy" if DESTROY parameter is true
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
}