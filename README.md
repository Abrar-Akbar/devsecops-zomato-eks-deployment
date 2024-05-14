# devsecops-zomato-eks-deployment
DevSecOps principles in action: Deploy a secure Zomato clone on Amazon EKS using GitHub Actions for CI/CD and Terraform for infrastructure provisioning

## Introduction

In the ever-evolving landscape of software development, the concept of DevSecOps has emerged as a crucial approach for integrating security practices seamlessly into the DevOps pipeline. By embedding security into every stage of the development lifecycle, DevSecOps ensures that software is not only delivered rapidly but also with robust security measures in place.

In this article, we will explore how to implement DevSecOps principles by deploying a Zomato clone application onto Amazon Elastic Kubernetes Service (EKS) using GitHub Actions for CI/CD and Terraform for infrastructure provisioning. The Zomato clone, a restaurant discovery and food ordering application, serves as an excellent example for demonstrating these principles in action.

By leveraging the power of cloud-native technologies like EKS, automation tools like Terraform, and integrating security best practices into the development process, we will demonstrate how to build a secure and scalable application deployment pipeline.

Let’s dive into the details of each component and understand how they work together to achieve our goal of deploying a Zomato clone securely and efficiently.

## Why GitHub Actions?

GitHub Actions is a powerful and versatile automation platform that seamlessly integrates with GitHub repositories, enabling developers to automate various tasks throughout the software development lifecycle. Here are several reasons why GitHub Actions is an excellent choice for implementing CI/CD in the context of deploying a Zomato clone in Amazon EKS:

1. **Native Integration**: GitHub Actions is tightly integrated with GitHub repositories, allowing developers to define workflows directly within the repository using YAML syntax. This native integration streamlines the CI/CD setup process and simplifies version control, making it easy to manage and maintain deployment pipelines alongside the application code.

2. **Flexibility and Customization**: GitHub Actions offers a high degree of flexibility and customization, allowing developers to define custom workflows tailored to their specific requirements. Whether it’s running tests, building Docker images, or deploying Kubernetes manifests, GitHub Actions provides a wide range of actions and triggers that can be combined to create sophisticated deployment pipelines.

3. **Scalability**: GitHub Actions scales seamlessly to accommodate projects of any size, from small open-source repositories to large enterprise applications. With built-in support for parallel and matrix workflows, GitHub Actions can efficiently handle complex CI/CD pipelines, enabling faster build and deployment times.

4. **Community Ecosystem**: GitHub Actions benefits from a vibrant community ecosystem, with a vast library of pre-built actions and workflows available in the GitHub Marketplace. Developers can leverage these community-contributed actions to automate common tasks and integrate with third-party services, reducing development time and effort.

5. **Security and Compliance**: GitHub Actions incorporates security best practices by providing features such as secrets management, environment protection, and workflow visualization. By leveraging these built-in security features, developers can ensure that sensitive information is securely handled throughout the CI/CD pipeline, reducing the risk of data breaches and compliance violations.

## GitHub Repo

[GitHub Repo Link](https://github.com/Abrar-Akbar/devsecops-zomato-eks-deployment.git)

## Steps

### Step 1: Launch GitHub Runner EC2 Instance

1. Clone the GitHub repository:
    ```
    git clone https://github.com/Abrar-Akbar/devsecops-zomato-eks-deployment.git

    ```
    Requirements:
    - Create an IAM user and store the access keys.
    - Create an S3 bucket.
    - Create a DynamoDB table with the name “Lock-Files”
    - Create a Key-Pair and download the Pem file.
    - Install AWS CLI and Terraform.
    - See Terraform and AWS CLI installation scripts in the provided documentation.

2. Run the below command and add your keys.
    ```
    aws configure
    ```

3. Do some modifications to the `backend.tf` file such as changing the bucket name and DynamoDB table.

4. Now, you have to replace the Pem File name with one that is already created on AWS in `variables.tfvars` file.

5. Initialize the backend by running the below command.
    ```
    terraform init
    ```

6. Run the below command to get the blueprint of what kind of AWS services will be created.
    ```
    terraform plan -var-file=variables.tfvars
    ```

7. Now, run the below command to create the infrastructure on AWS Cloud which will take 3 to 4 minutes maximum.
    ```
    terraform apply -var-file=variables.tfvars --auto-approve
    ```

    This will create an EC2 instance with the name “GitHub-Server”.

8. Connect to it using the Pem file.

### Step 2: Add a self-hosted runner to EC2

1. Go to GitHub and click on Settings –> Actions –> Runners.

2. Click on New self-hosted runner and select Linux and Architecture X64.

3. Then copy all the commands one by one displayed under Download section.

4. Then Configure the runner:
    - Name of runner: Provide a name.
    - Additional labels: Customize any other labels with commas.
    - Leave other as default.

### Step 3: Configure SonarQube Server

1. Access the SonarQube server on port 9000 of the created EC2 Server.

2. Login with “admin” as username and password.

3. Reset the password.

4. Click on manually (< > symbol).

5. Next, provide a name for your project and Branch name then click on setup.

6. Then Click on “With GitHub Actions”.

7. This will generate an overview of the Project and provide some instructions to integrate.

8. Now in GitHub Under your Repository Click on settings then Secrets and variables then Actions.

9. Now go back to Your SonarQube Dashboard then copy SONAR_TOKEN and click on Generate Token.

10. Click on continue and copy it.

11. Now go back to GitHub and paste the copied name for the secret and token:
    - Name: SONAR_TOKEN
    - Secret: Paste Your Token
    - Click on Add secret

12. Similarly, copy the Sonar host URL with its value.

13. Add them as another secret.

14. In SonarQube Dashboard and click on continue.

15. Click on “other”.

16. In GitHub create a file with this name and add the content by copying it:
    - sonar-project.properties

17. Now create a file in GitHub:
    - .github/workflows/build.yml  # you can use any name I am using deploy.yml

### Step 4: Configure Docker

1. Login to the Docker Hub and Click on Profile and then settings.

2. Click on “New Access Token”.

3. Provide a name for it then click on “Generate”.

4. Add the username as another secret:
    - Name: DOCKERHUB_USERNAME
    - Secret: your Docker username

5. Then Add copied Docker Hub token:
    - Name: DOCKERHUB_TOKEN
    - Secret: copied token

6. Add this script in .github/workflows/build.yml file:

    ```yaml
    name: Build, Analyze, scan

    on:
      push:
        branches:
          - main

    jobs:
      build-analyze-scan:
        name: Build
        runs-on: [self-hosted]
        steps:
          - name: Checkout code
            uses: actions/checkout@v2
            with:
              fetch-depth: 0  # Shallow clones should be disabled for a better relevancy of analysis
          - name: Build and analyze with SonarQube
            uses: sonarsource/sonarqube-scan-action@master
            env:
              SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
              SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
          - name: npm install dependency
            run: npm install
          - name: Trivy file scan
            run: trivy fs . > trivyfs.txt
          - name: Docker Build and push
            run: |
              docker build -t zomato .
              docker tag zomato abrarakbar623/zomato:latest
              docker login -u ${{ secrets.DOCKERHUB_USERNAME }} -p ${{ secrets.DOCKERHUB_TOKEN }}
              docker push abrarakbar623/zomato:latest
            env:
              DOCKER_CLI_ACI: 1
          - name: Image scan
            run: trivy image abrarakbar623/zomato:latest > trivyimage.txt

      deploy:
        needs: build-analyze-scan
        runs-on: [self-hosted]
        steps:
          - name: docker pull image
            run: docker pull abrarakbar623/zomato:latest
          - name: Image scan
            run: trivy image abrarakbar623/zomato:latest > trivyimagedeploy.txt
          - name: Deploy to container
            run: docker run -d --name zomato -p 3000:3000 abrarakbar623/zomato:latest
    ```

7. Let’s start the runner:
    ```
    ./run.sh
    ```

8. Commit the changes to GitHub. This will trigger a workflow under “Actions” in GitHub.

### Step 5: Create EKS Cluster

1. In the cloned Repo, Navigate to “EKS-TF” folder.

2. Initialize the backend by running the below command:
    ```
    terraform init
    ```

3. Run the below command to get the blueprint of what kind of AWS services will be created:
    ```
    terraform plan -var-file=variables.tfvars
    ```

4. Now, run the below command to create the infrastructure on AWS Cloud which will take 3 to 4 minutes maximum:
    ```
    terraform apply -var-file=variables.tfvars --auto-approve
    ```

    This will create an EKS Cluster on AWS.

[Continued...]

### Step 6: Configure Slack for Notifications

1. Go to your Slack channel, if you don’t have create one by following the instructions: [Slack Channel Creation Tutorial](https://youtu.be/9ZUy3oHNgh8?si=h-iI96BZDRsJixd-)

2. Go to Slack channel and create a channel for notifications.

3. Click on your Workspace then select Settings and Administration then click on Manage apps.

4. Under the right corner click on “Build”.

5. Click on “Create an App”.

6. Give a name for it and choose your workspace.

7. Click on Incoming Webhooks.

8. Activate Incoming Webhooks to “on”.

9. Click on “Add Webhook to Workspace”.

10. Choose the channel you have created and then click “Allow”.

11. Copy the Webhook URL.

12. Add it as a secret with the name “SLACK_WEBHOOK_URL”.

### Step 7: Deployment on EKS

1. Create a deployment-service.yaml file and add this content:

    ```yaml
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: zomato
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: zomato
      template:
        metadata:
          labels:
            app: zomato
        spec:
          containers:
          - name: zomato
            image: abrarakbar623/zomato:latest
            ports:
            - containerPort: 3000  # Use port 3000

    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: zomato-service
    spec:
      selector:
        app: zomato
      ports:
      - protocol: TCP
        port: 80          # Expose port 80
        targetPort: 3000
      type: LoadBalancer
    ```

2. Add these steps to the GitHub Workflow:

    ```yaml
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    [Continued...]

    name: Update kubeconfig
      run: aws eks --region us-east-1 update-kubeconfig --name Zomato-EKS-Cluster
    - name: Deploy to Kubernetes
      run: kubectl apply -f deployment-service.yml
    - name: Send a Slack Notification
      if: always()
      uses: act10ns/slack@v1
      with:
        status: ${{ job.status }}
        steps: ${{ toJson(steps) }}
        channel: '#githubactions-eks'
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}

3. Commit the changes to GitHub.

4. Now run this command for reference to ensure all resources are created:
    ```
    kubectl get all
    ```

5. This will create a Classic Load Balancer on AWS.

6. Copy and Paste the DNS name on your favorite browser.

7. Access the application on port 3000 of the EC2 instance. Note: Allow port 3000 in the Security Group of the EC2 server.

### Step 8: Clean Up Resources

This is very Simple in the Cloned Repo Run.

i. To destroy the EKS Cluster:

    ```bash
    cd EKS-TF/
    terraform destroy -var-file=variables.tfvars --auto-approve
    ```

ii. To destroy the GitHub EC2 Server:

    ```bash
    cd GitHub-Server-TF/
    terraform destroy -var-file=variables.tfvars --auto-approve
    ```

That's it! You've successfully deployed a Zomato clone application onto Amazon EKS using DevSecOps principles with GitHub Actions and Terraform.

        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ secrets.AWS_REGION }}

    -
