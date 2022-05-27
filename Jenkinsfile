@Library('slack') _
pipeline {
  agent any

    environment {
      deploymentName = "devsecops"
      containerName  = "devsecops-container"
      serviceName    = "devsecops-svc"
      imageName      = "jibolaolu/numeric-app:${GIT_COMMIT}"
      applicationURL = "http://seundevsecops-demo.eastus.cloudapp.azure.com"
      applicationURI = "compare/51"
    }
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
        }

      stage('Mutation Tests - PIT') {
            steps {
              sh "mvn org.pitest:pitest-maven:mutationCoverage"
            }
          }

       stage('SonarQube - SAST') {
                  steps {
                    withSonarQubeEnv('SonarQube'){
                     sh "mvn sonar:sonar \
                      -Dsonar.projectKey=numeric-application \
                      -Dsonar.host.url=http://seundevsecops-demo.eastus.cloudapp.azure.com:9000\
                      -Dsonar.login=593b9badd89bc4bfbb278d116a0c5b358c1549dd"

                      }
                      timeout(time: 2, unit:'MINUTES'){
                        script{
                            waitForQualityGate abortPipeline: true
                        }
                    }
                }
            }

       stage('Vulnerability Scan - Docker ') {
            steps {
              parallel(
                "Dependency Scan": {
                    sh "mvn dependency-check:check"
              },
                "Trivy Scan": {
                    sh "bash trivy-docker-image-scan.sh"
                },
                "OPA Conftest":{
                     sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
                }
               )
            }
          }

      stage("Docker Build and Push"){
        steps {
            withDockerRegistry([credentialsId: "docker-hub credentials", url:""]){
            sh "printenv"
            sh 'sudo docker build -t jibolaolu/numeric-app:""$GIT_COMMIT"" . '
            sh 'docker push jibolaolu/numeric-app:""$GIT_COMMIT"" '
                }
            }
        }

      stage('Vulnerability Scan for Kubernetes'){

        steps{
            parallel(
               "OPA Scan":{
                    sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
               },
               "Kubesec Scan": {
                    sh 'bash kubesec-scan.sh'
               },
               "Trivy Scan": {
                    sh 'bash trivy-k8s-scan.sh'
               }

            )

         }
        }
      //stage("Kubernetes Deployment DEV"){
        //steps {
            //withKubeConfig([credentialsId: 'kubeconfig']){
            //sh "sed -i 's#replace#jibolaolu/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
            //sh "kubectl apply -f k8s_deployment_service.yaml"
             //}
         //}
      //}
  //}
      stage('K8 Deployment -DEV'){
        steps {
            parallel(
                "Deployment": {
                    withKubeConfig([credentialsId: 'kubeconfig']){
                        sh 'bash k8s-deployment.sh'
                    }
                },
                "Roll-Out Status": {
                    withKubeConfig([credentialsId: 'kubeconfig']){
                        sh 'bash k8s-deployment-rollout-status.sh'
                    }
                }
                )
            }
        }

      stage('Integration Tests - DEV') {
            steps {
              script {
                try {
                  withKubeConfig([credentialsId: 'kubeconfig']) {
                    sh "bash integration-test.sh"
                  }
                } catch (e) {
                  withKubeConfig([credentialsId: 'kubeconfig']) {
                    sh "kubectl -n default rollout undo deploy ${deploymentName}"
                  }
                  throw e
                }
              }
            }
          }
       stage('OWASP ZAP - DAST') {
          steps {
            withKubeConfig([credentialsId: 'kubeconfig']) {
                sh 'bash zap.sh'
            }
          }
       }
       stage('Prompte to PROD?') {
         steps {
           timeout(time: 2, unit: 'DAYS') {
             input 'Do you want to Approve the Deployment to Production Environment/Namespace?'
           }
         }
       }

    stage('K8S CIS Benchmark') {
      steps {
        script {

          parallel(
            "Master": {
              sh "bash cis-master.sh"
            },
            "Etcd": {
              sh "bash cis-etcd.sh"
            },
            "Kubelet": {
              sh "bash cis-kubelet.sh"
            }
          )

        }
      }
    }
     }

  post{
    always{
        junit 'target/surefire-reports/*.xml'
        jacoco execPattern: 'target/jacoco.exec'
        pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
        dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
        publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'HTML Report', reportTitles: 'OWASP ZAP  HTML Report'])
        // Use sendNotifications.groovy from shared library and provide current build result as parameter
        sendNotification currentBuild.result
    }
  }
}