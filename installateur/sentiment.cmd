@echo off
REM ============================================================================
REM Lanceur Windows de la commande "sentiment"
REM Utilise exclusivement le Python embarque situe dans "%~dp0python\python.exe"
REM Transmet tous les arguments (%*) et renvoie le code de sortie exact.
REM ============================================================================

if exist "%~dp0python\Lib\site-packages\sentiment_app\__main__.py" (
    "%~dp0python\python.exe" -X utf8 -m sentiment_app %*
) else (
    "%~dp0python\python.exe" -X utf8 -m sentiment_app.cli %*
)
exit /b %ERRORLEVEL%
