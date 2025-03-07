provider "aws" {
  region = "us-east-2"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MainVPC"
  }
}

resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "MainSubnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "InternetGateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "reniecdb_sg" {
  name        = "reniecdb_sg"
  description = "Allow reniecDB inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "reniecdb" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.reniecdb_sg.id]
  subnet_id              = aws_subnet.main_subnet.id

  tags = {
    Name = "reniecDB-Server"
  }

   user_data = base64encode(<<-EOF
              #!/bin/bash
              # Update the instance
              sudo yum update -y

              # Install Docker
              sudo amazon-linux-extras install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user

              # Install Git
              sudo yum install -y git

              # Clone your Node.js app from the Git repository (replace with your repo)
              cd /home/ec2-user
              git clone https://github.com/giovanni-pe/reniecApiSimulation.git nodeapp
              cd nodeapp/charlie-service

              # Build the Docker image
              sudo docker build -t nodeapp .

              # Run the Docker container
              sudo docker run -d -p 80:3000 nodeapp
              EOF
  )

  provisioner "local-exec" {
    command = "echo 'reniecIP=${self.public_ip}' > ../.env.prod"
  }

  depends_on = [aws_internet_gateway.gw]
}
