remote_user = ubuntu
ssh_key_name = keys/aws_terraform.pem

ansible/ec2.py:
	curl -o ansible/ec2.py \
		https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/ec2.py
	chmod u+x ansible/ec2.py

ansible/ec2.ini:
	curl -o ansible/ec2.ini \
		https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/ec2.ini


ansible/roles/williamyeh.oracle-java:
	ansible-galaxy install williamyeh.oracle-java -p ansible/roles

ansible/roles/alexagranov.jenkins-oracle-java:
	ansible-galaxy install alexagranov.jenkins-oracle-java -p ansible/roles


ansible_roles:  ansible/roles/williamyeh.oracle-java ansible/roles/alexagranov.jenkins-oracle-java 

ansible: ansible/ec2.ini ansible/ec2.py ansible_roles

keys:
	mkdir keys
	ssh-keygen -t rsa \
		-C aws_terraform \
		-f $(ssh_key_name) \
		-P ''

clean:

	rm -rf ansible/roles/williamyeh.oracle-java
	rm -rf ansible/roles/alexagranov.jenkins-oracle-java
	rm -rf ansible/ec2.py
	rm -rf ansible/ec2.ini
	
	terraform destroy

	rm -rf keys

build: keys
	terraform apply

provision: ansible
	ANSIBLE_HOST_KEY_CHECKING=false \
	ANSIBLE_REMOTE_USER=$(remote_user) \
	ANSIBLE_PRIVATE_KEY_FILE=$(ssh_key_name) \
	ansible-playbook -i ansible/ec2.py ansible/site.yml \
		--extra-vars='{"pipeline_repo":"$(repo)", "pipeline_project_name":"$(project_name)", "jenkins_auth_user": "$(jenkins_auth_user)", "jenkins_auth_password": "$(jenkins_auth_password)"}'

jenkins: build provision