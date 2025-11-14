```mermaid
graph TB

    Users[Users] --> IGW[Internet Gateway]

    subgraph VPC["VPC 10.0.0.0/16"]

        subgraph AZ1["Availability Zone 1a"]
            PubSub1[Public Subnet 10.0.1.0/24]
            PrivSub1[Private Subnet 10.0.11.0/24]
        end

        subgraph AZ2["Availability Zone 1b"]
            PubSub2[Public Subnet 10.0.2.0/24]
            PrivSub2[Private Subnet 10.0.12.0/24]
        end

        subgraph ALB_Layer["Application Load Balancer"]
            ALB[ALB Internet Facing]
            TG[Target Group Health Check Root]
        end

        subgraph ASG_Layer["Auto Scaling Group Min1 Max4"]
            EC2_1[EC2 Instance 1 t3 micro]
            EC2_2[EC2 Instance 2 t3 micro]
            EC2_3[EC2 Instance N t3 micro]
        end

        subgraph RDS_Layer["RDS MySQL"]
            RDS_Primary[RDS Primary MySQL 8]
            RDS_Standby[RDS Standby Multi AZ]
        end
    end

    subgraph Docker1["Docker Instance 1"]
        Frontend1[Nginx Frontend 80]
        Backend1[Node Backend 8080]
    end

    subgraph Docker2["Docker Instance 2"]
        Frontend2[Nginx Frontend 80]
        Backend2[Node Backend 8080]
    end

    subgraph Monitoring["Monitoring and Alerts"]
        CW[CloudWatch Metrics Logs]
        SNS[SNS Email Alerts]
    end

    IGW --> ALB
    ALB --> TG
    TG --> EC2_1
    TG --> EC2_2
    TG --> EC2_3

    ALB -.-> PubSub1
    ALB -.-> PubSub2

    EC2_1 -.-> PubSub1
    EC2_2 -.-> PubSub2
    EC2_3 -.-> PubSub1

    RDS_Primary -.-> PrivSub1
    RDS_Standby -.-> PrivSub2

    EC2_1 --> Docker1
    EC2_2 --> Docker2

    Frontend1 --> Backend1
    Frontend2 --> Backend2

    Backend1 --> RDS_Primary
    Backend2 --> RDS_Primary

    EC2_1 --> CW
    EC2_2 --> CW
    EC2_3 --> CW
    CW --> SNS

```

## 🏗️ Template Dependencies Flow

```mermaid
graph TD
    Start([🚀 deploy.sh]) --> S3[📦 Upload templates to S3]
    S3 --> Main[🎭 Deploy main.yaml]
    
    Main --> VPC[🌐 1. VPC Stack]
    VPC --> VPC_Complete{VPC Ready?}
    VPC_Complete -->|Yes| Parallel_Deploy[⚡ Parallel Deployment]
    
    Parallel_Deploy --> RDS[🗄️ 2. RDS Stack]
    Parallel_Deploy --> ALB[⚖️ 3. ALB Stack]
    
    RDS --> RDS_Complete{RDS Ready?}
    ALB --> ALB_Complete{ALB Ready?}
    
    RDS_Complete -->|Yes| ASG_Ready{All Dependencies Ready?}
    ALB_Complete -->|Yes| ASG_Ready
    
    ASG_Ready -->|Yes| ASG[🚀 4. AutoScaling Stack]
    ASG --> EC2_Launch[🖥️ Launch EC2 Instances]
    EC2_Launch --> Docker[🐳 Docker Deployment]
    Docker --> Health[🏥 Health Checks]
    Health --> Register[📝 Register to Target Group]
    Register --> ASG_Complete{ASG Ready?}
    
    ASG_Complete -->|Yes| CloudWatch[📊 5. CloudWatch Stack]
    CloudWatch --> SNS[📧 6. SNS Notifications]
    SNS --> Complete[✅ Deployment Complete]
    
    %% Error paths
    VPC_Complete -->|No| Error_VPC[❌ VPC Error]
    RDS_Complete -->|No| Error_RDS[❌ RDS Error]
    ALB_Complete -->|No| Error_ALB[❌ ALB Error] 
    ASG_Complete -->|No| Error_ASG[❌ ASG Error]
    
    %% Estilos
    classDef success fill:#c8e6c9
    classDef error fill:#ffcdd2
    classDef process fill:#e3f2fd
    classDef decision fill:#fff3e0
    
    class Complete success
    class Error_VPC,Error_RDS,Error_ALB,Error_ASG error
    class VPC,RDS,ALB,ASG,CloudWatch,SNS process
    class VPC_Complete,RDS_Complete,ALB_Complete,ASG_Ready,ASG_Complete decision
```

## 🔧 Component Communication Matrix

| Component | Communicates With | Protocol/Port | Purpose |
|-----------|-------------------|---------------|---------|
| 🌐 **Internet** | ALB | HTTP/80 | User requests |
| ⚖️ **ALB** | EC2 Instances | HTTP/80 | Load balancing |
| 🎯 **Target Group** | EC2 Instances | HTTP/80 | Health checks |
| 🖥️ **EC2 Instances** | RDS | MySQL/3306 | Database queries |
| 🐳 **nginx (Frontend)** | Node.js (Backend) | HTTP/8080 | API proxy |
| ⚙️ **Node.js (Backend)** | RDS MySQL | MySQL/3306 | Data persistence |
| 📊 **CloudWatch** | EC2 + ASG | CloudWatch API | Metrics collection |
| 📧 **SNS** | Email/SMS | SMTP/SMS | Alert notifications |

## 🛡️ Security Groups Summary

| Security Group | Resource | Inbound Rules | Purpose |
|----------------|----------|---------------|---------|
| **ALB-SG** | ALB | HTTP/80 from 0.0.0.0/0 | Public web access |
| **App-SG** | EC2 Instances | SSH/22, HTTP/80, HTTP/8080 from 0.0.0.0/0 | Instance access |
| **RDS-SG** | RDS | MySQL/3306 from VPC CIDR | Database access |
