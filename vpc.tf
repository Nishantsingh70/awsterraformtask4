provider "aws" {
region="ap-south-1"
profile="nishant"
}


resource "aws_vpc" "myvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "myvpc"
  }
}
output "myvpc"{
        value=aws_vpc.myvpc.id
}


resource "aws_subnet" "mypublicsubnet" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "mypublicsubnet"
  }
}
resource "aws_subnet" "myprivatesubnet" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "myprivatesubnet"
  }
}


resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "myigw"
  }
}

resource "aws_route_table" "mypublicroute" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }

  tags = {
    Name = "mypublicroute"
  }
}


resource "aws_route_table_association" "mypublicroutetable" {
  subnet_id      = aws_subnet.mypublicsubnet.id
  route_table_id = aws_route_table.mypublicroute.id
}

resource "aws_eip" "myeip" {
   vpc = true
   depends_on = [ aws_internet_gateway.myigw , 
       ]
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.myeip.id
  subnet_id = aws_subnet.mypublicsubnet.id
  depends_on = [ aws_internet_gateway.myigw , ]
  tags = {
    Name = "natgw"
  }
}

resource "aws_route_table" "myprivateroute" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "myprivateroute"
  }
}
resource "aws_route_table_association" "myprivateroutetable" {
  subnet_id      = aws_subnet.myprivatesubnet.id
  route_table_id = aws_route_table.myprivateroute.id
}


resource "aws_security_group" "mysg1" {
  name        = "mysg1"
  description = "Allow 80 port"
  vpc_id      = aws_vpc.myvpc.id

ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 }
ingress {
    description = "TCP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysg1"
  }
}
resource "aws_security_group" "mysg2" {
  name        = "mysg2"
  description = "Allow 3306 port"
  vpc_id      = aws_vpc.myvpc.id

ingress {
    description = "HTTP"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysg2"
  }
}

resource "aws_instance" "dbos" {
   ami = "ami-0019ac6129392a0f2"
   instance_type = "t2.micro"
   key_name="mykey1332"
   vpc_security_group_ids = ["${aws_security_group.mysg2.id}" ]
   subnet_id = aws_subnet.myprivatesubnet.id
  tags = {
      Name = "mysqlos"
}
}
resource "aws_instance" "wpos" {
   ami = "ami-000cbce3e1b899ebd"
   instance_type = "t2.micro"
   key_name="mykey1332"
   vpc_security_group_ids = ["${aws_security_group.mysg1.id}" ]
   subnet_id = aws_subnet.mypublicsubnet.id
  tags = {
      Name = "wpos"
}
}

