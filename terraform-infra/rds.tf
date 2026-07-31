resource "aws_db_subnet_group" "mean_app" {
  name       = "mean-app-db-subnet"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_security_group" "rds_sg" {
  name   = "mean-app-rds-sg"
  vpc_id = data.aws_vpc.default.id

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
}

resource "aws_db_instance" "mean_app_db" {
  identifier              = "mean-app-db"
  engine                  = "mysql"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.mean_app.name
  vpc_security_group_ids  = [data.aws_security_group.existing_sg.id]
  publicly_accessible     = true
  backup_retention_period = 1
  multi_az                = false
  skip_final_snapshot     = true
  db_name                 = "meanapp"
}