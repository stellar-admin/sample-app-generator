#!/usr/bin/env bash
# Voyager Travel's own changes to the generated app; generate.sh runs it after copying the overlay.
set -euo pipefail

perl -i -pe 's/IdentityUser/ApplicationUser/g; $_ .= "\@using VoyagerTravel.Data\r\n" if $. == 1' "$APP/Views/Shared/_LoginPartial.cshtml"
printf '\n# Uploaded images, saved by LocalImageStore\n/src/%s/uploads/*\n!/src/%s/uploads/.gitkeep\n' "$PROJECT" "$PROJECT" >> "$TARGET/.gitignore"
