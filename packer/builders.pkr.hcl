build {
  sources = ["source.wiki"]
  name = "Personal Wiki"

  provisioner "shell" {
    inline = [
      "echo Connected via SSM at '${build.User}@${build.Host}:${build.Port}'"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo yum update",
      "sudo yum install -y python3 python3-pip python3-wheel python3-setuptools coreutils shadow-utils"
    ]
  }

  provisioner "ansible" {
    extra_arguments = [
      "-e",
      "ansible_python_interpreter=/usr/bin/python3",
      "--skip-tags",
      "skip"
    ]
    galaxy_file     = "ansible/requirements.yml"
    host_alias      = "wiki"
    playbook_file   = "ansible/main.yml"
    user            = "ssm-user"
  }

  provisioner "shell" {
    expect_disconnect = true
    inline            = ["sudo systemctl reboot"]
  }

  provisioner "shell" {
    inline = ["echo System rebooted, done provisioning"]
  }

}
