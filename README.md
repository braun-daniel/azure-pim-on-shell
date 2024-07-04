
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

### Required Parameters

- `--subscription, -s`: Subscription ID or name (fuzzy search enabled)
- `--resource-group, -g`: Resource group name (fuzzy search enabled)

### Optional Parameters

- `--message, -m`: Justification message
- `--role, -r`: Role name (default: Contributor)
- `--time, -t`: Duration (default: 8H). Format: 8H (hours) or 8M (minutes)
- `--help`: Show help message

### Example

```bash
./pim --subscription "My Subscription" --resource-group "MyResourceGroup" --message "Access required for deployment" --role "Contributor" --time "4H" --verbose
```

### Fuzzy Search

If you do not provide `--subscription` or `--resource-group`, the script will invoke `fzf` to let you select from available options.

### Running Without Parameters

You can run the script without specifying `--subscription` or `--resource-group`, and you will be prompted to select them using `fzf`.

```bash
./pim
```

## Example Workflow

1. Ensure you are logged into Azure CLI:
    ```bash
    az login
    ```
2. Run the script:
    ```bash
    ./pim --verbose
    ```
3. Select the subscription and resource group using `fzf`.
4. Provide the required justification message when prompted.

## Error Handling

The script performs various checks and provides meaningful error messages for missing dependencies, invalid input formats, and operational errors.

## Contribution

Contributions are welcome! Please fork the repository and create a pull request with your changes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
