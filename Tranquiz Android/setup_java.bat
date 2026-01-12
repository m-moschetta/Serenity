@echo off
echo Configurazione automatica di JAVA_HOME per Tranquiz...
echo.

REM Cerca il JDK di Android Studio nelle posizioni comuni
set "ANDROID_STUDIO_JDK="

REM Controlla le posizioni comuni di Android Studio
if exist "C:\Program Files\Android\Android Studio\jbr" (
    set "ANDROID_STUDIO_JDK=C:\Program Files\Android\Android Studio\jbr"
    goto :found
)

if exist "C:\Program Files\Android\Android Studio\jre" (
    set "ANDROID_STUDIO_JDK=C:\Program Files\Android\Android Studio\jre"
    goto :found
)

if exist "%LOCALAPPDATA%\Android\Sdk\jre" (
    set "ANDROID_STUDIO_JDK=%LOCALAPPDATA%\Android\Sdk\jre"
    goto :found
)

if exist "%USERPROFILE%\AppData\Local\Android\Sdk\jre" (
    set "ANDROID_STUDIO_JDK=%USERPROFILE%\AppData\Local\Android\Sdk\jre"
    goto :found
)

echo ERRORE: Non riesco a trovare il JDK di Android Studio.
echo.
echo Soluzioni:
echo 1. Installa Android Studio se non è già installato
echo 2. Configura manualmente JAVA_HOME seguendo le istruzioni in SETUP_INSTRUCTIONS.md
echo 3. Usa Android Studio per compilare il progetto (raccomandato)
echo.
pause
exit /b 1

:found
echo Trovato JDK di Android Studio in: %ANDROID_STUDIO_JDK%
echo.

REM Imposta JAVA_HOME per questa sessione
set "JAVA_HOME=%ANDROID_STUDIO_JDK%"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo JAVA_HOME impostato a: %JAVA_HOME%
echo.

REM Verifica che Java funzioni
echo Verifica installazione Java...
java -version
if %ERRORLEVEL% neq 0 (
    echo ERRORE: Java non funziona correttamente.
    echo Usa Android Studio per compilare il progetto.
    pause
    exit /b 1
)

echo.
echo ✅ Java configurato correttamente!
echo.
echo Ora compilo il progetto...
echo.

REM Compila il progetto
call gradlew.bat clean assembleDebug

echo.
echo Compilazione completata!
echo.
echo NOTA: Questa configurazione di JAVA_HOME è temporanea.
echo Per una configurazione permanente, segui le istruzioni in SETUP_INSTRUCTIONS.md
echo.
pause