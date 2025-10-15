# CI/CD Integration Examples

This document provides complete examples for integrating the Linux Security Baseline InSpec profile into various CI/CD platforms.

## Table of Contents

1. [Jenkins Pipeline](#jenkins-pipeline)
1. [GitLab CI](#gitlab-ci)
1. [Azure DevOps](#azure-devops)
1. [GitHub Actions](#github-actions)
1. [Terraform Integration](#terraform-integration)
1. [Ansible Integration](#ansible-integration)

-----

## Jenkins Pipeline

### Jenkinsfile - Complete Example

```groovy
pipeline {
    agent any
    
    environment {
        INSPEC_VERSION = '5.22.3'
        TARGET_SERVER = credentials('target-server')
        SSH_KEY = credentials('ssh-private-key')
        REPORT_DIR = "${WORKSPACE}/inspec-reports"
    }
    
    stages {
        stage('Setup') {
            steps {
                script {
                    // Install InSpec if not already installed
                    sh '''
                        if ! command -v inspec &> /dev/null; then
                            curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec
                        fi
                        inspec --version
                    '''
                }
            }
        }
        
        stage('Clone InSpec Profile') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/yourusername/learning-inspec.git'
            }
        }
        
        stage('Run Security Compliance Scan') {
            steps {
                script {
                    sh """
                        mkdir -p ${REPORT_DIR}
                        
                        inspec exec . \
                            -t ssh://${TARGET_SERVER} \
                            -i ${SSH_KEY} \
                            --reporter cli \
                            --reporter json:${REPORT_DIR}/compliance-report.json \
                            --reporter html:${REPORT_DIR}/compliance-report.html \
                            --no-distinct-exit || true
                    """
                }
            }
        }
        
        stage('Analyze Results') {
            steps {
                script {
                    def report = readJSON file: "${REPORT_DIR}/compliance-report.json"
                    def failed = report.profiles[0].controls.findAll { it.results[0].status == 'failed' }.size()
                    def passed = report.profiles[0].controls.findAll { it.results[0].status == 'passed' }.size()
                    def total = passed + failed
                    def compliance_percentage = (passed / total * 100).round(2)
                    
                    echo "Compliance Score: ${compliance_percentage}%"
                    echo "Passed: ${passed}/${total}"
                    echo "Failed: ${failed}/${total}"
                    
                    // Set build status based on compliance threshold
                    if (compliance_percentage < 80) {
                        currentBuild.result = 'UNSTABLE'
                        error("Compliance below 80% threshold")
                    } else if (compliance_percentage < 95) {
                        currentBuild.result = 'UNSTABLE'
                        echo "Warning: Compliance below 95%"
                    }
                }
            }
        }
        
        stage('Publish Reports') {
            steps {
                publishHTML([
                    reportDir: "${REPORT_DIR}",
                    reportFiles: 'compliance-report.html',
                    reportName: 'InSpec Security Compliance Report',
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true
                ])
                
                archiveArtifacts artifacts: "${REPORT_DIR}/*.json", allowEmptyArchive: false
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        failure {
            emailext(
                subject: "Security Compliance Scan Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "Security compliance scan failed. Check the report at ${env.BUILD_URL}",
                to: 'security-team@example.com'
            )
        }
    }
}
```

-----

## GitLab CI

### .gitlab-ci.yml - Complete Example

```yaml
stages:
  - setup
  - scan
  - report
  - notify

variables:
  INSPEC_VERSION: "5.22.3"
  REPORT_DIR: "inspec-reports"
  COMPLIANCE_THRESHOLD: "90"

.inspec_base:
  image: chef/inspec:${INSPEC_VERSION}
  before_script:
    - mkdir -p ${REPORT_DIR}
    - inspec --version

install_inspec:
  stage: setup
  extends: .inspec_base
  script:
    - echo "InSpec ready"
  only:
    - merge_requests
    - main

security_scan_staging:
  stage: scan
  extends: .inspec_base
  script:
    - |
      inspec exec . \
        -t ssh://${STAGING_SERVER_USER}@${STAGING_SERVER_HOST} \
        -i ${SSH_PRIVATE_KEY} \
        --input-file inputs-staging.yml \
        --reporter cli \
        --reporter json:${REPORT_DIR}/staging-compliance.json \
        --reporter html:${REPORT_DIR}/staging-compliance.html \
        --no-distinct-exit || true
  artifacts:
    name: "staging-compliance-report-${CI_COMMIT_SHORT_SHA}"
    paths:
      - ${REPORT_DIR}/
    reports:
      junit: ${REPORT_DIR}/staging-compliance.json
    expire_in: 30 days
  only:
    - merge_requests
  environment:
    name: staging

security_scan_production:
  stage: scan
  extends: .inspec_base
  script:
    - |
      inspec exec . \
        -t ssh://${PROD_SERVER_USER}@${PROD_SERVER_HOST} \
        -i ${SSH_PRIVATE_KEY} \
        --input-file inputs-production.yml \
        --reporter cli \
        --reporter json:${REPORT_DIR}/prod-compliance.json \
        --reporter html:${REPORT_DIR}/prod-compliance.html \
        --no-distinct-exit || true
  artifacts:
    name: "production-compliance-report-${CI_COMMIT_SHORT_SHA}"
    paths:
      - ${REPORT_DIR}/
    expire_in: 90 days
  only:
    - main
  environment:
    name: production
  when: manual

analyze_compliance:
  stage: report
  image: python:3.9-slim
  script:
    - pip install jq
    - |
      TOTAL=$(jq '.profiles[0].controls | length' ${REPORT_DIR}/prod-compliance.json)
      PASSED=$(jq '[.profiles[0].controls[] | select(.results[0].status == "passed")] | length' ${REPORT_DIR}/prod-compliance.json)
      FAILED=$((TOTAL - PASSED))
      COMPLIANCE=$((PASSED * 100 / TOTAL))
      
      echo "Compliance Score: ${COMPLIANCE}%"
      echo "Total Controls: ${TOTAL}"
      echo "Passed: ${PASSED}"
      echo "Failed: ${FAILED}"
      
      if [ ${COMPLIANCE} -lt ${COMPLIANCE_THRESHOLD} ]; then
        echo "ERROR: Compliance ${COMPLIANCE}% is below threshold ${COMPLIANCE_THRESHOLD}%"
        exit 1
      fi
  dependencies:
    - security_scan_production
  only:
    - main

notify_security_team:
  stage: notify
  image: curlimages/curl:latest
  script:
    - |
      curl -X POST ${SLACK_WEBHOOK_URL} \
        -H 'Content-Type: application/json' \
        -d "{
          \"text\": \"Security Compliance Scan Complete\",
          \"attachments\": [{
            \"color\": \"good\",
            \"text\": \"Pipeline: ${CI_PIPELINE_URL}\nCommit: ${CI_COMMIT_SHORT_SHA}\"
          }]
        }"
  only:
    - main
  when: on_success
```

-----

## Azure DevOps

### azure-pipelines.yml - Complete Example

```yaml
trigger:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  inspectVersion: '5.22.3'
  reportDirectory: '$(Build.ArtifactStagingDirectory)/inspec-reports'

stages:
  - stage: Setup
    displayName: 'Setup InSpec'
    jobs:
      - job: InstallInSpec
        displayName: 'Install InSpec'
        steps:
          - script: |
              curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec
              inspec --version
            displayName: 'Install InSpec'

  - stage: SecurityScan
    displayName: 'Security Compliance Scan'
    dependsOn: Setup
    jobs:
      - job: RunInSpec
        displayName: 'Run InSpec Profile'
        steps:
          - checkout: self
          
          - task: Bash@3
            displayName: 'Create Report Directory'
            inputs:
              targetType: 'inline'
              script: 'mkdir -p $(reportDirectory)'
          
          - task: Bash@3
            displayName: 'Execute InSpec Security Scan'
            inputs:
              targetType: 'inline'
              script: |
                inspec exec $(Build.SourcesDirectory) \
                  -t ssh://$(targetUsername)@$(targetHost) \
                  -i $(sshKeyPath) \
                  --input-file $(Build.SourcesDirectory)/inputs.yml \
                  --reporter cli \
                  --reporter json:$(reportDirectory)/compliance-report.json \
                  --reporter html:$(reportDirectory)/compliance-report.html \
                  --no-distinct-exit || true
            env:
              targetHost: $(TARGET_HOST)
              targetUsername: $(TARGET_USERNAME)
              sshKeyPath: $(SSH_KEY_PATH)
          
          - task: PowerShell@2
            displayName: 'Analyze Compliance Results'
            inputs:
              targetType: 'inline'
              script: |
                $reportPath = "$(reportDirectory)/compliance-report.json"
                $report = Get-Content $reportPath | ConvertFrom-Json
                
                $total = $report.profiles[0].controls.Count
                $passed = ($report.profiles[0].controls | Where-Object { $_.results[0].status -eq "passed" }).Count
                $failed = $total - $passed
                $compliance = [math]::Round(($passed / $total) * 100, 2)
                
                Write-Host "Compliance Score: $compliance%"
                Write-Host "Total Controls: $total"
                Write-Host "Passed: $passed"
                Write-Host "Failed: $failed"
                
                if ($compliance -lt 80) {
                    Write-Host "##vso[task.logissue type=error]Compliance below 80% threshold"
                    exit 1
                } elseif ($compliance -lt 95) {
                    Write-Host "##vso[task.logissue type=warning]Compliance below 95%"
                }
          
          - task: PublishBuildArtifacts@1
            displayName: 'Publish InSpec Reports'
            inputs:
              PathtoPublish: '$(reportDirectory)'
              ArtifactName: 'InSpec-Compliance-Reports'
              publishLocation: 'Container'
          
          - task: PublishTestResults@2
            displayName: 'Publish Test Results'
            inputs:
              testResultsFormat: 'JUnit'
              testResultsFiles: '$(reportDirectory)/*.json'
              testRunTitle: 'InSpec Security Compliance'

  - stage: Notify
    displayName: 'Notifications'
    dependsOn: SecurityScan
    condition: always()
    jobs:
      - job: SendNotification
        displayName: 'Send Compliance Report'
        steps:
          - task: SendEmail@1
            inputs:
              To: 'security-team@example.com'
              Subject: 'Security Compliance Report - Build $(Build.BuildNumber)'
              Body: |
                Security compliance scan completed.
                
                Build: $(Build.BuildNumber)
                Branch: $(Build.SourceBranch)
                Status: $(Agent.JobStatus)
                
                View detailed report: $(System.CollectionUri)$(System.TeamProject)/_build/results?buildId=$(Build.BuildId)
```

-----

## GitHub Actions

### .github/workflows/inspec-security-scan.yml

```yaml
name: InSpec Security Compliance Scan

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * 1'  # Weekly scan every Monday at 2 AM

jobs:
  security-scan:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3
      
      - name: Setup InSpec
        run: |
          curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec
          inspec --version
      
      - name: Create Reports Directory
        run: mkdir -p inspec-reports
      
      - name: Run InSpec Security Scan
        env:
          TARGET_HOST: ${{ secrets.TARGET_HOST }}
          TARGET_USER: ${{ secrets.TARGET_USER }}
          SSH_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
        run: |
          echo "${SSH_KEY}" > /tmp/ssh_key
          chmod 600 /tmp/ssh_key
          
          inspec exec . \
            -t ssh://${TARGET_USER}@${TARGET_HOST} \
            -i /tmp/ssh_key \
            --input-file inputs.yml \
            --reporter cli \
            --reporter json:inspec-reports/compliance-report.json \
            --reporter html:inspec-reports/compliance-report.html \
            --no-distinct-exit || true
      
      - name: Analyze Compliance
        id: analyze
        run: |
          TOTAL=$(jq '.profiles[0].controls | length' inspec-reports/compliance-report.json)
          PASSED=$(jq '[.profiles[0].controls[] | select(.results[0].status == "passed")] | length' inspec-reports/compliance-report.json)
          FAILED=$((TOTAL - PASSED))
          COMPLIANCE=$((PASSED * 100 / TOTAL))
          
          echo "total=${TOTAL}" >> $GITHUB_OUTPUT
          echo "passed=${PASSED}" >> $GITHUB_OUTPUT
          echo "failed=${FAILED}" >> $GITHUB_OUTPUT
          echo "compliance=${COMPLIANCE}" >> $GITHUB_OUTPUT
          
          echo "### Security Compliance Report" >> $GITHUB_STEP_SUMMARY
          echo "- Compliance Score: **${COMPLIANCE}%**" >> $GITHUB_STEP_SUMMARY
          echo "- Total Controls: ${TOTAL}" >> $GITHUB_STEP_SUMMARY
          echo "- Passed: ${PASSED}" >> $GITHUB_STEP_SUMMARY
          echo "- Failed: ${FAILED}" >> $GITHUB_STEP_SUMMARY
      
      - name: Upload Reports
        uses: actions/upload-artifact@v3
        with:
          name: inspec-compliance-reports
          path: inspec-reports/
          retention-days: 30
      
      - name: Check Compliance Threshold
        if: steps.analyze.outputs.compliance < 90
        run: |
          echo "::error::Compliance score ${COMPLIANCE}% is below 90% threshold"
          exit 1
      
      - name: Comment PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const compliance = '${{ steps.analyze.outputs.compliance }}';
            const passed = '${{ steps.analyze.outputs.passed }}';
            const total = '${{ steps.analyze.outputs.total }}';
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## InSpec Security Compliance Report\n\n` +
                    `🔒 Compliance Score: **${compliance}%**\n` +
                    `✅ Passed: ${passed}/${total}\n` +
                    `❌ Failed: ${total - passed}/${total}`
            })
```

-----

## Terraform Integration

### main.tf - Null Resource with InSpec

```hcl
resource "null_resource" "inspec_scan" {
  depends_on = [
    aws_instance.web_server
  ]
  
  triggers = {
    instance_id = aws_instance.web_server.id
    timestamp   = timestamp()
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      # Wait for instance to be ready
      sleep 60
      
      # Run InSpec scan
      inspec exec ./inspec-profile \
        -t ssh://admin@${aws_instance.web_server.public_ip} \
        -i ${var.ssh_private_key_path} \
        --reporter cli \
        --reporter json:compliance-${aws_instance.web_server.id}.json
    EOT
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Cleaning up compliance reports'"
  }
}

output "compliance_report" {
  value = "Compliance report generated: compliance-${aws_instance.web_server.id}.json"
}
```

-----

## Ansible Integration

### playbook-with-inspec.yml

```yaml
---
- name: Deploy and Validate Security Compliance
  hosts: all
  become: yes
  
  vars:
    inspec_profile_path: "./learning-inspec"
    report_dir: "/tmp/inspec-reports"
  
  tasks:
    - name: Install InSpec
      shell: |
        curl https://omnitruck.chef.io/install.sh | bash -s -- -P inspec
      args:
        creates: /usr/bin/inspec
    
    - name: Create Report Directory
      file:
        path: "{{ report_dir }}"
        state: directory
        mode: '0755'
    
    - name: Run InSpec Profile
      shell: |
        inspec exec {{ inspec_profile_path }} \
          --reporter cli \
          --reporter json:{{ report_dir }}/compliance-report.json \
          --reporter html:{{ report_dir }}/compliance-report.html
      register: inspec_result
      ignore_errors: yes
    
    - name: Fetch Compliance Reports
      fetch:
        src: "{{ report_dir }}/{{ item }}"
        dest: "./reports/{{ inventory_hostname }}-{{ item }}"
        flat: yes
      loop:
        - compliance-report.json
        - compliance-report.html
    
    - name: Parse Compliance Results
      shell: |
        jq -r '.profiles[0].controls[] | select(.results[0].status == "failed") | .title' \
          {{ report_dir }}/compliance-report.json
      register: failed_controls
      changed_when: false
    
    - name: Display Failed Controls
      debug:
        msg: "{{ failed_controls.stdout_lines }}"
      when: failed_controls.stdout_lines | length > 0
    
    - name: Fail if Critical Controls Failed
      fail:
        msg: "Critical security controls failed"
      when: 
        - inspec_result.rc != 0
        - failed_controls.stdout_lines | length > 5
```

-----

## Best Practices for CI/CD Integration

1. **Always use `--no-distinct-exit`** in CI/CD to prevent build failures during reporting
1. **Store reports as artifacts** for compliance tracking and auditing
1. **Set compliance thresholds** appropriate for your environment
1. **Schedule regular scans** (daily/weekly) in addition to deployment scans
1. **Use waivers** for accepted risks with proper documentation
1. **Separate staging and production configs** using input files
1. **Send notifications** to security teams on failures
1. **Track compliance trends** over time using reporting tools

-----

## Author

**Willem van Heemstra**  

Demonstrating real-world InSpec integration in DevSecOps workflows
