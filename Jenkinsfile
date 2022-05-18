pipeline {
  agent any

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' //so that they can be downloaded later
              echo "I have finished building"
            }

         }

      stage('Unit Test') {
            steps {
                echo "Starting my unt testing"
                sh "mvn test"
            }
            post {
                always {
                   junit 'target/surefire-reports/*.xml'
                   jacoco execPattern: 'target/jacoco.exec'
                }
            }
        }

      stage("Docker Build and Push"){
      steps {
        sh "printenv"
        sh 'docker build -t jibolaolu/numeric-app:""$GIT_COMMIT"" . '
        sh 'docker push jibolaolu/numeric-app:""$GIT_COMMIT"" '
        }
      }
    }
}