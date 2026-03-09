class AppStrings {
  const AppStrings._();

  static const appName = 'Cloudflare Email Manager Mobile';
  static const planningBanner = 'Phase 2 · Auth Foundation';
  static const loginTitle = 'Login with API Token';
  static const loginDescription =
      'Use your Cloudflare API Token to access email routing management.';
  static const apiTokenLabel = 'API Token';
  static const apiTokenHint = 'Paste raw token here';
  static const loginButton = 'Login';
  static const logoutButton = 'Logout';
  static const authCheckingSession = 'Checking secure session...';
  static const authStartupError = 'Unable to verify saved session.';
  static const retryButton = 'Retry';
  static const loginValidationEmpty = 'API token is required.';
  static const loginValidationBearerPrefix =
      'Paste the raw token only, without the Bearer prefix.';
  static const loginValidationWhitespace =
      'API token must not contain spaces or line breaks.';
  static const loginValidationTooShort = 'API token looks too short.';
  static const authErrorInvalidToken =
      'API token is invalid or has been rejected by Cloudflare.';
  static const authErrorInsufficientPermissions =
      'API token does not have sufficient permissions for this app.';
  static const authErrorNetwork =
      'Unable to verify token right now. Please try again.';
  static const logoutError = 'Unable to clear saved session. Please try again.';
  static const domainSelectorTitle = 'Select Domain';
  static const domainLoadError = 'Unable to load Cloudflare domains.';
  static const domainEmptyState =
      'No managed domains were found in this account.';
  static const domainActionLabel = 'Select domain';
  static const domainLoadingLabel = 'Loading domains...';
  static const aliasLoadingLabel = 'Loading aliases...';
  static const aliasLoadError = 'Unable to load aliases for this domain.';
  static const aliasNoDomainSelected =
      'Select a domain first to manage email aliases.';
  static const catchAllLoadingLabel = 'Loading detected catch-all addresses...';
  static const catchAllLoadError =
      'Unable to load catch-all activity for this domain.';
  static const catchAllNoDomainSelected =
      'Select a domain first to monitor catch-all activity.';
  static const catchAllRefreshButton = 'Refresh catch-all';
  static const catchAllListSubtitle =
      'Detected addresses that may need a dedicated alias.';
  static const catchAllDetectedSubtitle =
      'Detected from recent catch-all activity.';
  static const catchAllIgnoreButton = 'Ignore';
  static const catchAllBlockButton = 'Block';
  static const catchAllBlockPlaceholder =
      'Block action is not available in this MVP slice yet.';
  static const createAliasButton = 'Create Alias';
  static const aliasGeneratorButton = 'Generate Alias';
  static const aliasGeneratorTitle = 'Alias Generator';
  static const aliasGeneratorServiceLabel = 'Service';
  static const aliasGeneratorServiceHint = 'amazon';
  static const aliasGeneratorPreviewLabel = 'Generated Alias';
  static const aliasGeneratorPreviewPlaceholder =
      'Enter a service and generate an alias.';
  static const aliasGeneratorRegenerateButton = 'Regenerate';
  static const aliasGeneratorCreateButton = 'Create Generated Alias';
  static const aliasGeneratorServiceRequired = 'Service is required.';
  static const createAliasTitle = 'Create Alias';
  static const createAliasAliasLabel = 'Alias';
  static const createAliasAliasHint = 'sales';
  static const createAliasDestinationLabel = 'Destination Email';
  static const createAliasDestinationHint = 'destination@example.com';
  static const createAliasSubmitButton = 'Save Alias';
  static const createAliasCancelButton = 'Cancel';
  static const createAliasGenericError = 'Unable to create alias right now.';
  static const createAliasAliasRequired = 'Alias is required.';
  static const createAliasAliasLocalPartOnly =
      'Alias must contain the local part only.';
  static const createAliasAliasInvalid =
      'Alias format is invalid. Use letters, numbers, dots, underscores, plus, or hyphens only.';
  static const createAliasDestinationRequired =
      'Destination email is required.';
  static const createAliasDestinationInvalid =
      'Destination email format is invalid.';
  static const createAliasSuccess = 'Alias created successfully.';
  static const editAliasTitle = 'Edit Alias';
  static const editAliasAliasLabel = 'Alias Address';
  static const editAliasDestinationLabel = 'Destination Email';
  static const editAliasSubmitButton = 'Save Changes';
  static const editAliasSuccess = 'Alias updated successfully.';
  static const editAliasGenericError = 'Unable to update alias right now.';
  static const deleteAliasTooltip = 'Delete Alias';
  static const deleteAliasTitle = 'Delete Alias';
  static const deleteAliasMessage =
      'Are you sure you want to delete this alias?';
  static const deleteAliasConfirmButton = 'Delete';
  static const deleteAliasSuccess = 'Alias deleted successfully.';
  static const deleteAliasGenericError = 'Unable to delete alias right now.';
  static const toggleAliasEnableTooltip = 'Enable Alias';
  static const toggleAliasDisableTooltip = 'Disable Alias';
  static const toggleAliasEnableSuccess = 'Alias enabled successfully.';
  static const toggleAliasDisableSuccess = 'Alias disabled successfully.';
  static const toggleAliasGenericError =
      'Unable to update alias status right now.';
  static const aliasRefreshButton = 'Refresh aliases';
  static const aliasListSubtitle = 'Email routing rules for the active domain.';
  static const aliasUnsupportedRule = 'Unsupported routing rule';
  static const aliasStatusEnabled = 'Enabled';
  static const aliasStatusDisabled = 'Disabled';
  static const settingsPlaceholder =
      'Manage your session and future app preferences here.';
  static const dashboardTab = 'Dashboard';
  static const aliasesTab = 'Aliases';
  static const catchAllTab = 'Catch-All';
  static const activityTab = 'Activity';
  static const settingsTab = 'Settings';

  static String placeholderTitle(String tabLabel) => '$tabLabel Page';

  static String placeholderDescription(String tabLabel) =>
      'Initial placeholder for the $tabLabel feature.';

  static String aliasEmptyState(String domainName) =>
      'No aliases were found for $domainName yet.';

  static String aliasListTitle(String domainName) => 'Aliases · $domainName';

  static String catchAllEmptyState(String domainName) =>
      'No catch-all activity was detected for $domainName yet.';

  static String catchAllListTitle(String domainName) =>
      'Catch-All · $domainName';
}
