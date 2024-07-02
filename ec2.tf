provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "devops" {
  ami                         = "ami-04b70fa74e45c3917"
  instance_type               = "t2.micro"
  key_name                    = "test-jenkins"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_security_group.id]


  user_data = <<-EOF
              #!/bin/bash

              # Install Docker
              apt-get install sudo
              apt-get install wget
              sudo apt-get update
              sudo apt install apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              yes | sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
              yes | sudo apt install docker-ce



              # Install Jenkins
              sudo apt-get update
              sudo apt-get upgrade -y
              wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian/jenkins.io-2023.key
              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
              sudo apt-get update
              sudo apt-get install fontconfig -y
              sudo apt-get install openjdk-17-jre -y
              sudo apt-get install jenkins -y
              sudo systemctl enable jenkins
              sudo systemctl start jenkins

              # Install kubectl
              curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
              chmod +x ./kubectl
              sudo mv ./kubectl /usr/local/bin/kubectl

              # Install terraform 
              cd /usr/bin
              wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
              echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
              sudo apt update && sudo apt install terraform

              # Install pip3
              yes | sudo apt install python3-pip
              yes | sudo apt install python3.12-venv
              python3 -m venv myenv
              source myenv/bin/activate
              python3 -m pip install awscli
              sudo pip3 install boto3

              # Add Jenkins user to sudoers for Docker without password
              echo "jenkins ALL=(ALL) NOPASSWD: /usr/bin/docker" | tee -a /etc/sudoers

              EOF
}

resource "aws_security_group" "jenkins_security_group" {
  name        = "jenkins_security_group"
  description = "Allows Port SSH and HTTP Traffic"

  ingress {
    description = "Allow SSH Traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS Traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow 8080 Traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "ec2_global_ips" {
  value = aws_instance.devops.public_ip
}
