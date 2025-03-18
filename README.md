# legal-term-api

An HTTP API for legal terms.

## Endpoints

* `GET /terms`: list all available terms.
* `GET /definitions?term=<term>`: get the definition of a term.

## App deployment details

The application is deployed to Kubernetes using the manifest files in the `k8s` directory.  An example of how to do this from the shell can be seen in the file `ztest-pipeline.sh`.  Alternatively, the application can be deployed by the Github Actions pipeline defined in `.github/workflows/main.yml`.

Either way, a few secrets need to be defined for the environment:

* `AZ_ID` - The Client ID of a service principal with the *Azure Kubernetes Service RBAC Cluster Admin* role
* `AZ_SECRET` - Secret for the service principal
* `REG_USER` - User login for the container registry
* `REG_PASS` - Password for the container registry
* `AZURE_CREDENTIALS` - A json string to authenticate to Azure, in the format described here: https://github.com/marketplace/actions/azure-login#creds

## Application monitoring

The application will run a minimum of 2 replica pods to ensure stability.  A horizontal pod autoscaler is configured which will add more replicas when the CPU usage average across the pods goes above 70 percent.  This behavior is configurable in the `k8s/api-hpa.yaml` file. The status of this HPA can be viewed by running the following command:

* `kubectl get hpa -n legal-term-api`

The actual replica pods can be displayed by running the following command:

* kubectl get pods -n legal-term-api

The Kubernetes cluster will monitor the health and readiness of the application by hitting the `terms` endpoint within each pod.  This endpoint could also be monitored by an external monitoring solution if desired.

## Adaptation for other projects

The pipeline, Dockerfile, and Kubernetes configuration could be used for other similar Python / Poetry projects.

* The Dockerfile could be reused unchanged for other simple Poetry based projects.
* The pipeline would need to be lightly modified.  The `APP` environment variable name would need to be changed, which would alter the image name as published to the container registry, and the names of the deployed Kubernetes resources.  If using a different cluster or registry, then those values would need to be updated as well.
* The Kubernetes resources could be reused by modifying several attributes:
  * Deployment:
    * The name and image of the container
    * The name of the app itself (in this case legal-term-api)
    * The container port
    * The path and port for the readiness and liveness probes
  * Service:
    * The port, name, and selector.app must be updated to match the definition in the new deployment.
    