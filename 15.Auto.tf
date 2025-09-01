# Launch Template (기존 Launch Configuration 대체)
resource "aws_launch_template" "as_conf" {
  name_prefix   = "terraform-lt-backend"
  image_id      = "ami-056a29f2eddc40520"
  instance_type = "t3.micro"
  key_name      = "soonge97"

  user_data = base64encode(<<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y nginx
  EOF
  )

  vpc_security_group_ids = [aws_security_group.terraform-sg-bastion.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "jeff-userdata"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group (Launch Template 기반으로 수정)
resource "aws_autoscaling_group" "terraform-prd-asg" {
  name                      = "terraform-prd-asg"
  vpc_zone_identifier       = [
    aws_subnet.terraform-pub-subnet-2a.id,
    aws_subnet.terraform-pub-subnet-2c.id
  ]
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 3
  health_check_grace_period = 120
  health_check_type         = "ELB"
  target_group_arns         = [aws_lb_target_group.terraform-prd-tg.arn]

  launch_template {
    id      = aws_launch_template.as_conf.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "terraform-prd-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
