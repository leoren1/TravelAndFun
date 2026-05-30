// Jenkins pipeline: build the Flutter app and deploy it to a USB-connected iPhone.
// Trigger: SCM polling — Jenkins checks the GitHub repo every ~2 min and runs
// on new commits pushed to the tracked branch (and instantly via the pre-push
// git hook). The build runs against the freshly checked-out repository code.
pipeline {
  agent any

  triggers {
    pollSCM('H/2 * * * *')
  }

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  environment {
    PATH = "/Users/erentazegul/development/flutter/bin:/opt/homebrew/bin:${env.PATH}"
    LANG = 'en_US.UTF-8'
    LC_ALL = 'en_US.UTF-8'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Environment') {
      steps {
        sh 'flutter --version'
        sh 'flutter devices || true'
      }
    }

    stage('Build & Deploy to iPhone') {
      steps {
        sh 'chmod +x scripts/deploy_ios.sh'
        sh './scripts/deploy_ios.sh'
      }
    }
  }

  post {
    success { echo '✅ App built and installed on the iPhone.' }
    failure { echo '❌ Build/deploy failed — check the stage logs above.' }
  }
}
