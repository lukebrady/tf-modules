# Repository Guidelines

## Project Structure & Module Organization
- Terraform modules live under `networking/*` (for example: `networking/vpc`, `networking/nat-subnet`, `networking/nat-instance-subnet`, `networking/vpn/*`).
- Each module follows the standard layout: `provider.tf`, `variables.tf`, `main.tf`, `outputs.tf`, plus optional `scripts/` assets.
- Kubernetes-related content is under `kubernetes/` and `kubernetes-the-hard-way/` (reference material and assets; not Terraform modules).

## Build, Test, and Development Commands
- Format: `terraform fmt -recursive` — apply canonical HCL formatting across the repo.
- Init a module: `cd networking/vpc && terraform init` — download providers and set up the working dir.
- Validate: `terraform validate` — static checks for configuration errors.
- Plan: `terraform plan -var-file=example.tfvars` — preview changes (supply vars as needed).
- Apply: `terraform apply -auto-approve -var-file=example.tfvars` — create/update resources. Use cautiously.
- Lint (optional): `tflint --recursive` — if installed, run linter across modules.

## Coding Style & Naming Conventions
- Language: Terraform (HCL2), 2-space indentation, one resource per logical block.
- Filenaming: keep to `provider.tf`, `variables.tf`, `main.tf`, `outputs.tf`.
- Names: use `snake_case` for variables/outputs, short and descriptive resource names (e.g., `aws_vpc.vpc`).
- Providers/versions: pin in `provider.tf` (e.g., `required_version`, `required_providers`).
- Run `terraform fmt` before pushing.

## Testing Guidelines
- Baseline checks: `terraform validate` and `tflint` must pass for changed modules.
- Create minimal runnable examples in a temporary dir referencing the module:
  ```hcl
  module "vpc" { source = "../networking/vpc" cidr_block = "10.0.0.0/24" }
  ```
  Then run `terraform init && terraform plan`.
- If adding automated tests, prefer Terratest; place under `tests/` mirroring module paths.

## Commit & Pull Request Guidelines
- Commits: follow Conventional Commits where practical (e.g., `feat(vpc): add flow logs` / `fix(nat-subnet): correct route`).
- PRs must include:
  - Summary of what/why, and impacted modules/paths.
  - Sample `terraform plan` output (redacted) from a minimal example.
  - Notes on breaking changes, new variables/outputs, and provider/version updates.
  - Linked issues and any manual steps or migration notes.

## Security & Configuration Tips
- Do not commit secrets, state files, or real `*.tfvars`; provide `*.tfvars.example` when useful.
- Prefer explicit provider version constraints and least-privilege IAM usage.
- Validate `terraform destroy` behavior in a scratch account before merging disruptive changes.
