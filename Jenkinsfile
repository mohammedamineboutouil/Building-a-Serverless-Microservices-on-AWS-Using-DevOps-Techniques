#!/usr/bin/env groovy
import java.time.LocalDateTime

def remote = [:] as Object
def currentVersion = "latest"
def serviceParams = """
CheckboxParameter:
  - key: Landing
    value: landing
  - key: Workspace
    value: workspace
  - key: Micro-service
    value: service
"""

pipeline {
    agent any
    environment {
        PROJECT_NAME = 'Serverless Microservices On AWS'
        SLACK_CHANNEL = 'serverless_pipeline'
        ECS_SERVICE_NAME = '<REPLACE-WITH-SERVICE-NAME>
        ECS_CLUSTER_NAME = '<REPLACE-WITH-CLUSTER-NAME>'
        DEFAULT_REGION = 'eu-west-1'
        GRADLE_OPTS = "-Dorg.gradle.daemon=false -Dorg.gradle.internal.launcher.welcomeMessageEnabled=false"
        TIMESTAMP = LocalDateTime.now()
    }

    parameters {
        choice(
                choices: ['All', 'Build', 'Deploy'],
                description: 'Select deployment action',
                name: 'REQUESTED_ACTION'
        )
        checkboxParameter(
                pipelineSubmitContent: serviceParams,
                description: 'Select services',
                name: 'SELECTED_SERVICES',
                format: 'YAML'
        )
    }

    options {
        disableConcurrentBuilds() // No more than one job at a time is allowed to run.
        buildDiscarder(logRotator(numToKeepStr: '5')) // Only keep latest 14 jobs.
    }

    stages {
        stage('Debug info') {
            steps {
                script {
                    sh './gradlew --version'
                    sh 'docker --version'
                    sh 'aws --version'
                }
            }
        }
        stage('Setup version') {
            steps {
                script {
                    FULL_PATH_BRANCH = sh(script: 'git name-rev --name-only HEAD', returnStdout: true).trim()
                    currentVersion = FULL_PATH_BRANCH.substring(FULL_PATH_BRANCH.lastIndexOf('/') + 1, FULL_PATH_BRANCH.length())
                    sh "echo Building version ${currentVersion}"
                }
            }
        }
        stage('Build Landing') {
            when {
                expression { return stepCondition(['All', 'Build'], 'landing') }
            }
            steps {
                script {
                    sh "make build-landing"
                }
            }
        }
        stage('Build Workspace') {
            when {
                expression { return stepCondition(['All', 'Build'], 'workspace') }
            }
            steps {
                script {
                    sh "make build-space"
                }
            }
        }
        stage('Build Micro-service') {
            when {
                expression { return stepCondition(['All', 'Build'], 'service') }
            }
            steps {
                script {
                    def serviceName = "micro-service"
                    def repositoryUri = sh(script: "./_ci/repo ${serviceName}", returnStdout: true)
                            .trim()
                    sh "./gradlew :${serviceName}:clean"
                    sh "./gradlew :${serviceName}:jib -PrepositoryUri=${repositoryUri}"
                }
            }
        }
        stage('Deploy Landing') {
            when {
                expression { return stepCondition(['All', 'Deploy'], 'landing') }
            }
            steps {
                script {
                    sh "make deploy-landing"
                }
            }
        }
        stage('Deploy Workspace') {
            when {
                expression { return stepCondition(['All', 'Deploy'], 'workspace') }
            }
            steps {
                script {
                    sh "make deploy-space"
                }
            }
        }
        stage('Deploy Micro-service') {
            when {
                expression { return stepCondition(['All', 'Deploy'], 'service') }
            }
            steps {
                script {
                    def serviceName = "micro-service-task-definition"
                    sh("./_ci/deploy ${serviceName} ${env.ECS_SERVICE_NAME} ${env.ECS_CLUSTER_NAME} ${env.DEFAULT_REGION}")
                }
            }
        }
    }
    post {
        changed {
            script {
                slackSend(
                        color: (currentBuild.currentResult == 'SUCCESS') ? 'good' : 'danger',
                        channel: "${env.SLACK_CHANNEL}",
                        message: "Job: ${currentBuild.fullDisplayName} - `${currentBuild.currentResult}`\n${env.BUILD_URL}")
/*                emailext(
                        subject: "[${currentBuild.fullDisplayName}] ${currentBuild.currentResult}",
                        mimeType: 'text/html',
                        recipientProviders: [[$class: 'CulpritsRecipientProvider'], [$class: 'RequesterRecipientProvider']],
                        body: "<a href=\"${env.BUILD_URL}\">${currentBuild.fullDisplayName} is reported as ${currentBuild.currentResult}</a>")
*/
            }
        }
    }
}

boolean stepCondition(List<String> actions, String service) {
    def requestedAction = params.REQUESTED_ACTION
    def selectedServices = String.valueOf(params.SELECTED_SERVICES).split(',')
    return actions.contains(requestedAction) && selectedServices.contains(service)
}