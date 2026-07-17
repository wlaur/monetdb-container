# Docker Hub setup

Docker Hub publishing is optional. Release tags always publish to GitHub
Container Registry; they also publish to Docker Hub after these settings are
configured.

## Create the account and repository

1. [Create a Docker account](https://docs.docker.com/accounts/create-account/).
   Choose a Docker ID you are comfortable keeping as the permanent public image
   namespace.
2. Complete Docker's email OTP verification and
   [enable two-factor authentication](https://docs.docker.com/security/2fa/).
3. In Docker Hub, [create a **public** repository](https://docs.docker.com/docker-hub/repos/create/)
   named `monetdb-container`.
   Use `Unofficial MonetDB container images` as the description. Do not
   configure a Docker Hub automated build.
4. Open **Account settings → Personal access tokens** and
   [create a token](https://docs.docker.com/security/access-tokens/) named
   `github-monetdb-container`. Grant **Write** permission, which includes read
   access, and set a reasonable expiration. Copy it when shown; Docker Hub will
   not show it again.

## Connect GitHub Actions

From this repository, set the public username variable:

```console
gh variable set DOCKERHUB_USERNAME --body YOUR_DOCKER_HUB_USERNAME
```

Then set the token secret. This command prompts without putting the token in
the command line or shell history:

```console
gh secret set DOCKERHUB_TOKEN
```

Confirm the names, not the secret value:

```console
gh variable list
gh secret list
```

The next `v<MonetDB-version>-<image-revision>` Git tag publishes the same image
digest under these Docker Hub tags:

```text
YOUR_DOCKER_HUB_USERNAME/monetdb-container:11.55.7-1
YOUR_DOCKER_HUB_USERNAME/monetdb-container:11.55.7
YOUR_DOCKER_HUB_USERNAME/monetdb-container:Dec2025-SP3
```

There is intentionally no `latest` tag. The revisioned tag is immutable; the
version and release aliases identify the current container rebuild for that
MonetDB release.
