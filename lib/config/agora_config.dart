/// Agora App ID, injected at build time from the git-ignored
/// `config/env.json`:
///
///     flutter run --dart-define-from-file=config/env.json
///
/// Copy `config/env.example.json` to `config/env.json` to set it up.
const agoraAppId = String.fromEnvironment('AGORA_APP_ID');
