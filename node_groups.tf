
# Creating managed node group
resource "aws_eks_node_group" "eci" {
  cluster_name    = "${var.cluster_name}"
  node_group_name = "${var.node_group_name}"
  node_role_arn   = "${aws_iam_role.node_group.arn}"
  subnet_ids      = "${var.subnets}"

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    "${aws_iam_role_policy_attachment.node-group-AmazonEKSWorkerNodePolicy}",
    "${aws_iam_role_policy_attachment.node-group-AmazonEKS_CNI_Policy}",
    "${aws_iam_role_policy_attachment.node-group-AmazonEC2ContainerRegistryReadOnly}",
  ]
}


## IAM role and policy attachement required for node_groups
resource "aws_iam_role" "node_group" {
  name = "eks-node-group-eci"

    assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "node-group-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.node_group.name}"
}

resource "aws_iam_role_policy_attachment" "node-group-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.node_group.name}"
}

resource "aws_iam_role_policy_attachment" "node-group-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.node_group.name}"
}

# Subnets for EKS managed node group

resource "aws_subnet" "app_subnet" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "${var.subnet_app_cidr_blocks}"
  vpc_id            = "${var.vpc_id}"

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}