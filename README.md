# IMPACT Manager 2.2 BETA — wygląd meble impact

Nowa jasna szata graficzna, logo użytkownika w panelu bocznym i na ekranie logowania. Funkcjonalność i struktura bazy danych jak w wersji 2.1.

## Aktualizacja z 2.1
1. Zachowaj kopię poprzedniej wersji.
2. Rozpakuj ZIP i przenieś plik `.env` z poprzedniej wersji do nowego folderu (nie publikuj go na GitHub).
3. W folderze projektu wykonaj `npm.cmd install`, potem `npm.cmd run dev`.
4. Nie uruchamiaj ponownie migracji SQL, jeżeli 2.1 już działa. Jeśli instalujesz od zera, wykonaj migracje według kolejności opisanej w plikach SQL.

Uwaga: moduły Produkcja, Kalendarz i Dokumentacja w menu pozostają placeholderami; dokumenty zamówienia są w karcie zamówienia. To wersja beta, wymagająca testów przed użyciem na danych klientów.

# IMPACT Manager 2.1 BETA — pliki zamówień

Rozszerza wersję 2.0 o zdjęcia i PDF przypisane do zamówień.

1. Zachowaj starą wersję i eksport bazy.
2. Upewnij się, że wykonałeś wcześniej 01_MIGRACJA_SUPABASE.sql i 04_ROZSZERZENIE.sql.
3. W Supabase -> SQL Editor (PostgreSQL) uruchom **05_PLIKI_STORAGE.sql**.
4. Skopiuj swój dotychczasowy `.env` do nowego katalogu. Nie przesyłaj kluczy do czatu.
5. Otwórz katalog w VS Code. `npm.cmd install`, następnie `npm.cmd run dev`.
6. Otwórz zamówienie -> Zdjęcia i dokumenty -> Dodaj zdjęcia lub PDF.

Prywatny bucket, podpisane linki ważne 60 sekund, ograniczenie 10 MB na plik i cztery typy MIME. Admin i biuro mogą usuwać, wszyscy aktywni członkowie zespołu mogą dodawać i przeglądać. Nie przesyłaj wrażliwych dokumentów przed przetestowaniem uprawnień na drugim koncie.

Uwaga: darmowy Supabase ma limity przestrzeni i transferu. Duże PDF mogą szybko wyczerpać dostępny limit. Zmiana bazy wymaga osobnej kopii zapasowej plików ze Storage.

To nadal wersja BETA.
