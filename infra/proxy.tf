# ─── PROXY HTTPS (EC2 + Nginx) — evita Mixed Content del frontend HTTPS ───────
resource "aws_security_group" "proxy" {
  name        = "${var.project_name}-proxy-sg"
  description = "HTTP/HTTPS publico, SSH restringido"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.dev_ip_address == "0.0.0.0" ? "0.0.0.0/0" : "${var.dev_ip_address}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-proxy-sg" }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "proxy" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.proxy.id]
  key_name                = "notevate-key"

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    systemctl enable nginx

    cat > /etc/nginx/conf.d/notevate-proxy.conf <<'NGINXCONF'
    server {
        listen 80;
        server_name notevate.duckdns.org;

        location / {
            proxy_pass http://${aws_lb.main.dns_name};
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    NGINXCONF

    systemctl start nginx

    # Actualizar DuckDNS con la IP publica de esta instancia
    curl "https://www.duckdns.org/update?domains=notevate&token=e45645bd-527f-4e63-84a8-c35ba3d0ab34&ip="
  EOF

  tags = { Name = "${var.project_name}-proxy" }
}

resource "aws_eip" "proxy" {
  instance = aws_instance.proxy.id
  domain   = "vpc"
  tags     = { Name = "${var.project_name}-proxy-eip" }
}

output "proxy_public_ip" {
  value = aws_eip.proxy.public_ip
}

output "proxy_http_url" {
  value = "http://notevate.duckdns.org"
}