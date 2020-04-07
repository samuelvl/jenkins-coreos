# Terraform parameters
tf_cmd=terraform
tf_files=src
tf_backend_conf=configuration/backend
tf_variables=configuration/tfvars
environment=localhost
ssh_maintuser_pubkey=`cat src/ssh/maintuser/id_rsa.pub`
ssh_jenkins_pubkey=`cat src/ssh/jenkins/id_rsa.pub`

all: init plan deploy test
init:
	@echo "Generating SSH keypair for Jenkins slaves..."
	@mkdir -p src/ssh/jenkins
	echo -e 'y\n' | ssh-keygen -o -t rsa -b 4096 -C "" -N="" -f "$(pwd)/src/ssh/jenkins/id_rsa"

	@echo "Generating SSH keypair for maintenance user..."
	@mkdir -p src/ssh/maintuser
	echo -e 'y\n' | ssh-keygen -o -t rsa -b 4096 -C "" -N="" -f "$(pwd)/src/ssh/maintuser/id_rsa"

	@echo "Initializing Terraform plugins"
	terraform init \
		-backend-config="$(tf_backend_conf)/$(environment).conf" $(tf_files)
plan:
	@echo "Rendering FCC configuration for Jenkins master..."
	yq write -i src/ignition/jenkins-master/ignition.yml \
		'passwd.users[1].ssh_authorized_keys[0]' "$(ssh_maintuser_pubkey)"
	podman run -i --rm quay.io/coreos/fcct:release --pretty --strict \
  		< src/ignition/jenkins-master/ignition.yml > src/ignition/jenkins-master/ignition.json

	@echo "Rendering FCC configuration for Jenkins slaves..."
	yq write -i src/ignition/jenkins-slave/ignition.yml \
		'passwd.users[0].ssh_authorized_keys[0]' "$(ssh_jenkins_pubkey)"
	yq write -i src/ignition/jenkins-slave/ignition.yml \
		'passwd.users[1].ssh_authorized_keys[0]' "$(ssh_maintuser_pubkey)"
	podman run -i --rm quay.io/coreos/fcct:release --pretty --strict \
		< src/ignition/jenkins-slave/ignition.yml > src/ignition/jenkins-slave/ignition.json

	@echo "Planing infrastructure changes..."
	terraform plan \
		-var-file="$(tf_variables)/default.tfvars" \
		-var-file="$(tf_variables)/$(environment).tfvars" \
		-out "output/tf.$(environment).plan" \
		$(tf_files)
deploy:
	@echo "Deploying infrastructure..."
	terraform apply output/tf.$(environment).plan
test:
	@echo "Testing infrastructure..."
destroy:
	@echo "Destroying infrastructure..."
	terraform destroy \
		-var-file="$(tf_variables)/default.tfvars" \
		-var-file="$(tf_variables)/$(environment).tfvars" \
		$(tf_files)
	@rm -rf .terraform
	@rm -rf output/tf.$(environment).plan
	@rm -rf state/terraform.$(environment).tfstate