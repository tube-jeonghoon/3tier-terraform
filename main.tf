# VPC 설정
resource "aws_vpc" "tier3-vpc"{
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "tier3-vpc"
    }
}

# IG 설정
resource "aws_internet_gateway" "tier3-igw"{
    vpc_id = aws_vpc.tier3-vpc.id
    tags = {
        Name = "tier3-igw"
    }
}

# Nat Gateway 설정
resource "aws_eip" "tier3-nip"{
    vpc = true
    tags = {
        Name = "tier3-nip"
    }
}

resource "aws_nat_gateway" "tier3-ngw"{
    allocation_id = aws_eip.tier3-nip.id
    subnet_id   = aws_subnet.tier3-sub-pub-a.id
    tags = {
        Name = "tier3-ngw"
    }
}

# Subnet 생성
# public
resource "aws_subnet" "tier3-sub-pub-a"{
    vpc_id  = aws_vpc.tier3-vpc.id
    cidr_block  = "10.0.1.0/24"
    availability_zone = "ap-northeast-2a"
    # public ip를 할당하기 위해 true로 설정
    map_public_ip_on_launch = true

    tags = {
        Name = "tier3-sub-pub-a"
    }

}
resource "aws_subnet" "tier3-sub-pub-c"{
    vpc_id  = aws_vpc.tier3-vpc.id
    cidr_block  = "10.0.2.0/24"
    availability_zone = "ap-northeast-2c"
    map_public_ip_on_launch = true

    tags = {
        Name = "tier3-sub-pub-c"
    }
}

# private web
resource "aws_subnet" "tier3-sub-pri-a-web"{
    vpc_id  = aws_vpc.tier3-vpc.id
    cidr_block  = "10.0.10.0/24"
    availability_zone = "ap-northeast-2a"

    tags = {
        Name = "tier3-sub-pri-a-web"
    }
}
resource "aws_subnet" "tier3-sub-pri-c-web"{
    vpc_id  = aws_vpc.tier3-vpc.id
    cidr_block  = "10.0.20.0/24"
    availability_zone = "ap-northeast-2c"

    tags = {
        Name = "tier3-sub-pri-c-web"
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
resource "aws_route_table_association" "tier3-rtass-pub-a"{
    subnet_id = aws_subnet.tier3-sub-pub-a.id
    route_table_id = aws_route_table.tier3-rt-pub.id
}

resource "aws_route_table_association" "tier3-rtass-pub-c"{
    subnet_id = aws_subnet.tier3-sub-pub-c.id
    route_table_id = aws_route_table.tier3-rt-pub.id
}

# private web > nat
resource "aws_route_table" "tier3-rt-pri-web"{
    vpc_id = aws_vpc.tier3-vpc.id
    
    tags = {
      Name = "tier3-rt-pri-web"
    }
}

resource "aws_route" "tier3-r-pri-web"{
    route_table_id = aws_route_table.tier3-rt-pri-web.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.tier3-ngw.id
}

# private web subnet을 pirvate route table에 연결
resource "aws_route_table_association" "tier3-rtass-pri-a-web"{
    subnet_id = aws_subnet.tier3-sub-pri-a-web.id
    route_table_id = aws_route_table.tier3-rt-pri-web.id
}

resource "aws_route_table_association" "tier3-rtass-pri-c-web"{
    subnet_id = aws_subnet.tier3-sub-pri-c-web.id
    route_table_id = aws_route_table.tier3-rt-pri-web.id
}