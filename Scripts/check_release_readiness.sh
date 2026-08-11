#!/bin/zsh
set -eu

task_root="${0:A:h:h}"
task_info="$task_root/PicoButtons/Resources/Info.plist"
task_ads="$task_root/PicoButtons/Services/AdService.swift"
task_settings="$task_root/PicoButtons/Views/SettingsView.swift"
task_failed=0

check_missing() {
  local task_message="$1"
  print -- "✗ $task_message"
  task_failed=1
}

if /usr/libexec/PlistBuddy -c 'Print :GADApplicationIdentifier' "$task_info" | rg -q '3940256099942544'; then
  check_missing 'AdMob App ID is still a Google test ID.'
fi

if rg -q '3940256099942544' "$task_ads"; then
  check_missing 'Banner or interstitial unit ID is still a Google test ID.'
fi

if rg -q 'example\.com/privacy' "$task_settings"; then
  check_missing 'Privacy Policy URL is still a placeholder.'
fi

if rg -q '各Pro機能のUI本体は今後追加' "$task_root/README.md"; then
  check_missing 'Advertised Pro features are not implemented.'
fi

if (( task_failed )); then
  print -- 'Release readiness check failed. Complete Docs/Release-Checklist.md before uploading.'
  exit 1
fi

print -- '✓ Release configuration has no known local blockers.'
