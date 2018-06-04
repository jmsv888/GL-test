remote_user = ubuntu
ssh_key_name = keys/aws_terraform2.pem

keys:
	mkdir keys
	ssh-keygen -t rsa \
		-C aws_terraform \
		-f $(ssh_key_name) \
		-P ''

clean:
	
	terraform destroy -auto-approve
	rm -rf keys

build: keys
	terraform apply -auto-approve

cluster: build