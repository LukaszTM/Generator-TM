# Jak wygenerować GeneratorTM.exe — instrukcja krok po kroku

Cały proces zajmuje ok. 10–15 minut (najdłużej trwa jednorazowe pobranie szablonów eksportu).
Potrzebujesz tylko komputera z Windows i internetu.

## Krok 1. Pobierz i uruchom Godota

1. Wejdź na stronę: **https://godotengine.org/download/windows/**
2. Pobierz **Godot Engine 4.4.x** — wybierz zwykłą wersję (NIE „.NET” / „C#”).
3. Pobrany plik to ZIP — rozpakuj go w dowolne miejsce (np. `C:\Godot\`).
   Godot nie wymaga instalacji: w środku jest jeden plik, np. `Godot_v4.4.1-stable_win64.exe`.
4. Uruchom go dwuklikiem.

## Krok 2. Zaimportuj projekt Generator TM

1. Rozpakuj `GeneratorTM_projekt_Godot.zip` do własnego folderu, np. `C:\Projekty\GeneratorTM\`
   (albo sklonuj repozytorium z GitHuba — zawartość jest ta sama).
2. W oknie startowym Godota (Menedżer projektów) kliknij przycisk **Import** (Importuj).
3. Kliknij **Browse** (Przeglądaj), wejdź do folderu z projektem i wskaż plik **`project.godot`**.
4. Kliknij **Import & Edit** (Zaimportuj i edytuj) — projekt otworzy się w edytorze.
5. Przy pierwszym otwarciu Godot przez chwilę importuje zasoby (pasek postępu na dole) — poczekaj aż skończy.

> Możesz od razu sprawdzić, że program działa: naciśnij **F5** (Uruchom projekt).
> Zamknij okno programu przed przejściem dalej.

## Krok 3. Zainstaluj szablony eksportu (jednorazowo)

Szablony to gotowe „silniki” dla eksportowanych aplikacji — pobiera się je raz dla danej wersji Godota.

1. W górnym menu edytora wybierz: **Editor → Manage Export Templates…**
   (Edytor → Zarządzaj szablonami eksportu…).
2. W oknie kliknij **Download and Install** (Pobierz i zainstaluj).
3. Poczekaj na pobranie (~700 MB) i instalację, po czym zamknij okno.

## Krok 4. Wyeksportuj plik .exe

1. W górnym menu wybierz: **Project → Export…** (Projekt → Eksportuj…).
2. Na liście po lewej jest już gotowy preset **„Windows Desktop”** — kliknij go.
   Wszystko jest skonfigurowane: jeden plik `.exe` z wbudowanymi danymi (embed PCK), architektura 64-bit.
3. Kliknij przycisk **Export Project…** (Eksportuj projekt…) na dole okna.
4. W oknie zapisu zostaw podpowiedzianą ścieżkę `build/GeneratorTM.exe` (albo wybierz własną)
   i **odznacz** pole „Export With Debug” (Eksport z debugowaniem), jeśli jest zaznaczone —
   wersja bez debugowania jest mniejsza i szybsza.
5. Kliknij **Save** (Zapisz).

Gotowe! W folderze projektu, w podfolderze **`build\`**, znajdziesz **`GeneratorTM.exe`**.

## Krok 5. Korzystanie i przenoszenie

- `GeneratorTM.exe` jest **samodzielny** — możesz go skopiować na pendrive'a, wysłać
  lub przenieść na inny komputer z Windows 10/11 (64-bit). Nie wymaga instalacji ani Godota.
- Program działa w pełni offline; internet jest używany tylko, gdy sam podasz adres URL do wczytania.

## Możliwe problemy i rozwiązania

| Problem | Rozwiązanie |
|---|---|
| W oknie eksportu przy „Windows Desktop” jest czerwony komunikat „No export template found” | Nie wykonano kroku 3 — zainstaluj szablony eksportu i wróć do eksportu. |
| Ostrzeżenie o braku **rcedit** przy eksporcie | Niegroźne — dotyczy tylko własnej ikony i metadanych pliku. Eksport i tak się powiedzie (plik będzie miał standardową ikonę Godota). Jeśli chcesz własną ikonę: pobierz `rcedit` (link podaje Godot w **Editor → Editor Settings → Export → Windows**), wskaż ścieżkę do niego i ustaw plik `.ico` w opcjach presetu. |
| Windows SmartScreen blokuje uruchomienie na innym komputerze | Normalne dla niepodpisanych programów: kliknij **Więcej informacji → Uruchom mimo to**. Podpis cyfrowy można dodać w opcjach presetu (wymaga certyfikatu). |
| Antywirus skanuje/przytrzymuje plik | Rzadkie, ale zdarza się przy świeżo wygenerowanych `.exe` — dodaj plik do wyjątków albo odczekaj na zakończenie skanowania. |
| Eksport kończy się błędem zapisu | Upewnij się, że folder `build\` nie jest otwarty w innym programie i że masz prawa zapisu w folderze projektu. |
