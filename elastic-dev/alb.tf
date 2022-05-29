
###-------- ALB -------###
resource "aws_lb" "elasticlb" {
  name               = join("-", [local.application.app_name, "elasticlb"])
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elastic.id, aws_security_group.main-alb.id]
  subnets            = [aws_subnet.main-public-1.id, aws_subnet.main-public-2.id]
  idle_timeout       = "60"

  access_logs {
    bucket  = aws_s3_bucket.elastics3dev.bucket
    prefix  = join("-", [local.application.app_name, "elasticlb-s3logs"])
    enabled = true
  }
  tags = merge(local.common_tags,
    { Name = "elasticserver"
  Application = "public" })
}

###------- ALB Health Check -------###
resource "aws_lb_target_group" "elastic_tglb" {
  name     = join("-", [local.application.app_name, "elastictglb"])
  port     = 12443
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
resource "aws_lb_target_group_attachment" "elastic_tglbat" {
  target_group_arn = aws_lb_target_group.elastic_tglb.arn
  target_id        = aws_instance.elastic-1.id
  port             = 12443
}

# # ####-------- SSL Cert ------#####
resource "aws_lb_listener" "elastic_lblist2" {
  load_balancer_arn = aws_lb.elasticlb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.elasticcert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.elastic_tglb.arn
  }
}


####---- Redirect Rule -----####
resource "aws_lb_listener" "elastic_lblist" {
  load_balancer_arn = aws_lb.elasticlb.arn
  port              = "12443"
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
resource "aws_s3_bucket" "elastics3dev" {
  bucket = join("-", [local.application.app_name, "logdev"])
  acl    = "private"

  tags = merge(local.common_tags,
    { Name = "elasticserver"
  bucket = "private" })
}
resource "aws_s3_bucket_policy" "elastics3dev" {
  bucket = aws_s3_bucket.elastics3dev.id

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
          aws_s3_bucket.elastics3dev.arn,
          "${aws_s3_bucket.elastics3dev.arn}/*",
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
resource "aws_iam_role" "elastic_role" {
  name = join("-", [local.application.app_name, "elasticrole"])

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
    { Name = "elasticserver"
  Role = "elasticrole" })
}

#######------- IAM Role ------######
resource "aws_iam_role_policy" "elastic_policy" {
  name = join("-", [local.application.app_name, "elasticpolicy"])
  role = aws_iam_role.elastic_role.id

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
resource "aws_acm_certificate" "elasticcert" {
  domain_name       = "*.elitelabtools.com"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = merge(local.common_tags,
    { Name = "elasticdev.elitelabtools.com"
  Cert = "elasticcert" })
}

###------- Cert Validation -------###
data "aws_route53_zone" "main-zone" {
  name         = "elitelabtools.com"
  private_zone = false
}

resource "aws_route53_record" "elasticzone_record" {
  for_each = {
    for dvo in aws_acm_certificate.elasticcert.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "elasticcert" {
  certificate_arn         = aws_acm_certificate.elasticcert.arn
  validation_record_fqdns = [for record in aws_route53_record.elasticzone_record : record.fqdn]
}

##------- ALB Alias record ----------##
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main-zone.zone_id
  name    = "elasticdev.elitelabtools.com"
  type    = "A"

  alias {
    name                   = aws_lb.elasticlb.dns_name
    zone_id                = aws_lb.elasticlb.zone_id
    evaluate_target_health = true
  }
}