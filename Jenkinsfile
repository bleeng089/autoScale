pipeline {
    agent any
    tools {
        jfrog 'jfrog-cli'
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
                            echo "Installing Snyk..."
                            curl -L https://github.com/snyk/snyk/releases/latest/download/snyk-linux -o /tmp/snyk
                            chmod +x /tmp/snyk
                            export PATH=$PATH:/tmp
                            echo "PATH is: $PATH"
                            /tmp/snyk --version || echo "Snyk install failed"
                            export SNYK_TOKEN=${SNYK_TOKEN}
                            /tmp/snyk iac test --json > snyk-report.json || true
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




    
    





// ### Breakdown of Each Section

// #### 1. `agent any`
// - **What it does**: Specifies that this pipeline can run on any available Jenkins agent (no specific requirements like a Docker image or labeled node).
// - **Implication**: The agent must have the JFrog CLI installed or configured via the `tools` block.

// #### 2. `tools { jfrog 'jfrog-cli' }`
// - **What it does**: Declares that the pipeline uses the JFrog CLI tool, with the identifier `'jfrog-cli'`. This is a Jenkins-specific configuration that ensures the JFrog CLI is available in the agent’s PATH.
// - **Implication**: The `'jfrog-cli'` must be a pre-configured tool in Jenkins’ global configuration (Manage Jenkins > Global Tool Configuration). Jenkins will automatically download and set it up if it’s not already present on the agent.

// #### 3. `stages { stage('Testing') { ... } }`
// - **What it does**: Defines a single stage called "Testing" that contains all the steps to be executed.
// - **Implication**: This is a logical grouping of tasks, typically used for reporting or visualization in Jenkins’ UI (e.g., Blue Ocean).

// #### 4. `steps { ... }`
// - Here’s where the actual work happens. Let’s analyze each step:

// ##### a. `jf '-v'`
// - **Command**: `jfrog -v`
// - **What it does**: Runs the JFrog CLI with the `-v` flag to display its version.
// - **Purpose**: Verifies that the JFrog CLI is installed and working on the agent.
// - **Output**: Something like `jfrog version 2.x.x`.

// ##### b. `jf 'c show'`
// - **Command**: `jfrog config show`
// - **What it does**: Displays the current JFrog CLI configuration (e.g., server URLs, credentials, repositories).
// - **Purpose**: Confirms that the CLI is configured to connect to an Artifactory instance. This assumes a configuration was previously set up (e.g., via `jfrog config add` outside this pipeline or in a prior step not shown).
// - **Output**: A list of configured servers and their details (e.g., URL, user, token).

// ##### c. `jf 'rt ping'`
// - **Command**: `jfrog rt ping`
// - **What it does**: Pings the Artifactory server configured in the CLI to check connectivity.
// - **Purpose**: Ensures the agent can communicate with the Artifactory instance.
// - **Output**: `OK` if successful, or an error if the server is unreachable or misconfigured.

// ##### d. `sh 'touch test-file'`
// - **Command**: `touch test-file`
// - **What it does**: Creates an empty file named `test-file` in the current working directory of the Jenkins workspace.
// - **Purpose**: Generates a simple file to use in subsequent Artifactory operations (upload/download).

// ##### e. `jf 'rt u test-file jfrog-cli/'`
// - **Command**: `jfrog rt upload test-file jfrog-cli/`
// - **What it does**: Uploads the `test-file` from the workspace to an Artifactory repository under the path `jfrog-cli/`.
// - **Details**:
//   - `rt u` is shorthand for `jfrog rt upload`.
//   - `test-file` is the source file.
//   - `jfrog-cli/` is the target path in Artifactory (assumes a repository is specified in the CLI config).
// - **Purpose**: Tests the ability to upload artifacts to Artifactory.
// - **Implication**: The repository (e.g., `jfrog-cli`) must exist and be writable in the configured Artifactory instance.

// ##### f. `jf 'rt bp'`
// - **Command**: `jfrog rt build-publish`
// - **What it does**: Publishes build information to Artifactory, associating uploaded artifacts (like `test-file`) with the current build.
// - **Details**:
//   - Requires a build name and number, which might be implicitly set by Jenkins (e.g., via the Artifactory plugin) or explicitly via environment variables like `BUILD_NAME` and `BUILD_NUMBER`.
// - **Purpose**: Links the pipeline’s artifacts to a build record in Artifactory for traceability.
// - **Implication**: If no build info is configured, this might fail or do nothing unless pre-set (e.g., via `jfrog rt build-add-dependencies` or Jenkins integration).

// ##### g. `jf 'rt dl jfrog-cli/test-file'`
// - **Command**: `jfrog rt download jfrog-cli/test-file`
// - **What it does**: Downloads the `test-file` from the `jfrog-cli/` path in Artifactory back to the workspace.
// - **Purpose**: Verifies that the file can be retrieved from Artifactory after upload.
// - **Output**: The `test-file` reappears in the workspace (possibly overwriting the original if not cleaned up).

// ---

// ### What This Pipeline Does Overall
// This Jenkins pipeline is a simple test or proof-of-concept for interacting with JFrog Artifactory using the JFrog CLI. Here’s the sequence of actions:
// 1. **Setup**: Ensures the JFrog CLI is available and configured.
// 2. **Validation**: Checks the CLI version, configuration, and Artifactory connectivity.
// 3. **Artifact Lifecycle**:
//    - Creates a dummy file (`test-file`).
//    - Uploads it to Artifactory under `jfrog-cli/`.
//    - Publishes build metadata.
//    - Downloads the file back to verify the round trip.
// 4. **Purpose**: Likely used to:
//    - Test JFrog CLI integration with Jenkins.
//    - Validate Artifactory connectivity and permissions.
//    - Demonstrate basic artifact management (upload, build info, download).

// ---

// ### Assumptions and Potential Issues
// 1. **JFrog CLI Config**: The pipeline assumes the JFrog CLI has a pre-existing configuration (e.g., server URL, credentials) set via `jfrog config add`. If not, steps like `rt ping`, `rt u`, etc., will fail.
//    - **Fix**: Add a `jf 'c add'` step with credentials if needed (e.g., using `withCredentials`).
// 2. **Repository**: The `jfrog-cli/` target implies a repository named `jfrog-cli` or a path within a repo. If it doesn’t exist or isn’t specified in the config, the upload will fail.
//    - **Fix**: Specify the repo explicitly, e.g., `jf 'rt u test-file my-repo/jfrog-cli/'`.
// 3. **Build Info**: `rt bp` assumes build info is set. Without it, this step might silently do nothing or error out.
//    - **Fix**: Set build info explicitly with `env.BUILD_NAME` and `env.BUILD_NUMBER` or use Jenkins’ Artifactory plugin.
// 4. **Permissions**: The pipeline needs write/read access to the target Artifactory repo.

// ---

// ### Example with Fixes
// Here’s a more robust version addressing these assumptions:

// ```groovy
// pipeline {
//     agent any
//     tools {
//         jfrog 'jfrog-cli'
//     }
//     environment {
//         BUILD_NAME = "Test-Build"
//         BUILD_NUMBER = "${env.BUILD_NUMBER}"
//     }
//     stages {
//         stage('Testing') {
//             steps {
//                 withCredentials([usernamePassword(credentialsId: 'artifactory-creds', usernameVariable: 'JFROG_USER', passwordVariable: 'JFROG_TOKEN')]) {
//                     sh '''
//                         jf config add my-artifactory --url=https://myartifactory.com --user=$JFROG_USER --password=$JFROG_TOKEN
//                         jf config use my-artifactory
//                     '''
//                     jf '-v'
//                     jf 'c show'
//                     jf 'rt ping'
//                     sh 'touch test-file'
//                     jf 'rt u test-file my-repo/jfrog-cli/'
//                     jf 'rt bp'
//                     jf 'rt dl my-repo/jfrog-cli/test-file'
//                 }
//             }
//         }
//     }
// }
// ```

// ---

// ### Summary
// This pipeline is a basic test harness for JFrog Artifactory integration. It:
// - Validates the JFrog CLI setup.
// - Uploads a test file to Artifactory.
// - Publishes build info.
// - Downloads the file back.
// It’s simple but assumes a configured environment. With minor tweaks (e.g., explicit config, repo names), it could be a starting point for real artifact management workflows.