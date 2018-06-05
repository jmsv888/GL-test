# GL-test
How  it Works 

Pre-requisits:

Valid AWS account
	Setting aws profile
		~/.aws/credentials should exist

Should look like:
	
[terraform-test]
aws_access_key_id = KEY
aws_secret_access_key = Secret-Key

Install terraform
Install ansible


After clone the repository, we should follow the next course of actions:

From the GL-test folder, should be created after cloning of the repository.

Execute:

make cluster

command above will generate all the infraestructura as code:

	1 Jenkins Master instances
	1 Kubernetes Master Node
	2 Kubernetes Slaves Nodes

After all the infrastructure is genareted we can execute a cat over the “host.ini” and we will know all the ip address for our infrastructure

	With the IP of Jenkin master node we can go and configure the Jenkins masters (sadly I did not have enough time to configure the automation process for this part  of the project).

	Install pipeline pluging and maven plugin and then proceed to load the jenkings file.

After the jenkins file is loaded we should see all the pipeline process within the Project (Sadly again, even when the Project builds completely,  dockers images get pulled from repositories (docker hub), kubectl apply, bring up de pods but not all of them loads, we identify that the issue is with the way of the .yaml are configured).

![alt text](https://raw.githubusercontent.com/jmsv888/GL-test/master/pipeline-results.png)
