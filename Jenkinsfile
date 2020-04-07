pipeline {
    agent {
        docker {
            label 'docker'
            image 'docker.io/alpine:3.11.5'
        }
    }
    stages {
        stage('Test') {
            steps {
                sh 'echo "Hello world!"'
            }
        }
    }
}
