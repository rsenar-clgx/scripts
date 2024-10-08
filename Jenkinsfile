@Library('CoreLogicDevopsUtils') _
import com.corelogic.devops.utils.VaultTemplate
import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException

vaultImpl = new com.corelogic.devops.utils.VaultTemplate()

/** Pipeline Global Variables: These will not be changed and has global scope **/
env.GIT_REPO = scm.getUserRemoteConfigs()[0].getUrl().tokenize('/')[3].split("\\.")[0]
env.REPO_TYPE = GIT_REPO.split("-")[-1]
env.GIT_BRANCH = scm.branches[0].name
def SLACK_CHANNEL = '@ozipunnikov'

// Pipeline Global Variables: These will be changed based on the environment
def GIT_COMMIT
def GIT_MESSAGE
def SLACK_MESSAGE

pipeline {
    agent {
        kubernetes {
            yaml """
            apiVersion: v1
            kind: Pod
            metadata:
              labels:
                master_name: platform_services_glb
                label: dataproc
            spec:
              tolerations:
                - key: cloud.google.com/gke-nodepool
                  operator: Equal
                  value: ephemeral-pods
                  effect: NoSchedule
              containers:
                - name: commercialprefill
                  image: >-
                    us-docker.pkg.dev/clgx-artregistry-mgt-prd-3b27/platform-services-glb-jenkins-docker-local/iac-tools
                  imagePullPolicy: Always
                  command:
                    - cat
                  tty: true
              imagePullSecrets:
                - name: us-docker-pkg-dev-credentials
            """
        }
    }
    stages {
        stage('auto_increment_tag') {
            steps {
                container('commercialprefill') {
                    script {
                        currentBuild.displayName = "${env.GIT_BRANCH}-${env.BUILD_ID}"
                        currentBuild.description = "CLGX_ENVIRONMENT: ${env.BRANCH_NAME}\n"
                        if (env.BRANCH_NAME == 'dev') {
                            tag('dev')
                        } else if (env.BRANCH_NAME == 'int') {
                            tag('int')
                        } else if (env.BRANCH_NAME == 'prd') {
                            tag('prd')
                        } else {
                            echo "Branch ${env.BRANCH_NAME} does not have a deployment target."
                        }
                    }
                }
            }
        }
        stage('auto_update_airflow_dag_repo') {
            steps {
                container('commercialprefill') {
                    script {
                        if (env.BRANCH_NAME == 'dev') {
                            dag('dev')
                        } else if (env.BRANCH_NAME == 'int') {
                            dag('int')
                        } else if (env.BRANCH_NAME == 'prd') {
                            dag('prd')
                        } else {
                            echo "Branch ${env.BRANCH_NAME} does not have a deployment target."
                        }
                        env.SLACK_MESSAGE = "Job finished for ${env.GIT_REPO} on BRANCH ${env.BRANCH_NAME}\nGit message: ${env.GIT_MESSAGE}\nSHA: ${env.GIT_COMMIT}\nJERKINS BUILD: ${JOB_NAME} #${BUILD_NUMBER} (<${BUILD_URL}|Open>)"
                    }
                }
            }
        }
    }

    post {
        success {
            slackSend(channel: "${SLACK_CHANNEL}", color: '#3EE74E', message: "SUCCESS: ${env.SLACK_MESSAGE}")
        }
        failure {
            slackSend(channel: "${SLACK_CHANNEL}", color: '#E7433E', message: "FAILED: ${env.SLACK_MESSAGE}")
        }
        aborted {
            slackSend(channel: "${SLACK_CHANNEL}", color: '#930DFF', message: "ABORTED: ${env.SLACK_MESSAGE}")
        }
    }
}

def tag(tier){
    withCredentials([usernamePassword(credentialsId: 'clgx-jenkins-token1', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
        echo sh(script: """
            git config --global user.email "jenkins@jenkins.solutions.corelogic.com"
            git config --global user.name "Jenkins"
            sudo wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
            sudo chmod +x /usr/bin/yq
            set -x // Enable command tracing
            export CLGX_ENVIRONMENT=${tier}
            bash scripts/auto_increment_tag.sh
        """, returnStdout: true).trim()
    }
}

def dag(tier){
    withCredentials([usernamePassword(credentialsId: 'clgx-jenkins-token', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
        sh """
            git config --global user.email "jenkins@jenkins.solutions.corelogic.com"
            git config --global user.name "Jenkins"
            sudo wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
            sudo chmod +x /usr/bin/yq
            set -x // Enable command tracing
            export CLGX_ENVIRONMENT=${tier}
            bash scripts/auto_update_airflow_dag_repo.sh
        """
    }
}
