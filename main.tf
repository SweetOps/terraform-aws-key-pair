module "label" {
  source      = "git::https://github.com/SweetOps/terraform-null-label.git?ref=tags/0.5.4"
  namespace   = "${var.namespace}"
  stage       = "${var.stage}"
  environment = "${var.environment}"
  name        = "${var.name}"
  attributes  = "${var.attributes}"
  delimiter   = "${var.delimiter}"
  tags        = "${var.tags}"
  enabled     = "${var.generate_ssh_key}"
}

locals {
  public_key_filename  = "${var.ssh_public_key_path}/${module.label.id}${var.public_key_extension}"
  private_key_filename = "${var.ssh_public_key_path}/${module.label.id}${var.private_key_extension}"
}

resource "tls_private_key" "default" {
  count     = "${var.generate_ssh_key == "true" ? 1 : 0}"
  algorithm = "${var.ssh_key_algorithm}"
}

resource "aws_key_pair" "generated" {
  count      = "${var.generate_ssh_key == "true" ? 1 : 0}"
  depends_on = ["tls_private_key.default"]
  key_name   = "${module.label.id}"
  public_key = "${tls_private_key.default.public_key_openssh}"
}

resource "local_file" "public_key_openssh" {
  count      = "${var.generate_ssh_key == "true" ? 1 : 0}"
  depends_on = ["tls_private_key.default"]
  content    = "${tls_private_key.default.public_key_openssh}"
  filename   = "${local.public_key_filename}"
}

resource "local_file" "private_key_pem" {
  count      = "${var.generate_ssh_key == "true" ? 1 : 0}"
  depends_on = ["tls_private_key.default"]
  content    = "${tls_private_key.default.private_key_pem}"
  filename   = "${local.private_key_filename}"
}

resource "null_resource" "chmod" {
  count      = "${var.generate_ssh_key == "true" && var.chmod_command != "" ? 1 : 0}"
  depends_on = ["local_file.private_key_pem"]

  provisioner "local-exec" {
    command = "${format(var.chmod_command, local.private_key_filename)}"
  }
}

resource "aws_s3_bucket_object" "public_key" {
  count      = "${var.generate_ssh_key == "true" && var.bucket != "" ? 1 : 0}"
  depends_on = ["local_file.public_key_openssh"]
  key        = "${local.public_key_filename}"
  bucket     = "${var.bucket}"
  source     = "${local.public_key_filename}"
  etag       = "${md5(file(local.public_key_filename))}"
  tags       = "${module.label.tags}"
}

resource "aws_s3_bucket_object" "private_key" {
  count      = "${var.generate_ssh_key == "true" && var.bucket != "" ? 1 : 0}"
  depends_on = ["local_file.private_key_pem"]
  key        = "${local.private_key_filename}"
  bucket     = "${var.bucket}"
  source     = "${local.private_key_filename}"
  etag       = "${md5(file(local.private_key_filename))}"
  tags       = "${module.label.tags}"
}
