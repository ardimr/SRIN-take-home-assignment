<br />
<div align="center">
  <!-- <a href="https://github.com/othneildrew/Best-README-Template">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a> -->

  <h3 align="center">SRIN Take Home Assignment</h3>

  <p align="center">
    The documentation of the solution implementation for SRIN Take Home Assignment
    <br />
   
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#dotnet">Dotnet</a>
    </li>
    <li>
      <a href="#docker">Docker</a>
      <ul>
        <li><a href="#build-docker-image">Build Docker Image</a></li>
        <li><a href="#push-docker-image">Push Docker Image</a></li>
        <li><a href="#run-with-docker">Run with Docker</a></li>
        <li><a href="#run-with-docker-compose">Run with Docker Compose</a></li>
      </ul>
    </li>
    <li>
      <a href="#kubernetes">Kubernetes</a>
      <ul>
        <li><a href="#setup-the-cluster">Setup The Cluster</a></li>
        <li><a href="#create-namespace">Create Namespace</a></li>
        <li><a href="#create-deployment">Create Deployment</a></li>
        <li><a href="#create-service">Create Service</a></li>
        <li><a href="#create-ingress">Create Ingress</a></li>
      </ul>
    </li>
    <li>
      <a href="#aws">AWS</a>
      <ul>
        <li><a href="#setup-vpc">Setup VPC</a></li>
        <li><a href="#setup-aws-eks-cluster">Setup AWS EKS Cluster</a></li>
        <li><a href="#connect-to-the-cluster">Connect to the cluster</a></li>
        <li><a href="#create-nodes">Create Nodes</a></li>
        <li><a href="#setup-aws-load-balancers">Setup AWS Load Balancers</a></li>
        <li><a href="#deploy-application">Deploy Application</a></li>
        <li><a href="#list-resources">List Resources</a></li>
        <li><a href="#access-the-deployed-application">Access the deployed application</a></li>
      </ul>
    </li>

  </ol>
</details>

### Dotnet
----
**Requirements: Create a simple GRPC server using `.NET` that simply return `Hello, World!`.**

1. **Initialize new project**
    
    NET CLI for [ASP.NET](http://asp.net/) Core development functions is used to create a new gRPC project.  
    
    ```bash
    dotnet new grpc -o GrpcHelloWorld
    ```
    
2. **Open the project and modify the .proto file**
    
    ```protobuf
    syntax = "proto3";
    
    option csharp_namespace = "GrpcHelloWorld";
    
    package greet;
    
    // The greeting service definition.
    service Greeter {
      // Say Hello Worl
      rpc SayHelloWorld (google.protobuf.Empty) returns (HelloWorldReply);
    }
    
    // The request message containing the user's name.
    message HelloWorldRequest {
      string name = 1;
    }
    
    // The response message containing the greetings.
    message HelloWorldReply {
      string message = 1;
    }
    ```
    
    - This file defines a gRPC service named greeter
    - The service has one unary method, `SayHelloWorld` , which doesn’t require any input parameters (**`google.protobuf.Empty`**) and returns a **`HelloWorldReply`**
    - One message type is defined, **`HelloWorldReply`**, which contains the hello world response.
3. Service Implementation
    
    ```csharp
    using Google.Protobuf.WellKnownTypes;
    using Grpc.Core;
    using GrpcHelloWorld;
    
    namespace GrpcHelloWorld.Services;
    
    public class GreeterService : Greeter.GreeterBase
    {
        private readonly ILogger<GreeterService> _logger;
        public GreeterService(ILogger<GreeterService> logger)
        {
            _logger = logger;
        }
    
        public override Task<HelloWorldReply> SayHelloWorld(Empty request, ServerCallContext context)
        {
            return Task.FromResult(new HelloWorldReply
            {
                Message = "Hello, World!"
            });
        }
    }
    
    ```
    
4. Modify the desired applicationUrl in the `launchSetting.json` . In my case, I set my applicationURL to `http://localhost:8080`.
    
    ```protobuf
    ﻿{
      "$schema": "http://json.schemastore.org/launchsettings.json",
      "profiles": {
        "http": {
          "commandName": "Project",
          "dotnetRunMessages": true,
          "launchBrowser": false,
          "applicationUrl": "http://localhost:8080",
          "environmentVariables": {
            "ASPNETCORE_ENVIRONMENT": "Development"
          }
        },
        "https": {
          "commandName": "Project",
          "dotnetRunMessages": true,
          "launchBrowser": false,
          "applicationUrl": "https://localhost:443;http://localhost:8080",
          "environmentVariables": {
            "ASPNETCORE_ENVIRONMENT": "Development"
          }
        }
      }
    }
    ```
    
5. Build and Run the gRPC server
    
    ```bash
    dotnet run
    ```
    
    ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled.png)
    
6. Test using grpcurl
    
    ```bash
    grpcurl -plaintext -import-path Protos/ -proto greet.proto localhost:8080 greet.Greeter/SayHelloWorld
    ```
    
    Since I didn’t set my gRPC server to use reflection, I need to specify the location of the profo file.
    
    ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%201.png)
    
7. Test using Postman
    
    ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%202.png)
    

### Docker
---
**Requirements:** 

- Create a Dockerfile for the code  in the previous assignment
- Push the image to Docker repository
- Run the container using Docker compose

#### **Build Docker Image**
---
  1. **Create the Dockerfile**
      
      ```docker
      # Implemented multi-stage builds to minimize the image size
      FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-env
      WORKDIR /App
      EXPOSE 80
      
      # Copy everything
      COPY . ./
      # Restore as distinct layers
      RUN dotnet restore
      # Build and publish a release
      RUN dotnet publish -c Release -o out
      
      # Build runtime image
      FROM mcr.microsoft.com/dotnet/aspnet:8.0
      WORKDIR /App
      COPY --from=build-env /App/out .
      ENTRYPOINT ["dotnet", "GrpcHelloWorld.dll"]
      ```
      
      Multi-stage builds are used to create smaller and more efficient Docker images. This can be achieved by separating the build environment from the runtime environment. The build environment contains the required tools, resources, and dependencies to compile and build the application, while the runtime environment only contains the necessary components to run the application. The runtime environment is used as the final Docker image. This separation helps reducing the size of final image, as it doesn't inclue build tools.
      
  2. **Build the image**
      
      ```bash
      EXPORT TAG=dev
      docker build -t ardimr/grpc-hello-world:$(TAG) .
      ```

      This command build an image with a specific name and tag `ardimr/grpc-hello-world:dev` using the Dockerfile in the project directory.
#### **Push Docker Image**
---          

  Once the docker image can be run properly, push the image to a container registry
  
  ```bash
  EXPORT TAG=dev
  docker image push ardimr/grpc-hello-world:$(TAG)
  ```
  This command push the `ardimr/grpc-hello-world:dev` to my docker hub. This is the default configuration. In the `AWS` section, I pushed the image to my `AWS ECR`.
    
#### **Run with Docker**
---
    
  1. **Run the container**
      ```bash
      docker container run --rm -d -p 8080:8080 --name grpc-hello-world ardimr/grpc-hello-world:$TAG
      ```
      This command runs a new container named **`grpc-hello-world`** from the **`ardimr-hello-world:dev`** image. The container runs in the background with port `8080` exposed, allowing us to access the gRPC server through this port. Once the container stops, it will be automatically deleted.
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%203.png)
      
  2. **Access the application**
      ```bash
      grpcurl -plaintext -import-path Protos/ -proto greet.proto localhost:8080 greet.Greeter/SayHelloWorld
      ```
        
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%204.png)

#### **Run with Docker Compose**
---
  1. `docker-compose.yml`
      
      ```yaml
      services:
        grpc-server:
          image: ardimr/grpc-hello-world:dev
          container_name: grpc-hello-world
          ports:
            - 8080:8080
          networks:
            - grpc-hello-world-network
        
      networks:
        grpc-hello-world-network:
          driver: bridge
      ```
      
      This Docker Compose configration defines a `grpc-server` service that runs a container named `grpc-hello-world` using the `ardimr/grpc-hello-world:dev` image. The container runs with the port `8080` exposed, enabling access to the gRPC server through this port. This service runs with a custom network named `grpc-hello-world-network` which uses the bridge driver. Since the container doesn’t require volume mounting, no volume is defined.
      
  2. **Run the service**
      
      ```bash
      docker-compose up -d
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%205.png)
      
  3. **Access the application**
      
      ```bash
      grpcurl -plaintext -import-path Protos/ -proto greet.proto localhost:8080 greet.Greeter/SayHelloWorld
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%206.png)
      
  4. **Stop the service**
      
      ```bash
      docker-compose down
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%207.png)
        

### Kubernetes
----
**Requirements:**

- Deploy app in Kubernetes (using minimum of 2 pods)
- List pods and services
- Access the deployed App using tools like grpcurl

#### Setup the cluster
---
  Minikube is used as the local Kubernetes cluster.
  
  ```bash
  minikube start
  ```
  
  ```bash
  minikube ip
  ```
  
  ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%208.png)
    
#### Create namespace
---
  ```bash
  kubectl create namespace local
  ```
  
  ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%209.png)

#### Create Deployment
---    
  1. `deployment.yaml`
      
      ```yaml
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: backend
        namespace: local
        labels:
          app: backend
          tier: backend
      spec:
        replicas: 2
        selector:
          matchLabels:
            app: backend
            tier: backend
        template:
          metadata:
            labels:
              app: backend
              tier: backend
          spec:
            containers:
            - name: grpc-hello-world
              image: ardimr/grpc-hello-world:dev
              ports:
              - containerPort: 8080
      ```
      
      This deployment creates two pods running the container named `grpc-hello-world` from the `ardimr/grpc-hello-world:dev` image in the `development` namespace. Each pod will have a container exposing port `8080` . The pods are labeled with `app: backend` and `tier: backend` for identification purpose.
      
  2. **Apply the deployment**
      
      ```bash
      kubectl apply -f deployment.yaml
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2010.png)
      
  3. **List the running deployment**
      
      ```bash
      kubectl get deployment -n local
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2011.png)
      
  4. **List the pods**
      
      List the pods within the namespace `local`
      
      ```bash
      kubectl get pods -n local
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2012.png)
      
  
  <aside>
  ⚠️ **Delete the deployment**
  
  ```bash
  kubectl delete -f deployment.yaml
  ```
  This is the command to delete the deployment.
  </aside>

#### **Create Service**
---  
  1. `service.yaml`
      
      ```yaml
      apiVersion: v1
      kind: Service
      metadata:
        name: backend-service
        namespace: local
      spec:
        selector:
          app: backend
        ports:
          - protocol: TCP
            port: 8888
            targetPort: 8080
        type: LoadBalancer
      ```
      
      This service will route traffic to pods with label `app: backend` in the `development` namespace. Since the `type` is not specified, it defaults to `ClusterIP`, which exposes the service on a cluster-internal IP. The service has port `8888` exposed, allowing both internal and external access to the backend application through port 8888 without needing to know the individual pod IPs.
      
  2. **Run `minikube tunnel`**
      
      Before applying the service, it is required to run `minikube tunnel` command. The `minikube tunnel` command is used to expose a service running within the `Minikube` environment to the host machine. Minikube, basically creates a a created virtual machine to host the cluster. Services running inside the virtual machine are not directly accessible from the host machine. The `minikub tunnel` command creates a network route that allow traffic from the host machine to reach the services running inside the Minikube envirnment. 

      ```bash
      minikube tunnel
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2013.png)
      
  3. **Apply service by running the following command**
      
      ```bash
      kubectl apply -f backend-service.yaml
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2014.png)
      
  4. **List the services**
      
      List the services within the namespace `local`
      
      ```bash
      kubectl get svc -n local
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2015.png)

      The service can be accessed through `127.0.0.1` address since the `minikube tunnel` is running.
      
  5. **Call the gRPC server**
      - using grpcurl
          
          ```bash
          grpcurl -plaintext -import-path Protos/ -proto greet.proto 127.0.0.1:8888 greet.Greeter/SayHelloWorld
          ```
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2016.png)
          
      - Using postman
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2017.png)
          
  
  <aside>
  ⚠️ **Delete the service**
  
  ```bash
  kubectl delete -f service.yaml
  ```
  This is the command to delete the service.
  </aside>

#### **Create Ingress**
---  
    
  Even though using service type load balancer works properly, I try to employ `Ingress Nginx` to manage the traffic to the service. To implement this resource, I need to modify the service type from `Load Balancer` to `ClusterIP` .
  
  1. `service.yaml`
      
      ```bash
      apiVersion: v1
      kind: Service
      metadata:
        name: backend-service
        namespace: local
      
      spec:
        selector:
          app: backend
        ports:
          - protocol: TCP
            port: 8888
            targetPort: 8080
        type: ClusterIP
      ```
      
      I deleted the old service and redeploy this servive.
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2018.png)
      
  2. `ingress.yaml`
      
      ```yaml
      apiVersion: networking.k8s.io/v1
      kind: Ingress
      metadata:
        name: grpc-ingress
        namespace: local
        annotations:
          nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
      spec:
        ingressClassName: nginx
        rules:
        -  http:
            paths:
            - path: /
              pathType: Prefix
              backend:
                service:
                  name: backend-service
                  port:
                    number: 8888
      ```
      
  
  3. Enable ingress add-on on minikube by running the following command
      ```bash
      minikube addons enable ingress
      ```
  
      This command allows the external access to ingress from a provided port. In my case, it is `127.0.0.1`.
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2019.png)
  
  4. Since i am running minikube using docker-driver.  I need to run the tunnel command to provide an external IP.
      
      ```bash
      minikube tunnel
      ```
      
      Minikube create a tunnel where i can access the resource within the minikube using `127.0.0.1` port.
      
  5. Apply the ingress by running the following command:
      
      ```bash
      kubectl apply -f ingress.yaml
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2020.png)
      
  6. Access the application
      - Using grpcurl
          
          ```bash
          grpcurl -plaintext -import-path Protos/ -proto greet.proto 127.0.0.1:80 greet.Greeter/SayHelloWorld
          ```
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2021.png)
          
      - Using postman
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2022.png)
          
  
  <aside>
  ⚠️ Delete the ingress
  
  ```bash
  kubectl delete -f ingress.yaml
  ```
  This the command to delete the Ingress.
  </aside>
    
#### List used resources
---   
  ```bash
  kubectl get all -n local
  ```
  
  ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2023.png)
    

### AWS
---

**Requirements**
- Create a new VPC
- Create an EKS Cluster
- Deploy application in EKS
- List all the resources
- Access the deployed application

![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2024.png)

The diagram above illustrates the architecture for deploying the gRPC server pods using `Amazon EKS` within a Virtual Private Cloud (VPC) in the `ap-southeast-3` region. Here’s the detailed components breakdown:

1. **Internet Gateway**
    - Provides a connection between the VPC and the internet, allowing the gRPC client to communicate with resources inside the VPC
2. **Multiple Availability Zones**
    - The `Amazon EKS` cluster requires at least 2 available zones. In this assignment, `ap-southeast-3a` and `ap-southeast-3b` is selected.
    - Each available zone has 1 public subnet and 1 private subnet
3. **Public Subnets**
    - Each public subnet contains a NAT gateway, which enables instances in the private subnets to connect to the internet without being exposed directly.
4. **Private Subnets**
    - While employing public subnets suffices the requirement to deploy gRPC server in the EKS, it’s recommended to use private subnets to enhance the security.
    - Each private subnet hosts a Node (EC2 instance) that run the gRPC server pod
5. **Ingress**
    - Manages external access to the services within the cluster.
6. **Application Service**
    - This service will route traffic to pods without needinh to know the individual pod IPs.
7. **Node Group**
    - A group of EC2 instances that host the gRPC server pods. The node group can autoscale the number of instance within the group.

Before diving into the architecture implementation, In order to follow The principle of least privilege, I created a non-root user account with granted permissions to work with Amazon EKS IAM roles, service linked roles, AWS CloudFormation, a VPC, and related resources as presented in this [reference](https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonelastickubernetesservice.html).

```bash
aws sts get-caller-identity
```

![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2025.png)

The steps to implement the architecture is described as follows:

#### **Setup VPC**
---
  1. **Create a new VPC**
      
      Create a new VPC with CIDR block **`10.0.0.0/24`**. The CIDR block represents a range of IP addresses from **`10.0.0.0`** to **`10.0.0.255`**. Hence, the VPC will have 256 available IP addresses.
      
      ```bash
      aws ec2 create-vpc --cidr-block 10.0.0.0/24 --query Vpc.VpcId --output text
      ```
      
      - VPC ID: vpc-0387891a97329593e
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2026.png)
      
  2. **Tag the VPC**
      
      Add tag to the new VPC by using the create-tags command. It will be really helpful when there are multiple VPCs.
      
      ```bash
      aws ec2 create-tags --resources vpc-0387891a97329593e --tags Key=Name,Value=dev-VPC
      ```
      
  3. **Check the created VPC**
      
      ```bash
      aws ec2 describe-vpcs --filters "Name=tag:Name,Values=dev-VPC"
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2027.png)
      
      Once the VPC is successfully created, the VPC can be seen on the console.
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2028.png)
      
  4. **Create Subnets**
      
      AWS EKS requires at least two subnets with different availibility zones. Since the created VPC has 256 available address, I create 4 subnets (each 64 addresses) in two different availability zones:
      
      - (ap-southeast-3a) public-subnet-1 :  `10.0.0.0/26`
      - (ap-southeast-3a) private-subnet-1 : `10.0.0.64/26`
      - (ap-southeast-3b) public-subnet-2 : `10.0.0.128/26`
      - (ap-southeast-3b) private-subnet-2 : `10.0.0.192/26`
      
      ```bash
      # Create Subnet 1
      aws ec2 create-subnet --vpc-id vpc-0387891a97329593e --cidr-block 10.0.0.0/26 --availability-zone ap-southeast-3a --query Subnet.SubnetId --output text
      # Create Subnet 2
      aws ec2 create-subnet --vpc-id vpc-0387891a97329593e --cidr-block 10.0.0.64/26 --availability-zone ap-southeast-3a --query Subnet.SubnetId --output text
      # Create Subnet 3
      aws ec2 create-subnet --vpc-id vpc-0387891a97329593e --cidr-block 10.0.0.128/26 --availability-zone ap-southeast-3b --query Subnet.SubnetId --output text
      # Create Subnet 4
      aws ec2 create-subnet --vpc-id vpc-0387891a97329593e --cidr-block 10.0.0.192/26 --availability-zone ap-southeast-3b --query Subnet.SubnetId --output text
      ```
      
      Add tag to the new subnets by using the create-tags command. This will help us in searching or filtering the subnets.
      
      ```bash
      aws ec2 create-tags --resources subnet-044888367fdde3ab0 --tags Key=Name,Value=dev-public-subnet-1
      aws ec2 create-tags --resources subnet-0eb7d5ae19b09c537 --tags Key=Name,Value=dev-private-subnet-1
      aws ec2 create-tags --resources subnet-0ddf48ee197d61e53 --tags Key=Name,Value=dev-public-subnet-2
      aws ec2 create-tags --resources subnet-0fe1ec9f930e2363f --tags Key=Name,Value=dev-private-subnet-2
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2029.png)
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2030.png)
      
  5. **Set auto manage IP Address for public subnets**
      
      Apply the auto manage IP address to give public addresses for `dev-public-subnet-1` and `dev-public-subnet-2` .
      
      ```bash
      aws ec2 modify-subnet-attribute --subnet-id subnet-044888367fdde3ab0 --map-public-ip-on-launch
      aws ec2 modify-subnet-attribute --subnet-id subnet-0ddf48ee197d61e53 --map-public-ip-on-launch
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2031.png)
      
  6. **Setup Internet Gateway**
      
      Without an `internet gateway,` instances in the public subnets would be isolated and unable to interact with the internet. The `internet gateway` allows these instances to use their public IP addresses to communicate with the internet.
      
      1. Create internet gateway
          
          ```bash
          aws ec2 create-internet-gateway \
              --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=dev-igw}]'
          ```
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2032.png)
          
      2. Attach internet gateway to VPC
          
          ```bash
          aws ec2 attach-internet-gateway	--internet-gateway-id igw-0e32a00c59d66a5f6 	--vpc-id vpc-0387891a97329593e
          ```
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2033.png)
          
      3. Create route tables
          
          ```bash
          aws ec2 create-route-table --vpc-id vpc-0387891a97329593eD --query 'RouteTable.RouteTableId' --output text
          aws ec2 create-route --route-table-id rtb-0ed8abc1a9ca31330 --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
          ```
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2034.png)
          
      4. Associate route tables with public subnets
          
          ```bash
          export ROUTE_TABLE_ID=rtb-0ed8abc1a9ca31330
          # Public Subnet 1
          aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id subnet-044888367fdde3ab0
          #Public Subnet 2
          aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id subnet-0ddf48ee197d61e53
          ```
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2035.png)
          
  7. **Setup NAT Gateway**
      
      The instances in the private subnet cannot access the internet by default. Hence, NAT Gateway is created to enable instances in a private subnet to connect to the internet or other AWS services while preventing the internet from initiating connections to those instances.
      
      1. Get the allocation-id
          
          ```bash
          aws ec2 allocate-address --domain vpc
          ```
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2036.png)
          
      2. Create the NAT Gateway
          
          ```bash
              aws ec2 create-nat-gateway \
                  --subnet-id subnet-044888367fdde3ab0 \
                  --allocation-id eipalloc-088bd70ce339207a5
          ```
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2037.png)
          
      3. List the existing route table
          
          ```bash
          aws ec2 describe-route-tables --filters "Name=tag:Name,Values=PrivateRouteTable" --query "RouteTables[*].RouteTableId" --output text
          ```
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2038.png)
          
      4. Add route
          
          ```bash
          aws ec2 create-route --route-table-id rtb-06aef84a909104674 --destination-cidr-block 0.0.0.0/0 --nat-gateway-id nat-0a50d22520092195b
          ```
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2039.png)
          
      5. Associate the Route Table with Subnets
          
          ```bash
          aws ec2 associate-route-table --route-table-id rtb-06aef84a909104674 --subnet-id subnet-0eb7d5ae19b09c537
          ```
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2040.png)
          
      6. Since there are 2 available zones, I need to repeat the steps a-e for the private subnet 2
      
      The crated NAT gateways can be seen on the console
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2041.png)
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2042.png)
        
#### **Setup AWS EKS Cluster**
---
  1. **Create a cluster IAM role and attach the required Amazon EKS IAM managed policy to it.**
      1. Create a Role
          
          ```bash
          aws iam create-role \
            --role-name ardimrEKSClusterRole\
            --assume-role-policy-document file://"eks-cluster-role-trust-policy.json"
          
          ```
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2043.png)
          
      2. Attach The Role Policy.
          
          ```bash
          aws iam attach-role-policy \
            --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy \
            --role-name ardimrEKSClusterRole
          
          ```
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2044.png)
          
  2. **Create New EKS Cluster**
      
      ```bash
      aws eks create-cluster \
        --name dev-eks-cluster \
        --role-arn arn:aws:iam::616247551677:role/ardimrEKSClusterRole\
        --resources-vpc-config subnetIds=subnet-0eb7d5ae19b09c537,subnet-0fe1ec9f930e2363f
      ```
      
      The command above creates a new `EKS` cluster with name `dev-eks-cluster` and assigns the subnets with the created`private-subnet-1` and `private-subnet-2` .
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2045.png)
      
      Once the setup is complete, we can see the created cluster on the AWS Console.
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2046.png)
        
#### **Connect to the cluster**
---
  To connect the local computer with the created cluster, I need to update the my Kubernetes config by running this command:
  
  ```bash
  aws eks update-kubeconfig --region ap-southeast-3 --name dev-eks-cluster
  
  ```
  
  ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2047.png)
  
  Test the configuration
  
  ```bash
  kubectl get svc
  ```
  
  ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2048.png)
  
  <aside>
  📌 Sometimes, it’s required to update the update the configMap and add the account that need to interact with the cluster.
  
  ```bash
  kubectl edit -n kube-system configmap/aws-auth
  ```
  
  ```bash
  mapUsers: |
    - userarn: arn:aws:iam::616247551677:user/ardimr
      username: ardimr
        groups:
        - system:masters
  
  ```
  
  </aside>
    
#### **Create Nodes**
---    
  There are two options to create Nodes, using `Fargate` or `Managed Nodes` . I tried to use the Fargate but failed during the provisioning. Later, I realized that it was caused by network misconfiguration. The   `subnets` used by the `Fargate` don't have the internet access. The network misconfigration is just realized and solved when creating the `Node Group`. Hence, I decided to proceed to use `EC2` instances as the `managed nodes` since it alreadt works as expected. The implementation steps is described as follows:
  
  <details><summary>Using Fargate</summary>

  1. Create `fargate-profile.json`
      
      ```bash
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Condition": {
                "ArnLike": {
                  "aws:SourceArn": "arn:aws:eks:ap-southeast-3:fargateprofile/ardimr-eks-cluster/*"
                }
            },
            "Principal": {
              "Service": "eks-fargate-pods.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
          }
        ]
      }
      ```
      
  2. Create a Pod execution IAM role.
      
      ```bash
      aws iam create-role \
        --role-nameAmazonEKSFargatePodExecutionRole \
        --assume-role-policy-document file://"pod-execution-role-trust-policy.json"
      
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2049.png)
      
  3. Attach the required Amazon EKS managed IAM policy to the role
      
      ```bash
      **aws iam attach-role-policy \ 
        --policy-arn arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy \ 
        --role-name *AmazonEKSFargatePodExecutionRole***
      ```
      
  4. Create Fargate Profile
      
      ```bash
      aws eks create-fargate-profile \
        --cluster-name ardimr-eks-cluster \
        --fargate-profile-name grpc-hello-world-fargate-profile \
        --pod-execution-role-arn arn:aws:iam::616247551677:role/AmazonEKSFargatePodExecutionRole \
        --subnets subnet-0304ca5a149352790 subnet-057fbdca69a07adf3 \
        --selectors namespace=grpc-hello-world
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2050.png)
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2051.png)
  </details>

  <details><summary>Using Managed Nodes</summary>

  1. **Create a Node IAM Role**
      
      Create a Role and policies for the `node group` .
      
      1.  **Create `*node-role-trust-policy.json*`
          
          ```bash
          {
            "Version": "2012-10-17",
            "Statement": [
              {
                "Effect": "Allow",
                "Principal": {
                  "Service": "ec2.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
              }
            ]
          }
          ```
          
      2. **Create the node IAM role**
          
          ```bash
          aws iam create-role \
            --role-name ardimrEKSNodeRole\
            --assume-role-policy-document file://"node-role-trust-policy.json"
          
          ```
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2052.png)
          
      3. **Attach the required managed IAM policies to the role**
          
          ```bash
          aws iam attach-role-policy \
            --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy \
            --role-name ardimrEKSNodeRole
          aws iam attach-role-policy \
            --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
            --role-name ardimrEKSNodeRole
          aws iam attach-role-policy \
            --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy \
            --role-name ardimrEKSNodeRole
          
          ```
          
  2. **Create a node group**
      
      Create a `node group` that consists of multiple `EC2` instances to hosts the gRPC server pods.
      
      ```bash
      aws eks create-nodegroup  \
          --cluster-name dev-eks-cluster \
          --nodegroup-name dev-eks-nodegroup \
          --node-role arn:aws:iam::616247551677:role/ardimrEKSNodeRole \
          --subnets "subnet-0eb7d5ae19b09c537" "subnet-0fe1ec9f930e2363f" \
          --scaling-config minSize=1,maxSize=4,desiredSize=4 \
          --instance-types 't3.micro' \
          --disk-size 5 \
          --ami-type AL2_x86_64 \
          --update-config maxUnavailable=1
      ```
      
      This command creates a `node group` named `dev-eks-nodegroup` in the `dev-eks-cluster` . The `node group`  will consists of `t3.micro` running `Amazon Linux 2` , distributed accross specified subnets with minimum of 1 and maximum of 2 nodes, and initially starting with 2 nodes. Each node will have a 5 GiB disk, and during updates, only one node can be unavailable at a time to maintain service availability.
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2053.png)
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2054.png)
      
      During the experiment, I run out of pods so I scale up the number of nodes.
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2055.png)
  </details>       

#### **Setup AWS Load Balancers**
---    
  In this setup, I tried to use `AWS Load Balancers` to subsitute the `ingress Nginx` to manage the traffic to the services.
  
  1. Create an IAM OIDC Identity Provider for the cluster
      
      ```bash
      eksctl utils associate-iam-oidc-provider --cluster dev-eks-cluster --approve
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2056.png)
      
  2. Create IAM Policy
      
      ```bash
      curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json
      aws iam create-policy \
          --policy-name AWSLoadBalancerControllerIAMPolicy \
          --policy-document file://iam_policy.json
      ```
      
  3. Create the IAM Role
      
      ```bash
      aws iam create-role \
        --role-name AmazonEKSLoadBalancerControllerRole \
        --assume-role-policy-document file://"load-balancer-role-trust-policy.json"
      
      ```
      
  4. Attach the IAM policy to the IAM Role
      
      ```bash
      aws iam attach-role-policy \
        --policy-arn arn:aws:iam::616247551677:policy/AWSLoadBalancerControllerIAMPolicy \
        --role-name AmazonEKSLoadBalancerControllerRole
      
      ```
      
  5.  Create the Kubernetes service account
      
      ```bash
      kubectl apply -f aws-load-balancer-controller-service-account.yaml
      ```
      
  6. Install ALB using Helm
      
      ```bash
      helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=dev-eks-cluster \
        --set serviceAccount.create=false \
        --set serviceAccount.name=aws-load-balancer-controller
      ```
      
  7. Verify that the controller is installed
      
      ```bash
      kubectl get deployment -n kube-system aws-load-balancer-controller
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2057.png)
      
  <aside>
  ⚠️ Remove ALB from the cluster

  ```bash
  helm delete aws-load-balancer-controller -n kube-system
  ```
  This is the command used to remove the ALB from the cluster.
  </aside>
        
#### **Deploy Application**
---
  1. **Docker Image Setup**
      1. Create a new `ECR` repository
          
          ```bash
          aws ecr create-repository \
              --repository-name 616247551677.dkr.ecr.ap-southeast-3.amazonaws.com/grpc-hello-world
          ```
          
      2. Push the image
          
          ```bash
          export ECR_IMAGE_TAG=616247551677.dkr.ecr.ap-southeast-3.amazonaws.com/grpc-hello-world:dev
          docker tag ardimr/grpc-hello-world:dev $ECR_IMAGE_TAG && docker push $ECR_IMAGE_TAG
          ```
          
          ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2058.png)
          
  2. **Create a Kubernetes namespace.**
      
      ```bash
      kubectl create namespace development
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2059.png)

  4. `eks-grpcserver.yaml`
      ```yaml
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: backend
        namespace: development
        labels:
          app: backend
          tier: backend
      spec:
        replicas: 2
        selector:
          matchLabels:
            app: backend
            tier: backend
        template:
          metadata:
            labels:
              app: backend
              tier: backend
          spec:
            containers:
            - name: grpc-hello-world
              image: 616247551677.dkr.ecr.ap-southeast-3.amazonaws.com/grpc-hello-world:dev
              ports:
              - containerPort: 8080
              imagePullPolicy: Always
      ---
      apiVersion: v1
      kind: Service
      metadata:
        name: backend-service
        namespace: development

      spec:
        selector:
          app: backend
        ports:
          - protocol: TCP
            port: 8888
            targetPort: 8080
        type: ClusterIP
      ---
      apiVersion: networking.k8s.io/v1
      kind: Ingress
      metadata:
        annotations:
          alb.ingress.kubernetes.io/subnets: subnet-0eb7d5ae19b09c537,subnet-0fe1ec9f930e2363f
          alb.ingress.kubernetes.io/backend-protocol-version: GRPC
          # alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80},{"HTTPS": 443}]'
          alb.ingress.kubernetes.io/ssl-redirect: '443'
          alb.ingress.kubernetes.io/scheme: internet-facing
          alb.ingress.kubernetes.io/target-type: ip
          alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:ap-southeast-3:616247551677:certificate/afd765d3-c41e-4829-a333-ac55d4345353
        labels:
          app: backend-ingress
          environment: dev
        name: backend-ingress
        namespace: development
      spec:
        ingressClassName: alb
        rules:
        - http:
            paths:
            - path: /
              pathType: Prefix
              backend:
                service:
                  name: backend-service
                  port:
                    number: 8888

      ```
      The deployment pods and services manifests are similar to the local configuration in the `local` kubernets section. I just modified the `namespace` to `development`.
      For the Ingress one, I used `AWS Load Balancers` to subtitute the Nginx Ingress. To implement this, I created `self-signed-certificate` using `openssl` and import it to the `ACM` since using `AWS Load Balancers` for gRPC traffic requires a secure connection.
      
  3. **Deploy the applications**
      
      ```bash
      kubectl apply -f k8s/eks-grpcserver.yaml
      ```
        
#### **List Resources**
---
  1. All deployment
      
      ```bash
      kubectl get all -n development
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2060.png)
      
  2. Ingress
      
      ```bash
      kubectl get ingress -n development
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2063.png)

      As we can see here, the Ingress is deployed successfully and provided an External-IP. Unfortunately, the External-IP is not accessible. Initially, I tried to resolve the DNS using `nslookup` but it failed. The DNS is not accessible. Then, I tried to add inbound rules to the associated `security group` and the DNS can be resolved as shown on the Load balancers section below. However, when trying to send gRPC request using both `grpcurl` and `Postman`, It shows `context-deadline-exceeded` error. That means, the traffic can't reach the services. I tried to updated the inbound rules to allow grpc traffic for port `0-65535` but still couldn't solve the error. Unfortunately, my budget for the AWS operational has reached my limit so I couldn't proceed to solve the error in time. If possible, I'd really appreciate if you can give me a hint on how to solve this problem.

  3. Pods
      
      ```bash
      kubectl get pod -n development
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2061.png)
      
  4. Services
      
      ```bash
      kubectl get svc -n development
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2062.png)

      Because the `AWS Load Balancers` couldn't perform as expected, I decided to use the Service type `LoadBalancer` to route the traffic. By using this service type, a `Classic load balacner` is employed instead of `AWS Load Balancers`. The external-IP provided for this service is used to access the services. The result is shown on the "test the deployed application section" below.
      
      
  5. AWS load Balancer Controller
      
      ```bash
      kubectl get deployment -n kube-system aws-load-balancer-controller
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2064.png)
      
  6. Load balancers
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2065.png)
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2066.png)
        
#### **Access the deployed application**
---
  As mentioned in the previous section, the address to access the services is retrieved from the `Service type Load Balancer`.
  1. Using grpcurl
      ```bash
      grpcurl -plaintext -import-path Protos/ -proto greet.proto a63a498f42b164e2d913fcbdbfc79307-1261931033.ap-southeast-3.elb.amazonaws.com:8888 greet.Greeter/SayHelloWorld
      ```
      
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2067.png)
      
  2. Using Postman
      ![Untitled](AWS%20Deployment%201233135429644f8392737f7497d02fdd/Untitled%2068.png)