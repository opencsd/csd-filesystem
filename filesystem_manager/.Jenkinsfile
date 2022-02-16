#!groovy

/*
 * The GNU General Public License Version 3
 *
 * Copyright 2015-2021. Gluesys. Co., Ltd. All rights reserved.
 */
@Library('Gluesys') _

printParams()

pipeline
{
    agent {
        node {
            label 'AC2_GMS_BUILD_CENT7'
            customWorkspace '/usr/gms'
        }
    }

    parameters {
        string(
            name: 'gmsRepo',
            defaultValue: 'origin',
            description: 'GMS repository name')
        string(
            name: 'gmsBranch',
            defaultValue: 'master',
            description: 'GMS branch name')
        string(
            name: 'girasoleRepo',
            defaultValue: 'origin',
            description: 'Girasole repository name')
        string(
            name: 'girasoleBranch',
            defaultValue: 'master',
            description: 'Girasole branch name')
        string(
            name: 'eflowdBranch',
            defaultValue: 'master',
            description: 'Eflowd branch name')
        booleanParam(
            name: 'skipGirasoleTests',
            defaultValue: true,
            description: 'Skip Girasole test')
        booleanParam(
            name: 'skipEflowdTests',
            defaultValue: true,
            description: 'Skip Eflowd test')
        booleanParam(
            name: 'skipConfig',
            defaultValue: false,
            description: 'Skip cluster node configuration')
        booleanParam(
            name: 'skipInit',
            defaultValue: false,
            description: 'Skip cluster initialization')
        booleanParam(
            name: 'skipTests',
            defaultValue: false,
            description: 'Skip all test')
        booleanParam(
            name: 'stopSlavesAfterJob',
            defaultValue: false,
            description: 'Stop all slave VMs after this job')
    }

    options {
        timestamps()
        ansiColor('xterm')
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '30'))
    }

    stages {
        stage('Preparation') {
            steps {
                /*
                addGitLabMRComment \
                        comment: """
:pray: Build has started!

Build : [Jenkins [$env.JOB_NAME#$env.BUILD_NUMBER]]($env.BUILD_URL)
"""
*/

                echo 'Preparing...'

                sh 'git config --global --replace-all user.email "jenkins@gluesys.com"'
                sh 'git config --global --replace-all user.name "Gluesys Jenkins"'

                dir('/usr/jenkins') {
                    git \
                        branch: 'master', \
                        credentialsId: 'cf7ac1a3-e88a-4977-b094-1bb5c6e0c9d1', \
                        url: 'git@gitlab.gluesys.com:ac2/jenkins.git'

                    sh 'bash +x scripts/prepare.sh'
                }

                script {
                    env.CI_SRC = '/usr/jenkins'

                    sh "rm -rf ${env.CI_SRC}/nytprof*"
                    sh "rm -rf ${WORKSPACE}/rpmbuild/*"
                    sh "rm -rf ${WORKSPACE}/other_job_rpm/*"
                    sh "rm -rf /tmp/ANYSTOR-E/${env.JOB_NAME}"
                }

                sh """
                    echo 'Mounting artifacts directory with NFS...'

                    [ -d /mnt/jenkins_log ] || mkdir -p /mnt/jenkins_log

                    [ `mount | grep jenkins_log | wc -l` -ge 1 ] \
                        || mount -t nfs 192.168.3.4:/tank2/jenkins_log /mnt/jenkins_log

                    mkdir -p /mnt/jenkins_log/${env.JOB_NAME}/${env.BUILD_NUMBER}

                    yum install -y \
                        git etcd jq rpm-build expect cifs-utils nfs-utils \
                        bonnie++ ntpdate \
                        samba-client cifs-utils perl-Tree-Simple perl-Net-Interface \
                        perl-enum perl-libintl perl-AnyEvent perl-AnyEvent-HTTP \
                        perl-Array-Diff \
                        perl-Coro perl-Coro-Multicore perl-Crypt-AES-CTR \
                        perl-Crypt-DES perl-Crypt-OpenSSL-RSA perl-CryptX \
                        perl-Data-Compare perl-Data-Dump perl-Data-Validator \
                        perl-Data-Validate-IP perl-DateTime \
                        perl-DateTime-Format-Strptime perl-Devel-Cover \
                        perl-Devel-Leak-Object perl-Devel-NYTProf perl-Digest-SHA \
                        perl-Dir-Flock \
                        perl-Env perl-Etcd \
                        perl-File-chmod-Recursive perl-File-Copy-Recursive \
                        perl-File-Slurp perl-Filesys-Df perl-Filesys-Statvfs \
                        perl-Hash-Merge \
                        perl-IO-Compress perl-IO-Interface perl-IPC-Cmd \
                        perl-Memory-Usage perl-Mock-Sub perl-Module-Load \
                        perl-Module-Loaded perl-Mojo-JWT perl-Mojolicious \
                        perl-Mojolicious-Plugin-OpenAPI \
                        perl-Mojolicious-Plugin-SwaggerUI \
                        perl-MojoX-Log-Log4perl perl-Mouse perl-MouseX-Foreign \
                        perl-MouseX-NativeTraits \
                        perl-Net-IP perl-Net-Netmask perl-Net-OpenSSH perl-Net-Ping \
                        perl-Number-Bytes-Human \
                        perl-Proc-Exists \
                        perl-Socket6 perl-String-Random perl-String-Util \
                        perl-Switch perl-Sys-Hostname-FQDN perl-Sys-Syslog \
                        perl-Test-Class-Moose perl-Test-Harness \
                        perl-Test-MockModule perl-TimeDate \
                        perl-XML-Smart \
                        perl-YAML
                """
            }
        }

        /*
        stage('Unit-testing') {
            steps {
                echo 'Unit-testing...'

                dir('/usr/girasole') {
                    git \
                        branch: "${params.girasoleBranch}", \
                        credentialsId: 'cf7ac1a3-e88a-4977-b094-1bb5c6e0c9d1', \
                        url: 'git@gitlab.gluesys.com:potatogim/girasole.git'
                }

                dir('/usr/gms') {
                    script {
                        sh "cover -delete"

                        try {
                            sh """ \
                                MOCK_ETCD=1 TEST_VERBOSE=1 HARNESS_PERL_SWITCHES=-MDevel::Cover \
                                prove -lvm -Ilibgms -I/usr/girasole/lib t/unit.t :: --statistics
                            """
                        }
                        catch (e) {
                            currentBuild.result = 'FAILURE'
                            throw e
                        }
                        finally {
                            sh("cover -ignore_re '^libgms/|^t/|prove'")

                            sh """ \
                                mkdir -p /mnt/jenkins_log/${env.JOB_NAME}/${env.BUILD_NUMBER}/cover_db

                                cp -af cover_db /mnt/jenkins_log/${env.JOB_NAME}/${env.BUILD_NUMBER}/

                                cp -af unit.log /mnt/jenkins_log/${env.JOB_NAME}/${env.BUILD_NUMBER}/
                            """

                            //sh """
                            //    perl -ne '/Total.*\\>(?<cov>[\\d.]+)\\</ && printf \"Coverage: \$+{cov} %\\n\"' \
                            //    cover_db/coverage.html
                            //"""

                            echo "Unit-test Coverage: http://192.168.3.4/jenkins_log/${env.JOB_NAME}/${env.BUILD_NUMBER}/cover_db/coverage.html"
                            echo "Unit-test Log: http://192.168.3.4/jenkins_log/${env.JOB_NAME}/${env.BUILD_NUMBER}/unit.log"

                            script {
                                currentBuild.description \
                                    = (currentBuild.description \
                                            ? "${currentBuild.description}<br/>\n" : '') \
                                    + "<a href='http://192.168.3.4/jenkins_log/" \
                                        + "${env.JOB_NAME}/${env.BUILD_NUMBER}/cover_db/coverage.html'>" \
                                        + "Unit-test Coverage: ${env.JOB_NAME}/${env.BUILD_NUMBER}" \
                                    + "</a><br/>\n" \
                                    + "<a href='http://192.168.3.4/jenkins_log/" \
                                        + "${env.JOB_NAME}/${env.BUILD_NUMBER}/unit.log'>" \
                                        + "Unit-test Log: ${env.JOB_NAME}/${env.BUILD_NUMBER}" \
                                    + "</a>\n"
                            }
                        }
                    }
                }
            }
        }
        */

        stage('Girasole Testing') {
            steps {
                script {
                    echo "Girasole test start"

                    if (!upstreamIs("Girasole"))
                    {
                        /*
                        def girasoleBranch =
                            findBranch(params.girasoleRepo, env.gmsBranch)
                                ? env.gmsBranch
                                : params.girasoleBranch
                        */

                        def girasoleBranch = params.girasoleBranch

                        println "Girasole Branch: $girasoleBranch"

                        build \
                            job: 'Girasole', \
                            parameters: [ \
                                string(name: 'girasoleRepo', value: "${params.girasoleRepo}"), \
                                string(name: 'girasoleBranch', value: "${girasoleBranch}"), \
                                string(name: 'gmsRepo', value: "${params.gmsRepo}"), \
                                string(name: 'gmsBranch', value: "${env.gmsBranch}"), \
                                string(name: 'eflowdBranch', value: "${params.eflowdBranch}"), \
                                booleanParam(name: 'skipTests', value: params.skipGirasoleTests), \
                                booleanParam(name: 'integrationTest', value: false) \
                            ], \
                            wait: true
                    }
                }
            }

            post {
                /*
                always {
                    script {
                        def resultIcon = ':question:'

                        switch(currentBuild.currentResult) {
                            case "SUCCESS":
                                resultIcon = ':white_check_mark:'
                                break
                            case "FAILURE":
                                resultIcon = ':negative_squared_cross_mark:'
                                break
                            default:
                                resultIcon = ':anguished:'
                                break
                        }

                        echo "- /usr/gms/other_job_rpm"

                        addGitLabMRComment \
                            comment: """
$resultIcon Girasole Build $currentBuild.currentResult

Build : [Jenkins [$env.JOB_NAME#$env.BUILD_NUMBER]]($env.BUILD_URL)
"""
                    }
                }
                */

                success {
                    script {
                        if (upstreamIs("Girasole"))
                        {
                            echo "Copy artifacts from upstream"

                            copyArtifacts \
                                filter: 'rpmbuild/RPMS/x86_64/*.rpm', \
                                fingerprintArtifacts: true, \
                                projectName: 'Girasole', \
                                selector: upstream(), \
                                flatten: true, \
                                target: './other_job_rpm'

                            copyArtifacts \
                                filter: 'rpmbuild/SRPMS/*.rpm', \
                                fingerprintArtifacts: true, \
                                projectName: 'Girasole', \
                                selector: upstream(), \
                                flatten: true, \
                                target: './other_job_rpm'
                        }
                        else
                        {
                            echo "Copy artifacts from latest success"

                            copyArtifacts \
                                filter: 'rpmbuild/RPMS/x86_64/*.rpm', \
                                projectName: 'Girasole', \
                                selector: [ \
                                    $class: 'StatusBuildSelector', \
                                    stable: false \
                                ], \
                                flatten: true, \
                                target: './other_job_rpm'

                            copyArtifacts \
                                filter: 'rpmbuild/SRPMS/*.rpm', \
                                projectName: 'Girasole', \
                                selector: [ \
                                    $class: 'StatusBuildSelector', \
                                    stable: false \
                                ], \
                                flatten: true, \
                                target: './other_job_rpm'
                        }

                        echo "- /usr/gms/other_job_rpm"
                        sh "ls -1 ./other_job_rpm"
                    }
                }
            }
        }

        stage('Eflowd Testing') {
            steps {
                script {
                    if (!upstreamIs('Eflowd'))
                    {
                        build \
                            job: 'Eflowd', \
                            parameters: [ \
                                string(name: 'girasoleBranch', value: "${env.GIRASOLE_BRANCH}"), \
                                string(name: 'eflowdBranch', value: "${params.eflowdBranch}"), \
                                string(name: 'gmsBranch', value: "${params.gmsBranch}"), \
                                booleanParam(name: 'skipTests', value: params.skipGirasoleTests), \
                                booleanParam(name: 'integrationTest', value: false) \
                            ], \
                            wait: true
                    }
                }
            }

            post {
                /*
                always {
                    script {
                        def resultIcon = ':question:'

                        switch(currentBuild.currentResult) {
                            case "SUCCESS":
                                resultIcon = ':white_check_mark:'
                                break
                            case "FAILURE":
                                resultIcon = ':negative_squared_cross_mark:'
                                break
                            default:
                                resultIcon = ':anguished:'
                                break
                        }

                        addGitLabMRComment \
                            comment: """
$resultIcon eflowd Build $currentBuild.currentResult

Build : [Jenkins [$env.JOB_NAME#$env.BUILD_NUMBER]]($env.BUILD_URL)
"""
                    }
                }
                */

                success {
                    script {
                        if (upstreamIs('Eflowd'))
                        {
                            echo "Copy artifacts from upstream"

                            copyArtifacts \
                                filter: 'rpmbuild/RPMS/x86_64/*.rpm', \
                                fingerprintArtifacts: true, \
                                projectName: 'Eflowd', \
                                selector: upstream(), \
                                flatten: true, \
                                target: './other_job_rpm'
                        }
                        else
                        {
                            echo "Copy artifacts from latest success"

                            copyArtifacts \
                                filter: 'rpmbuild/RPMS/x86_64/*.rpm', \
                                projectName: 'Eflowd', \
                                selector: [ \
                                    $class: 'StatusBuildSelector', \
                                    stable: false \
                                ], \
                                flatten: true, \
                                target: './other_job_rpm'
                        }
                    }
                }
            }
        }

        stage('Building') {
            steps {
                echo 'Building...'

                dir('/usr/jenkins') {
                    sh """ \
                        bash +x scripts/packaging.sh \
                            --gms-repo=${params.gmsRepo}/GMS \
                            --gms-branch=${params.gmsBranch}
                    """
                }

                /*
                 * It is tricky way due to limitation of the archiveArtifacts
                 * method that cannot archive artifacts with absolute path
                 */
                script {
                    def artifact_dir = "/tmp/ANYSTOR-E/${env.JOB_NAME}/${env.BUILD_NUMBER}/rpmbuild"

                    sh "[ -d rpmbuild/RPMS ]  || mkdir -p rpmbuild/RPMS"
                    sh "[ -d rpmbuild/SRPMS ] || mkdir -p rpmbuild/SRPMS"

                    sh "cp -af ${artifact_dir}/RPMS  ${WORKSPACE}/rpmbuild"
                    sh "cp -af ${artifact_dir}/SRPMS ${WORKSPACE}/rpmbuild"
                }
            }
        }

        stage('Testing') {
            steps {
                echo 'Testing...'

                dir('/usr/jenkins') {
                    sh """ \
                        export SKIP_CONFIG=${params.skipConfig ? 1 : 0}
                        export SKIP_INIT=${params.skipInit ? 1 : 0}
                        export SKIP_MERGE_TEST=${params.skipTests ? 1 : 0}
                        bash +x scripts/mergetest.sh \
                            ${params.stopSlavesAfterJob ? "" : "NONSTOP"}
                    """
                }
            }
        }

        /*
        stage('Reporting') {
            steps {
                echo 'Collecting and summarizing test results...'
            }
        }

        stage('Deployment') {
            steps {
                echo 'Deploying...'
            }
        }
        */
    }

    post {
/*
        always {
            script {
                def resultIcon = ':question:'

                switch(currentBuild.currentResult) {
                    case "SUCCESS":
                        resultIcon = ':white_check_mark:'
                        break
                    case "FAILURE":
                        resultIcon = ':negative_squared_cross_mark:'
                        break
                    default:
                        resultIcon = ':anguished:'
                        break
                }

                addGitLabMRComment \
                    comment: """
$resultIcon GMS Build $currentBuild.currentResult

Build : [Jenkins [$env.JOB_NAME#$env.BUILD_NUMBER]]($env.BUILD_URL)
"""
            }
        }
*/

        success {
            archiveArtifacts artifacts: "rpmbuild/RPMS/x86_64/*.rpm", fingerprint: true
            archiveArtifacts artifacts: "rpmbuild/SRPMS/*.rpm", fingerprint: true
            archiveArtifacts artifacts: "other_job_rpm/*.rpm", fingerprint: true
//            archiveArtifacts artifacts: "unit.log", fingerprint: true
//            archiveArtifacts artifacts: "cover_db/*", fingerprint: true
//            junit allowEmptyResults: true, testResults: 'result.xml'
        }

        failure {
            script {
                currentBuild.description \
                    = (currentBuild.description \
                            ? "${currentBuild.description}<br/>\n" : '') \
                        + "<a href='http://192.168.3.4/jenkins_log/" \
                        + "${env.JOB_NAME}/${env.BUILD_NUMBER}/'>" \
                            + "Log for this build: ${env.JOB_NAME}/${env.BUILD_NUMBER}" \
                        + "</a>"
            }
        }
    }
}

