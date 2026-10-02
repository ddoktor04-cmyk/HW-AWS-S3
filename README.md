# AWS Terraform — ALB + 2 EC2 (MyStat Static Sites)

Infrastructure as Code (IaC) project: an **Application Load Balancer** distributing traffic across **2 EC2 instances** running Apache2 with different static sites about [MyStat](https://mystat.itstep.org/).

## Architecture

```
                        ┌─────────────────────────────┐
                        │   Application Load Balancer │
       Internet ───────▶│   HTTP :80 (public)         │
                        └──────────┬──────────────────┘
                     ┌─────────────┴─────────────┐
                     ▼                           ▼
        ┌────────────────────────┐   ┌────────────────────────┐
        │  EC2 Web1 (main)       │   │  EC2 Web2 (backup)     │
        │  Основний сайт         │   │  Резервний сайт        │
        │  13.48.28.151*         │   │  16.171.43.90*         │
        └────────────────────────┘   └────────────────────────┘
```

\* example IPs — dynamic, see `terraform output`

## Project Structure

```
cmd521_terraform/
├── main.tf                  # Provider, default VPC data sources, web SG
├── sg.tf                    # ALB security group
├── ec2.tf                   # 2 EC2 instances (count = 2)
├── alb.tf                   # ALB, target group, listener, attachments
├── vars.tf                  # Variable declarations
├── outputs.tf               # alb_dns_name, instance_ids, site_urls
├── files/
│   ├── site-main.html       # "Основний сайт" — served by Web1
│   ├── site-backup.html     # "Резервний сайт" — served by Web2
│   └── userdata.tftpl       # user_data template (Apache2 + site content)
├── terraform.tfvars         # Secrets (not in git)
├── terraform.tfvars.example # Example variables file
├── .gitignore               # Git ignore rules
└── README.md                # This file
```

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_lb.web` | Public Application Load Balancer (3 default subnets, 2+ AZ) |
| `aws_lb_target_group.web` | HTTP/80 target group, health check `GET /` → 200 |
| `aws_lb_listener.http` | Port 80 → forward to target group |
| `aws_lb_target_group_attachment.web` | Both instances attached |
| `aws_instance.web[0]` | Web1 — "Основний сайт" (MyStat main page) |
| `aws_instance.web[1]` | Web2 — "Резервний сайт" (MyStat backup mirror) |
| `aws_security_group.alb` | ALB SG: HTTP 80 from internet |
| `aws_security_group.web` | Web SG: HTTP 80 only from ALB SG, SSH 22 |

## Security Group Rules

| SG | Direction | Port | Source | Description |
|----|-----------|------|--------|-------------|
| alb | ingress | 80 | 0.0.0.0/0 | HTTP from internet |
| alb | egress | all | 0.0.0.0/0 | Allow all outbound |
| web | ingress | 80 | 0.0.0.0/0 | HTTP (lab: direct + via ALB) |
| web | ingress | 22 | 0.0.0.0/0 | SSH access |
| web | egress | all | 0.0.0.0/0 | Allow all outbound |

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in AWS credentials
terraform init
terraform plan
terraform apply
```

## Outputs

| Output | Description |
|--------|-------------|
| `alb_dns_name` | DNS name of the load balancer |
| `site_urls` | Full URL of the load balancer |
| `instance_ids` | EC2 instance IDs ([0] = main, [1] = backup) |
| `alb_zone_id` | Route 53 zone ID of the ALB |

## Verify

```bash
terraform output -raw site_urls
# Open in browser / curl repeatedly — responses alternate between
# "Основний сайт" and "Резервний сайт" (round-robin)
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_access_key` | AWS Access Key ID | - |
| `aws_secret_key` | AWS Secret Access Key | - |
| `aws_region` | AWS region | eu-north-1 |
| `aws_zone` | AWS availability zone | eu-north-1a |
| `aws_image_id` | Ubuntu AMI ID for EC2 | ami-0aba19e56f3eaec05 |
| `aws_instance_type` | EC2 instance type (legacy) | t3.small |
| `aws_instance_type_web` | Web node instance type | t3.micro |
| `aws_key_name` | Name of SSH key pair | Key1 |

## Security

- **Secrets**: Stored in `terraform.tfvars` (not committed to git)
- **Sensitive variables**: Marked with `sensitive = true`
- **State files**: Ignored by git (`.gitignore`)
- **Network**: Port 80 on instances is open (lab simplification) — direct IP access works, HTTP also goes through the ALB

⚠️ **Important**: Never commit `terraform.tfvars` or `*.tfstate` to version control!

## Cleanup

```bash
terraform destroy
```

## License

This project is for demonstration purposes.
