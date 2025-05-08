## Application Integration TF Sample

This is a sample Terraform deployment that enables the Google Cloud service Application Integration, as well as provisions optional connectors that you can configure.

Supported connectors:
- Vertex AI - turn on with the `use_vertexai=true` variable
- Google Translate - turn on with the `use_google_translate=true` variable
- Google Cloud Storage - turn on with the `use_storage=true` variable
- Salesforce - turn on with the `use_salesforce=true` variable

### Deployment

```sh
# go to the tf directory
cd tf
# copy var file and set your vars
cp vars.tfvars vars.local.tfvars
# edit and set your project, region and a optional connectors.
nano vars.local.tfvars

# take a look at main.tf and the resources configured there.
nano main.tf

# initialize and apply the configuration. 
terraform init
terraform apply --var-file=./vars.local.tfvars -auto-approve

# your GCP project should now the configured resources provisioned.

# now delete when you are finished.
terraform destroy --var-file=./vars.local.tfvars -auto-approve
```

### Guide to Terraform with Application Integration & Connectors
To build the terraform configuration for connectors, you need to first get some active configurations to see the properties in an active project.

```sh
# return the configuration for all active connections in a project
PROJECT_ID=apigee-hub-demo
REGION=europe-west1
curl "https://connectors.googleapis.com/v1/projects/$PROJECT_ID/locations/$REGION/connections" \
	-H "Authorization: Bearer $(gcloud auth print-access-token)"
```

The returned JSON shows the parameters needed to be configured for the connectors, which then must be added to the Terraform configuration for each connector.
