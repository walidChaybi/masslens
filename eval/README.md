# Private model evaluation

Copy `manifest.example.json` to the git-ignored `manifest.json`, add at least 30
labeled objects, and put photos in `private_dataset/`. Include both photo-only
and measured-dimension cases.

Run the Worker locally with a real development OpenAI key and scan enforcement
disabled, then run `npm run eval -- ../eval/manifest.json` from `worker/`.
The evaluator blocks release unless all thresholds in the approved plan pass.

If Nano fails, set `OPENAI_MODEL=gpt-5.6-luna` in the evaluation Worker and
rerun the same frozen dataset. Set `MASSLENS_EVAL_INPUT_USD_PER_MTOK` and
`MASSLENS_EVAL_OUTPUT_USD_PER_MTOK` to that model's current official rates so
the cost gate stays honest. Do not ship either model when it fails. Never commit
the photos, labels with private information, or an OpenAI key.
