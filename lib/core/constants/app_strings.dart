class AppStrings {
  const AppStrings._();

  static const appName = 'Cloudflare Email Manager Mobile';
  static const planningBanner = 'MVP Progress · Core Flows Active';
  static const loginTitle = 'Login with API Token';
  static const loginDescription =
      'Use your Cloudflare API Token to access email routing management.';
  static const apiTokenLabel = 'API Token';
  static const apiTokenHint = 'Paste raw token here';
  static const loginButton = 'Login';
  static const logoutButton = 'Logout';
  static const authCheckingSession = 'Checking secure session...';
  static const authStartupError = 'Unable to verify saved session.';
  static const authSessionCleanupError =
      'Unable to securely clear the saved session.';
  static const authSessionCleanupWarning =
      'Saved session cleanup may be incomplete. Please sign in again carefully.';
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
  static const activityLoadingLabel = 'Loading email activity...';
  static const activityLoadError =
      'Unable to load email activity for this domain.';
  static const activityNoDomainSelected =
      'Select a domain first to review email activity.';
  static const activityRefreshButton = 'Refresh activity';
  static const activityLoadMoreButton = 'Load more';
  static const activityLoadingMoreLabel = 'Loading more activity...';
  static const activityLoadMoreError =
      'Unable to load more activity right now.';
  static const activityListSubtitle =
      'Recent email routing events from Cloudflare analytics.';
  static const catchAllIgnoreButton = 'Ignore';
  static const catchAllBlockButton = 'Block';
  static const catchAllBlockSuccess = 'Address blocked successfully.';
  static const catchAllBlockError = 'Unable to block this address right now.';
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
  static const destinationLoadingLabel = 'Loading destination emails...';
  static const destinationPickerHint = 'Select a verified destination';
  static const destinationPickerEmpty =
      'No verified destination email available yet.';
  static const destinationPickerAddButton = 'Add Destination';
  static const destinationDialogTitle = 'Add Destination Email';
  static const destinationDialogDescription =
      'Add a destination email address to your verified destination list.';
  static const destinationDialogSubmitButton = 'Save Destination';
  static const destinationCreateSuccess =
      'Destination email added successfully.';
  static const destinationLoadError = 'Unable to load destination emails.';
  static const destinationCreateError =
      'Unable to add destination email right now.';
  static const destinationVerifiedBadge = 'Verified';
  static const destinationPendingBadge = 'Pending Verification';
  static const destinationRequired = 'Select a verified destination email.';
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
  static const dashboardTitle = 'Dashboard';
  static const dashboardNoDomainTitle = 'No active domain selected';
  static const dashboardNoDomainDescription =
      'Choose a Cloudflare domain to start managing aliases, catch-all activity, and routing logs.';
  static const dashboardNoDomainHint =
      'Your current management context will appear here after selecting a domain.';
  static const dashboardDomainHint =
      'This domain is currently active across aliases, catch-all review, and activity logs.';
  static const dashboardActiveDomainLabel = 'Active domain';
  static const dashboardSelectDomainButton = 'Select Domain';
  static const dashboardChangeDomainButton = 'Change Domain';
  static const dashboardQuickActionsTitle = 'Quick actions';
  static const dashboardSummaryTitle = 'MVP summary';
  static const dashboardSummaryBody =
      'Core alias management, catch-all review, and activity monitoring are available from this app shell.';
  static const settingsTitle = 'Settings';
  static const settingsDomainSectionTitle = 'Domain';
  static const settingsNoDomainSelected = 'No domain selected yet.';
  static const settingsChangeDomainButton = 'Change Domain';
  static const settingsChangeDomainHint =
      'Switch the active domain used by aliases, catch-all, and activity tabs.';
  static const settingsSessionSectionTitle = 'Session';
  static const settingsSessionDescription =
      'Your Cloudflare API token is stored securely on this device.';
  static const settingsLogoutHint =
      'Clear the saved session and return to login.';
  static const settingsAboutSectionTitle = 'About';
  static const settingsAboutDescription =
      'Mobile MVP for managing Cloudflare Email Routing from one active domain at a time.';
  static const dashboardTab = 'Dashboard';
  static const aliasesTab = 'Aliases';
  static const catchAllTab = 'Catch-All';
  static const activityTab = 'Activity';
  static const settingsTab = 'Settings';

  static String dashboardReadyDescription(String domainName) =>
      'Everything is ready for $domainName. Jump into aliases, catch-all review, or recent routing activity.';

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

  static String activityEmptyState(String domainName) =>
      'No email activity was detected for $domainName yet.';

  static String activityListTitle(String domainName) =>
      'Activity · $domainName';
}
