# Wizyty lekarskie

## Przegląd
System wieloagentowy realizujący rezerwacje wizyt lekarskich.

## Zakres projektu

W ramach projektu semestralnego został zrealizowany system wieloagentowy
obsługujący rezerwacje wizyt lekarskich.

System jest oparty na sieciach kontraktowych:
- manager przyjmuje zlecenie na omówienie wizyty z określonym specjalistą;
- manager wysyła żądanie do kontraktorów, którzy przeglądają rejestry wizyt
	i zwracają propozycję wizyty/informację o braku terminów;
-  manager wybiera najlepszą ofertę (według kryteriów zadanych przez zleceniodawcę,
	 np. w zależności od ceny/opinii lekarza, odległości) i wysyła żądanie umówienia wizyty;
- manager odbiera potwierdzenie rezerwacji i wysyła powiadomienie użytkownikowi o powodzeniu/niepowodzeniu operacji.


### Akcje użytkownika

W systemie użytkownik może wykonać następujące akcje:
- zadać zapytanie odnośnie wizyty u specjalisty (możliwe filtrowanie po dacie, regionie, nazwisku lekarza);
- zarezerwować wizytę spośród zwróconych w zapytaniu;
- odwołać wizytę.


## Technologie

System został zaimplementowany w języku Elixir (uruchamianie na maszynie wirtualnej BEAM).

BEAM jest maszyną wirtualną zorientowaną na działanie równoległe i rozproszone.
Rożne instancje maszyny wirtualnej potrafią się ze sobą komunikować i wykonywać funkcje zdalne
praktycznie bez ingerencji programisty już na poziomie maszyny wirtualnej.
BEAM jest wykorzystywany produkcyjnie w systemach telekomunikacyjnych, gdzie potrzebna
jest wysoka przepustowość, utrzymywanie wielu równoległych połączeń. BEAM pozwala także
na wprowadzanie poprawek do kodu na działających instancjach aplikacji tzw. hot swap.

BEAM jest zaprojektowany do systemów o poniższych cechach:
- rozproszony;
- odporny na błędy;
- system czasu rzeczywistego o miękkich ograniczeniach;
- wysoko-dostępny.

Oprócz powyższych cech, wybór Elixir'a uzasadniamy wbudowaną obsługą
agentów, kolejek wiadomości, nadzorców sprawującymi pieczę nad agentami.

Agenci porozumiewają się poprzez przesyłanie wiadomości, zarówno synchronicznych jak i asynchronicznych.

Nadzorcy są odpowiedzialni za wykrywanie anomalii w działaniu agentów oraz
restartowanie ich wedle ustawionych polityk.


## Architektura rozwiązania

System został zaimplementowany jako biblioteka działająca w systemie z następującym interfejsem:
 - get_available_slots(opts \\ []) - pobiera wolne terminy wizyt u lekarzy, można filtrować po:
   - region
   - lekarz
   - data
 - get_visits_for_user(id) - pobiera wizyty dla użytkownika z podanym `id`
 - delete_visit(visit_id) - usuwa/odwołuje wizytę z podanym `id`
 - add_visit(user_id, doctor_id, slot) - tworzy wizytę użytkownika (`user_id`) u wybranego lekarza (`doctor_id`) w podanym slocie czasowym (`slot`)

Powyższe zapytania trafiają do głównego routera aplikacji, który odpowiednio propaguje zapytania.
System został podzielony na `regiony`, którymi nadzoruje `supervisor`. Regiony podzielone są na
`kliniki`, kliniki składają się z `lekarzy` oraz ich `grafików wizyt`. Na każdym poziomie znajduje się supervisor który nadzoruje gałąź oraz lokalny router.

W zależności od zapytania, trafia ono albo do konkretnego bytu, albo do wszytskich i reaguje tylko zainteresowany agent. W przypadku kiedy system czeka na odpowiedź od jednego lub wielu agentów zbyt długo, zwracane są dane, które udało się do tej pory zgromadzić.

### Odporność na awarie
W systemie zostały zdefiniowane reguły mówiące o zależnościach pomiędzy poszczególnymi typami agentów:
 - region - kliniki: kliniki mogą działać w przypadku awarii regionu, w przypadku awarii kliniki nie będzie informacji z danej placówki
 - klinika - lekarze: lekarze mogą działać w przypadku awarii kliniki, w przypadku awarii lekarza nie będzie informacji o danej jednostce
 - lekarz - grafik wizyt: są to byty zależne, awaria jednego powoduje wyłączenie drugiego agenta


## Testowanie
