## Application Integration TF Sample

This is a sample Terraform deployment that enables `Application Integration`, a `Service Account`, a `Storage Bucket` and 3 `Integration Connectors` in a Google Cloud project.

The configuration included is for these 3 connectors as examples:
- Vertex AI
- Google Translate
- Google Cloud Storage

This is intended to be an example of how a Terraform deployment for `Application Integration` and associated `Integration Connectors` can be structured.

### Deployment

```sh
# go to the tf directory
cd tf
# copy var file and set your vars
cp vars.tfvars vars.local.tfvars
# edit and set your project, region and a unique storage bucket name (like int-bucket-5643j)
nano vars.local.tfvars

# take a look at main.tf and the resources configured there.
nano main.tf

# initialize and apply the configuration. 
terraform init
terraform apply --var-file=./vars.local.tfvars -auto-approve

# your GCP project should now have a service account, storage bucket, app. int and 3 connectors configured.

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
