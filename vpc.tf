module "label_vpc" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  context    = module.base_label.context
  name       = "vpc"
  attributes = ["main"]
}

module "label_subnet" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  context    = module.base_label.context
  name       = "subnet"
  attributes = ["dev"]
}

module "subnet_addrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.vpc_cidr
  networks = [
    {
      name     = "subnet1"
      new_bits = 24 - tonumber(split("/", var.vpc_cidr)[1])
    },
    {
      name     = "subnet2"
      new_bits = 24 - tonumber(split("/", var.vpc_cidr)[1])
    },
  ]
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = module.label_vpc.tags
}


resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.main.id
}


resource "aws_subnet" "example" {
  for_each = module.subnet_addrs.network_cidr_blocks

  vpc_id            = aws_vpc.main.id
  availability_zone = var.az_number
  cidr_block        = each.value
  tags              = module.label_subnet.tags
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.example["subnet1"].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route" "public_internet_gateway" {
  
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}