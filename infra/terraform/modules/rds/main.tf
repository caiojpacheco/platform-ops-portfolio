# RDS module — free-tier-compatible Postgres instance.
# Deployed in private subnets only; never exposed to the internet.

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-rds-subnets"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project}-${var.environment}-rds-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Allow Postgres access from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    description = "Postgres from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "this" {
  identifier        = "${var.project}-${var.environment}-postgres"
  engine            = "postgres"
  engine_version    = "16.2"
  instance_class    = "db.t3.micro"  # Free-tier eligible
  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = "platformops"
  username = "dbadmin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  backup_retention_period = 7
  deletion_protection     = terraform.workspace == "production" ? true : false
  skip_final_snapshot     = terraform.workspace != "production"

  tags = {
    Name = "${var.project}-${var.environment}-rds"
  }
}
