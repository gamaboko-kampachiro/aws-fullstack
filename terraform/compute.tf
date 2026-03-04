#------------------------------------------------
# Back-end EC2

resource "aws_instance" "backend" {
  ami                    = "ami-056335ec4a8783947" # Replace with latest Amazon Linux for your region
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
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

              pip3 install flask pymysql
              pip3 install -r requirements.txt

              echo "export DB_HOST=${aws_db_instance.smart_db.endpoint}" >> /etc/profile
              echo "export DB_USER=${var.db_username}" >> /etc/profile
              echo "export DB_PASS=${var.db_password}" >> /etc/profile
              echo "export S3_BUCKET=${aws_s3_bucket.app_bucket.bucket}" >> /etc/profile

              source /etc/profile

              nohup python3 app.py &          
              EOF

  tags = {
    Name = "backend-ec2"
  }
}

#------------------------------------------------