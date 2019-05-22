
resource "aws_instance" "runners" {
    ami             = "ami-0ebb3a801d5fb8b9b"
    count           = "${var.cnt}"
    instance_type   = "${var.instance_type}"
    key_name        = "${var.key_pair}"

    security_groups = [
        "${aws_security_group.allow_runner_ssh.name}",
        "${aws_security_group.allow_runner_outbound.name}",
    ]

    connection {
        type     = "ssh"
        user     = "ec2-user"
        password = ""
        private_key = "${file("~/.ssh/devops-learn.pem")}"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo yum update -y",
            "sudo amazon-linux-extras install docker -y",
            "sudo service docker start",
            "sudo mkdir -p /srv/gitlab-runner/config",
            "sudo docker run -d --name gitlab-runner --restart always -v /srv/gitlab-runner/config:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner:latest",
            "sudo docker exec -it gitlab-runner gitlab-runner register --non-interactive --url \"${var.gitlab_host}\" --registration-token \"${var.gitlab_token}\" --executor \"docker\" --docker-image docker:stable --description \"gitlab-runner\" --tag-list \"linux,dind\" --run-untagged --locked=\"false\""
        ]
    }

    tags {
        Name = "runner${count.index}"
    }
}
