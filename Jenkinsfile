pipeline {
    agent any
    tools {
        maven "Maven3"
    }
    environment {
        hub_user = "msy061618"
        containername = "tomcat"
        CA_CERTIFICATE = credentials('kubeca')
        jobName = "${env.JOB_NAME} #${env.BUILD_NUMBER}"
    }
    stages {
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
        stage('sonarQube Analysis') {
            steps {
                script {
                    withSonarQubeEnv(credentialsId: 'sonarqube-token') {
                        sh "mvn sonar:sonar"
                    }
                }
            }
        }
        stage('Docker Image Build & Push into Registry') {
            steps {
                script {
                    sh 'docker image build -t "${hub_user}"/$JOB_NAME:v1.$BUILD_ID .'
                    withCredentials([string(credentialsId: 'hubpasswd', variable: 'dockerpass')]) {
                        sh 'docker login -u "${hub_user}" -p ${dockerpass}'
                        sh 'docker image tag "${hub_user}"/$JOB_NAME:v1.$BUILD_ID "${hub_user}"/$JOB_NAME:latest'
                        sh 'docker image tag "${hub_user}"/$JOB_NAME:v1.$BUILD_ID "${hub_user}"/$JOB_NAME:v1.$BUILD_ID'
                        sh 'docker push "${hub_user}"/$JOB_NAME:v1.$BUILD_ID'
                        sh 'docker push "${hub_user}"/$JOB_NAME:latest'
                        def jobName = env.JOB_NAME
                        def previousVersionTag = "v1.${env.BUILD_ID.toInteger() - 1}"
                        def previousImage = "${hub_user}/${jobName}:${previousVersionTag}"
                    
                        // Check if the previous image exists and delete it if it does
                        sh """
                        if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '${previousImage}'; then
                            docker rmi -f ${previousImage}
                        fi
                        """
                    }
                }
            }
        }
        stage('Waiting for Project Head Approval Deployment') {
            steps {
                script {
                    def userAborted = false
                    withCredentials([string(credentialsId: 'toaddress', variable: 'mailToRecipients'), 
                                     string(credentialsId: 'fromaddress', variable: 'useremail')]) {
                        emailext body: '''
                        Please click the link below
                        ${BUILD_URL}input to approve or Reject.<br>
                        ''',
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
                        echo "Approval person has rejected the deploy."
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
                        sh 'kubectl get nodes'
                        sh """
                        helm upgrade --install ${containername} java-maven-chart \
                         --set image.repository=${hub_user}/${JOB_NAME} \
                         --set image.tag=v1.$BUILD_ID \
                         --namespace uat
                        """
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
