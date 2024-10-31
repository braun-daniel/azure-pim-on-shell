# PIM Assignment Script

This script automates the process of making Privileged Identity Management (PIM) assignments in Azure. It leverages `fzf` for fuzzy searching subscription names and resource group names for user convenience.

## Features

- Fuzzy search for subscription names and resource group names using `fzf`
- Customizable role assignments with duration and justification messages
- Supports verbose output for detailed operation logs

## Prerequisites

Ensure the following commands are installed and accessible in your environment:

- `curl`
- `az` (Azure CLI)
- `jq`
- `fzf`

## Usage

```bash
./pim [OPTIONS]
```

### Parameters

- `--subscription, -s`: Subscription ID or name (fuzzy search enabled)
- `--resource-group, -g`: Resource group name (fuzzy search enabled)
- `--message, -m`: Justification message
- `--role, -r`: Role name (fuzzy search enabled)
- `--time, -t`: Duration (default: 1H). Format: 8H (hours) or 8M (minutes)
- `--help`: Show help message

### Example

```bash
./pim --subscription "My Subscription" --resource-group "MyResourceGroup" --message "Access required for deployment" --role "Contributor" --time "4H"
```

### Fuzzy Search

If you do not provide `--subscription`, `--resource-group` or `--role`, the script will invoke `fzf` to let you select from available options.

## Error Handling

The script performs various checks and provides meaningful error messages for missing dependencies, invalid input formats, and operational errors.

## Contribution

Contributions are welcome! Please fork the repository and create a pull request with your changes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
