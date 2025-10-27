# Repository Guidelines

## Project Structure & Module Organization
Audio-text transformation code belongs under `src/audiotext/`; create the package if absent and break features into focused modules such as `ingest`, `transcribe`, and `export`. Keep shared orchestration in `src/audiotext/app.py` so both CLI and API surfaces reuse the same pipeline. Unit and integration tests live in `tests/`, mirroring the source path (for example `tests/transcribe/test_batch.py` for `src/audiotext/transcribe/batch.py`). Store sample audio, prompt fixtures, and manual reference transcripts in `data/samples/`, and place large binaries under Git LFS. Use the existing `References/` folder strictly for research artefacts and design snapshots to keep the working tree lean.

## Build, Test, and Development Commands
Bootstrap an isolated environment before modifying code:  
`python -m venv .venv && source .venv/bin/activate`  
Install dependencies in editable mode after updating `pyproject.toml` or `requirements.txt`:  
`pip install -e .`  
Run the quick lint gate:  
`ruff check src tests`  
Auto-format prior to committing:  
`black src tests`  
Execute the main suite with coverage metrics:  
`pytest --cov=audiotext --cov-report=term-missing`  
Once the API scaffold lands, start it locally with:  
`uvicorn audiotext.app:app --reload`

## Coding Style & Naming Conventions
Target Python 3.11+, four-space indentation, and exhaustive type hints. Modules, packages, and filenames use `snake_case`; classes use `PascalCase`; constants stay in screaming snake case. Keep functions under 40 lines by extracting reusable helpers. Configure `black`, `ruff`, and `mypy` via `pyproject.toml`, and run all three tools before pushing. Document non-obvious signal-processing math with short docstrings or comments referencing sample rates and assumptions.

## Testing Guidelines
Maintain at least 85% coverage for new modules. Name tests descriptively, e.g. `test_transcribe_handles_empty_chunk`. Mock cloud services and filesystem boundaries; integration tests may stream small artifacts from `data/samples/`. When introducing regression audio fixtures, log their checksum in the docstring so updates are intentional.

## Commit & Pull Request Guidelines
Adopt Conventional Commits (`feat:`, `fix:`, `chore:`) in the imperative mood. Limit subject lines to 72 characters, wrap bodies at 100, and reference tracked work as `Refs #123`. Every PR should outline motivation, implementation notes, manual QA steps (CLI output or screenshots), and a rollback strategy. Request review from a domain owner when touching transcription accuracy or decoding heuristics.

## Security & Configuration Tips
Never commit credentials; maintain `.env.example` with placeholder keys and load real values through environment variables or secret stores. Validate uploaded audio in `ingest` before persisting, and strip sensitive transcript fragments from logs or analytics exports.
