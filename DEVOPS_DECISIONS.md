# DevOps Implementation Notes

## What was changed

- The Java application now prints `Hello World from Guy Shtiler!`.
- The base Maven version in `pom.xml` is `1.0.0`.
- GitHub Actions builds, tests, packages, uploads, containerizes, publishes, pulls, and runs the application.
- The verified image is published to `shtiler/maven-hello-world:<version>`.

## Versioning logic

The project follows Semantic Versioning: `MAJOR.MINOR.PATCH`.

- `MAJOR`: incompatible changes.
- `MINOR`: backward-compatible features.
- `PATCH`: backward-compatible bug fixes.

For this assignment, every pipeline run is treated as a patch release. CI reads `1.0.0` from Maven and adds the GitHub run number to the patch component, producing versions such as `1.0.8`. This gives every run a unique, increasing version. Failed runs can leave gaps, which is acceptable because versions should not be reused. CI changes the version only in its workspace instead of committing it back to Git, avoiding noisy commits and pipeline loops.

The same version identifies the Maven project, JAR, GitHub artifact, Docker tag, and OCI image label. This provides end-to-end traceability.

## Workflow design

```text
Maven version
  -> compile, test, package
  -> verify and upload versioned JAR
  -> download that exact JAR
  -> build and verify Docker image
  -> push versioned image to Docker Hub
  -> fresh job pulls the published image by tag
  -> verify metadata and run the pulled digest
```

The main workflow only coordinates three small reusable workflows: Java build, Docker build/publish, and published-image verification. Jobs have explicit dependencies, timeouts, least-privilege permissions, actions pinned by commit SHA, and caching where useful. Maven runs in a digest-pinned Maven/JDK 8 container; Docker jobs use the fixed `ubuntu-24.04` runner because they require its Docker daemon.

Pull requests build and test without publishing or receiving secrets. Pushes to `devops-assignment` currently publish while the assignment is developed; this temporary trigger should be removed or changed to the final protected branch after merging.

## Docker decisions

The runtime image uses a digest-pinned minimal JRE and contains only the previously tested JAR. It runs as UID/GID `10001`, not root. Verification also runs it with no network, a read-only filesystem, all Linux capabilities dropped, and `no-new-privileges`.

OCI labels record the source repository, application version, and Git commit. They add traceability without adding runtime packages.

A multi-stage Docker build was intentionally not used. Maven already creates the CI artifact, and Docker packages that exact artifact. Building again in a Maven Docker stage would create a second JAR and weaken the guarantee that the uploaded and deployed artifacts are identical. Multi-stage would be appropriate if Docker owned compilation; here, artifact promotion is the cleaner design.

## Configuration and remaining work

- GitHub variable: `DOCKERHUB_REPOSITORY`.
- GitHub secrets: `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`.
- Verified through GitHub Actions run 8 with image `1.0.8`.
- Remaining assignment work: create and deploy the Helm chart as a Kubernetes `Job` because this application exits after printing.
- Security action: revoke the GitHub token that was exposed in chat and use a replacement.
