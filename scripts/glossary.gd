class_name Glossary
extends RefCounted
## Słowniczek podstawowych pojęć testerskich (tryb nauki dla początkujących).

const TERMS := [
	["Przypadek testowy", "Pojedynczy, powtarzalny scenariusz sprawdzenia jednej rzeczy: warunki wstępne + kroki + oczekiwany rezultat. Dobry przypadek może wykonać ktoś, kto widzi aplikację pierwszy raz."],
	["Plan testów", "Dokument opisujący CO, JAK i KIEDY testujemy: zakres, strategię, środowisko, kryteria rozpoczęcia i zakończenia oraz ryzyka. Plan czyta kierownik projektu — przypadki czyta tester."],
	["Test dymny (smoke test)", "Krótka kontrola „czy to w ogóle działa” wykonywana zaraz po otrzymaniu nowej wersji. Jeśli pada, nie ma sensu zaczynać właściwych testów — wersja wraca do programistów."],
	["Test regresji", "Powtórzenie wcześniejszych testów po zmianie w aplikacji, aby upewnić się, że naprawa jednej rzeczy nie zepsuła innej. To najczęstsze zajęcie testera w dojrzałym projekcie."],
	["Test pozytywny (ścieżka szczęśliwa)", "Sprawdzenie, że funkcja działa przy poprawnych danych i typowym użyciu. Zawsze wykonywany przed testami negatywnymi."],
	["Test negatywny", "Celowe podanie błędnych danych lub złamanie warunków. Aplikacja ma zawieść bezpiecznie: czytelny komunikat, brak utraty danych, brak awarii."],
	["Test brzegowy", "Sprawdzenie wartości na granicach zakresu: minimum, maksimum, zero, pusty, o jeden za dużo. Na granicach kryje się najwięcej błędów."],
	["Klasy równoważności", "Technika projektowania testów: dane dzielimy na grupy, które aplikacja powinna traktować tak samo (np. wiek 18–65), i testujemy po jednym reprezentancie z każdej grupy zamiast wszystkich wartości."],
	["Analiza wartości brzegowych", "Technika uzupełniająca klasy równoważności: testujemy dokładnie granice przedziałów (17, 18, 65, 66) — bo to tam programiści mylą „<” z „<=”."],
	["Warunek wstępny", "Stan, który musi istnieć PRZED rozpoczęciem testu (np. „istnieje konto użytkownika”). Bez spełnienia warunku wynik testu jest nieważny."],
	["Dane testowe", "Konkretne wartości używane w teście (loginy, kwoty, pliki). Dobre dane testowe są z góry znane, dzięki czemu można samodzielnie zweryfikować wynik."],
	["Oczekiwany rezultat", "Precyzyjny opis tego, co POWINNO się stać. Bez niego nie ma testu — jest tylko klikanie. Źródłem oczekiwań jest dokumentacja (tzw. wyrocznia testowa)."],
	["Priorytet a waga (severity)", "Priorytet mówi, jak szybko coś trzeba zrobić; waga — jak poważny jest skutek błędu. Literówka na stronie głównej ma niską wagę, ale może mieć wysoki priorytet."],
	["Defekt (zgłoszenie błędu)", "Udokumentowana rozbieżność między zachowaniem aplikacji a oczekiwanym. Dobre zgłoszenie zawiera kroki reprodukcji, rezultat aktualny i oczekiwany oraz zrzut ekranu."],
	["Kroki reprodukcji", "Minimalna sekwencja czynności prowadząca do błędu. Złota zasada: jeśli programista nie może powtórzyć błędu, to go nie naprawi."],
	["Środowisko testowe", "Miejsce wykonywania testów (system, przeglądarka, wersja aplikacji, dane), odseparowane od produkcji. Ten sam błąd może występować w jednym środowisku, a w innym nie."],
	["Kryteria wejścia / wyjścia", "Warunki rozpoczęcia testów (np. „build zainstalowany, środowisko gotowe”) i ich zakończenia (np. „100% przypadków o wysokim priorytecie wykonane, brak błędów krytycznych”)."],
	["Test eksploracyjny", "Testowanie bez szczegółowego scenariusza: równoczesne poznawanie aplikacji, projektowanie i wykonywanie testów. Świetne uzupełnienie przypadków — nie ich zamiennik."],
	["Pokrycie testowe", "Miara tego, jaka część wymagań/funkcji ma swoje testy. 100% pokrycia wymagań nie oznacza braku błędów — oznacza tylko, że każde wymaganie zostało sprawdzone przynajmniej raz."],
	["Wykonanie testów (test run)", "Przejście przez przygotowane przypadki z odnotowaniem wyniku każdego z nich: zaliczony, niezaliczony lub zablokowany (nie dało się wykonać, np. przez inny błąd)."],
]


static func as_text() -> String:
	var lines: Array[String] = []
	lines.append("SŁOWNICZEK TESTERA")
	lines.append("=".repeat(60))
	lines.append("")
	for term in TERMS:
		lines.append("● %s" % term[0])
		lines.append("   %s" % term[1])
		lines.append("")
	return "\n".join(lines)
