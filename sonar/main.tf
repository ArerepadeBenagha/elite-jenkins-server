###########------ sonar Server -----########
resource "aws_instance" "sonarserver" {
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
    { Name = "sonar-server"
  Application = "public" })
}
###-------- ALB -------###
resource "aws_lb" "sonarlb" {
  name               = join("-", [local.application.app_name, "sonarlb"])
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2-sg.id, aws_security_group.main-alb.id]
  subnets            = [aws_subnet.main-public-1.id, aws_subnet.main-public-2.id]
  idle_timeout       = "120"

  access_logs {
    bucket  = aws_s3_bucket.logs_s3dev.bucket
    prefix  = join("-", [local.application.app_name, "sonarlb-s3logs"])
    enabled = true
  }
  tags = merge(local.common_tags,
    { Name = "sonarserver"
  Application = "public" })
}
resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC5OS4XQssj/ySNaSlTQ+ToMeFgggyaDzLYVgVecOnHG2wrLbVnmvqt/ujdEZGhdcHVtlaEgBnjpoWB8CbUkjN280VDD6CLEwlT7pWM9JxXApkAt/uNiabeSeows2CReGz+KsOu3sYQRLl0M/++NfDzdjYNudeVoyMwXvuvL1x06cDRUs1FSVmRFeaHd99rOWHzCMnwOlCpqBNrzcvvcxG+dW2+N2QzoSylIyuUs4QVnV4yRPd/4VSBI6N08F43AcBqDGgUoNOsuUq+TFf957Ejo+vORUmLz0hFPHNgVsiMjK0ASp9ykLnGBT5bwGaXwMIA9C1gGTvN7ZZyTbMcZNNgRy9IxElJgWgNGqfQZ8qyd+jjitcs8Kx0UWAIv6I7ocnfV5cgWR1RB3DXuguogX7Me3WbDU9Qq8V4EkUJATp967MrsVQDNRTETE8oIcVV10W5DrBI2gzj5y92JdzKvrmFjqwqmddZeBfd70xD5sGchtR9ZWZsMs8YqgFgsmzURas= lbena@LAPTOP-QB0DU4OG"
}
# ###------- ALB Health Check -------###
resource "aws_lb_target_group" "sonar_tglb" {
  name     = join("-", [local.application.app_name, "sonartglb"])
  port     = 9000
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
resource "aws_lb_target_group_attachment" "sonar_tglbat" {
  target_group_arn = aws_lb_target_group.sonar_tglb.arn
  target_id        = aws_instance.sonarserver.id
  port             = 9000
}

# # ####-------- SSL Cert ------#####
resource "aws_lb_listener" "sonar_lblist2" {
  load_balancer_arn = aws_lb.sonarlb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.sonarcert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sonar_tglb.arn
  }
}

####---- Redirect Rule -----####
resource "aws_lb_listener" "sonar_lblist" {
  load_balancer_arn = aws_lb.sonarlb.arn
  port              = "9000"
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
    { Name = "sonarserver"
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
resource "aws_iam_role" "sonar_role" {
  name = join("-", [local.application.app_name, "sonarrole"])

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
    { Name = "sonarserver"
  Role = "sonarrole" })
}

#######------- IAM Role ------######
resource "aws_iam_role_policy" "sonar_policy" {
  name = join("-", [local.application.app_name, "sonarpolicy"])
  role = aws_iam_role.sonar_role.id

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
resource "aws_acm_certificate" "sonarcert" {
  domain_name       = "*.elitelabtools.com"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = merge(local.common_tags,
    { Name = "sonardev.elitelabtools.com"
  Cert = "sonarcert" })
}

###------- Cert Validation -------###
data "aws_route53_zone" "main-zone" {
  name         = "elitelabtools.com"
  private_zone = false
}

resource "aws_route53_record" "sonarzone_record" {
  for_each = {
    for dvo in aws_acm_certificate.sonarcert.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "sonarcert" {
  certificate_arn         = aws_acm_certificate.sonarcert.arn
  validation_record_fqdns = [for record in aws_route53_record.sonarzone_record : record.fqdn]
}

##------- ALB Alias record ----------##
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main-zone.zone_id
  name    = "sonardev.elitelabtools.com"
  type    = "A"

  alias {
    name                   = aws_lb.sonarlb.dns_name
    zone_id                = aws_lb.sonarlb.zone_id
    evaluate_target_health = true
  }
}

#EC2-SG
resource "aws_security_group" "ec2-sg" {
  vpc_id      = aws_vpc.main.id
  name        = "public web sonar sg"
  description = "security group Ec2-server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.main-alb.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.main-alb.id]
  }

    ingress {
    from_port       = 5432
    to_port         = 5432
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
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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