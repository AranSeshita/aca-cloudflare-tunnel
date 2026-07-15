# CLAUDE.md

Sample Terraform configuration that exposes Azure Container Apps (ACA) through a Cloudflare Tunnel.
The edge (CDN/WAF) lives on Cloudflare; ACA is an Internal (VNet-integrated) environment with **zero inbound ports open on Azure**.

## Layout

- `env/dev/` … root module. **Run terraform from here.**
  `main.tf` (module calls) / `variables.tf` / `locals.tf` / `outputs.tf` / `provider.tf` / `terraform.tfvars.example`
- `modules/` … reusable modules. For new infrastructure, **do not write flat resources — add them to the relevant module**.
  If none fits, create `modules/<name>/` with `main.tf` / `variables.tf` / `outputs.tf` (+ README).

## Conventions

- **Providers**: `azurerm ~> 4.0` / `cloudflare ~> 5.19`.
  Only modules that use cloudflare declare `required_providers` in `versions.tf` (not needed for azurerm-only modules).
- **Naming**: the primary resource is `"main"`, for_each'd resources are `"this"`.
  Names follow `<type>-<project_name>-<environment>` (ACR is alphanumeric-only: `acr{project}{env}`).
- **Comments and docs are unified in English.**
- Every module README follows the same format: `Usage` / `Inputs` / `Outputs` / `Notes`.
- **No Key Vault** (the Tunnel Token is stored inline as an ACA Secret).
- State is local by default. Use a remote backend for production (see "State management" in the README).

## Required workflow (every time a .tf file is edited)

```bash
cd env/dev
terraform fmt -recursive ../..
terraform init -backend=false -input=false
terraform validate
```

- `plan` / `apply` require Azure + Cloudflare credentials and real values. **Never run them unprompted.** If needed, present the steps and ask for confirmation.
