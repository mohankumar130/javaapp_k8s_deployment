pipeline {
    agent any
    tools {
        maven "Maven3"
    }
    environment {
        APP_NAME = "tomcat-java-app"
        RELEASE = "1.0.0"
        DOCKER_USER = "msy061618"
        DOCKER_PASS = "dockerhub"
        IMAGE_NAME = "${DOCKER_USER}/${APP_NAME}"
        IMAGE_TAG = "${RELEASE}-${BUILD_NUMBER}"
        CA_CERTIFICATE = credentials('kubeca')
    }
    stages {
        stage("Cleanup Workspace"){
                steps {
                cleanWs()
                }
        }
        stage('Git Checkout') {
            steps {
                git 'https://github.com/mohankumar130/maven.git'
            }
        }
        stage('Build Maven') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('SonarQube Analysis') {
            steps {
                script {
                    withSonarQubeEnv(credentialsId: 'sonarqube-token') {
                        sh "mvn sonar:sonar"
                    }
                }
            }
        }
        stage('Docker Image Build & scanning') {
            steps {
                script {
                    docker.withRegistry('', DOCKER_PASS) {
                        def docker_image = docker.build("${IMAGE_NAME}")
                        docker_image.push("${IMAGE_TAG}")
                        docker_image.push('latest')
                    }
                }
            }
        }
        stage('Scanning Images and after deleteing images') {
            steps {
                script {                       

                        echo " Deleting images after push registry"

                        sh 'trivy image --scanners vuln --exit-code 0 --severity HIGH,CRITICAL --format table ${IMAGE_NAME}:${IMAGE_TAG}'

                        sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG}"
                        sh "docker rmi ${IMAGE_NAME}:latest"
                                    
                }
            }
        }
        stage('Waiting for Project Head Approval Deployment') {
            steps {
                script {
                    def userAborted = false
                    def jobName = env.JOB_NAME
                    withCredentials([string(credentialsId: 'toaddress', variable: 'mailToRecipients'), 
                                     string(credentialsId: 'fromaddress', variable: 'useremail')]) {
                        emailext body: """
                        Please click the link below
                        ${BUILD_URL}input to approve or reject.<br>
                        """,
                        mimeType: 'text/html',
                        subject: "Approval Needed: ${jobName}",
                        from: "${useremail}",
                        to: "${mailToRecipients}",
                        recipientProviders: [[$class: 'CulpritsRecipientProvider']]
                    }

                    catchError(buildResult: 'ABORTED', stageResult: 'ABORTED') {
                        input submitter: 'project_approval', message: 'Do you approve?'
                    }

                    if (currentBuild.result == 'ABORTED') {
                        echo "Approval was not granted. Build aborted."
                        userAborted = true
                    }

                    if (userAborted) {
                        currentBuild.result = 'ABORTED'
                        echo "Approval person has rejected the deployment."
                        error("Approval was rejected, stopping the Deployment.")
                    } else {
                        echo "Approval granted. Proceeding with the Deployment."
                    }
                }
            }
        }
        stage('Deploy Application into Kubernetes Cluster') {
            when {
                expression {
                    currentBuild.result != 'ABORTED'
                }
            }
            steps {

                withCredentials([string(credentialsId: 'kubeca', variable: 'cacerti')]){
                    kubeconfig(
                        caCertificate: "${env.CA_CERTIFICATE}"  ,
                        credentialsId: 'kubeconfigfile', 
                        serverUrl: 'https://192.168.1.17:6443'
                        ) {
                            script {
                                try {
                                    sh 'kubectl version'
                                    sh 'kubectl get nodes'
                                    sh """
                                    helm upgrade --install ${APP_NAME} java-maven-chart \
                                        --set image.repository=${IMAGE_NAME} \
                                        --set image.tag=${IMAGE_TAG} \
                                        --namespace uat
                                    """
                                } catch (Exception e) {
                                    error("Failed to interact with Kubernetes cluster: ${e}")
                                }
                            }
                        }
                    }
                }
            }
        }
    post {
        success {
            echo "Build and deployment were successful."
        }
        failure {
            echo "Build or deployment failed. Check the logs for details."
        }
    }
}
