###########------ jenkins Server -----########
resource "aws_instance" "jenkinsserver" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main-public-1.id
  key_name               = aws_key_pair.mykeypair.key_name
  vpc_security_group_ids = [aws_security_group.ec2-sg.id, aws_security_group.main-alb.id]
  user_data_base64       = data.cloudinit_config.userdata.rendered
  lifecycle {
    ignore_changes = [ami, user_data_base64]
  }
  tags = merge(local.common_tags,
    { Name = "jenkins-server"
  Application = "public" })
}
###-------- ALB -------###
resource "aws_lb" "jenkinslb" {
  name               = join("-", [local.application.app_name, "jenkinslb"])
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2-sg.id, aws_security_group.main-alb.id]
  subnets            = [aws_subnet.main-public-1.id, aws_subnet.main-public-2.id]
  idle_timeout       = "60"

  access_logs {
    bucket  = aws_s3_bucket.logs_s3dev.bucket
    prefix  = join("-", [local.application.app_name, "jenkinslb-s3logs"])
    enabled = true
  }
  tags = merge(local.common_tags,
    { Name = "jenkinsserver"
  Application = "public" })
}
resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC98/ZrwBNqrQ662KrQGnUxUXg9EInl0rJP5OTVXzVoM+8gtD84Mgwap6L3NvC3BLRIzAjMb07P20CqOF8b+UVUT8Xoo4NKtkEZRyRLWcZQX8pIU/HcH1euejlC1w7SO5tlq5EY56TwF9oTIRzROwE3TkaKDpP27bQFZBVvoFnRBwwPWeP4BqmCZGk3THQOLoHkLNI0exX1ekSi/VrgWv7K38BIuDNQWzN75Yi5ZeLMYx50EAzIRtPqZgjJU9w3RjlDQCZr/y5epwc3+25SPU5V1+lIA5YeKQyFv/h9rVOajwfxdurq7ErpSV3mCh026Kdi9PS9SN5QaChKR4hxy2fgsWhzOMU89LoWx9q4Ho7zesQWUcapWiEVFRB6olN7IcVd7DpNy/JvCEAkTHj664LITV4NZla4mBea8pwPiZWRBkJo2RoC1Oz6m1H8xWn6l0KNhRiJzzxKzSreUZATh6gYZz4J32CyaLEVYHq0NncL5PjaPmiLvbpZbke0aL/6abs= lbena@LAPTOP-QB0DU4OG"
}

###------- ALB Health Check -------###
resource "aws_lb_target_group" "jenkins_tglb" {
  name     = join("-", [local.application.app_name, "jenkinstglb"])
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = "5"
    unhealthy_threshold = "2"
    timeout             = "5"
    interval            = "30"
    matcher             = "200"
  }
}
resource "aws_lb_target_group_attachment" "jenkins_tglbat" {
  target_group_arn = aws_lb_target_group.jenkins_tglb.arn
  target_id        = aws_instance.jenkinsserver.id
  port             = 8080
}

# # ####-------- SSL Cert ------#####
# resource "aws_lb_listener" "jenkins_lblist2" {
#   load_balancer_arn = aws_lb.jenkinslb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = "arn:aws:acm:us-east-1:375866976303:certificate/f3e1c14c-94cb-4c7f-b150-df5996c52f18"
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.jenkins_tglb.arn
#   }
# }


####---- Redirect Rule -----####
resource "aws_lb_listener" "jenkins_lblist" {
  load_balancer_arn = aws_lb.jenkinslb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

########------- S3 Bucket -----------####
resource "aws_s3_bucket" "logs_s3dev" {
  bucket = join("-", [local.application.app_name, "logdev"])
  acl    = "private"

  tags = merge(local.common_tags,
    { Name = "jenkinsserver"
  bucket = "private" })
}
resource "aws_s3_bucket_policy" "logs_s3dev" {
  bucket = aws_s3_bucket.logs_s3dev.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "MYBUCKETPOLICY"
    Statement = [
      {
        Sid       = "Allow"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.logs_s3dev.arn,
          "${aws_s3_bucket.logs_s3dev.arn}/*",
        ]
        Condition = {
          NotIpAddress = {
            "aws:SourceIp" = "8.8.8.8/32"
          }
        }
      },
    ]
  })
}

#IAM
resource "aws_iam_role" "jenkins_role" {
  name = join("-", [local.application.app_name, "jenkinsrole"])

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(local.common_tags,
    { Name = "jenkinsserver"
  Role = "jenkinsrole" })
}

#######------- IAM Role ------######
resource "aws_iam_role_policy" "jenkins_policy" {
  name = join("-", [local.application.app_name, "jenkinspolicy"])
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

#####------ Certificate -----------####
resource "aws_acm_certificate" "jenkinscert" {
  domain_name       = "*.elitelabtools.com"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = merge(local.common_tags,
    { Name = "elite-jenkins-server.elitelabtools.com"
  Cert = "jenkinscert" })
}

###------- Cert Validation -------###
data "aws_route53_zone" "main-zone" {
  name         = "elitelabtools.com"
  private_zone = false
}

resource "aws_route53_record" "jenkinszone_record" {
  for_each = {
    for dvo in aws_acm_certificate.jenkinscert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main-zone.zone_id
}

resource "aws_acm_certificate_validation" "jenkinscert" {
  certificate_arn         = aws_acm_certificate.jenkinscert.arn
  validation_record_fqdns = [for record in aws_route53_record.jenkinszone_record : record.fqdn]
}

##------- ALB Alias record ----------##
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main-zone.zone_id
  name    = "elite-jenkins-devserver.elitelabtools.com"
  type    = "A"

  alias {
    name                   = aws_lb.jenkinslb.dns_name
    zone_id                = aws_lb.jenkinslb.zone_id
    evaluate_target_health = true
  }
}

#EC2-SG
resource "aws_security_group" "ec2-sg" {
  vpc_id      = aws_vpc.main.id
  name        = "public web jenkins sg"
  description = "security group Ec2-server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.main-alb.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.main-alb.id]
  }
  /////sonarqubeSG
  ingress {
    from_port       = 4040
    to_port         = 4040
    protocol        = "tcp"
    security_groups = [aws_security_group.main-alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags,
  { Name = "Ec2 security group" })
}

#ALB-SG
resource "aws_security_group" "main-alb" {
  vpc_id      = aws_vpc.main.id
  name        = "public web allow"
  description = "security group for ALB"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //sonarqube
   ingress {
    from_port   = 4040
    to_port     = 4040
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
  { Name = "Alb security group" })
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
