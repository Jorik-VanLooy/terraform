provider "aws" {
    region = var.AWS_REGION
    secret_key = var.AWS_SECRET_KEY
    access_key = var.AWS_ACCESS_KEY
}
/*
-----------------------------------------------------------
             webserver instances creation
-----------------------------------------------------------
*/

#instance 1
resource "aws_instance" "webserver-01" {
  ami = var.INSTANCE_AMI
  instance_type = var.INSTANCE_TYPE
  subnet_id = aws_subnet.subnet-01.id
  security_groups = [ aws_security_group.allow-ssh.id, aws_security_group.allow-http.id ]
  key_name = "webserver"

    provisioner "remote-exec" {
      inline = [
          "sudo apt-get update && sudo apt-get install apache2 -y",
      ]
      connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file(var.ssh_key)
      host = aws_instance.webserver-01.public_dns
    }
  }

  provisioner "file" {
      source    = "index.php"
      destination = "/home/ubuntu/index.php"
      connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file(var.ssh_key)
      host = aws_instance.webserver-01.public_dns
    }
  }
  provisioner "remote-exec" {
      inline = [
          "sudo mv /home/ubuntu/index.php /var/www/html",
          "sudo rm /var/www/html/index.html"
      ]
      connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file(var.ssh_key)
      host = aws_instance.webserver-01.public_dns
    }
  }
}
# end instance 1

#instance 2
resource "aws_instance" "webserver-02" {
  ami = var.INSTANCE_AMI
  instance_type = var.INSTANCE_TYPE
  subnet_id = aws_subnet.subnet-02.id
  security_groups = [ aws_security_group.allow-ssh.id, aws_security_group.allow-http.id ]
  key_name = "webserver"

  provisioner "remote-exec" {
    inline = [
    "sudo apt-get update && sudo apt-get install apache2 -y"
    ]
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file(var.ssh_key)
      host = aws_instance.webserver-02.public_dns
    }
  }

  provisioner "file" {
      source    = "index.php"
      destination = "/home/ubuntu/index.php"
      connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file(var.ssh_key)
      host = aws_instance.webserver-02.public_dns
    }
  }
  provisioner "remote-exec" {
      inline = [
          "sudo mv /home/ubuntu/index.php /var/www/html/",
          "sudo rm /var/www/html/index.html"
      ]
      connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file(var.ssh_key)
      host = aws_instance.webserver-02.public_dns
    }
  }
}
# end instance 2


#instance 3
resource "aws_instance" "webserver-03" {
  ami = var.INSTANCE_AMI
  instance_type = var.INSTANCE_TYPE
  subnet_id = aws_subnet.subnet-02.id
  security_groups = [ aws_security_group.allow-ssh.id, aws_security_group.allow-http.id ]
  key_name = "webserver"

     provisioner "remote-exec" {
      inline = [
          "sudo apt-get update && sudo apt-get install apache2 -y"
      ]
      connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file(var.ssh_key)
      host = aws_instance.webserver-03.public_dns
    }
  }

  provisioner "file" {
      source    = "index.php"
      destination = "/home/ubuntu/index.php"
      connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file(var.ssh_key)
      host = aws_instance.webserver-03.public_dns
    }
  }
  provisioner "remote-exec" {
      inline = [
          "sudo mv /home/ubuntu/index.php /var/www/html/",
          "sudo rm /var/www/html/index.html"
      ]
      connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file(var.ssh_key)
      host = aws_instance.webserver-03.public_dns
    }
  }
}
#end instance 3

/*
-------------------------------------------------------------
              end webserver instances creation
-------------------------------------------------------------
*/


/*
---------------------------------------------------
              network creation
---------------------------------------------------
*/

#VPC creation
resource "aws_vpc" "main_VPC" {
    cidr_block = "10.0.0.0/24"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    enable_classiclink ="false"
    
}

#subnet-01 creation
resource "aws_subnet" "subnet-01" {
    vpc_id = aws_vpc.main_VPC.id
    cidr_block = "10.0.0.0/25"
    map_public_ip_on_launch = true
}

#subnet-02 creation
resource "aws_subnet" "subnet-02" {
  vpc_id = aws_vpc.main_VPC.id
  cidr_block = "10.0.0.128/25"
  map_public_ip_on_launch = true
}

#internet gateway creation
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_VPC.id
}

resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.main_VPC.id

route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}
}

resource "aws_route_table_association" "association-01"{

  subnet_id = aws_subnet.subnet-01.id
  route_table_id = aws_route_table.route-table.id
}
resource "aws_route_table_association" "association-02"{

  subnet_id = aws_subnet.subnet-02.id
  route_table_id = aws_route_table.route-table.id
}
/*
---------------------------------------------------------
              end network creation
---------------------------------------------------------
*/



/*
--------------------------------------------------
                security-groups
--------------------------------------------------
*/
resource "aws_security_group" "allow-ssh" {
    vpc_id = aws_vpc.main_VPC.id
    name = "allow-ssh"
    description = "allow all ssh traffic"

    egress {
      cidr_blocks = [ "0.0.0.0/0" ]
      from_port = 0
      protocol = "-1"
      to_port = 0
    } 

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "allow ssh"
    from_port = 22
    protocol = "TCP"
    to_port = 22
  }
}

#create aws-allow http to gain access to the webserver/website
resource "aws_security_group" "allow-http" {
  vpc_id = aws_vpc.main_VPC.id
  name = "allow-http"
  description = "allow all http traffic"

  egress {
      cidr_blocks = ["0.0.0.0/0"]
      from_port = 0
      to_port = 0
      protocol = "-1"
  }

  ingress {
      cidr_blocks = ["0.0.0.0/0"]
      from_port = 80
      to_port = 80
      protocol = "TCP"
  }
}

/*
------------------------------------------
            end security groups
------------------------------------------
*/




resource "aws_s3_bucket" "imagejvl" {
  bucket = "imagejvl"
  acl = "public-read"
}

resource "aws_s3_bucket_object" "image" {
  bucket = "imagejvl"
  key = "imagejvl"
  source = "image.png"
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ec2:Describe*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "lambda_role" {
  name = "lamdba_role"

  assume_role_policy = <<-EOF
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

resource "aws_lambda_function" "lambda" {
  filename = "lambda_function-1.py"
  function_name = "apache_lambda.py"
  handler = "index.php"
  runtime = "python3.8"
  role = aws_iam_role.lambda_role.id
}