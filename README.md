# Wizyty lekarskie

## Przegląd 
System wleloagentowy realizujący rezerwacje wizyt lekarskich.

## Zakres projektu

W ramach projektu semestranlego powstanie system wieloagentowy 
obsługujący rezerwacje wizyt lekarskich. 

System będzie oparty na sieciach kontraktkowych:
- manager przyjmuje zlecenie na omówienie wizyty z określonym specjalistą;
- manager wysyła żądanie do kontraktorów, którzy przeglądają rejestry wizyt 
	i zwracają propozycję wizyty/informację o braku terminów;
-  manager wybiera najlepszą ofertę (według kryteriów zadanych przez zleceniodawcę,
	 np. w zależności od ceny/opinii lekarza, odległości) i wysyła żądanie umówienia wizyty;
- manager odbiera potwierdzenie rezerwacji i wysyła powiadomienie użytkownikowi o powodzeniu/niepowodzeniu operacji.


### Akcje użytkownika

W systemie użytkownik będzie mógł wykonać następujące akcje:
- zadać zapytanie odnośnie wizyty u specjalisty (możliwe filtrowanie po dacie, regionie, nazwisku lekarza);
- zarezerwować wizytę spośród zwróconych w zapytaniu;
- odwołać wizytę.


## Technologie

System zostanie napisany w języku Elixir i będzie uruchamiany na maszynie wirtualnej BEAM.

BEAM jest maszyną wirtualną zorientowaną na działanie równoległe i rozproszone.
Rożne instancje maszyny wirtualnej potrafią się ze sobą komunikować i wykonywać funkcje zdalne
praktycznie bez ingerencji programisty już na poziomie maszyny wirtualnej.
BEAM jest wykorzystywany produkcyjnie w systemach telekomunikacyjnych, gdzie potrzebna
jest wysoka przepustowość, utrzymywanie wielu równoległych połączeń. BEAM pozwala także
na wprowadzanie poprawek do kodu na działających instancjach aplikacji tzw. hot swap.

BEAM jest zaprojektowany do systemów o poniższych cechach:
- rozporoszony;
- odporny na błędy;
- system czasu rzeczywistego o miękkich ograniczeniach;
- wysoko-dostępny.

Oprócz powyższych cech, wybór Elixir'a uzasadniamy wbudowaną obsługą
agentów, kolejek wiadomości, nadzorców sprawującymi pieczę nad agentami.

Agenci porozumiewają się poprzez przesyłanie wiadomości, zarówno sychnornicznych jak i asynchronicznych.

Nazdorcy są dopowiedzialni za wykrywanie anomalii w działanie agentów oraz
restartowanie ich wedle ustawionych polityk.

## Architektura rozwiąznia

System będzie podzielony na kilka grup agentów, każda z nich będzie pełniła określone, odmienne zadanie w systemie.

Celem zwiększenia ilości agentów każde zapytanie będzie reprezentowane w systemie przez osobnego agenta.
Agent-zapytanie rozpropaguje zapytanie do wszystkich, znanych sobie, routerów. Stąd zapytanie zostanie 
przekierowane do routerów. Stąd zapytnie zostanie przekierowane do routerów obsługującego specjalistów określonychw
w zapytaniu. Stąd zapytanie trafi do agentów reprezentujących lekarzy specjalistów. Ta warstwa agentów przetworzy
zapytanie oraz odpowie bezpośrednio agentowi zadającemu zapytanie. 


## Testowanie

Testowanie systemu będzie się odbywało poprzez wstrzykiwanie agentów o określonych parametrach
oraz obserwowanie zachownia systemu pod różnym obciążeniem.
Agentów będziemy parametryzować w taki sposób, aby symulować wysokie obciążenie systemu oraz błędy oprogramowania.
 
Zamierzamy również wyłączać ręcznie pewne fragmenty systemu.

Zastosujemy poniższe wskaźniki:
- średni czas odpowiedzi;
- wariancja czasu odpowiedzi;
- minimalny czas odpowiedzi;
- maksymalny czas odpowiedzi;
- error rate.

### Testowi użytkowncy

Użytkownicy w SUT będą generowani programowo.
Użytkownicy będą wysyłali zapytania do systemu zgodnie z rozkładem Gaussa.
Rozkład naturalny będzie też cechował czasy reakcji użytkowników.

Użytkownicy będą także złośliwi - próby rezerwacji nieistniejąccyh slotów, nieistniejących lekarzy,
odwoływnie nieistniejących wizyt, jak i wizyt już odbytych.
