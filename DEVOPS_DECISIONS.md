# DevOps Implementation Notes

## What was changed

- The Java application now prints `Hello World from Guy Shtiler!`.
- The base Maven version in `pom.xml` is `1.0.0`.
- GitHub Actions builds, tests, packages, uploads, containerizes, publishes, pulls, runs, and deploys the application with Helm.
- The verified image is published to `shtiler/maven-hello-world:<version>`.

## Versioning logic

The project follows Semantic Versioning: `MAJOR.MINOR.PATCH`.

- `MAJOR`: incompatible changes.
- `MINOR`: backward-compatible features.
- `PATCH`: backward-compatible bug fixes.

For this assignment, every pipeline run is treated as a patch release. CI reads `1.0.0` from Maven and adds the GitHub run number to the patch component, producing versions such as `1.0.8`. This gives every run a unique, increasing version. Failed runs can leave gaps, which is acceptable because versions should not be reused. CI changes the version only in its workspace instead of committing it back to Git, avoiding noisy commits and pipeline loops.

The same version identifies the Maven project, JAR, GitHub artifact, Docker tag, and OCI image label. This provides end-to-end traceability.

## CI/CD summary

```text
Maven version
  -> compile, test, package
  -> verify and upload versioned JAR
  -> download that exact JAR
  -> build and verify Docker image
  -> push versioned image to Docker Hub
  -> fresh job pulls the published image by tag
  -> verify metadata and run the pulled digest
  -> deploy the same version with Helm to ephemeral Kubernetes
  -> verify the Deployment image and pod logs
```

`ci-cd.yml` is the entry point and coordinates four reusable workflows in order:

- `java-build.yml`: calculates the patch version, runs Maven `clean verify`, tests the JAR, and uploads it as a versioned artifact.
- `docker-build.yml`: downloads that exact JAR, builds and security-checks the non-root image, runs it, and publishes it to Docker Hub.
- `docker-verify.yml`: uses a fresh runner to pull the published image, resolves its immutable digest, checks its labels/user, and runs it securely.
- `helm-deploy.yml`: lints the chart, creates an ephemeral kind cluster, deploys the published version, and verifies the Deployment image and pod logs.

Jobs have explicit dependencies, timeouts, least-privilege permissions, actions pinned by commit SHA, and caching where useful. Maven runs in a digest-pinned Maven/JDK 8 container; Docker and Kubernetes jobs use the fixed `ubuntu-24.04` runner because they require its Docker daemon.

Pull requests targeting `master` run Maven and local Docker validation without using publishing secrets. Pushes to `master` and manual runs execute the full chain: build, publish, independently pull, and deploy.

The deployment target is an ephemeral kind Kubernetes cluster created inside the GitHub Actions runner. The cluster is real but temporary and is deleted when the workflow finishes; nothing is deployed to the home computer or a persistent cloud environment.

Important logic is kept in the reusable workflow responsible for it: version and JAR logic in `java-build.yml`, image security and publication in `docker-build.yml`, remote-image proof in `docker-verify.yml`, and Kubernetes deployment verification in `helm-deploy.yml`. The application version is passed between them so the JAR, artifact, Docker tag, and deployed image stay aligned.

## Docker decisions

The runtime image uses a digest-pinned minimal JRE and contains only the previously tested JAR. It runs as UID/GID `10001`, not root. Verification also runs it with no network, a read-only filesystem, all Linux capabilities dropped, and `no-new-privileges`.

OCI labels record the source repository, application version, and Git commit. They add traceability without adding runtime packages.

A multi-stage Docker build was intentionally not used. Maven already creates the CI artifact, and Docker packages that exact artifact. Building again in a Maven Docker stage would create a second JAR and weaken the guarantee that the uploaded and deployed artifacts are identical. Multi-stage would be appropriate if Docker owned compilation; here, artifact promotion is the cleaner design.

## Helm decisions

The chart has generic, safe defaults in `values.yaml`. `values-maven-project.yaml` explicitly owns the Maven application's Docker Hub image, pull policy, release name, UID/GID, container restrictions, replica count, and resource requests/limits instead of inheriting nearly everything. Its image tag stays empty because CI injects the exact generated version. The chart intentionally renders only a Deployment to keep the assignment small and clear.

The chart applies the same non-root and restricted-container settings as Docker. CI lints both value layers, creates an ephemeral kind cluster, deploys the exact published image version, and verifies the Deployment and application output. Because the application prints once and exits, Kubernetes restarts its container; a continuously healthy Deployment would require changing the application into a long-running process.

No Service, Ingress, or OpenShift Route is created because the application does not listen on a port or serve network traffic. These resources should be added only if the application becomes a network service.

## Configuration

- GitHub variable: `DOCKERHUB_REPOSITORY`.
- GitHub secrets: `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`.
- CI assigns and verifies the exact version dynamically on every run.
