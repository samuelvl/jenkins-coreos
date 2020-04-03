# Terraform parameters
tf_cmd=terraform
tf_files=src
tf_backend_conf=configuration/backend
tf_variables=configuration/tfvars
environment=localhost

all: init plan deploy test
init:
	terraform init \
		-backend-config="$(tf_backend_conf)/$(environment).conf" $(tf_files)
plan:
	@echo "Planing infrastructure changes..."
	@podman run -i --rm quay.io/coreos/fcct:release --pretty --strict \
  		< src/ignition/jenkins-master/ignition.yml > src/ignition/jenkins-master/ignition.json
	@podman run -i --rm quay.io/coreos/fcct:release --pretty --strict \
		< src/ignition/jenkins-slave/ignition.yml > src/ignition/jenkins-slave/ignition.json
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