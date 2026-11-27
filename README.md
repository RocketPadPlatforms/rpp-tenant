# rpp-tenant

Rocket Pad Platforms' own apps on helium, deployed exactly the way our
customers deploy theirs: through Argo CD, from this repository, within the
limits every tenant has. It doubles as a working example of a tenant
repository.

## Layout

```text
apps/<app>/application.yaml   the Argo CD Application, created by hand
apps/<app>/values.yaml        values for the app's Helm chart
apps/<app>/manifests/         optional plain manifests, e.g. SealedSecrets
```

Each app has its own namespace `rpp-<app>`, which Argo CD creates
(`CreateNamespace=true`), and its own Application in `tenants-rpp`. The
chart stays in the app's repository: the Application takes the chart from
there, and the values and manifests from here.

| App | Repository | Hosts |
| --- | --- | --- |
| website | <https://github.com/RocketPadPlatforms/rpp-website> | `rocketpadplatforms.de`, `www.rocketpadplatforms.de`, `website.rpp.helium.app.rpp.gmbh` |

## Rules

- This repository is public: commit nothing that is not meant for the public.
- Secrets go in only as `SealedSecret`, sealed with `kubeseal` for the
  namespace and name the app uses. Never commit a plain `Secret`; base64 is
  not encryption.

## Releasing an app

Chart and image come from the same commit of the app's repository, and both
are pinned in `apps/<app>/application.yaml`.

1. Wait until the app's CI has pushed
   `ghcr.io/rocketpadplatforms/<app>:<short hash>` for the commit.
2. Open a PR that sets the chart source's `targetRevision` to the commit's
   full hash and the `image.tag` parameter to its first 7 characters.
3. After the merge, apply the Application from an up-to-date `main`, signed in
   with Customer login:

   ```bash
   argocd login <argocd-host> --sso
   argocd app create -f apps/<app>/application.yaml --upsert
   ```

The Application is not synced from this repository (tenants cannot deploy
Applications from Git), so a change to `application.yaml` takes effect only
with step 3. Changes to `values.yaml` and `manifests/` sync on their own once
merged.

## Adding an app

1. Create `apps/<app>/` like `apps/website/`, with the namespace
   `rpp-<app>` and an `HTTPRoute` on the ListenerSet `rpp` in namespace
   `gateway`, from the chart's values or in `manifests/`. A `manifests/`
   folder needs its own source in the Application.
2. Ask the platform operator to add the app's repository to the tenant (and
   its read-only token, sealed, if the repository is private) and any custom
   domains. Hosts under `*.rpp.helium.app.rpp.gmbh` need nothing.
3. After the merge, create the Application:
   `argocd app create -f apps/<app>/application.yaml`.

## What the platform expects from an app

- No `Ingress`: publish with an `HTTPRoute` whose parent is the ListenerSet
  `rpp`, for hosts under `*.rpp.helium.app.rpp.gmbh` or the tenant's custom
  domains.
- A container's memory request equals its limit. Without a CPU limit, the
  platform sets 500m.
- Pods run under the `restricted` Pod Security profile, as non-root, with
  user and group IDs up to 65535.
