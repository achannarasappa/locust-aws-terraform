######
# Role
######
resource "aws_iam_role" "locust_job" {
  name = "locust_job"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda-role-policy-attach" {
  role       = "${aws_iam_role.locust_job.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

resource "aws_iam_role_policy_attachment" "lambda-execute-policy-attach" {
  role       = "${aws_iam_role.locust_job.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

resource "aws_iam_role_policy_attachment" "lambda-basic-execution-policy-attach" {
  role       = "${aws_iam_role.locust_job.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda-vpc-access-execution-policy-attach" {
  role       = "${aws_iam_role.locust_job.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

######
# Compute
######
resource "aws_ecs_cluster" "locust" {
  name = "locust"
}

resource "aws_ecs_task_definition" "locust_chrome" {
  family                   = "chrome"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  container_definitions = <<DEFINITION
[
  {
    "essential": true,
    "image": "browserless/chrome:latest",
    "memory": 512,
    "name": "locust_chrome",
    "network_mode": "awsvpc",
    "portMappings": [
      {
        "containerPort": ${var.chrome_port},
        "hostPort": ${var.chrome_port}
      }
    ]
  }
]
DEFINITION
}

data "aws_ecs_task_definition" "locust_chrome" {
  task_definition = "${aws_ecs_task_definition.locust_chrome.family}"
  depends_on = [
    aws_ecs_task_definition.locust_chrome
  ]
}

resource "aws_ecs_service" "locust_chrome" {
  name            = "locust_chrome"
  cluster         = "${aws_ecs_cluster.locust.id}"
  desired_count   = 1
  task_definition = "${aws_ecs_task_definition.locust_chrome.family}:${max("${aws_ecs_task_definition.locust_chrome.revision}", "${data.aws_ecs_task_definition.locust_chrome.revision}")}"
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = ["${aws_security_group.locust.id}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.locust_chrome.id}"
    container_name   = "locust_chrome"
    container_port   = "${var.chrome_port}"
  }

  depends_on = [
    aws_lb_listener.locust_chrome,
    data.aws_ecs_task_definition.locust_chrome
  ]

}

######
# Network
######
resource "aws_security_group" "locust" {
  vpc_id = "${var.vpc_id}"

  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "locust_chrome" {
  name               = "locust-chrome"
  internal           = true
  load_balancer_type = "application"
  subnets            = var.private_subnet_ids
  security_groups    = ["${aws_security_group.locust.id}"]
}

resource "aws_lb_target_group" "locust_chrome" {
  name        = "locust-chrome"
  port        = var.chrome_port
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"
  stickiness {
    type    = "lb_cookie"
    enabled = false
  }
}

resource "aws_lb_listener" "locust_chrome" {
  load_balancer_arn = "${aws_lb.locust_chrome.id}"
  port              = var.chrome_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.locust_chrome.id}"
    type             = "forward"
  }
}

######
# Storage
######
resource "aws_elasticache_subnet_group" "locust_redis" {
  name       = "locust-cache-subnet"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_cluster" "locust_redis" {
  cluster_id           = "locust-queue"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379
  subnet_group_name    = "${aws_elasticache_subnet_group.locust_redis.name}"
  security_group_ids   = ["${aws_security_group.locust.id}"]
}
