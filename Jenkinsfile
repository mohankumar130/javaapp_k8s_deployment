pipeline {
    agent any
    tools {
        maven "Maven3"
    }
    environment {
        hub_user = "msy061618"
        containername = "tomcat"
        CA_CERTIFICATE = credentials('kubeca')
    }
    stages {
        stage('Git Chekout') {
            steps {
                git 'https://github.com/mohankumar130/maven.git'
            }
        }
        stage('Build Maven'){
            steps {
                sh 'mvn clean package'
            }
        }       
        stage('Docker Image Build') {
            steps {
                sh 'docker image build -t "${hub_user}"/$JOB_NAME:v1.$BUILD_ID .'
            }
        }
        stage('Docker Image push into Regis') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'hubpasswd', variable: 'dockerpass')]) {
                        sh 'docker login -u "${hub_user}" -p ${dockerpass}'
                        sh 'docker image tag "${hub_user}"/$JOB_NAME:v1.$BUILD_ID "${hub_user}"/$JOB_NAME:latest'
                        sh 'docker image tag "${hub_user}"/$JOB_NAME:v1.$BUILD_ID "${hub_user}"/$JOB_NAME:v1.$BUILD_ID'
                        sh 'docker push "${hub_user}"/$JOB_NAME:v1.$BUILD_ID'
                        sh 'docker push "${hub_user}"/$JOB_NAME:latest'
                        // sh 'docker image rm "${hub_user}"/$JOB_NAME:v1.$BUILD_ID-1 "${hub_user}"/$JOB_NAME:latest '
                        }
                    }
                }               
            }
        stage('Clean Previous Docker Image') {
            steps {
                script {
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
        // stage('Deploy into docker container') {
        //     steps {
        //         script {
        //             sh 'docker run -it -d --name tomcat -p 8085:8080 "${hub_user}"/$JOB_NAME:latest'
        //         }
        //     }
        // }
        stage('deploy application into kubernetes cluster') {
            steps {
                withCredentials([string(credentialsId: 'kubeca', variable: 'cacerti')]){
                 kubeconfig(
                    caCertificate: "${env.CA_CERTIFICATE}"  ,
                    credentialsId: 'kubeconfigfile', 
                    serverUrl: 'https://192.168.1.17:6443'
                                            )
                    {
                        sh 'kubectl get nodes'
                        sh 'helm upgrade -i tomcat java-maven-chart --set image.repository=${hub_user}"/$JOB_NAME --image.tag=v1.$BUILD_ID --namespace uat'                    
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