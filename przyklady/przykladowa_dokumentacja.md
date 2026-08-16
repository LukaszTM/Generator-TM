# Logowanie i konta

Moduł odpowiada za uwierzytelnianie użytkowników.

- Użytkownik musi mieć możliwość logowania adresem e-mail i hasłem.
- System powinien blokować konto po 5 nieudanych próbach logowania na 15 minut.
- Użytkownik może zresetować hasło przez link wysyłany na e-mail; link wygasa po 24 godzinach.
- Hasło musi mieć co najmniej 10 znaków, w tym cyfrę i znak specjalny.
- Rejestracja nowego konta wymaga potwierdzenia adresu e-mail.

# Wyszukiwarka produktów

- Użytkownik może wyszukiwać produkty po nazwie i kodzie.
- Wyniki wyszukiwania muszą być stronicowane po 20 pozycji.
- System powinien podpowiadać frazy po wpisaniu co najmniej 3 znaków.
- Lista wyników umożliwia filtrowanie po kategorii i cenie oraz sortowanie po cenie.

# Koszyk i zamówienia

- Użytkownik może dodać produkt do koszyka i zmienić jego ilość.
- System musi przeliczać wartość koszyka wraz z podatkiem VAT.
- Złożenie zamówienia wymaga podania adresu dostawy.
- Płatność realizowana jest kartą lub BLIK; po odrzuceniu płatności zamówienie pozostaje nieopłacone.
- Po opłaceniu zamówienia system wysyła e-mail z potwierdzeniem.

# Panel administratora

- Dostęp do panelu mają wyłącznie użytkownicy z rolą Administrator.
- Administrator może eksportować listę zamówień do pliku CSV.
- Administrator może generować raport sprzedaży za wybrany zakres dat.
- Panel umożliwia zmianę ustawień sklepu, w tym stawek dostawy.
