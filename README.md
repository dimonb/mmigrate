# Slack to Mattermost Migration Guide

This guide provides comprehensive instructions for migrating data from Slack to Mattermost using the provided scripts. It includes steps for both Linux/macOS and Windows users.

---

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Required Tools](#required-tools)
- [Migration Steps](#migration-steps)
  - [Linux/macOS Instructions](#linuxmacos-instructions)
  - [Windows Instructions](#windows-instructions)
- [Notes](#notes)
- [Conclusion](#conclusion)
- [Support](#support)
- [Acknowledgments](#acknowledgments)
- [License](#license)

---

## Introduction

This repository contains scripts and instructions to help you migrate your Slack workspace data to Mattermost. The migration process involves exporting data from Slack, transforming it into a format compatible with Mattermost, and importing it into your Mattermost instance.

---

## Prerequisites

- **Access to Slack Workspace**: Ensure you have the necessary permissions to export data from your Slack workspace.
- **Access to Mattermost Instance**: You need administrative access to your Mattermost server.
- **Command-Line Interface (CLI)**: Familiarity with using the terminal, command prompt, or PowerShell.
- **Python 3**: Installed on your system.
- **Git and Wget**: For downloading repositories and files.
- **Permissions**: The user running the scripts should have read/write permissions on the necessary directories and files.

---

## Required Tools

To perform the migration, you will need the following tools:

1. **slackdump**

   - Tool used to export data from Slack.
   - [Download slackdump](https://github.com/rusq/slackdump)

2. **mmetl**

   - Mattermost's ETL tool for transforming Slack export data.
   - [Download mmetl](https://github.com/mattermost/mmetl)

3. **mmctl**

   - Command-line tool for managing Mattermost.
   - [Download mmctl](https://github.com/mattermost/mmctl)

4. **Python 3 and Required Packages**

   - Ensure Python 3 is installed on your system.
   - Required Python packages: `json`, `shutil`

---

## Migration Steps

### Linux/macOS Instructions

#### Run the Migration Script

In Windows, use PowerShell to execute the script:

```powershell
./run.ps1 -workspace <workspace> -chatid <chatid>
```

- `<workspace>`: The name of your **Mattermost team**.
- `<chatid>`: The identifier for the Slack channel or group you want to migrate.

**Example:**

```powershell
./run.ps1 -workspace "ebac-online" -chatid "FAKECHATID1234"
```

**Script Breakdown:**

1. **Create Directory**: The script creates a directory named after the `<chatid>`.

2. **Download Slack Data**: Checks if `mm-export.zip` exists. If not, downloads it using `slackdump`.

3. **Transform Data**: Uses `mmetl` to transform the Slack export to a Mattermost import file. The `-t` option specifies the target Mattermost team (`<workspace>`).

4. **Process Import File**: Runs `fix_users.py` to adjust user information. Splits large import files using `split_large.py`.

5. **Import into Mattermost**: For each chunk, the script compresses the chunk, uploads the ZIP file, and processes the import using `mmctl`.

---

## Notes

- **Environment Variables**: You may need to set environment variables for authentication tokens or other configurations.
- **Backups**: Always back up your Mattermost instance before performing bulk imports.
- **Testing**: It's recommended to test the migration process in a staging environment before applying it to production.
- **Permissions**: Ensure that you have the necessary permissions to execute scripts and access required resources.
- **Data Validation**: After the import, verify that all channels, messages, and attachments have been migrated correctly.

---

## Conclusion

By following this guide, you should be able to migrate your Slack data to Mattermost efficiently. The provided scripts automate much of the process, but it's important to understand each step to troubleshoot any potential issues.

---

## Support

If you encounter any issues or have questions:

- **Mattermost Documentation**: [https://docs.mattermost.com/](https://docs.mattermost.com/)
- **slackdump Repository**: [https://github.com/nixuch/slackdump](https://github.com/nixuch/slackdump)
- **Mattermost ETL Tool (mmetl)**: [https://github.com/mattermost/mmetl](https://github.com/mattermost/mmetl)
- **Mattermost Command-Line Tool (mmctl)**: [https://github.com/mattermost/mmctl](https://github.com/mattermost/mmctl)

---

## Acknowledgments

- **Scripts Author**: Thank you for providing the scripts that automate the migration process.
- **Community Support**: Thanks to the open-source community for developing these valuable tools.

---

## License

This guide is provided under the [MIT License](https://opensource.org/licenses/MIT).

---

