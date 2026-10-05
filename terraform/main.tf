locals {
  github_owner      = "romanzamora"
  github_repository = "vault-github-actions-demo"
  secret_mount      = "secret"
  secret_name       = "github-actions-demo"
  jwt_auth_path     = "jwt-github-actions"
  jwt_role_name     = "github-actions-demo"

  github_subject = "repo:${local.github_owner}/${local.github_repository}:ref:refs/heads/main"
}

# This demo secret is generated in HCP Terraform; it never appears in Git.
resource "random_password" "demo_api_key" {
  length  = 32
  special = false
}

resource "vault_kv_secret_v2" "github_actions_demo" {
  mount = local.secret_mount
  name  = local.secret_name

  data_json = jsonencode({
    "demo-api-key" = random_password.demo_api_key.result
  })
}

resource "vault_policy" "github_actions_demo_read" {
  name = "github-actions-demo-read"

  policy = <<-EOT
    path "${local.secret_mount}/data/${local.secret_name}" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_jwt_auth_backend" "github_actions" {
  path               = local.jwt_auth_path
  type               = "jwt"
  oidc_discovery_url = "https://token.actions.githubusercontent.com"
  bound_issuer       = "https://token.actions.githubusercontent.com"
}

resource "vault_jwt_auth_backend_role" "github_actions_demo" {
  backend   = vault_jwt_auth_backend.github_actions.path
  role_name = local.jwt_role_name
  role_type = "jwt"

  user_claim      = "repository"
  bound_audiences = ["https://github.com/${local.github_owner}"]
  bound_subject   = local.github_subject

  token_policies          = [vault_policy.github_actions_demo_read.name]
  token_no_default_policy = true
  token_type              = "batch"
  token_ttl               = 300
  token_max_ttl           = 600
}
