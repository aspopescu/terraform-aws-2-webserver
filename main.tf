terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
  shared_credentials_file = "/Users/{user}/.aws/{credentials file}"
}

resource "aws_vpc" "vpctf" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc-tf-4"
  }
}

resource "aws_internet_gateway" "igtf" {
  vpc_id = aws_vpc.vpctf.id

}

resource "aws_route_table" "rttf" {
  vpc_id = aws_vpc.vpctf.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igtf.id
  }
  route {
      ipv6_cidr_block = "::/0"
      gateway_id = aws_internet_gateway.igtf.id
  }
  tags = {
    Name = "rt-tf-4"
  }
}

resource "aws_subnet" "subnettf" {
  vpc_id = aws_vpc.vpctf.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "subnet-tf-4"
  }
}

resource "aws_route_table_association" "rtatf" {
  subnet_id = aws_subnet.subnettf.id
  route_table_id = aws_route_table.rttf.id
}

resource "aws_security_group" "sgtf" {
  name = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id = aws_vpc.vpctf.id

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web_traffic"
  }
}

resource "aws_network_interface" "nitf" {
  subnet_id = aws_subnet.subnettf.id
  private_ips = ["10.0.1.50"]
  security_groups = [aws_security_group.sgtf.id]
}

resource "aws_eip" "eiptf" {
  vpc = true
  network_interface = aws_network_interface.nitf.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.igtf]
}

resource "aws_instance" "ubuntutf" {
    ami = "ami-00c90dbdc12232b58"
    instance_type = "t2.micro"
    tags = {
      Name = "ubuntu-via-tf-6"
    }
    availability_zone = "eu-west-1a"
    network_interface {
      network_interface_id = aws_network_interface.nitf.id
      device_index = 0
    }
    key_name = "terraform_key_name_set_in_ec2"
    user_data = <<-EOF
                  #!/bin/bash
                  sudo apt update -y
                  sudo apt install apache2 -y
                  sudo systemctl start apache2
                  sudo bash -c 'echo web server deployed using terraform > /var/www/html/index.html'
                  EOF
}
