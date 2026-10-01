#!/bin/zsh
# MassLens - run the backend tests, then deploy the Cloudflare Worker.
cd "$(dirname "$0")/worker"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
setopt pipefail
echo "== Running backend tests =="
npm run check 2>&1 | tee ../deploy_log.txt || { read -k 1 "?Tests failed - nothing was deployed. Press any key to close..."; exit 1; }
echo
echo "== Deploying to Cloudflare =="
npx wrangler deploy 2>&1 | tee -a ../deploy_log.txt || { read -k 1 "?Deploy failed - see the messages above. Press any key to close..."; exit 1; }
echo
echo "Done! The new estimation logic is live."
read -k 1 "?Press any key to close..."
