# Private model evaluation

Copy `manifest.example.json` to the git-ignored `manifest.json`, add at least 30
labeled objects, and put photos in `private_dataset/`. Record ground-truth mass
and physical length, width, and height for every object, but never send those
labels to the Worker. At least 10 objects need a second 45-90 degree side photo.
The evaluator sends the primary image alone and then both images for those
objects, so the comparison is paired.

Run the Worker locally with a real development OpenAI key and scan enforcement
disabled, then run `npm run eval -- ../eval/manifest.json` from `worker/`.
The evaluator blocks release unless all thresholds in the approved AI-only plan
pass, including positive structured dimensions, one-view and two-view dimension
error, latency, and cost. Horizontal axes are compared without assuming which
one the model named `width` or `depth`.

Keep `gpt-5-nano`; do not silently switch to a more expensive model when an
evaluation fails. Iterate the prompt and capture guidance against the same
frozen dataset. Never commit photos, private labels, or an OpenAI key.
