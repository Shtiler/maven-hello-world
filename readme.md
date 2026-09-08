# Maven Hello World - DevOps Assignment

This repository contains a small Java application that prints:

```text
Hello World from Guy Shtiler!
```

The application source is `myapp/src/main/java/com/myapp/App.java`, and its base version is `1.0.0`.

## Repository overview

The programming language is **Java**.

**Maven** is the project's build and dependency-management tool. It reads `pom.xml` and runs an ordered lifecycle such as `compile`, `test`, `package`, and `verify`. Running a later phase also runs the required earlier phases.

`pom.xml` is Maven's Project Object Model. It defines the project coordinates, version, dependencies, compiler settings, and build plugins. This project's coordinates are:

```text
com.myapp:myapp:1.0.0
```

A GitHub **fork** is the server-side copy under this account; a **clone** is the local working copy.

## Build and run

From the `myapp` directory:

```bash
mvn --batch-mode clean verify
java -jar target/myapp-1.0.0.jar
```

## CI/CD

The GitHub Actions entry point is `.github/workflows/ci-cd.yml`.

```text
calculate PATCH version
  -> compile, test, package
  -> upload the versioned JAR artifact
  -> build and verify the non-root Docker image
  -> push the versioned image to Docker Hub
  -> pull and run the published image by digest
  -> deploy and verify it with Helm in ephemeral Kubernetes
```

Pull requests targeting `master` run Maven and Docker validation without publishing. Pushes to `master` and manual runs execute the complete publication and deployment flow.

Required GitHub configuration:

- Variable: `DOCKERHUB_REPOSITORY`
- Secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`

The JAR, GitHub artifact, Docker tag, OCI version label, and Helm image tag all use the same generated application version.

## Docker and Helm

The Docker runtime image is digest-pinned, contains the tested JAR, and runs as non-root UID/GID `10001`.

The Helm chart is under `helm/maven-hello-world`. It uses:

- `values.yaml` for chart defaults
- `values-maven-project.yaml` for application-specific values
- a Deployment template with restricted container security settings

CI deploys the chart to a temporary kind cluster inside the GitHub Actions runner. The cluster is removed after the workflow. No Service or Ingress is created because this console application does not listen on a network port.

Implementation details and design reasoning are documented in [DEVOPS_DECISIONS.md](DEVOPS_DECISIONS.md).
