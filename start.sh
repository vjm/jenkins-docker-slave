docker rm -f always_on_jenkins_slave
docker create --name always_on_jenkins_slave vjm03/jenkins-docker-slave
docker start always_on_jenkins_slave