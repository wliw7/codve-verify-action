# codve-verify-action
GitHub Action to verify code changes with Codve and fail PRs on risky behavior.
# Codve Verify GitHub Action

Run Codve verification on pull requests and fail the workflow when risky behavior is detected.

## Quick start

1) Add your Codve API key as a repo secret:
- `Settings` → `Secrets and variables` → `Actions` → `New repository secret`
- Name: `CODVE_API_KEY`

2) Create `.github/workflows/codve.yml`:

```yaml
name: Codve Verify
on:
  pull_request:

jobs:
  codve:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Codve Verify
        uses: wliw7/codve-verify-action@v1
        with:
          api-key: ${{ secrets.CODVE_API_KEY }}
          config: ".codve.yml"
Inputs
Name	Required	Description
api-key	yes	Your Codve API key
config	yes	Path to your Codve config file (example: .codve.yml) or inline YAML/JSON (depending on your setup)

Example config
Create a file named .codve.yml in your repo:

yml
Copy code
preset: backend-safety
fail_on: fail
Output
This action exits non-zero when Codve reports a failing verification, causing the workflow to fail.

Support
Website: https://codve.ai

Issues: use this repo’s GitHub Issues

yaml
Copy code

Then commit to `main`.

---

## After README update: bump patch release (optional but clean)
Since you already released `v1.0.0`, after updating README you *can*:
- create `v1.0.1` release  
…but it’s not required. README updates still show up.

---

## One important thing
Right now you released **`v1.0.0`**, but people will want `@v1`.

So next: create tag/release **`v1`** (stable major tag).

If you want the simplest:
- Draft new release → Tag `v1` → Publish.

---

If you paste your `entrypoint.sh`, I’ll adjust the README line about `config` so it’s 100% correct (file path 
