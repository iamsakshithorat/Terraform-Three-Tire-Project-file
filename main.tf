terraform {
  backend "s3" {
    bucket = "terraform-bucket-60"
    key = "terraform.tfstate"
    region = "us-east-2"
    
  }

}
  
provider  "aws" {
    region ="us-east-2"
}
#vpc
resource "aws_vpc" "tf-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
      Name ="${var.name}-VPC"

    }
  
}
#subnet
resource "aws_subnet" "tf-public-subnet" {
    vpc_id = aws_vpc.tf-vpc.id
    cidr_block = var.public_subnet
    availability_zone = var.az1
    map_public_ip_on_launch = true
    tags ={
        Name="${var.name}-public_subnet"
    }
}
resource "aws_subnet" "tf-private_subnet-1" {
    vpc_id = aws_vpc.tf-vpc.id
    cidr_block = var.private_subnet-1
    availability_zone = var.az2
    tags ={
        Name="${var.name}-private-subnet-1"
    }
  
}
resource "aws_subnet" "tf-private_subnet-2" {
    vpc_id = aws_vpc.tf-vpc.id
    cidr_block = var.private_subnet-2
    availability_zone = var.az3
    tags ={
        Name="${var.name}-private-subnet-2"
      
    }
  
}
#internet gateway
resource "aws_internet_gateway" "tf-igw" {
    vpc_id = aws_vpc.tf-vpc.id
    tags = {
      Name="${var.name}-igw"
    }
  
}
#Elastic ip(NAT)
resource "aws_eip" "tf-nat-eip" {
    domain = "vpc"
    tags={
        Name="${var.name}-nat-eip"
    }
  
}
#natgateway
resource "aws_nat_gateway" "tf-aws_nat_gateway" {
  allocation_id = aws_eip.tf-nat-eip.id
  subnet_id = aws_subnet.tf-public-subnet.id
  tags={
    Name="${var.name}-nat-gw"
  }
  depends_on = [ aws_internet_gateway.tf-igw ]
}
#public route table
resource "aws_route_table" "tf-public-route" {
    vpc_id = aws_vpc.tf-vpc.id
    tags = {
      Name = "public-route"
    }
  
}
resource "aws_route" "tf-public-rt"{
    route_table_id = aws_route_table.tf-public-route.id
    destination_cidr_block = var.igw-rt-cidr
    gateway_id = aws_internet_gateway.tf-igw.id
}
#private natgateway
resource "aws_route_table" "tf-private-route" {
  vpc_id = aws_vpc.tf-vpc.id
  tags={
    Name="private-route"
  }
}
resource "aws_route" "tf-private-route" {
    route_table_id =aws_route_table.tf-private-route.id
    destination_cidr_block = var.nat-rt-cidr
    nat_gateway_id = aws_nat_gateway.tf-aws_nat_gateway.id
}
#public subnet association
resource "aws_route_table_association" "public" {
    subnet_id = aws_subnet.tf-public-subnet.id
    route_table_id = aws_route_table.tf-public-route.id
  
}
#private subnet association
resource "aws_route_table_association" "private1" {
    subnet_id = aws_subnet.tf-private_subnet-1.id
    route_table_id = aws_route_table.tf-private-route.id
  
}
#private subnet association
resource "aws_route_table_association" "private2" {
    subnet_id = aws_subnet.tf-private_subnet-2.id
    route_table_id = aws_route_table.tf-private-route.id
  
}
#security group
resource "aws_security_group" "tf-sg" {
    vpc_id = aws_vpc.tf-vpc.id
    name="${var.name}-sg"
    
    ingress{
        description = "allow ssh"
        to_port = 22
        from_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

    }
    ingress  {
        description="allow http"
        to_port = 80
        from_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

    }
    ingress {
        description = "allow-mysql"
        to_port = 3306
        from_port = 3306
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        description = "allow all"
        to_port = 0
        from_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    depends_on = [ aws_vpc.tf-vpc ]
}
#server
resource "aws_instance" "tf-web" {
    subnet_id = aws_subnet.tf-public-subnet.id
    vpc_security_group_ids = [aws_security_group.tf-sg.id]
    availability_zone = var.az1
    ami=var.ami
    instance_type = var.instance_type
    key_name = var.key
    tags={
        Name="${var.name}-web-server"
    }
    depends_on = [ aws_security_group.tf-sg ]
}
resource "aws_instance" "tf-app" {
    subnet_id = aws_subnet.tf-private_subnet-1.id
    vpc_security_group_ids = [aws_security_group.tf-sg.id]
    availability_zone = var.az2
    ami=var.ami
    instance_type = var.instance_type
    key_name = var.key
    tags={
        Name="${var.name}-app-server"
    }
    depends_on = [ aws_security_group.tf-sg ]
}
#RDS DB-Server
resource "aws_db_instance" "db_server" {
    allocated_storage = 10
    db_name = "db"
    engine = "mysql"
    engine_version = "8.0"
    instance_class ="db.t3.micro"
    username = "admin"
    password = "pass12345"
    parameter_group_name = "default.mysql8.0"
    skip_final_snapshot = true
    db_subnet_group_name = aws_db_subnet_group.db_subnet.name
    vpc_security_group_ids = [aws_security_group.tf-sg.id]
    publicly_accessible = false
}
resource "aws_db_subnet_group" "db_subnet" {
    name ="my-db-subnet-group"
    subnet_ids = [
        aws_subnet.tf-private_subnet-1.id,
        aws_subnet.tf-private_subnet-2.id
    ]
    tags={
        name="db subnet group"
    }
  
}