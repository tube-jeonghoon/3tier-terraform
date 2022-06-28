# VPC 설정
resource "aws_vpc" "tier3-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "tier3-vpc"
  }
}

# IG 설정
resource "aws_internet_gateway" "tier3-igw" {
  vpc_id = aws_vpc.tier3-vpc.id
  tags = {
    Name = "tier3-igw"
  }
}

# Nat Gateway 설정
resource "aws_eip" "tier3-nip" {
  vpc = true
  tags = {
    Name = "tier3-nip"
  }
}

resource "aws_nat_gateway" "tier3-ngw" {
  allocation_id = aws_eip.tier3-nip.id
  subnet_id     = aws_subnet.tier3-sub-pub-a.id
  tags = {
    Name = "tier3-ngw"
  }
}

# Subnet 생성
# public
resource "aws_subnet" "tier3-sub-pub-a" {
  vpc_id            = aws_vpc.tier3-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"
  # public ip를 할당하기 위해 true로 설정
  map_public_ip_on_launch = true

  tags = {
    Name = "tier3-sub-pub-a"
  }

}
resource "aws_subnet" "tier3-sub-pub-c" {
  vpc_id                  = aws_vpc.tier3-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "tier3-sub-pub-c"
  }
}

# private web
resource "aws_subnet" "tier3-sub-pri-a-web" {
  vpc_id            = aws_vpc.tier3-vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "tier3-sub-pri-a-web"
  }
}
resource "aws_subnet" "tier3-sub-pri-c-web" {
  vpc_id            = aws_vpc.tier3-vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "tier3-sub-pri-c-web"
  }
}

# private was
resource "aws_subnet" "tier3-sub-pri-a-was" {
  vpc_id            = aws_vpc.tier3-vpc.id
  cidr_block        = "10.0.30.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "tier3-sub-pri-a-was"
  }
}
resource "aws_subnet" "tier3-sub-pri-c-was" {
  vpc_id            = aws_vpc.tier3-vpc.id
  cidr_block        = "10.0.40.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "tier3-sub-pri-c-was"
  }
}

# private db
resource "aws_subnet" "tier3-sub-pri-a-db" {
  vpc_id            = aws_vpc.tier3-vpc.id
  cidr_block        = "10.0.50.0/24"
  availability_zone = "ap-northeast-2c"
  
  tags = {
    Name = "tier3-sub-pri-a-db"
  }
}

resource "aws_subnet" "tier3-sub-pri-c-db" {
  vpc_id            = aws_vpc.tier3-vpc.id
  cidr_block        = "10.0.60.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "tier3-sub-pri-c-db"
  }
}


# Route table
# public > igw
resource "aws_route_table" "tier3-rt-pub" {
  vpc_id = aws_vpc.tier3-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tier3-igw.id
  }
  tags = {
    Name = "tier3-rt-pub"
  }
}

# public subnet을 public route table에 연결
resource "aws_route_table_association" "tier3-rtass-pub-a" {
  subnet_id      = aws_subnet.tier3-sub-pub-a.id
  route_table_id = aws_route_table.tier3-rt-pub.id
}

resource "aws_route_table_association" "tier3-rtass-pub-c" {
  subnet_id      = aws_subnet.tier3-sub-pub-c.id
  route_table_id = aws_route_table.tier3-rt-pub.id
}

# private web > nat
resource "aws_route_table" "tier3-rt-pri-web" {
  vpc_id = aws_vpc.tier3-vpc.id

  tags = {
    Name = "tier3-rt-pri-web"
  }
}

resource "aws_route" "tier3-r-pri-web" {
  route_table_id         = aws_route_table.tier3-rt-pri-web.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.tier3-ngw.id
}

# private web subnet을 pirvate route table에 연결
resource "aws_route_table_association" "tier3-rtass-pri-a-web" {
  subnet_id      = aws_subnet.tier3-sub-pri-a-web.id
  route_table_id = aws_route_table.tier3-rt-pri-web.id
}

resource "aws_route_table_association" "tier3-rtass-pri-c-web" {
  subnet_id      = aws_subnet.tier3-sub-pri-c-web.id
  route_table_id = aws_route_table.tier3-rt-pri-web.id
}

# BASTION
# security group
resource "aws_security_group" "tier3-sg-pub-bastion" {
  name        = "tier3-sg-pub-bastion"
  description = "tier3-sg-pub-bastion"
  vpc_id      = aws_vpc.tier3-vpc.id

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
  tags = {
    Name = "tier3-sg-pub-bastion"
  }
}

# EC2
resource "aws_instance" "tier3-ec2-pub-a-bastion" {
  ami               = "ami-0fd0765afb77bcca7"
  instance_type     = "t3.small"
  availability_zone = "ap-northeast-2a"

  subnet_id = aws_subnet.tier3-sub-pub-a.id
  key_name  = aws_key_pair.mykeypair.key_name
  vpc_security_group_ids = [
    aws_security_group.tier3-sg-pub-bastion.id
  ]
  tags = {
    Name = "tier3-ec2-pub-a-bastion"
  }
}

# WEB & WAS
# web security group
resource "aws_security_group" "tier3-sg-pri-web" {
  name        = "tier3-sg-pri-web"
  description = "tier3-sg-pri-web"
  vpc_id      = aws_vpc.tier3-vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.tier3-sg-pub-bastion.id]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "tier3-sg-pri-web"
  }
}

# was securtiy group
resource "aws_security_group" "tier3-sg-pri-was" {
  name        = "tier3-sg-pri-was"
  description = "tier3-sg-pri-was"
  vpc_id      = aws_vpc.tier3-vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.tier3-sg-pub-bastion.id]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.10.0/24", "10.0.20.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "tier3-sg-pri-was"
  }
}

# DB scurity group
resource "aws_security_group" "tier3-sg-pri-db" {
  name        = "tier3-sg-pri-db"
  description = "tier3-sg-pri-db"
  vpc_id      = aws_vpc.tier3-vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.tier3-sg-pub-bastion.id]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "tier3-sg-pri-db"
  }
}

# web & was & DB EC2
# web, db 이중화 구성
# a 대역에 ec2 생성
resource "aws_instance" "tier3-ec2-pri-a-web1" {
  ami               = "ami-0fd0765afb77bcca7"
  instance_type     = "t3.small"
  availability_zone = "ap-northeast-2a"

  subnet_id = aws_subnet.tier3-sub-pri-a-web.id
  key_name  = aws_key_pair.mykeypair.key_name
  vpc_security_group_ids = [
    aws_security_group.tier3-sg-pri-web.id
  ]
  tags = {
    Name = "tier3-ec2-pri-a-web1"
  }
}

# c 대역에 ec2 생성
resource "aws_instance" "tier3-ec2-pri-c-web2" {
  ami               = "ami-0fd0765afb77bcca7"
  instance_type     = "t3.small"
  availability_zone = "ap-northeast-2c"

  subnet_id = aws_subnet.tier3-sub-pri-c-web.id
  key_name  = aws_key_pair.mykeypair.key_name
  vpc_security_group_ids = [
    aws_security_group.tier3-sg-pri-web.id
  ]
  tags = {
    Name = "tier3-ec2-pri-c-web2"
  }
}

#db
resource "aws_instance" "tier3-ec2-pri-a-db1" {
  ami               = "ami-0fd0765afb77bcca7"
  instance_type     = "t3.small"
  availability_zone = "ap-northeast-2a"

  subnet_id = aws_subnet.tier3-sub-pri-a-db.id
  key_name  = aws_key_pair.mykeypair.key_name
  vpc_security_group_ids = [
    aws_security_group.tier3-sg-pri-db.id
  ]
  tags = {
    Name = "tier3-ec2-pri-a-db1"
  }
}

resource "aws_instance" "tier3-ec2-pri-c-db2" {
  ami               = "ami-0fd0765afb77bcca7"
  instance_type     = "t3.small"
  availability_zone = "ap-northeast-2c"

  subnet_id = aws_subnet.tier3-sub-pri-c-db.id
  key_name  = aws_key_pair.mykeypair.key_name
  vpc_security_group_ids = [
    aws_security_group.tier3-sg-pri-db.id
  ]
  tags = {
    Name = "tier3-ec2-pir-c-db2"
  }
}



# was 역시 이중화 구성이지만 ebs를 추가적으로 붙여준다.

# was
resource "aws_instance" "tier3-ec2-pri-a-was1" {
  ami               = "ami-0fd0765afb77bcca7"
  instance_type     = "t3.small"
  availability_zone = "ap-northeast-2a"

  subnet_id = aws_subnet.tier3-sub-pri-a-was.id
  key_name  = aws_key_pair.mykeypair.key_name


  # ebs 추가적으로 구성
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = "8"
  }


  vpc_security_group_ids = [
    aws_security_group.tier3-sg-pri-was.id
  ]
  tags = {
    Name = "tier3-ec2-pri-a-was1"
  }
}


resource "aws_instance" "tier3-ec2-pri-c-was2" {
  ami               = "ami-0fd0765afb77bcca7"
  instance_type     = "t3.small"
  availability_zone = "ap-northeast-2c"

  subnet_id = aws_subnet.tier3-sub-pri-c-was.id
  key_name  = aws_key_pair.mykeypair.key_name


  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = "8"
  }

  vpc_security_group_ids = [
    aws_security_group.tier3-sg-pri-was.id
  ]
  tags = {
    Name = "tier3-ec2-pri-c-was2"
  }
}

# Application Load Balencer (ALB)
# alb 생성
resource "aws_lb" "tier3-alb-web" {
  name               = "tier3-alb-web"
  internal           = false # 외부
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tier3-sg-alb-web.id]                       # alb는 sg 필요
  subnets            = [aws_subnet.tier3-sub-pub-a.id, aws_subnet.tier3-sub-pub-c.id] # public subnet에서 web 통신
  tags = {
    Name = "tier3-alb-web"
  }
}

# 타겟그룹 생성
resource "aws_lb_target_group" "tier3-atg-web" {
  name        = "tier3-atg-web"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.tier3-vpc.id
  target_type = "instance"
  tags = {
    Name = "tier3-atg-web"
  }
}

# 리스너 생성
resource "aws_lb_listener" "tier3-alt-web" {
  load_balancer_arn = aws_lb.tier3-alb-web.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tier3-atg-web.arn
  }
}

# 2개의 web attachement
resource "aws_lb_target_group_attachment" "tier3-att-web1" {
  target_group_arn = aws_lb_target_group.tier3-atg-web.arn
  target_id        = aws_instance.tier3-ec2-pri-a-web1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "tier3-att-web2" {
  target_group_arn = aws_lb_target_group.tier3-atg-web.arn
  target_id        = aws_instance.tier3-ec2-pri-c-web2.id
  port             = 80
}

# alb sg
resource "aws_security_group" "tier3-sg-alb-web" {
  name        = "tier3-sg-alb-web"
  description = "tier3-sg-alb-web"
  vpc_id      = aws_vpc.tier3-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "tier3-sg-alb-web"
  }
}

# Network Load Balancer (NLB)
# nlb 생성
resource "aws_lb" "tier3-nlb-was" {
  name               = "tier3-nlb-was"
  internal           = true # 내부 접근
  load_balancer_type = "network"
  subnets            = [aws_subnet.tier3-sub-pri-a-web.id, aws_subnet.tier3-sub-pri-c-web.id] # web subnet에서 was를 바라봄
  tags = {
    Name = "tier3-nlb-was"
  }
}

# 타겟그룹
# was에서 진행 될 tomcat의 경우, 8080 port로 통신된다.
resource "aws_lb_target_group" "tier3-ntg-was" {
  name        = "tier3-ntg-was"
  port        = "8080"
  protocol    = "TCP"
  vpc_id      = aws_vpc.tier3-vpc.id
  target_type = "instance"
  tags = {
    Name = "tier3-ntg-was"
  }
}

resource "aws_lb_listener" "tier3-nlt-was" {
  load_balancer_arn = aws_lb.tier3-nlb-was.arn
  port              = "8080"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tier3-ntg-was.arn
  }
}

resource "aws_lb_target_group_attachment" "tier3-ntt-was1" {
  target_group_arn = aws_lb_target_group.tier3-ntg-was.arn
  target_id        = aws_instance.tier3-ec2-pri-a-was1.id
  port             = 8080
}
resource "aws_lb_target_group_attachment" "tier3-ntt-was2" {
  target_group_arn = aws_lb_target_group.tier3-ntg-was.arn
  target_id        = aws_instance.tier3-ec2-pri-c-was2.id
  port             = 8080
}
