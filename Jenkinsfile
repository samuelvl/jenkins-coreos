pipeline {
    agent {
        docker {
            label 'docker'
            image 'docker.io/alpine:3.11.5'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'id'
            }
        }
        stage('Test') {
            steps {
                sh 'hostname'
            }
        }
        stage('Deploy') {
            steps {
                sh 'date'
            }
        }
    }
}
