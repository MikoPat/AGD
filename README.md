# AGD

Wydobywanie informacji na podstawie hurtowni danych

Folder *Dane* zawiera dane podstawowe: Frania2004.txt, Frania200507.txt. 

### Elementy z hurtowni:
Tabele wymiarów: 
- Dim_Klienci (Id, Klient)
- Dim_Regiony (Id, Region)
- Dim_Czas (Id, Miesiac, Kwartal, Rok)
- Dim_Towary (Id, Towar, Podgrupa, Grupa, Towar_Hierarchia, Podgrupa_Hierarchia, Grupa_Hierarchia)

Tabele faktów:
- Sprzedaz_hist (IdKlient, IdRegion, IdTowary, IdCzas, Cena, Ilosc, Obrot)
- Sprzedarz_plan (IdKlient, IdRegion, IdTowary, IdCzas, Cena, Ilosc, Obrot)

