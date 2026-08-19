$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$jupyter = Join-Path $repoRoot ".venv\Scripts\jupyter.exe"
$notebook = Join-Path $repoRoot "Day19_GraphRAG_vs_FlatRAG_Production_Lab_Guide.ipynb"

if (-not (Test-Path -LiteralPath $jupyter)) {
    throw "Missing virtual environment Jupyter executable: $jupyter"
}

Push-Location $repoRoot
try {
    & $jupyter nbconvert --to notebook --execute --inplace `
        --ExecutePreprocessor.timeout=1800 `
        --ExecutePreprocessor.kernel_name=python3 `
        $notebook
    if ($LASTEXITCODE -ne 0) {
        throw "Notebook execution failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

