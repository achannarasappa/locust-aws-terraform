output "redis_hostname" {
  value       = aws_elasticache_cluster.locust_redis.cache_nodes.0.address
  description = "Hostname for the Redis instance containing the Locust queue"
}
output "chrome_hostname" {
  value       = aws_lb.locust_chrome.dns_name
  description = "Hostname for the Chrome instance used to execute HTTP requests"
}

output "security_group_id" {
  value       = aws_security_group.locust.id
  description = "Security group for infrastructure related to Locust"
}

output "iam_role_arn" {
  value       = aws_iam_role.locust_job.arn
  description = "AWS ARN with permissions for an AWS Lambda to connect to Chrome and Redis and run a Locust in a AWS Lambda"
}
