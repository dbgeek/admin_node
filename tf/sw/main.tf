provider "scaleway" {
  region = "par1"
}

data "scaleway_bootscript" "latest" {
  architecture = "x86_64"
  name_filter  = "docker"
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

  provisioner "file" {
    source      = "/home/pi/.secrets.tar"
    destination = "/root/.secrets.tar"

    connection {
      type        = "ssh"
      user        = "root"
      private_key = "${file("~/.ssh/id_rsa")}"
    }
  }

  provisioner "file" {
    source      = "~/.ssh/id_rsa"
    destination = "/root/.ssh_id_rsa"

    connection {
      type        = "ssh"
      user        = "root"
      private_key = "${file("~/.ssh/id_rsa")}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get -qq update",
      "apt-get -qq install emacs mosh git docker.io",
      "adduser --disabled-password --gecos \" \" admin",
      "curl -O https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz",
      "tar -C /usr/local -xzf go1.8.3.linux-amd64.tar.gz",
      "echo export PATH=\\$PATH:/usr/local/go/bin >> /etc/profile",
      "su - admin -c 'mkdir -p src/github.com/dbgeek'",
      "su - admin -c 'go get -u github.com/golang/lint/golint'",
      "su - admin -c 'mkdir -p ~/.emacs.d/go-mode'",
      "su - admin -c 'curl https://raw.githubusercontent.com/dominikh/go-mode.el/master/go-mode-autoloads.el -o ~/.emacs.d/go-mode/go-mode-autoloads.el'",
      "su - admin -c 'export GOPATH=~/ && go get -u github.com/golang/lint/golint'",
      "ln -sf /usr/bin/docker.io /usr/local/bin/docker",
      "usermod -G docker admin",
      "tar xf .secrets.tar -C /",
      "su - admin -c 'mkdir /home/admin/.ssh '",
      "cp ~/.ssh/authorized_keys /home/admin/.ssh/",
      "chown admin:admin /home/admin/.ssh/authorized_keys",
      "cp /root/.ssh_id_rsa /home/admin/.ssh/id_rsa && chown admin:admin /home/admin/.ssh/id_rsa && chmod 600 /home/admin/.ssh/id_rsa",
      "su - admin -c 'ssh-keyscan github.com > ~/.ssh/known_hosts'",
      "su - admin -c 'cd src/github.com/dbgeek && git clone git@github.com:dbgeek/admin_node.git && git clone git@github.com:dbgeek/dotfiles.git && dotfiles/bootstrap.sh && admin_node/dotfiles/bootstrap'",
			"su - admin -c 'git config --global user.email "bjorn.ahl@gmail.com" && git config --global user.name "Bjorn Ahl"'"
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
