pipeline {
    agent any
    tools {
        maven "Maven3"
    }
    stages {
        stage('Git Chekout') {
            steps {
                git 'https://github.com/mohankumar130/maven.git'
            }
        }
        stage('Build'){
            steps {
                sh 'mvn clean package'
            }
        }
        stage('Image Build') {
            steps {
                sh 'docker image build -t $JOB_NAME:v1.$BUILD_ID dockerbuild_$JOB_NAME'
            }
        }
    }
}
