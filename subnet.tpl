resource "aws_subnet" "${name}" {

  vpc_id     = "${vpc_id}" 
  cidr_block = "${cidr_block}"

  tags = {
    Automation = "terraform"
    Name       = "Default subnet for ${name}"
  }
}
