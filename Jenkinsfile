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

      stage('Mutation Tests - PIT') {
            steps {
              sh "mvn org.pitest:pitest-maven:mutationCoverage"
            }
            post {
              always {
                pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
              }
            }
          }

       stage('SonarQube - SAST') {
                  steps {
                    withSonarQubeEnv('SonarQube'){
                     sh "mvn sonar:sonar \
                      -Dsonar.projectKey=numeric-application \
                      -Dsonar.host.url=http://seundevsecops-demo.eastus.cloudapp.azure.com:9000 \
                      -Dsonar.login=95a653fe2d77ad7e42f0f6f4deefa3105f1abfa3"
                      }
                      timeout(time: 2, unit:'MINUTES'){
                        script{
                            waitForQualityGate abortPipeline: true
                        }
                    }
                }
            }

      stage("Docker Build and Push"){
        steps {
            withDockerRegistry([credentialsId: "docker-hub credentials", url:""]){
            sh "printenv"
            sh 'docker build -t jibolaolu/numeric-app:""$GIT_COMMIT"" . '
            sh 'docker push jibolaolu/numeric-app:""$GIT_COMMIT"" '
                }
            }
        }

      stage("Kubernetes Deployment DEV"){
        steps {
            withKubeConfig([credentialsId: 'kubeconfig']){
            sh "sed -i 's#replace#jibolaolu/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
            sh "kubectl apply -f k8s_deployment_service.yaml"
             }
         }
      }
  }
}