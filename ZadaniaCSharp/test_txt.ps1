param (
    [string]$scriptDirectory
)

# Ustalenie ścieżki do folderu nadrzędnego
$parentDirectory = Split-Path -Path $scriptDirectory -Parent

# Kompilacja i uruchomienie testów
dotnet test "$scriptDirectory\UnitTesting" --logger "trx;LogFileName=TestResults.trx"

# Analiza pliku wynikowego i zapisanie rezultatów do pliku tekstowego
$testResultsFile = Join-Path -Path $scriptDirectory -ChildPath "UnitTesting\TestResults\TestResults.trx"
if (Test-Path $testResultsFile) {
    $trxContent = Get-Content $testResultsFile

    # Inicjalizacja słownika wyników testów
    $testResults = @{}

    # Znalezienie sekcji wyników testów i grupowanie ich
    $trxContent | ForEach-Object {
        if ($_ -match '<UnitTestResult.*?testName="([^"]*)".*?outcome="([^"]*)"') {
            $testName = $Matches[1].Split('.')[0].Split('_')[0]
            $outcome = $Matches[2]

            # Aktualizacja wyników testów
            if (-not $testResults[$testName]) {
                $testResults[$testName] = [PSCustomObject]@{
                    TestName = $testName
                    Passed = 0
                    Failed = 0
                }
            }
            if ($outcome -eq "Passed") {
                $testResults[$testName].Passed++
            } elseif ($outcome -eq "Failed") {
                $testResults[$testName].Failed++
            }
        }
    }

    # Zapisanie wyników do pliku tekstowego
    $outputTxt = Join-Path -Path $parentDirectory -ChildPath "output.txt"
    if (Test-Path $outputTxt) {
        Clear-Content -Path $outputTxt
    }

    foreach ($testName in $testResults.Keys) {
        $passed = $testResults[$testName].Passed
        $failed = $testResults[$testName].Failed
        "${testName}: $($passed)/$failed" | Out-File -FilePath $outputTxt -Append -Encoding utf8
    }
} else {
    # Jeśli plik TestResults.trx nie istnieje, zapisz komunikat do pliku output.txt
    $outputTxt = Join-Path -Path $parentDirectory -ChildPath "output.txt"
    "Plik TestResults.trx nie istnieje." | Out-File -FilePath $outputTxt -Encoding utf8
}

# Usunięcie folderu UnitTesting\TestResults wraz z zawartością
$testResultsDirectory = Join-Path -Path $scriptDirectory -ChildPath "UnitTesting\TestResults"
Remove-Item -Path $testResultsDirectory -Recurse -Force
