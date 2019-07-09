#!groovy

def steps(String message, Closure block, Closure tearDown = null) {
    try {
        block();
    }
    catch (Throwable t) {
        slackSend message: "${env.JOB_NAME}: ${message} failure ${env.BUILD_URL}", channel: '#ci-channel-app', color: 'danger'

        throw t;
    }
    finally {
        if (tearDown) {
            tearDown();
        }
    }
}


node {

    stage("Checkout") {
        checkout scm
    }

    // stage("Test") {
    //     steps "Test", {
    //         sh "test.sh"
    //     }
    // }

    stage("Build dockers") {
        steps "build", {
            def api = docker.build("repo.data.amsterdam.nl/datapunt/signals-maintenance-page:${env.BUILD_NUMBER}", "api")
            api.push()
            api.push("acceptance")
        }
    }
}

String BRANCH = "${env.BRANCH_NAME}"

if (BRANCH == "master") {

    node {
        stage('Push acceptance image') {
            steps "image tagging", {
                def image = docker.image("repo.data.amsterdam.nl/datapunt/signals-maintenance-page:${env.BUILD_NUMBER}")
                image.pull()
                image.push("acceptance")
            }
        }
    }

    node {
        stage("Deploy to ACC") {
            steps "deployment", {
                build job: 'Subtask_Openstack_Playbook',
                parameters: [
                    [$class: 'StringParameterValue', name: 'INVENTORY', value: 'acceptance'],
                    [$class: 'StringParameterValue', name: 'PLAYBOOK', value: 'deploy-signals-maintenance-page.yml'],
                ]
            }
        }
    }


    stage('Waiting for approval') {
        slackSend channel: '#ci-channel', color: 'warning', message: 'Signals Maintenance Page is waiting for Production Release - please confirm'
        input "Deploy to Production?"
    }

    node {
        stage('Push production image') {
            steps "image tagging", {
                def api = docker.image("repo.data.amsterdam.nl/datapunt/signals-maintenance-page:${env.BUILD_NUMBER}")
                api.pull()
                api.push("production")
                api.push("latest")
            }
        }
    }

    node {
        stage("Deploy") {
            steps "deployment", {
                build job: 'Subtask_Openstack_Playbook',
                parameters: [
                        [$class: 'StringParameterValue', name: 'INVENTORY', value: 'production'],
                        [$class: 'StringParameterValue', name: 'PLAYBOOK', value: 'signals-maintenance-page.yml'],
                ]
            }
        }
    }
}
