# Azure PIM Assignment Shell Tool

Automate Azure Privileged Identity Management (PIM) assignments for both Azure resource and Entra ID (Azure AD) roles—much faster than the Azure Portal. Fuzzy search and interactive prompts make role activation quick and user-friendly.

## Why use this tool?

> `pim` on the shell is significantly faster than the Azure Portal. Search, select, and activate roles in seconds—ideal for power users and automation.

## Prerequisites

Install and ensure these are in your PATH:

- `curl`, `az` (Azure CLI), `jq`, `fzf`, `pwsh` (for Entra ID roles)

## Usage

```bash
./pim [OPTIONS]
```

### Parameters (all can be prompted)

- `--subscription, -s` Subscription ID or name
- `--resource-group, -g` Resource group name
- `--role, -r` Role name
- `--message, -m` Justification message
- `--time, -t` Duration (`nH` 1-8 or `nM` 5-60)
- `--entra, -e` Request Entra ID (Azure AD) role (ignores sub/rg)
- `--help` Show help

If any parameter is omitted, you'll be prompted (with fuzzy search for sub/rg/role).

### Examples

Entra ID role:

```bash
./pim --entra --role "Global Administrator" --time 1H --message "Emergency access"
```

Azure resource role:

```bash
./pim --subscription "My Subscription" --resource-group "MyResourceGroup" --role "Contributor" --time 4H --message "Access required for deployment"
```

## Implementation

- Main logic: `pim` (Bash)
- Entra ID support: `pim_entra.ps1` (PowerShell, Microsoft Graph SDK)

## Contribution

Contributions are welcome! Please fork the repository and create a pull request with your changes.

## License

MIT License. See [LICENSE](LICENSE).
