
#main.tffffff

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  alias  = "aws-us-west-1"
  region = "us-west-1"
}

provider "aws" {
  alias  = "aws-us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "aws-us-east-2"
  region = "us-east-2"
}







/* resource "aws_instance" "node_1" {
  provider      = aws.aws-us-west-1
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"
  tags = {
    Name = "VINDemo"
  }
}

resource "aws_instance" "node_2" {
  provider      = aws.aws-us-east-1
  ami           = "ami-0f924dc71d44d23e2"
  instance_type = "t2.micro"
  tags = {
    Name = "VINDemo"
  }
}

resource "aws_instance" "node_3" {
  provider      = aws.aws-us-east-2
  ami           = "ami-0f924dc71d44d23e2"
  instance_type = "t2.micro"
  tags = {
    Name = "VINDemo"
  }
}
*/



###VPCName[0]=East1 will always be for USEast1 and the subnets match the indices of the VPC they should be in. Use VPCName[1]= East2, VPCName[2]=West1 when you only want to apply VPC configs that are not shared between all 3 VPCs. 
data "aws_region" "current" {}




module "vpcEast2" {
  providers = {
    aws = aws.aws-us-east-2
  }
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.16.1"
  name = "East2VPC"
	

  cidr = var.East2NetSpace
  instance_tenancy = "default"

  azs                 =  ["us-east-2a", "us-east-2b"] ##hardcoding az's because not all az's are available for every region i.e. us-east2b exists but us-west1b doesn't 
  private_subnets     = var.E2PrivateSubnet 
  public_subnets      = var.E2PublicSubnet

  create_database_subnet_group = false

  enable_nat_gateway = false #if we enable NAT Gateway to be false, should we be using infra_subnets instead?
  enable_vpn_gateway = false
  create_igw = true #will create an Internet Gateway when public subnets are created
  


  tags = {
    Name        = "VPCEAST2"
  }
}

module "vpcEast1" {
  providers = {
    aws = aws.aws-us-east-1
  }
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.16.1"
  name = "East1VPC"

  cidr = var.East1NetSpace
  instance_tenancy = "default"

  azs = ["us-east-1a", "us-east-1b"]
  private_subnets     = var.E1PrivateSubnet
  public_subnets      = var.E1PublicSubnet

  create_database_subnet_group = false

  enable_nat_gateway = false #if we enable NAT Gateway to be false, should we be using infra_subnets instead?
  enable_vpn_gateway = false
  create_igw = true #will create an Internet Gateway when public subnets are created
  


  tags = {
    Name        = "VPCEAST1"
  }
}

module "vpcWest1" {
  providers = {
    aws = aws.aws-us-west-1
  }
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.16.1"
  name = "West1VPC"

  cidr = var.West1NetSpace
  instance_tenancy = "default"

  azs                 = ["us-west-1a", "us-west-1c"]
  private_subnets     = var.W1PrivateSubnet
	private_subnet_tags = {
    SubName        = "VPCWESTPrivate"
  }

  public_subnets      = var.W1PublicSubnet

  create_database_subnet_group = false

  enable_nat_gateway = false #if we enable NAT Gateway to be false, should we be using infra_subnets instead?
  enable_vpn_gateway = false
  create_igw = true #will create an Internet Gateway when public subnets are created
  


  tags = {
    Name        = "VPCWEST"
  }
}



provider "aws" {
  alias  = "peer"
  region = "us-east-1"

  # Accepter's credentials.
}


resource "aws_vpc_peering_connection" "E2RequesterPeer" {
  
  provider = aws.aws-us-east-2 #region provider of where the requester vpc is
  vpc_id        = module.vpcEast2.vpc_id #requester vpc id
  peer_vpc_id   = module.vpcEast1.vpc_id #accepter vpc id
  peer_owner_id = <AWS Account ID>
  peer_region   = "us-east-1" #region of accepter
  auto_accept   = false #must be false for inter-region VPC

  tags = {
    Side = "Requester"
		Relation = "East2ToEast1"
  }
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer" {
 
  provider                  = aws.aws-us-east-1 #region/provider of Accepter VPC
  vpc_peering_connection_id = aws_vpc_peering_connection.E2RequesterPeer.id #id of the vpc_peering_connection resource created in block above
  auto_accept               = true
  tags = {
    Side = "Accepter"
		Relation = "East1AcceptsEast2"
  }
}






















resource "aws_vpc_peering_connection" "W1RequesterPeer" {
  
  provider = aws.aws-us-west-1 #region provider of where the requester vpc is
  vpc_id        = module.vpcWest1.vpc_id #requester vpc id
  peer_vpc_id   = module.vpcEast1.vpc_id #accepter vpc id
  peer_owner_id = <AWS Account ID>
  peer_region   = "us-east-1" #region of accepter
  auto_accept   = false #must be false for inter-region VPC

  tags = {
    Side = "Requester"
		Relation = "West1RequestingEast1"
  }
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "E1AcceptW1" {
 
  provider                  = aws.aws-us-east-1 #region/provider of Accepter VPC
  vpc_peering_connection_id = aws_vpc_peering_connection.W1RequesterPeer.id #id of the vpc_peering_connection resource created in block above
  auto_accept               = true
  tags = {
    Side = "Accepter"
		Relation = "East1AcceptsWest1"
  }
}


resource "aws_vpc_peering_connection" "W1toE2RequesterPeer" {
  
  provider = aws.aws-us-west-1 #region provider of where the requester vpc is
  vpc_id        = module.vpcWest1.vpc_id #requester vpc id
  peer_vpc_id   = module.vpcEast2.vpc_id #accepter vpc id
  peer_owner_id = <AWS Account ID>
  peer_region   = "us-east-2" #region of accepter
  auto_accept   = false #must be false for inter-region VPC

  tags = {
    Side = "Requester"
		Relation = "West1RequestingEast2"
  }
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "E2AcceptW1" {
 
  provider                  = aws.aws-us-east-2 #region/provider of Accepter VPC
  vpc_peering_connection_id = aws_vpc_peering_connection.W1toE2RequesterPeer.id #id of the vpc_peering_connection resource created in block above
  auto_accept               = true
  tags = {
    Side = "Accepter"
		Relation = "East2AcceptsWest1"
  }
}
































resource "aws_route" "W1toE2RouteSubnet1" {
 count = 2
provider = aws.aws-us-west-1
  route_table_id                       = module.vpcWest1.private_route_table_ids[0]
  destination_cidr_block         = module.vpcEast2.private_subnets_cidr_blocks[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.W1toE2RequesterPeer.id
	  timeouts {
    create = "5m"
		update = "5m"
  }
}


resource "aws_route" "W1toE2RouteSubnet2" {
 provider = aws.aws-us-west-1
count = 2
  route_table_id                       = module.vpcWest1.private_route_table_ids[1]
  destination_cidr_block         = module.vpcEast2.private_subnets_cidr_blocks[count.index] #add both private subnets of East2 route table
  vpc_peering_connection_id = aws_vpc_peering_connection.W1toE2RequesterPeer.id #vpc peer connection id for peer connection between w1 and e2 used for routing
	
		  timeouts {
    create = "5m"
		update = "5m"
  }
}






resource "aws_route" "E2toW1RouteSubnet1" {
 count = 2
provider = aws.aws-us-east-2
  route_table_id                       = module.vpcEast2.private_route_table_ids[0]
  destination_cidr_block         = module.vpcWest1.private_subnets_cidr_blocks[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.W1toE2RequesterPeer.id
		  timeouts {
    create = "5m"
		update = "5m"
  }
}


resource "aws_route" "E2toW1RouteSubnet2" {
 count = 2
 provider = aws.aws-us-east-2

  route_table_id                       = module.vpcEast2.private_route_table_ids[1]
  destination_cidr_block         = module.vpcWest1.private_subnets_cidr_blocks[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.W1toE2RequesterPeer.id
		  timeouts {
    create = "5m"
		update = "5m"
  }
}


resource "aws_route" "E2toE1RouteSubnet1" {
 count = 2
 provider = aws.aws-us-east-2

  route_table_id                       = module.vpcEast2.private_route_table_ids[0]
  destination_cidr_block         = module.vpcEast1.private_subnets_cidr_blocks[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.E2RequesterPeer.id
}

resource "aws_route" "E2toE1RouteSubnet2" {
 
count = 2
provider = aws.aws-us-east-2
  route_table_id                       = module.vpcEast2.private_route_table_ids[1]
  destination_cidr_block         = module.vpcEast1.private_subnets_cidr_blocks[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.E2RequesterPeer.id
}


resource "aws_route" "E1toE2RouteSubnet1" {
 
count = 2
provider = aws.aws-us-east-1
  route_table_id                       = module.vpcEast1.private_route_table_ids[0]
  destination_cidr_block         = module.vpcEast2.private_subnets_cidr_blocks[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.E2RequesterPeer.id
}

resource "aws_route" "E1toE2outeSubnet2" {
 count = 2
 provider = aws.aws-us-east-1

  route_table_id                       = module.vpcEast1.private_route_table_ids[1]
  destination_cidr_block         = module.vpcEast2.private_subnets_cidr_blocks[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.E2RequesterPeer.id
}

resource "aws_route" "W1toE1RouteSubnet1" {
 provider = aws.aws-us-west-1
count = 2
  route_table_id                       = module.vpcWest1.private_route_table_ids[0]
  destination_cidr_block         = module.vpcEast1.private_subnets_cidr_blocks[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.W1RequesterPeer.id
}

resource "aws_route" "W1ToE1RouteSubnet2" {
 provider = aws.aws-us-west-1
count = 2
  route_table_id                       = module.vpcWest1.private_route_table_ids[1]
  destination_cidr_block         = module.vpcEast1.private_subnets_cidr_blocks[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.W1RequesterPeer.id
}



resource "aws_route" "E1toW1RouteSubnet1" {
 provider = aws.aws-us-east-1
count = 2
  route_table_id                       = module.vpcEast1.private_route_table_ids[0]
  destination_cidr_block         = module.vpcWest1.private_subnets_cidr_blocks[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.W1RequesterPeer.id
}

resource "aws_route" "E1toW1RouteSubnet2" {
 provider = aws.aws-us-east-1
count = 2
  route_table_id                       = module.vpcEast1.private_route_table_ids[1]
  destination_cidr_block         = module.vpcWest1.private_subnets_cidr_blocks[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.W1RequesterPeer.id
}
