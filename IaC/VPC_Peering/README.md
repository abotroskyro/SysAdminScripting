# VPC Peering Terraform Plan
# main.tf
This contains a terraform plan that creates a VPC peering connection between 3 separate VPCs spanning three regions. There are:
1. 3 VPCs in US-East1, US-East2, and US-West1. Each VPC has a public and 2 private subnets, and two availability zones. 
2. Route tables for the the private subnets in each VPC with the other 2 VPCs CIDR block to enable the peering connection as seen below:

## Routing Tables

**East 2 private route table #1 (10.2.16.0/20 and 10.2.32.0/20)**

| CIDR Block   | Target |
|:------------:|:------:|
| 10.2.16.0/20 | pc-e2w1 |
| 10.2.32.0/20 | pc-e2w1 |
| 10.0.16.0/20 | pc-e2e1 |
| 10.0.16.0/20 | pc-e2e1 |

**East 2 private route table #2 (10.1.32.0/20)**

| CIDR Block   | Target |
|:------------:|:------:|
| 10.2.16.0/20 | pc-e2w1 |
| 10.2.32.0/20 | pc-e2w1 |
| 10.0.16.0/20 | pc-e2e1 |
| 10.0.16.0/20 | pc-e2e1 |

**East 1 private route table #1 (10.0.16.0/20)**

| CIDR Block   | Target |
|:------------:|:------:|
| 10.2.16.0/20 | pc-e1w1 |
| 10.2.32.0/20 | pc-e1w1 |
| 10.1.16.0/20 | pc-e1e2 |
| 10.1.32.0/20 | pc-e1e2 |

**East 1 private route table #2 (10.0.32.0/20)**

| CIDR Block   | Target |
|:------------:|:------:|
| 10.2.16.0/20 | pc-e1w1 |
| 10.2.32.0/20 | pc-e1w1 |
| 10.1.16.0/20 | pc-e1e2 |
| 10.1.32.0/20 | pc-e1e2 |

**West 1 private route table #1 (10.2.16.0/20)**

| CIDR Block   | Target |
|:------------:|:------:|
| 10.0.16.0/20 | pc-w1e1 |
| 10.0.32.0/20 | pc-w1e1 |
| 10.1.16.0/20 | pc-w1e2 |
| 10.1.32.0/20 | pc-w1e2 |

**West 1 private route table #2 (10.2.32.0/20)**

| CIDR Block   | Target |
|:------------:|:------:|
| 10.0.16.0/20 | pc-w1e1 |
| 10.0.32.0/20 | pc-w1e1 |
| 10.1.16.0/20 | pc-w1e2 |
| 10.1.32.0/20 | pc-w1e2 |
