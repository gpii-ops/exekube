release_spec = {
  enabled        = false
  release_name   = "vault"
  release_values = "values.yaml"

  chart_repo    = "incubator"
  chart_name    = "vault"
  chart_version = "0.3.0"
}

pre_hook = {
  command = <<-EOF
            kubectl create secret generic gcp-credentials-vault \
            --from-file=/exekube/live/prod/kube/core/vault/release/secrets/gcp-credentials/ || true \
            && kubectl create secret generic vault-tls \
            --from-file=/exekube/live/prod/kube/core/vault/release/secrets/vault-tls/ || true
            EOF
}
