pipeline {
    agent any
    tools {
        jfrog 'jfrog-cli'
        terraform 'terraform-cli'
    }
    environment {
        AWS_REGION = 'us-east-1' // env variable
        SONAR_HOST_URL = 'https://sonarcloud.io'
        JAVA_HOME = '/usr/lib/jvm/java-17-openjdk-amd64' 
        PATH = "${JAVA_HOME}/bin:${env.PATH}" //Sets path to Java 17 for SonarQube
    }


    parameters {
        booleanParam(name: 'DESTROY', defaultValue: true, description: 'Set to true to destroy resources')
    }


     stages {
        /*stage('Checkout Code') {
            steps {
                git branch: 'jfrog', url: 'https://github.com/bleeng089/autoScale.git'
            }
        }
        stage('SonarQube Scanner') {
            steps {
                script {
                    // Securely fetch Sonar token using withCredentials
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) { // variable should always = 'SONAR_TOKEN' in withCredentials
                        def scannerHome = tool 'Install SonarScanner instance' // Name of SonarQube Scanner in Jenkins manage/configureTools
                        
                        // Execute SonarScanner with proper syntax
                        def scanStatus = sh(
                            script: """
                                export SONAR_TOKEN=${SONAR_TOKEN}
                                ${scannerHome}/bin/sonar-scanner \
                                -Dsonar.projectKey=bleeng089_AWSUltramarine \
                                -Dsonar.organization=bleeng089 \
                                -Dsonar.host.url=${SONAR_HOST_URL} \
                                -Dsonar.login=\${SONAR_TOKEN} \
                            """,
                            returnStatus: true // Correct placement
                        )
                        // Process scan results
                        if (scanStatus != 0) {
                            echo "SonarScanner detected issues, fetching details..."

                            // Use Groovy's JsonSlurper to parse the JSON response
                            def sonarIssues = sh(
                                script: """
                                    curl -s -u \${SONAR_TOKEN}: \
                                    "https://sonarcloud.io/api/issues/search?componentKeys=bleeng089&severities=BLOCKER,CRITICAL&statuses=OPEN"
                                """,
                                returnStdout: true // Fetch the JSON response as a string
                            ).trim()

                            def jsonSlurper = new groovy.json.JsonSlurper()
                            def issuesResponse = jsonSlurper.parseText(sonarIssues)

                            // Extract issue messages from the JSON response
                            if (issuesResponse.issues && !issuesResponse.issues.isEmpty()) {
                                def issueMessages = issuesResponse.issues.collect { it.message }.join("\n")
                                def issueDescription = """ 
                                    **SonarCloud Security Issues:**
                                    ${issueMessages}
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
        }

        stage('Fetch SonarCloud Results and Upload to JFrog') {
            steps {
                script {
                    // Use withCredentials to access the Sonar token securely
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        // Fetch Sonar results using curl
                        def sonarResults = sh(
                            script: """
                                curl -s -u "${SONAR_TOKEN}:" \
                                "https://sonarcloud.io/api/issues/search?componentKeys=bleeng089_AWSUltramarine" > sonar-report.json
                            """,
                            returnStatus: true // Ensure we proceed even if there are no issues
                        )
                        echo "SonarQube results: "
                        sh 'cat sonar-report.json'
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
                            echo "Snyk results: "
                            cat snyk-report.json 
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
                jf 'rt u snyk-report.json  jfrog-remote-repo/'
                jf 'rt u sonar-report.json  jfrog-remote-repo/' 
                jf "rt bp my-build ${env.BUILD_NUMBER}" //adds meta data to snyk & sonar reports
            }
        }*/

        stage ("Docker Pull Dastardly from Burp Suite container image") {
            steps {
                sh 'docker pull public.ecr.aws/portswigger/dastardly:latest'
            }
        }
        stage ("Docker run Dastardly from Burp Suite Scan") {
            steps {
                cleanWs()
                sh '''
                    # Run Dastardly in detached mode and capture container ID
                    container_id=$(docker run -d \
                        -e BURP_START_URL=https://example.com \
                        -e BURP_REPORT_FILE_PATH=/tmp/dastardly-report.xml \
                        public.ecr.aws/portswigger/dastardly:latest)
                    # Wait for completion, cap at 300 seconds
                    timeout 300 docker wait $container_id || docker stop $container_id
                    # Copy report
                    docker cp $container_id:/tmp/dastardly-report.xml ${WORKSPACE}/dastardly-report.xml || echo "No report generated"
                    # Clean up
                    docker rm $container_id
                    # Verify output
                    ls -l ${WORKSPACE}
                '''
            }
        }

        /*stage('Initialize Terraform') {
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
        }*/
    }
    post {
        success {
            echo 'Terraform operation completed successfully!'
        }
        failure {
            echo 'Terraform operation failed!'
        }
        always {
            junit testResults: 'dastardly-report.xml', skipPublishingChecks: true
            cleanWs()  // Deletes all files and directories in the workspace directory allocated for the pipeline run. This reduces the risk of sensitive data lingering on the agent.
        }
    }
}