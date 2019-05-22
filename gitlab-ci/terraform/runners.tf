
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
            "sudo wget -O /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64",
            "sudo chmod +x /usr/local/bin/gitlab-runner",
            "sudo useradd --comment \"GitLab Runner\" --create-home gitlab-runner --shell /bin/bash",
            "gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner",
            "gitlab-runner start",
            "gitlab-runner register --non-interactive --url \"${var.gitlab_host}\" --registration-token \"${var.gitlab_token}\" --executor \"docker\" --docker-image alpine:latest --description \"docker-runner\" --tag-list \"dind\" --run-untagged=\"true\" --locked=\"false\""
        ]
    }

    tags {
        Name = "runner${count.index}"
    }
}
