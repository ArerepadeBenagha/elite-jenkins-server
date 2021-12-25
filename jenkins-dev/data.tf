data "cloudinit_config" "userdata" {
  gzip          = true
  base64_encode = true
  
  part {
    content_type = "text/x-shellscript"
    filename     = "userdata_jenkins"
    content      = templatefile("../templates/userdata_jenkins.tpl", {})
  }
}
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
data "aws_key_pair" "key_name" {
  key_id = "key-04bbc3f64e20fecf3"
}