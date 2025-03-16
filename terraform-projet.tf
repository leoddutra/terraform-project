provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "vepece" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vepece"
  }
}

resource "aws_subnet" "publica" {
  vpc_id            = aws_vpc.vepece.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "publica"
  }
}

resource "aws_subnet" "privada" {
  vpc_id            = aws_vpc.vepece.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "privada"
  }
}

resource "aws_subnet" "privada2" {
  vpc_id            = aws_vpc.vepece.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "privada2"
  }
}

resource "aws_security_group" "cw_sg" {
  name        = "cw-sg"
  description = "Security group for web tier"
  vpc_id      = aws_vpc.vepece.id

  #Permitir tráfego HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Permitir tráfego SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Permitir todo o trafego de saída
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cw-sg"
  }
}

resource "aws_security_group" "bd_sg" {
  name        = "bd-sg"
  description = "SecurityGroup banco de dados"
  vpc_id      = aws_vpc.vepece.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.cw_sg.id] # Apenas a camada web pode acessar
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bd_sg"
  }
}

resource "aws_instance" "ec2img" {
  ami                    = "ami-0cb91c7de36eed2cb"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.publica.id
  vpc_security_group_ids = [aws_security_group.cw_sg.id]

  associate_public_ip_address = true # APARECER IP PUBLICO

  tags = {
    Name = "ec2img"
  }
}

resource "aws_db_instance" "my_db" {
  identifier           = "mydbinstance"
  engine               = "mysql"
  engine_version       = "5.7" 
  instance_class       = "db.t3.micro" 
  allocated_storage    = 20 
  storage_type         = "gp2" 
  username             = "admin"
  password             = "suasenha123" 
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  publicly_accessible  = false # Banco de dados não acessível diretamente da internet
  vpc_security_group_ids = [aws_security_group.bd_sg.id]
  db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.name

  tags = {
    Name = "my-db-instance"
  }
}

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name = "my-db-subnet-group"
  subnet_ids = [
    aws_subnet.privada.id,
    aws_subnet.privada2.id
  ]

  tags = {
    Name = "my-db-subnet-group"
  }

}