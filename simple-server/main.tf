###########------ simple Server -----########
resource "aws_instance" "simpleserver" {
  ami                    = "ami-0b5eea76982371e91" #data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main-public-1.id
  key_name               = aws_key_pair.mykeypair.key_name
  vpc_security_group_ids = [aws_security_group.simpleserver.id]
  lifecycle {
    ignore_changes = [ami]
  }
  tags = merge(local.common_tags, { Name = "simple-server", Application = "public" })
}

resource "aws_key_pair" "mykeypair" {
  key_name   = "simple-server-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC95BAOwdGtHUdOVoY7Wf7S2ZYxCKkt7KxjhV9qtoiwb5kuwqGk6wXRG+3WsmyN4LwlWnRhTrCvZRuF9BhF2KKi7JIH6a6iPcu6b0j33ZF+4Z/yOiND20BjczaPyErIelqKWZ+0VRZ9ImepYMarhoCxn8eoG18V+NGcOThiwJWbJkUK6shxBYQGFW79BzVx22ZzMdL1UktADZAM+Qb0IFajSPckPkMe7emQPzdbgmmsS1EOdU3wyXLfYqDqcnqmarX6zvpDIaKDJHdrtvGi+cC+bisClNUJL8Nn0ZRgiFTR2kZvXci0Ie+6Mce8QIrRy24dwYbkCt2Q7iQxCGRREcxROJPH0acEGjq7BhFFf3R+D7OXkE4XSlepEAte5xLq2dV4ErKqT4Th3wwQK20xvV8IxsHrbSZZR/lRtj/7tI+39+gC5Z63tLfzbzbG+RKJGUuIk/2/qzgxwODKCZQ/IEQrALOaj5VVjryAH80mUSfUfmtriwhQXDGMmJpoATLcM2k= lbena@LAPTOP-QB0DU4OG"
}


////VPC
# Vars.tf
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  tags = {
    Name = "main"
  }
}

# Subnets
resource "aws_subnet" "main-public-1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"

  tags = {
    Name = "Main-public-1"
  }
}
resource "aws_subnet" "main-public-2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1b"

  tags = {
    Name = "Main-public-2"
  }
}
resource "aws_subnet" "main-public-3" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1c"

  tags = {
    Name = "Main-public-3"
  }
}
resource "aws_subnet" "main-private-1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "us-east-1a"

  tags = {
    Name = "Main-private-1"
  }
}
resource "aws_subnet" "main-private-2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "us-east-1b"

  tags = {
    Name = "Main-private-2"
  }
}
resource "aws_subnet" "main-private-3" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.6.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "us-east-1c"

  tags = {
    Name = "Main-private-3"
  }
}

# Internet GW
resource "aws_internet_gateway" "main-gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

# route tables
resource "aws_route_table" "main-public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-gw.id
  }

  tags = {
    Name = "main-public-1"
  }
}

# route associations public
resource "aws_route_table_association" "main-public-1-a" {
  subnet_id      = aws_subnet.main-public-1.id
  route_table_id = aws_route_table.main-public.id
}
resource "aws_route_table_association" "main-public-2-a" {
  subnet_id      = aws_subnet.main-public-2.id
  route_table_id = aws_route_table.main-public.id
}
resource "aws_route_table_association" "main-public-3-a" {
  subnet_id      = aws_subnet.main-public-3.id
  route_table_id = aws_route_table.main-public.id
}

resource "aws_security_group" "simpleserver" {
  vpc_id      = aws_vpc.main.id
  name        = "public-web-allow"
  description = "security group for ubuntuserver"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["76.198.149.152/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["76.198.149.152/32"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["76.198.149.152/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags,
  { Name = "simpleservergroup" })
}
