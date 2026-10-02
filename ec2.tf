# Два веб-інстанси за ALB: [0] — основний сайт, [1] — резервний сайт
resource "aws_instance" "web" {
  count = 2

  ami                    = var.aws_image_id
  instance_type          = var.aws_instance_type_web
  key_name               = var.aws_key_name
  subnet_id              = local.default_subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.web.id]

  # user_data: Apache2 + статичний сайт (різний контент для кожної ноди)
  user_data = templatefile("${path.module}/files/userdata.tftpl", {
    site_content = file("${path.module}/files/${count.index == 0 ? "site-main.html" : "site-backup.html"}")
  })

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true

    tags = {
      Name = count.index == 0 ? "RootVolume-Web1" : "RootVolume-Web2"
    }
  }

  tags = {
    Name = count.index == 0 ? "MyStat-Web1-Main" : "MyStat-Web2-Backup"
    Role = count.index == 0 ? "main" : "backup"
  }
}
