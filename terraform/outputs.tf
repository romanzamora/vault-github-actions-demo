output "github_actions_configuration" {
  description = "Non-secret values used by the GitHub Actions workflow."
  value = {
    auth_path   = vault_jwt_auth_backend.github_actions.path
    role        = vault_jwt_auth_backend_role.github_actions_demo.role_name
    namespace   = "admin"
    secret_path = "${local.secret_mount}/data/${local.secret_name}"
  }
}
