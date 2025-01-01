resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = var.vpc_id
  peer_vpc_id = var.remote_state.outputs.vpc_id
  auto_accept = true
  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
  tags = merge(
    {
      Name = "vpc-peer-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )
}

resource "aws_vpc_peering_connection_accepter" "peer_accepter" {
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true

  tags = merge(
    {
      Name = "vpc-peer-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )
}

resource "aws_route" "eks_to_ec2" {
  count                     = length(var.private_subnet_route_tables)
  route_table_id            = var.private_subnet_route_tables[count.index]
  destination_cidr_block    = var.remote_state.outputs.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "ec2_to_eks" {
  for_each                  = toset(sort(var.remote_state.outputs.route_table_id))
  route_table_id            = each.key
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
