# Vault + GitHub Actions OIDC demo

This demo retrieves a KV v2 secret from HCP Vault in a GitHub Actions workflow
without storing a Vault credential in GitHub. GitHub issues an OpenID Connect
(OIDC) token for the job; Vault validates it and returns a short-lived Vault
token with permission to read exactly one secret.

## What Terraform configures

The [`terraform`](./terraform) configuration manages the following resources in
the `admin` namespace:

- `secret/github-actions-demo` with a generated `demo-api-key` value
- a read-only Vault policy for that KV v2 path
- JWT auth mounted at `jwt-github-actions`
- a JWT role locked to the `romanzamora/vault-github-actions-demo` repository
  and `main` branch claims

The generated demo secret is stored in encrypted HCP Terraform state. Use a
different pattern for production secrets: write them directly to Vault through
an approved secret-management process, not Terraform.

## GitHub Actions workflow

The workflow is at
[`retrieve-vault-secret.yml`](./.github/workflows/retrieve-vault-secret.yml).
It requests `id-token: write`, then uses `hashicorp/vault-action` with the JWT
auth mount, role, and namespace created by Terraform.

The final step verifies that `DEMO_API_KEY` exists without printing it.

## HCP Terraform workspace configuration

Create a VCS-driven workspace with:

| Setting | Value |
| --- | --- |
| Workspace | `vault-github-actions-demo` |
| Repository | `romanzamora/vault-github-actions-demo` |
| Working directory | `terraform` |
| Execution mode | Remote |
| Auto-apply | Off |

Set these workspace environment variables:

| Variable | Sensitive | Value |
| --- | --- | --- |
| `VAULT_ADDR` | No | HCP Vault public endpoint |
| `VAULT_NAMESPACE` | No | `admin` |
| `VAULT_TOKEN` | Yes | Bootstrap/admin Vault token |

`VAULT_TOKEN` is used only by HCP Terraform to administer the demo Vault
resources. It is not configured in GitHub or passed to the workflow.

## Validate the demo

After Terraform applies successfully, open GitHub Actions and run **Retrieve a
Vault secret with GitHub OIDC**. A successful run proves that this repository
on `main` can fetch the demo key through OIDC.

## Clean up

Destroy the HCP Terraform workspace resources, revoke the temporary GitHub and
HCP Terraform API tokens, then delete the repository when the PoC ends.
