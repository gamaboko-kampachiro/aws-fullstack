#------------------------------------------------
# decribing alb

resource "aws_lb" "app_alb" {
  name               = "smart-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id] # We'll create this
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "SmartAppALB"
  }
}

#------------------------------------------------
# alb security groups

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  vpc_id      = aws_vpc.smart_vpc.id
  description = "Allow HTTP/HTTPS traffic"

  ingress {
    from_port   = 80
    to_port     = 80
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
}

#------------------------------------------------
# target groups

resource "aws_lb_target_group" "backend_tg" {
  name     = "backend-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.smart_vpc.id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

#------------------------------------------------
# listner

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

#------------------------------------------------
# launch template

resource "aws_launch_template" "backend_lt" {
  name_prefix   = "backend-lt-"
  image_id      = "ami-056335ec4a8783947"
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install git python3 -y
              sudo systemctl start amazon-ssm-agent
              sudo systemctl enable amazon-ssm-agent

              python3 -m ensurepip
              pip3 install --upgrade pip

              cd /home/ec2-user

              git clone https://github.com/gamaboko-kampachiro/aws-fullstack.git
              cd aws-fullstack/backend

              pip3 install flask pymysql boto3
              pip3 install -r requirements.txt

              echo "export DB_HOST=${aws_db_instance.smart_db.endpoint}" >> /etc/profile
              echo "export DB_USER=${var.db_username}" >> /etc/profile
              echo "export DB_PASS=${var.db_password}" >> /etc/profile
              echo "export S3_BUCKET=${aws_s3_bucket.app_bucket.bucket}" >> /etc/profile

              source /etc/profile

              nohup python3 app.py &          
              EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "backend-ec2"
    }
  }
}


#------------------------------------------------
# auto scaling groups

resource "aws_autoscaling_group" "backend_asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
  vpc_zone_identifier  = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.backend_tg.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 120

  tag {
    
      key                 = "Name"
      value               = "backend-ec2"
      propagate_at_launch = true
    
  }
}

#------------------------------------------------
# scaling policy

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "cpu-scale-out"
  scaling_adjustment      = 1
  adjustment_type         = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.backend_asg.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 60

  alarm_actions = [aws_autoscaling_policy.scale_out.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.backend_asg.name
  }
}

#------------------------------------------------
