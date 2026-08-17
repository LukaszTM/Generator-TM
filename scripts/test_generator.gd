class_name TestGenerator
extends RefCounted
## Regułowy generator planu testów i przypadków testowych.
## Działa w pełni offline: analizuje treść wybranych modułów i na podstawie
## wykrytych słów kluczowych oraz zdań-wymagań buduje przypadki testowe.

## Pojedynczy przypadek testowy.
class TestCase:
	var id := ""
	var module := ""
	var title := ""
	var type := "Pozytywny"      # Pozytywny / Negatywny / Brzegowy / Bezpieczeństwo
	var priority := "Średni"     # Wysoki / Średni / Niski
	var preconditions := ""
	var steps: Array[String] = []
	var test_data := ""
	var expected := ""
	var why := ""                # tryb nauki: dlaczego ten test istnieje / jaka technika

# Domyślne wyjaśnienia edukacyjne wg typu testu (tryb nauki).
const WHY_BY_TYPE := {
	"Pozytywny": "Test pozytywny (tzw. ścieżka szczęśliwa) — najpierw potwierdzamy, że funkcja w ogóle działa zgodnie z dokumentacją. Dopiero na działającej funkcji szukanie błędów ma sens.",
	"Negatywny": "Test negatywny — celowo podajemy błędne dane lub łamiemy warunki, bo aplikacja musi zawieść bezpiecznie: czytelny komunikat i brak utraty danych. Technika: niepoprawne klasy równoważności.",
	"Brzegowy": "Test brzegowy — błędy najczęściej kryją się na granicach zakresów: wartość minimalna, maksymalna, pusta albo o jeden za duża. Technika: analiza wartości brzegowych.",
	"Bezpieczeństwo": "Test bezpieczeństwa — sprawdzamy odporność na nadużycia i złośliwe dane. Aplikacja ma chronić dane nawet wtedy, gdy ktoś świadomie próbuje ją oszukać.",
}

## Parametry generowania.
class Options:
	var project_name := "Aplikacja"
	var author := ""
	var id_prefix := "TC"
	var include_positive := true
	var include_negative := true
	var include_boundary := true
	var include_security := true
	var max_generic_per_module := 8
	var doc_source := ""
	var app_source := ""

## Wynik generowania.
class Output:
	var plan_markdown := ""
	var cases: Array[TestCase] = []


# ------------------------------------------------------------------
# Reguły: słowa kluczowe funkcjonalności -> szablony przypadków.
# Pola szablonu: title, type, priority, pre, steps, data, expected.
# ------------------------------------------------------------------
static func _rules() -> Array[Dictionary]:
	return [
		{
			"keywords": ["logowan", "login", "zalogo", "sign in", "sign-in", "uwierzytelni", "authentication"],
			"label": "Logowanie",
			"cases": [
				{"title": "Logowanie z poprawnymi danymi", "type": "Pozytywny", "priority": "Wysoki",
				 "pre": "Istnieje aktywne konto użytkownika.",
				 "steps": ["Otwórz ekran logowania.", "Wprowadź poprawny identyfikator (login/e-mail).", "Wprowadź poprawne hasło.", "Zatwierdź przyciskiem logowania."],
				 "data": "Poprawny login i hasło istniejącego użytkownika.",
				 "expected": "Użytkownik zostaje zalogowany i przeniesiony do widoku startowego; sesja jest aktywna.",
				 "why": "Logowanie to najczęściej używana funkcja aplikacji — jej awaria blokuje wszystko inne, dlatego zawsze testujemy ją jako pierwszą i z wysokim priorytetem."},
				{"title": "Logowanie z błędnym hasłem", "type": "Negatywny", "priority": "Wysoki",
				 "pre": "Istnieje aktywne konto użytkownika.",
				 "steps": ["Otwórz ekran logowania.", "Wprowadź poprawny identyfikator.", "Wprowadź błędne hasło.", "Zatwierdź przyciskiem logowania."],
				 "data": "Poprawny login, losowe błędne hasło.",
				 "expected": "Logowanie odrzucone, czytelny komunikat o błędnych danych; hasło nie jest ujawniane w komunikacie ani w adresie URL.",
				 "why": "Sprawdzamy nie tylko odrzucenie, ale i treść komunikatu — zbyt szczegółowy komunikat („złe hasło”) zdradza napastnikowi, że login istnieje. To pogranicze testu negatywnego i bezpieczeństwa."},
				{"title": "Logowanie na nieistniejące konto", "type": "Negatywny", "priority": "Średni",
				 "pre": "Brak konta o podanym identyfikatorze.",
				 "steps": ["Otwórz ekran logowania.", "Wprowadź identyfikator, który nie istnieje w systemie.", "Wprowadź dowolne hasło.", "Zatwierdź."],
				 "data": "Login: nieistniejacy_uzytkownik@test.pl",
				 "expected": "Logowanie odrzucone; komunikat nie zdradza, czy konto istnieje (ochrona przed enumeracją kont).",
				 "why": "Komunikat błędu nie może zdradzać, czy konto istnieje — inaczej można masowo wyliczać zarejestrowanych użytkowników (tzw. enumeracja kont)."},
				{"title": "Logowanie z pustymi polami", "type": "Brzegowy", "priority": "Średni",
				 "pre": "Ekran logowania jest otwarty.",
				 "steps": ["Pozostaw pola loginu i hasła puste.", "Zatwierdź przyciskiem logowania."],
				 "data": "Puste pola.",
				 "expected": "Walidacja blokuje wysłanie formularza i wskazuje wymagane pola."},
				{"title": "Ochrona przed atakiem siłowym (wielokrotne błędne logowania)", "type": "Bezpieczeństwo", "priority": "Wysoki",
				 "pre": "Istnieje aktywne konto użytkownika.",
				 "steps": ["Wykonaj co najmniej 10 prób logowania z błędnym hasłem.", "Obserwuj zachowanie systemu."],
				 "data": "Poprawny login, błędne hasła.",
				 "expected": "System ogranicza próby (blokada czasowa, CAPTCHA lub inne zabezpieczenie) zgodnie z dokumentacją.",
				 "why": "Bez ograniczenia liczby prób napastnik może zgadywać hasła w nieskończoność (atak siłowy). Blokada czasowa, opóźnienie lub CAPTCHA to standardowe zabezpieczenia."},
			],
		},
		{
			"keywords": ["rejestrac", "załóż konto", "utworzenie konta", "sign up", "signup", "register"],
			"label": "Rejestracja",
			"cases": [
				{"title": "Rejestracja nowego użytkownika z poprawnymi danymi", "type": "Pozytywny", "priority": "Wysoki",
				 "pre": "Adres e-mail nie jest zarejestrowany w systemie.",
				 "steps": ["Otwórz formularz rejestracji.", "Wypełnij wszystkie wymagane pola poprawnymi danymi.", "Zatwierdź formularz."],
				 "data": "Unikalny e-mail, hasło spełniające politykę bezpieczeństwa.",
				 "expected": "Konto zostaje utworzone; użytkownik otrzymuje potwierdzenie (ekran lub e-mail) zgodnie z dokumentacją."},
				{"title": "Rejestracja na zajęty adres e-mail", "type": "Negatywny", "priority": "Wysoki",
				 "pre": "W systemie istnieje konto z danym adresem e-mail.",
				 "steps": ["Otwórz formularz rejestracji.", "Podaj adres e-mail już zarejestrowany.", "Wypełnij pozostałe pola i zatwierdź."],
				 "data": "E-mail istniejącego konta.",
				 "expected": "Rejestracja odrzucona z czytelnym komunikatem; duplikat konta nie powstaje."},
				{"title": "Walidacja formatu adresu e-mail", "type": "Negatywny", "priority": "Średni",
				 "pre": "Formularz rejestracji jest otwarty.",
				 "steps": ["Wprowadź niepoprawny adres e-mail (np. bez znaku @).", "Zatwierdź formularz."],
				 "data": "\"niepoprawny.adres\", \"a@b\", \"a b@c.pl\"",
				 "expected": "Walidacja odrzuca błędny format i wskazuje pole z błędem."},
				{"title": "Hasło niespełniające polityki bezpieczeństwa", "type": "Bezpieczeństwo", "priority": "Średni",
				 "pre": "Formularz rejestracji jest otwarty.",
				 "steps": ["Wprowadź hasło krótsze/prostsze niż wymaga polityka.", "Zatwierdź formularz."],
				 "data": "Hasła: \"1\", \"abc\", \"12345678\"",
				 "expected": "System odrzuca słabe hasło i pokazuje wymagania dotyczące hasła."},
			],
		},
		{
			"keywords": ["hasł", "password", "reset has", "przypomnij", "odzyskiwanie"],
			"label": "Hasło / odzyskiwanie",
			"cases": [
				{"title": "Reset hasła poprawnym linkiem", "type": "Pozytywny", "priority": "Wysoki",
				 "pre": "Istnieje konto; użytkownik ma dostęp do skrzynki e-mail.",
				 "steps": ["Użyj funkcji odzyskiwania hasła.", "Podaj adres e-mail konta.", "Otwórz link z otrzymanej wiadomości.", "Ustaw nowe hasło zgodne z polityką.", "Zaloguj się nowym hasłem."],
				 "data": "E-mail istniejącego konta, nowe poprawne hasło.",
				 "expected": "Hasło zostaje zmienione; logowanie nowym hasłem działa, a starym jest odrzucane."},
				{"title": "Użycie wygasłego/zużytego linku resetu", "type": "Negatywny", "priority": "Średni",
				 "pre": "Wygenerowano link resetu hasła, który wygasł lub został już użyty.",
				 "steps": ["Otwórz nieaktualny link resetu hasła.", "Spróbuj ustawić nowe hasło."],
				 "data": "Wygasły token resetu.",
				 "expected": "System odrzuca operację z czytelnym komunikatem i pozwala wygenerować nowy link."},
			],
		},
		{
			"keywords": ["formularz", "pole", "pola", "walidac", "input", "form ", "validation"],
			"label": "Formularze i walidacja",
			"cases": [
				{"title": "Wysłanie formularza z poprawnymi danymi", "type": "Pozytywny", "priority": "Wysoki",
				 "pre": "Formularz jest dostępny dla użytkownika.",
				 "steps": ["Otwórz formularz.", "Wypełnij wszystkie wymagane pola poprawnymi danymi.", "Zatwierdź formularz."],
				 "data": "Zestaw poprawnych danych zgodny z dokumentacją modułu.",
				 "expected": "Dane zostają zapisane/przetworzone, użytkownik widzi potwierdzenie."},
				{"title": "Wysłanie formularza z pustymi polami wymaganymi", "type": "Negatywny", "priority": "Wysoki",
				 "pre": "Formularz jest dostępny dla użytkownika.",
				 "steps": ["Pozostaw wymagane pola puste.", "Zatwierdź formularz."],
				 "data": "Puste pola wymagane.",
				 "expected": "Walidacja blokuje wysłanie i oznacza brakujące pola; dane nie zostają zapisane."},
				{"title": "Wartości graniczne długości pól", "type": "Brzegowy", "priority": "Średni",
				 "pre": "Znane są limity długości pól (z dokumentacji lub interfejsu).",
				 "steps": ["Wprowadź wartość o minimalnej dozwolonej długości i zapisz.", "Wprowadź wartość o maksymalnej dozwolonej długości i zapisz.", "Wprowadź wartość przekraczającą maksimum o 1 znak i spróbuj zapisać."],
				 "data": "Łańcuchy o długości min, max, max+1.",
				 "expected": "Wartości min i max są przyjmowane; wartość max+1 jest odrzucana lub ucinana zgodnie z dokumentacją."},
				{"title": "Znaki specjalne i próba wstrzyknięcia kodu w polach tekstowych", "type": "Bezpieczeństwo", "priority": "Wysoki",
				 "pre": "Formularz jest dostępny dla użytkownika.",
				 "steps": ["Wprowadź w pola tekstowe znaki specjalne, cudzysłowy i fragmenty znaczników HTML.", "Zatwierdź formularz.", "Wyświetl zapisane dane."],
				 "data": "Np. „<b>test</b>”, „O'Brien”, „&amp;”, polskie znaki diakrytyczne.",
				 "expected": "Dane są bezpiecznie zapisane i wyświetlane jako tekst (bez wykonania kodu), polskie znaki nie są zniekształcane.",
				 "why": "Jeśli aplikacja wykona wpisany kod zamiast potraktować go jak zwykły tekst, mamy podatność XSS — jedną z najczęstszych dziur bezpieczeństwa aplikacji webowych. Nazwisko „O'Brien” z apostrofem to z kolei klasyczny sprawdzian obsługi cudzysłowów."},
			],
		},
		{
			"keywords": ["wyszukiw", "szukaj", "search"],
			"label": "Wyszukiwanie",
			"cases": [
				{"title": "Wyszukiwanie istniejącej frazy", "type": "Pozytywny", "priority": "Wysoki",
				 "pre": "W systemie istnieją dane zawierające szukaną frazę.",
				 "steps": ["Otwórz wyszukiwarkę.", "Wpisz frazę występującą w danych.", "Uruchom wyszukiwanie."],
				 "data": "Fraza istniejąca w danych testowych.",
				 "expected": "Lista wyników zawiera pasujące rekordy; wyniki są trafne."},
				{"title": "Wyszukiwanie frazy bez wyników", "type": "Negatywny", "priority": "Średni",
				 "pre": "Fraza nie występuje w danych.",
				 "steps": ["Wpisz frazę, która na pewno nie występuje w danych.", "Uruchom wyszukiwanie."],
				 "data": "Np. „xqzv123niematakiego”.",
				 "expected": "Czytelny komunikat o braku wyników; aplikacja nie zgłasza błędu."},
				{"title": "Wyszukiwanie pustej frazy i znaków specjalnych", "type": "Brzegowy", "priority": "Niski",
				 "pre": "Wyszukiwarka jest dostępna.",
				 "steps": ["Uruchom wyszukiwanie z pustym polem.", "Uruchom wyszukiwanie ze znakami specjalnymi (%, _, *, \").", "Uruchom wyszukiwanie bardzo długiej frazy."],
				 "data": "\"\", \"%\", \"*\", fraza 500+ znaków.",
				 "expected": "Aplikacja obsługuje przypadki bez błędów; zachowanie zgodne z dokumentacją."},
			],
		},
		{
			"keywords": ["filtr", "sortow", "filter", "sort"],
			"label": "Filtrowanie i sortowanie",
			"cases": [
				{"title": "Filtrowanie listy pojedynczym kryterium", "type": "Pozytywny", "priority": "Średni",
				 "pre": "Lista zawiera dane o różnych wartościach filtrowanego atrybutu.",
				 "steps": ["Otwórz listę.", "Ustaw jeden filtr.", "Zastosuj filtr."],
				 "data": "Wartość filtra występująca w danych.",
				 "expected": "Widoczne są wyłącznie rekordy spełniające kryterium."},
				{"title": "Kombinacja wielu filtrów i ich reset", "type": "Pozytywny", "priority": "Średni",
				 "pre": "Lista zawiera zróżnicowane dane.",
				 "steps": ["Ustaw kilka filtrów jednocześnie.", "Zweryfikuj wyniki.", "Wyczyść filtry."],
				 "data": "Kombinacja co najmniej 2 filtrów.",
				 "expected": "Wyniki spełniają wszystkie kryteria łącznie; po resecie lista wraca do stanu pełnego."},
				{"title": "Sortowanie rosnąco i malejąco", "type": "Pozytywny", "priority": "Niski",
				 "pre": "Lista zawiera co najmniej kilka rekordów.",
				 "steps": ["Posortuj listę po wybranej kolumnie rosnąco.", "Posortuj malejąco.", "Zweryfikuj kolejność rekordów."],
				 "data": "Kolumna liczbowa lub tekstowa.",
				 "expected": "Kolejność rekordów odpowiada wybranemu kierunkowi sortowania (w tym poprawna kolejność polskich znaków)."},
			],
		},
		{
			"keywords": ["lista", "tabel", "paginac", "stronicow", "list ", "table", "pagination"],
			"label": "Listy i paginacja",
			"cases": [
				{"title": "Wyświetlenie listy z danymi", "type": "Pozytywny", "priority": "Wysoki",
				 "pre": "W systemie istnieją rekordy do wyświetlenia.",
				 "steps": ["Otwórz widok listy.", "Zweryfikuj wyświetlone kolumny i wartości względem danych źródłowych."],
				 "data": "Istniejące rekordy testowe.",
				 "expected": "Lista prezentuje kompletne i poprawne dane."},
				{"title": "Zachowanie pustej listy", "type": "Brzegowy", "priority": "Średni",
				 "pre": "Brak rekordów spełniających kryteria widoku.",
				 "steps": ["Otwórz widok listy bez danych (lub przefiltruj tak, aby nie było wyników)."],
				 "data": "Brak rekordów.",
				 "expected": "Czytelny komunikat o braku danych; brak błędów interfejsu.",
				 "why": "Stan pusty to klasyka zapomnianych przypadków — ekrany projektuje się z przykładowymi danymi, a użytkownik często zaczyna od zera. Zero elementów to wartość brzegowa listy."},
				{"title": "Nawigacja między stronami wyników", "type": "Pozytywny", "priority": "Średni",
				 "pre": "Liczba rekordów przekracza rozmiar jednej strony.",
				 "steps": ["Przejdź na kolejną stronę wyników.", "Przejdź na ostatnią stronę.", "Wróć na pierwszą stronę."],
				 "data": "Liczba rekordów > rozmiar strony.",
				 "expected": "Nawigacja działa; rekordy nie powtarzają się między stronami; ostatnia strona pokazuje właściwą resztę rekordów."},
			],
		},
		{
			"keywords": ["upload", "wgraj", "import", "załącznik", "zalacznik", "przesył", "wczytaj plik", "attachment"],
			"label": "Import / wgrywanie plików",
			"cases": [
				{"title": "Wgranie poprawnego pliku", "type": "Pozytywny", "priority": "Wysoki",
				 "pre": "Dostępny jest plik w obsługiwanym formacie i rozmiarze.",
				 "steps": ["Otwórz funkcję wgrywania/importu.", "Wybierz poprawny plik.", "Zatwierdź operację."],
				 "data": "Plik w formacie zgodnym z dokumentacją.",
				 "expected": "Plik zostaje przyjęty i przetworzony; użytkownik widzi potwierdzenie."},
				{"title": "Wgranie pliku w nieobsługiwanym formacie", "type": "Negatywny", "priority": "Wysoki",
				 "pre": "Dostępny jest plik w formacie spoza listy obsługiwanych.",
				 "steps": ["Spróbuj wgrać plik w nieobsługiwanym formacie."],
				 "data": "Np. plik .exe lub .xyz.",
				 "expected": "Operacja odrzucona z czytelnym komunikatem; plik nie jest przetwarzany."},
				{"title": "Wgranie pliku przekraczającego limit rozmiaru", "type": "Brzegowy", "priority": "Średni",
				 "pre": "Znany jest limit rozmiaru pliku.",
				 "steps": ["Wgraj plik tuż poniżej limitu.", "Spróbuj wgrać plik powyżej limitu."],
				 "data": "Pliki o rozmiarze limit-1 i limit+1.",
				 "expected": "Plik pod limitem jest przyjmowany; plik nad limitem odrzucany z komunikatem."},
			],
		},
		{
			"keywords": ["eksport", "export", "pobier", "download", "wydruk", "pdf", "csv", "xlsx"],
			"label": "Eksport / pobieranie",
			"cases": [
				{"title": "Eksport danych do pliku", "type": "Pozytywny", "priority": "Średni",
				 "pre": "W systemie istnieją dane do wyeksportowania.",
				 "steps": ["Uruchom eksport w wybranym formacie.", "Otwórz pobrany plik.", "Porównaj zawartość z danymi w aplikacji."],
				 "data": "Istniejący zbiór danych.",
				 "expected": "Plik otwiera się poprawnie; zawartość (w tym polskie znaki) zgadza się z danymi w aplikacji."},
				{"title": "Eksport pustego zbioru danych", "type": "Brzegowy", "priority": "Niski",
				 "pre": "Brak danych spełniających kryteria eksportu.",
				 "steps": ["Uruchom eksport dla pustego zbioru."],
				 "data": "Brak rekordów.",
				 "expected": "Aplikacja obsługuje sytuację bez błędu (pusty plik lub czytelny komunikat)."},
			],
		},
		{
			"keywords": ["płatnoś", "platnos", "koszyk", "zamówien", "zamowien", "checkout", "payment", "cart", "order"],
			"label": "Zamówienia / płatności",
			"cases": [
				{"title": "Złożenie zamówienia — ścieżka podstawowa", "type": "Pozytywny", "priority": "Wysoki",
				 "pre": "Użytkownik ma produkty możliwe do zamówienia; metoda płatności testowej jest dostępna.",
				 "steps": ["Dodaj produkt do koszyka.", "Przejdź do podsumowania/kasy.", "Uzupełnij wymagane dane.", "Opłać zamówienie testową metodą płatności."],
				 "data": "Produkt testowy, testowa karta/metoda płatności.",
				 "expected": "Zamówienie zostaje złożone i opłacone; użytkownik otrzymuje potwierdzenie z poprawnym numerem i kwotą."},
				{"title": "Odrzucona płatność", "type": "Negatywny", "priority": "Wysoki",
				 "pre": "Dostępna jest testowa metoda płatności symulująca odmowę.",
				 "steps": ["Przejdź proces zamówienia do kroku płatności.", "Użyj metody płatności, która zostanie odrzucona."],
				 "data": "Testowa karta odrzucana przez operatora.",
				 "expected": "Czytelny komunikat o niepowodzeniu; zamówienie nie jest oznaczone jako opłacone; możliwe ponowienie płatności."},
				{"title": "Poprawność kwot i podatków w podsumowaniu", "type": "Pozytywny", "priority": "Wysoki",
				 "pre": "W koszyku znajduje się kilka pozycji o różnych cenach.",
				 "steps": ["Dodaj do koszyka kilka pozycji.", "Zweryfikuj sumę częściową, podatki/rabaty i sumę końcową."],
				 "data": "Pozycje o znanych cenach.",
				 "expected": "Wszystkie kwoty są policzone poprawnie i zgodne z cennikiem.",
				 "why": "Błędy w pieniądzach są najkosztowniejsze i najbardziej podważają zaufanie. Kwoty liczymy na z góry znanych danych, żeby móc samodzielnie zweryfikować każdy grosz."},
			],
		},
		{
			"keywords": ["mail", "e-mail", "powiadomien", "notyfikac", "notification"],
			"label": "Powiadomienia / e-mail",
			"cases": [
				{"title": "Wysłanie powiadomienia po zdarzeniu", "type": "Pozytywny", "priority": "Średni",
				 "pre": "Skonfigurowany jest odbiorca powiadomień (np. testowa skrzynka).",
				 "steps": ["Wywołaj zdarzenie generujące powiadomienie (zgodnie z dokumentacją).", "Sprawdź skrzynkę/centrum powiadomień odbiorcy."],
				 "data": "Zdarzenie opisane w dokumentacji modułu.",
				 "expected": "Powiadomienie dociera do odbiorcy; treść, odnośniki i polskie znaki są poprawne."},
			],
		},
		{
			"keywords": ["api", "endpoint", "rest", "request", "żądanie", "zadanie http", "integrac"],
			"label": "API / integracje",
			"cases": [
				{"title": "Poprawne żądanie do API", "type": "Pozytywny", "priority": "Wysoki",
				 "pre": "Dostępny jest klucz/token API środowiska testowego.",
				 "steps": ["Wyślij poprawne żądanie do endpointu zgodnie z dokumentacją.", "Zweryfikuj kod odpowiedzi i strukturę danych."],
				 "data": "Poprawne parametry wg dokumentacji.",
				 "expected": "Odpowiedź 2xx; struktura i wartości pól zgodne z dokumentacją."},
				{"title": "Żądanie z błędnymi parametrami", "type": "Negatywny", "priority": "Średni",
				 "pre": "Dostępny jest token API środowiska testowego.",
				 "steps": ["Wyślij żądanie z brakującymi lub błędnymi parametrami.", "Zweryfikuj kod i treść odpowiedzi."],
				 "data": "Brakujące pola wymagane, złe typy danych.",
				 "expected": "Odpowiedź 4xx z czytelnym opisem błędu; brak zmian w danych."},
				{"title": "Żądanie bez autoryzacji", "type": "Bezpieczeństwo", "priority": "Wysoki",
				 "pre": "Endpoint wymaga uwierzytelnienia.",
				 "steps": ["Wyślij żądanie bez tokenu oraz z niepoprawnym tokenem."],
				 "data": "Brak nagłówka autoryzacji / token nieważny.",
				 "expected": "Odpowiedź 401/403; dane nie są zwracane.",
				 "why": "API trzeba testować bezpośrednio — interfejs może ukrywać przycisk, ale żądanie i tak da się wysłać ręcznie. Zabezpieczenie musi działać po stronie serwera."},
			],
		},
		{
			"keywords": ["uprawnie", "rola", "role", "administrator", "admin", "dostęp", "dostep", "permission"],
			"label": "Uprawnienia i role",
			"cases": [
				{"title": "Dostęp do funkcji zgodny z rolą", "type": "Pozytywny", "priority": "Wysoki",
				 "pre": "Istnieją konta o różnych rolach.",
				 "steps": ["Zaloguj się na konto z uprawnieniem do funkcji.", "Otwórz funkcję modułu."],
				 "data": "Konto z wymaganą rolą.",
				 "expected": "Funkcja jest dostępna i działa zgodnie z dokumentacją."},
				{"title": "Próba dostępu bez wymaganych uprawnień", "type": "Bezpieczeństwo", "priority": "Wysoki",
				 "pre": "Istnieje konto bez uprawnień do funkcji.",
				 "steps": ["Zaloguj się na konto bez uprawnień.", "Spróbuj otworzyć funkcję (także bezpośrednim adresem URL, jeśli dotyczy)."],
				 "data": "Konto o niższej roli; bezpośredni link do funkcji.",
				 "expected": "Dostęp zablokowany (komunikat lub przekierowanie); dane nie są ujawniane.",
				 "why": "Ukrycie przycisku czy linku to nie zabezpieczenie — kontrola dostępu musi być egzekwowana na serwerze przy każdym żądaniu, dlatego próbujemy wejść „bocznymi drzwiami”."},
			],
		},
		{
			"keywords": ["raport", "report", "statystyk", "wykres", "dashboard"],
			"label": "Raporty",
			"cases": [
				{"title": "Wygenerowanie raportu i weryfikacja danych", "type": "Pozytywny", "priority": "Średni",
				 "pre": "W systemie istnieją dane wejściowe do raportu.",
				 "steps": ["Wygeneruj raport dla znanego zakresu danych.", "Porównaj wartości raportu z danymi źródłowymi."],
				 "data": "Zakres danych o znanych wartościach.",
				 "expected": "Raport generuje się bez błędów; wartości i podsumowania są zgodne z danymi źródłowymi."},
			],
		},
		{
			"keywords": ["ustawien", "konfigurac", "settings", "preferenc"],
			"label": "Ustawienia",
			"cases": [
				{"title": "Zmiana i zapis ustawień", "type": "Pozytywny", "priority": "Średni",
				 "pre": "Użytkownik ma dostęp do ustawień.",
				 "steps": ["Zmień wybrane ustawienie.", "Zapisz zmiany.", "Zamknij i ponownie otwórz aplikację/widok.", "Zweryfikuj wartość ustawienia."],
				 "data": "Wartość inna niż domyślna.",
				 "expected": "Ustawienie zostaje trwale zapisane i zastosowane w działaniu aplikacji."},
			],
		},
		{
			"keywords": ["data", "kalendarz", "termin", "date", "calendar"],
			"label": "Daty i kalendarz",
			"cases": [
				{"title": "Wprowadzanie dat granicznych i niepoprawnych", "type": "Brzegowy", "priority": "Średni",
				 "pre": "Pole daty jest dostępne w module.",
				 "steps": ["Wprowadź poprawną datę i zapisz.", "Wprowadź datę w złym formacie.", "Wprowadź datę nieistniejącą (np. 31 lutego) lub spoza dozwolonego zakresu."],
				 "data": "Data poprawna, „31.02.2025”, data sprzed dozwolonego zakresu.",
				 "expected": "Poprawna data jest przyjmowana; błędne wartości są odrzucane z komunikatem."},
			],
		},
	]


static func generate(modules: Array, options: Options) -> Output:
	var out := Output.new()
	var counters := {}
	for module in modules:
		var lower: String = (module.name + "\n" + module.content).to_lower()
		var matched_rules: Array[Dictionary] = []
		for rule in _rules():
			for kw in rule["keywords"]:
				if lower.contains(kw):
					matched_rules.append(rule)
					break
		var module_cases: Array[TestCase] = []
		for rule in matched_rules:
			for tmpl in rule["cases"]:
				if not _type_enabled(tmpl["type"], options):
					continue
				module_cases.append(_case_from_template(module.name, tmpl))
		# Przypadki ogólne dla zdań-wymagań nieobjętych regułami.
		var generic_added := 0
		for sentence in module.sentences:
			if generic_added >= options.max_generic_per_module:
				break
			if _sentence_covered(sentence, matched_rules):
				continue
			if not options.include_positive:
				continue
			module_cases.append(_generic_case(module.name, sentence))
			generic_added += 1
		# Gdy moduł nie dopasował żadnej reguły i nie ma wymagań — dodaj dymne.
		if module_cases.is_empty():
			module_cases.append(_smoke_case(module.name))
		# Nadaj identyfikatory.
		var mod_code := _module_code(module.name)
		for c in module_cases:
			var key := mod_code
			counters[key] = int(counters.get(key, 0)) + 1
			c.id = "%s-%s-%03d" % [options.id_prefix, mod_code, counters[key]]
			out.cases.append(c)
	out.plan_markdown = _build_plan(modules, out.cases, options)
	return out


static func _type_enabled(type: String, options: Options) -> bool:
	match type:
		"Pozytywny": return options.include_positive
		"Negatywny": return options.include_negative
		"Brzegowy": return options.include_boundary
		"Bezpieczeństwo": return options.include_security
	return true


static func _case_from_template(module_name: String, tmpl: Dictionary) -> TestCase:
	var c := TestCase.new()
	c.module = module_name
	c.title = tmpl["title"]
	c.type = tmpl["type"]
	c.priority = tmpl["priority"]
	c.preconditions = tmpl["pre"]
	for s in tmpl["steps"]:
		c.steps.append(s)
	c.test_data = tmpl["data"]
	c.expected = tmpl["expected"]
	c.why = tmpl.get("why", WHY_BY_TYPE.get(c.type, ""))
	return c


static func _generic_case(module_name: String, sentence: String) -> TestCase:
	var c := TestCase.new()
	c.module = module_name
	var short := sentence.strip_edges().trim_suffix(".")
	if short.length() > 90:
		short = short.substr(0, 87) + "..."
	c.title = "Weryfikacja wymagania: " + short
	c.type = "Pozytywny"
	c.priority = "Średni"
	c.preconditions = "Aplikacja uruchomiona; użytkownik ma dostęp do modułu „%s”." % module_name
	c.steps = [
		"Przygotuj warunki opisane w wymaganiu.",
		"Wykonaj działanie opisane w wymaganiu: „%s”." % sentence.strip_edges(),
		"Zweryfikuj rezultat względem dokumentacji.",
	]
	c.test_data = "Dane zgodne z opisem wymagania w dokumentacji."
	c.expected = "Zachowanie aplikacji jest zgodne z wymaganiem: „%s”." % sentence.strip_edges()
	c.why = "Przypadek utworzony wprost z zapisu w dokumentacji — weryfikujemy zgodność zachowania z wymaganiem. Dokumentacja to nasza „wyrocznia testowa”: źródło wiedzy o tym, co jest poprawne."
	return c


static func _smoke_case(module_name: String) -> TestCase:
	var c := TestCase.new()
	c.module = module_name
	c.title = "Test dymny modułu „%s”" % module_name
	c.type = "Pozytywny"
	c.priority = "Wysoki"
	c.preconditions = "Aplikacja uruchomiona."
	c.steps = [
		"Otwórz moduł „%s”." % module_name,
		"Zweryfikuj, że widok ładuje się bez błędów.",
		"Wykonaj podstawową operację dostępną w module.",
	]
	c.test_data = "—"
	c.expected = "Moduł uruchamia się i podstawowa operacja kończy się powodzeniem, bez błędów interfejsu."
	c.why = "Test dymny — krótka kontrola „czy to w ogóle działa”, wykonywana przed właściwymi testami. Jeśli test dymny pada, dalsze testowanie modułu nie ma sensu."
	return c


static func _sentence_covered(sentence: String, rules: Array[Dictionary]) -> bool:
	var lower := sentence.to_lower()
	for rule in rules:
		for kw in rule["keywords"]:
			if lower.contains(kw):
				return true
	return false


static func _module_code(name: String) -> String:
	var clean := ""
	for ch in name.to_upper():
		if (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9"):
			clean += ch
		elif ch in "ĄĆĘŁŃÓŚŹŻ":
			clean += {"Ą": "A", "Ć": "C", "Ę": "E", "Ł": "L", "Ń": "N", "Ó": "O", "Ś": "S", "Ź": "Z", "Ż": "Z"}[ch]
	if clean.length() < 2:
		clean = "MOD"
	return clean.substr(0, 5)


# ------------------------------------------------------------------
# Plan testów (Markdown), struktura wg IEEE 829 / ISO 29119.
# ------------------------------------------------------------------
static func _build_plan(modules: Array, cases: Array[TestCase], options: Options) -> String:
	var date := Time.get_date_string_from_system()
	var lines: Array[String] = []
	var by_priority := {"Wysoki": 0, "Średni": 0, "Niski": 0}
	var by_type := {}
	for c in cases:
		by_priority[c.priority] = int(by_priority.get(c.priority, 0)) + 1
		by_type[c.type] = int(by_type.get(c.type, 0)) + 1

	lines.append("# Plan testów — %s" % options.project_name)
	lines.append("")
	lines.append("| | |")
	lines.append("|---|---|")
	lines.append("| Data utworzenia | %s |" % date)
	if options.author != "":
		lines.append("| Autor | %s |" % options.author)
	lines.append("| Liczba modułów objętych testami | %d |" % modules.size())
	lines.append("| Liczba przypadków testowych | %d |" % cases.size())
	lines.append("")

	lines.append("## 1. Wprowadzenie i cel")
	lines.append("")
	lines.append("Celem niniejszego planu jest określenie zakresu, podejścia i organizacji testów aplikacji **%s** dla wybranych modułów. Plan oraz przypadki testowe zostały wygenerowane automatycznie na podstawie analizy dokumentacji i podlegają przeglądowi przez zespół testowy." % options.project_name)
	lines.append("")

	lines.append("## 2. Podstawa opracowania")
	lines.append("")
	if options.doc_source != "":
		lines.append("- Dokumentacja: `%s`" % options.doc_source)
	if options.app_source != "":
		lines.append("- Aplikacja testowana: `%s`" % options.app_source)
	if options.doc_source == "" and options.app_source == "":
		lines.append("- Źródła nie zostały wskazane.")
	lines.append("")

	lines.append("## 3. Zakres testów")
	lines.append("")
	lines.append("Testami objęte są następujące moduły (wybrane przez użytkownika):")
	lines.append("")
	lines.append("| Moduł | Źródło wykrycia | Wykryte wymagania |")
	lines.append("|---|---|---|")
	for m in modules:
		lines.append("| %s | %s | %d |" % [m.name, m.source, m.requirement_count()])
	lines.append("")
	lines.append("Pozostałe moduły aplikacji są **poza zakresem** tej iteracji testów.")
	lines.append("")

	lines.append("## 4. Strategia i typy testów")
	lines.append("")
	var types: Array[String] = []
	if options.include_positive:
		types.append("**testy pozytywne** (ścieżki podstawowe)")
	if options.include_negative:
		types.append("**testy negatywne** (obsługa błędów)")
	if options.include_boundary:
		types.append("**testy brzegowe** (wartości graniczne)")
	if options.include_security:
		types.append("**testy bezpieczeństwa** (podstawowy zakres)")
	lines.append("Zastosowane będą testy funkcjonalne wykonywane ręcznie na podstawie przypadków testowych, w tym: %s." % ", ".join(types))
	lines.append("")
	lines.append("Rozkład wygenerowanych przypadków:")
	lines.append("")
	lines.append("| Typ | Liczba |")
	lines.append("|---|---|")
	for t in by_type:
		lines.append("| %s | %d |" % [t, by_type[t]])
	lines.append("")
	lines.append("| Priorytet | Liczba |")
	lines.append("|---|---|")
	for p in ["Wysoki", "Średni", "Niski"]:
		lines.append("| %s | %d |" % [p, by_priority[p]])
	lines.append("")

	lines.append("## 5. Środowisko testowe")
	lines.append("")
	lines.append("- Środowisko testowe odseparowane od produkcji, z danymi testowymi możliwymi do odtworzenia.")
	if options.app_source != "":
		lines.append("- Testowana aplikacja: `%s`." % options.app_source)
	lines.append("- Konta testowe o rolach wymaganych przez przypadki testowe.")
	lines.append("- Dostęp do dokumentacji stanowiącej podstawę oczekiwanych rezultatów.")
	lines.append("")

	lines.append("## 6. Kryteria wejścia i wyjścia")
	lines.append("")
	lines.append("**Kryteria rozpoczęcia testów:**")
	lines.append("- środowisko testowe dostępne i skonfigurowane,")
	lines.append("- build aplikacji zainstalowany w wersji przeznaczonej do testów,")
	lines.append("- przypadki testowe przejrzane i zaakceptowane.")
	lines.append("")
	lines.append("**Kryteria zakończenia testów:**")
	lines.append("- wykonane 100% przypadków o priorytecie wysokim i co najmniej 90% pozostałych,")
	lines.append("- brak otwartych defektów krytycznych i wysokich,")
	lines.append("- raport z testów przygotowany i zaakceptowany.")
	lines.append("")

	lines.append("## 7. Ryzyka i ograniczenia")
	lines.append("")
	lines.append("- Przypadki wygenerowane automatycznie wymagają przeglądu — dokumentacja może być niekompletna lub nieaktualna.")
	lines.append("- Moduły wyłączone z zakresu nie będą weryfikowane w tej iteracji (ryzyko regresji).")
	lines.append("- Zmiany aplikacji w trakcie testów mogą unieważnić część przypadków.")
	lines.append("")

	lines.append("## 8. Szacunek pracochłonności")
	lines.append("")
	var minutes := cases.size() * 15
	lines.append("Przy założeniu średnio 15 minut na wykonanie i udokumentowanie jednego przypadku: **ok. %d godz. %d min** (%d przypadków)." % [minutes / 60, minutes % 60, cases.size()])
	lines.append("")

	lines.append("## 9. Zestawienie przypadków testowych")
	lines.append("")
	lines.append("| ID | Moduł | Tytuł | Typ | Priorytet |")
	lines.append("|---|---|---|---|---|")
	for c in cases:
		lines.append("| %s | %s | %s | %s | %s |" % [c.id, c.module, c.title, c.type, c.priority])
	lines.append("")
	return "\n".join(lines)
