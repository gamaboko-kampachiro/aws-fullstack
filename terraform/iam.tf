#------------------------------------------------
# IAM Role

resource "aws_iam_role" "ec2_role" {
  name = "backend-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

#------------------------------------------------
# Attach S3 Access Policy

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

#------------------------------------------------
# attaching ssm manager 

resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#------------------------------------------------
# give Instance Profile

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "backend-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

#------------------------------------------------
