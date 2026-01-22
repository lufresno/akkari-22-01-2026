data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Ubuntu 22.04 LTS (Canonical)
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "api_sg" {
  name        = "${var.project}-api-sg"
  description = "Security Group for SVFlix API"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH (lab; restrict by IP in prod)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Si quieres probar directo sin Nginx (no recomendado), abre 3000
  # ingress {
  #   description = "NestJS direct (demo)"
  #   from_port   = 3000
  #   to_port     = 3000
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-api-sg"
    Project = var.project
  }
}

resource "aws_instance" "api" {
  ami                    = data.aws_ami.ubuntu_2204.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.api_sg.id]

  key_name = var.key_name

  tags = {
    Name    = "${var.project}-api"
    Project = var.project
    Role    = "api"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    apt-get update -y
    apt-get install -y curl git nginx

    # Node.js 18
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs

    # PM2
    npm i -g pm2

    # Carpeta de despliegue
    mkdir -p /var/www/${var.project}-api
    chown -R ubuntu:ubuntu /var/www/${var.project}-api

    # Nginx reverse proxy -> Nest (3000)
    cat > /etc/nginx/sites-available/${var.project}-api << 'NGINX'
    server {
      listen 80;
      server_name _;

      location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
      }
    }
    NGINX

    ln -sf /etc/nginx/sites-available/${var.project}-api /etc/nginx/sites-enabled/${var.project}-api
    nginx -t
}