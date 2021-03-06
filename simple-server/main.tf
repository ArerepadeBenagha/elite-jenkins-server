###########------ simple Server -----########
resource "aws_instance" "simpleserver" {
  ami                    = data.aws_ami.ubuntu.id
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
  key_name   = "jenkinskey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuKNjBPele+SRWs7zhpRlELfPVZl8Uo+Z1B09Wsb2fI8YaPaPLv33HNTxabZ/94rMd60gCpBYr2F/EFyr8Z3tkvGoLEnot6tntePY+wwVyrxQ9AhJoJQXJnv/vvlMR1OfMRXyxerUaZ3I2WHGuPNQcWFUfZ81IcTYoZWz3wcmgA3t0lRy8Zofl3gtPYluNXe1bEY6CW7XkBvOaMAtM7SPgm/3Tz8rlYyYk3kuKubOKHGGLnhZhdS/f/vPb6hZz8xG1T58s6owyZl3vkMCy1fUll6UizuF1pogv11+2av/IjlE1WWUvbM7DIYWvWTG7BViNOmQ4BfuQvRSgSJcSxo/joAvHC5Lgor3ZhJ7siJHSCje9u38KCUv09+3lj8QKOn6jT144c+LTHdYMvnXmE/wxOtlhyip6qzFYuEWypX/qVRPEvNfqqFNbldVpKgWVD+m75eXCxuqwiphVWojC2JCF3NzlrAA773GUCEwZ7/GPl12ofzvv5+YPgWzjQ60mUQ8= lbena@LAPTOP-QB0DU4OG"
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
  name        = "public web allow"
  description = "security group for ubuntuserver"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
