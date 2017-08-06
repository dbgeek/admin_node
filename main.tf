provider "scaleway" {
  region = "par1"
}

data "scaleway_bootscript" "latest" {
  architecture = "x86_64"
  name_filter  = "latest"
}

data "scaleway_image" "centos" {
  architecture = "x86_64"
  name         = "Ubuntu Zesty"
}

resource "scaleway_ip" "tf-admin-node-ip" {}

resource "scaleway_server" "tf-admin-node" {
  name  = "tf-admin-node"
  image = "${data.scaleway_image.centos.id}"
  type  = "VC1S"

  public_ip = "${scaleway_ip.tf-admin-node-ip.ip}"

  bootscript     = "${data.scaleway_bootscript.latest.id}"
  security_group = "${scaleway_security_group.tf-ssh.id}"

  provisioner "remote-exec" {
    inline = [
      "apt-get -qq update",
      "apt-get -qq install emacs mosh git",
      "adduser --disabled-password --gecos \" \" admin",
      "curl -O https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz",
      "tar -C /usr/local -xzf go1.8.3.linux-amd64.tar.gz",
      "echo export PATH=\\$PATH:/usr/local/go/bin >> /etc/profile",
			"su - admin -c 'mkdir -p src/github.com/dbgeek && cd src/github.com/dbgeek &&git clone https://github.com/dbgeek/dotfiles.git'",
			"su - admin -c 'go get -u github.com/golang/lint/golint'",
			"su - admin -c 'mkdir -p ~/.emacs.d/go-mode'",
			"su - admin -c 'curl https://raw.githubusercontent.com/dominikh/go-mode.el/master/go-mode-autoloads.el -o ~/.emacs.d/go-mode/go-mode-autoloads.el'",
			"su - admin -c 'go get -u github.com/golang/lint/golint'",
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = "${file("~/.ssh/id_rsa")}"
    }
  }
}

resource "scaleway_security_group" "tf-ssh" {
  name        = "tf-ssh"
  description = "Allow SSH traffic"
}

resource "scaleway_security_group_rule" "tf-ssh_accept" {
  security_group = "${scaleway_security_group.tf-ssh.id}"

  action    = "accept"
  direction = "inbound"
  ip_range  = "0.0.0.0/0"
  protocol  = "TCP"
  port      = 22
}
