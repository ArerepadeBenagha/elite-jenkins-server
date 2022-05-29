###########------ elaastice Server -----########
resource "aws_instance" "elastic-1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.main-public-1.id
  key_name               = aws_key_pair.mykeypair.key_name
  vpc_security_group_ids = [aws_security_group.elastic.id]
  lifecycle {
    ignore_changes = [ami]
  }
  tags = merge(local.common_tags, { Name = "elastic-server-1", Application = "public" })
}

resource "aws_ebs_volume" "ebs-vol1" {
  availability_zone = "us-east-1a"
  size              = 200
  tags = merge(local.common_tags, { Name = "ebs-vol1", Application = "public" })
}
resource "aws_volume_attachment" "ebs_att-1" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.ebs-vol1.id
  instance_id = aws_instance.elastic-1.id
}

resource "aws_key_pair" "mykeypair" {
  key_name   = "elastickey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDdBWlQgwWW6oh6sgEBEG5GfVWKEOQS+ll7u3rQvohNI2ZWrLvkY87408I5jfspOElI9op4SF1MGwgbt2e6gnmeES3BK2ZKtHu0soHWNtA8Zne7//LQJ1fHxfrTpIYqbvJqFCzMj5Zj+QPVE36umWKZMy/w2Otfw+yE63xpraRyWCLaWYaHWh4uxvTtw55g9d9YV41RclbCjkqjsRCaOpD/vUqo9smDFey6+Qzcjj8u6tO4HCmjG98E4EDH4tyHQBjzWkjybgg+jmLHxT99Qq0+HjZNtHicvdahC0lB94ZnFTOTFJSbc28PmMBkFZ1q0Y3uSkrCMPdOBGETj9ZvL5rIJLhP5hCywO8lXzcITpeaUFOk5/cwcChg0R96B/VOx/RYpFe43ZvbI+PLhe2IIvC6lrHSz95bAqQSLwNrfPqFVUWqrJVdAmbY5/ydVPfSB46Uq4Kqem7RdE/OoBGKnpHFAguYX13fg0nst7cVsmP7k3Ax9r2agA3U2hqLS5Gt2Ik= lbena@LAPTOP-QB0DU4OG"
}

resource "aws_instance" "elastic-2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.main-public-2.id
  key_name               = aws_key_pair.mykeypair.key_name
  vpc_security_group_ids = [aws_security_group.elastic.id]
  lifecycle {
    ignore_changes = [ami]
  }
  tags = merge(local.common_tags, { Name = "elastic-server-2", Application = "public" })
}

resource "aws_ebs_volume" "ebs-vol2" {
  availability_zone = "us-east-1b"
  size              = 200
  tags = merge(local.common_tags, { Name = "ebs-vol2", Application = "public" })
}

resource "aws_volume_attachment" "ebs_att-2" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.ebs-vol2.id
  instance_id = aws_instance.elastic-2.id
}

resource "aws_instance" "elastic-3" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.main-public-3.id
  key_name               = aws_key_pair.mykeypair.key_name
  vpc_security_group_ids = [aws_security_group.elastic.id]
  lifecycle {
    ignore_changes = [ami]
  }
  tags = merge(local.common_tags, { Name = "elastic-server-3", Application = "public" })
}

resource "aws_ebs_volume" "ebs-vol3" {
  availability_zone = "us-east-1c"
  size              = 200
  tags = merge(local.common_tags, { Name = "ebs-vol3", Application = "public" })
}

resource "aws_volume_attachment" "ebs_att-3" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.ebs-vol3.id
  instance_id = aws_instance.elastic-3.id
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

resource "aws_security_group" "elastic" {
  vpc_id      = aws_vpc.main.id
  name        = "public web allow"
  description = "security group for ubuntuserver"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 8200
    to_port     = 8200
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
  { Name = "elasticgroup" })
}
