
output "vpc_id" { value = aws_vpc.main.id }

output "public_subnet_id" { value = aws_subnet.public_a.id }

output "private_subnet_id" { value = aws_subnet.private_a.id }

output "igw_id" { value = aws_internet_gateway.igw.id }

output "public_route_table_id" { value = aws_route_table.public.id }

output "public_nacl_id" { value = aws_network_acl.public.id }

output "alb_dns_name" { value = aws_lb.this.dns_name }

output "mysql_endpoint" { value = aws_db_instance.mysql.address }
