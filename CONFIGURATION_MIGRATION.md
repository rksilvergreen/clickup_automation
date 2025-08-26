# Configuration Migration Guide

## Overview
This document describes the migration from the old single `env.yaml` file to the new multi-file configuration structure.

## What Changed

### Before (Single File)
- **File**: `env.yaml`
- **Structure**: All configuration in one file
- **Git Status**: Tracked (contained sensitive information)
- **Problems**: 
  - Mixed sensitive and non-sensitive data
  - Hard to manage different deployment environments
  - No separation of concerns

### After (Multi-File Structure)
- **Files**: 
  - `config/api.yaml` - API constants (tracked in git)
  - `config/server.yaml` - Server settings (NOT tracked in git)
  - `config/runtime.yaml` - Runtime settings (NOT tracked in git)
  - `config/server.yaml.template` - Template (tracked in git)
  - `config/runtime.yaml.template` - Template (tracked in git)

## Migration Steps

### 1. ✅ Configuration Files Created
- [x] `config/api.yaml` - Contains ClickUp API constants
- [x] `config/server.yaml.template` - Server configuration template
- [x] `config/runtime.yaml.template` - Runtime configuration template
- [x] `config/server.yaml` - Actual server config (gitignored)
- [x] `config/runtime.yaml` - Actual runtime config (gitignored)

### 2. ✅ Code Updated
- [x] `lib/environment.dart` - Updated to load from multiple files
- [x] `.gitignore` - Updated to exclude sensitive config files
- [x] `env.yaml` - Removed (replaced by new structure)

### 3. ✅ Documentation Created
- [x] `config/README.md` - Comprehensive configuration guide
- [x] `CONFIGURATION_MIGRATION.md` - This migration guide

## File Contents

### `config/api.yaml` (Tracked in Git)
```yaml
# ClickUp API Configuration
CLICKUP_BASE_URL: "https://api.clickup.com/api/v2"
CLICKUP_TEAM_ID: "90181045003"
CLICKUP_WEBHOOK_SECRET: "0ZOP0IPDY4II7ZBKIVFRZRKKU85SW8O4OE71L6LXNKXIO0WW6T6Q5I1NAN9ZUCYZ"

# ClickUp Workspace Constants
task_types:
  TASK_TYPE_ID_EVENT: "1011"
lists:
  LIST_ID_SHOPPING: "901810374798"
custom_fields:
  CUSTOM_FIELD_ID_START_TIME: "ea56a6af-6e6d-4742-b792-02ca01350dad"
  # ... more fields
tags:
  TAG_NAME_PURCHASE: "purchase"
```

### `config/server.yaml` (NOT Tracked in Git)
```yaml
# Server Configuration
PUBLIC_BASE_URL: "http://automation-local.ronbal.net"
PORT: "8080"
CLICKUP_TOKEN: "pk_..."  # Your actual token here
```

### `config/runtime.yaml` (NOT Tracked in Git)
```yaml
# Runtime Configuration
automation:
  events:
    default_relevance_interval: 7
    auto_status_update: true
    timezone: "Asia/Jerusalem"
  # ... more settings
```

## Benefits of New Structure

### 1. **Security**
- Sensitive data (tokens, URLs) not committed to git
- Each deployment can have different server settings
- API constants remain version-controlled

### 2. **Maintainability**
- Clear separation of concerns
- Easy to update API constants without touching server config
- Runtime settings can be modified without redeployment

### 3. **Deployment Flexibility**
- Different environments can have different server configs
- Runtime settings can be customized per instance
- Template files show what configuration is needed

### 4. **Team Collaboration**
- Developers can see what configuration is needed
- Sensitive information stays local
- Easy to onboard new team members

## Next Steps

### 1. **Update Your Deployment**
- Copy `server.yaml.template` to `server.yaml`
- Fill in your actual server settings
- Copy `runtime.yaml.template` to `runtime.yaml`
- Customize runtime settings as needed

### 2. **Verify Configuration**
- Run the application to ensure all config files load
- Check that environment variables are populated correctly
- Verify that sensitive data is not logged

### 3. **Future Enhancements**
- Add environment variable support for production
- Implement runtime configuration reloading
- Add configuration validation

## Troubleshooting

### Configuration Not Loading
- Ensure all three config files exist
- Check file permissions
- Verify YAML syntax

### Missing Values
- Check that required fields are set in `server.yaml`
- Verify `api.yaml` contains all necessary constants
- Ensure `runtime.yaml` has sensible defaults

### Git Issues
- Make sure `server.yaml` and `runtime.yaml` are in `.gitignore`
- Commit `api.yaml` and template files
- Don't commit actual configuration files

## Support
If you encounter issues during migration, check:
1. File paths and permissions
2. YAML syntax in configuration files
3. Application logs for configuration loading messages
4. `.gitignore` file to ensure sensitive files are excluded 