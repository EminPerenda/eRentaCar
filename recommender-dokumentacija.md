# Sistem preporuke — eRentaCar

## 1. Uvod

Sistem preporuke u platformi eRentaCar osmišljen je s ciljem poboljšanja korisničkog iskustva kroz personalizovane prijedloge vozila. Preporuke se generišu na osnovu historije korisničkih akcija kombinovanjem dva pristupa: **content-based filteringa** (na osnovu preferenci konkretnog korisnika) i **popularity-based filteringa** (na osnovu globalne popularnosti vozila).

Cjelokupna logika implementirana je u servisu `SearchHistoryService` (`eRentaCar.API/Services/SearchHistoryService.cs`) i izložena je putem endpointa `GET /api/recommendations`.

---

## 2. Arhitektura sistema

```
Korisnik (Flutter Mobile)
        │
        ▼
GET /api/recommendations  (JWT autorizacija)
        │
        ▼
RecommendationsController
        │
        ▼
SearchHistoryService.GetRecommendationsAsync(userId)
        │
   ┌────┴────┐
   ▼          ▼
Content-     Popularity-
Based        Based
Filtering    Filtering
   │          │
   └────┬─────┘
        │  deduplikacija + spajanje
        ▼
  JSON lista RecommendationResponse
```

---

## 3. Praćenje korisničkog ponašanja

### 3.1 Model podataka — `SearchHistory`

| Kolona | Tip | Opis |
|---|---|---|
| `Id` | int | Primarni ključ |
| `UserId` | int | FK na korisnika |
| `VehicleId` | int? | FK na vozilo (opcionalno) |
| `CategoryId` | int? | FK na kategoriju (opcionalno) |
| `ActionType` | enum | Vrsta akcije korisnika |
| `SearchedAt` | DateTime (UTC) | Timestamp akcije |

### 3.2 Tipovi akcija (`SearchActionType`)

| Vrijednost | Naziv | Trigger |
|---|---|---|
| 0 | `VehicleView` | Korisnik otvori stranicu s detaljima vozila |
| 1 | `CategorySearch` | Korisnik filtrira vozila po kategoriji |
| 2 | `Reservation` | Korisnik kreira novu rezervaciju |
| 3 | `Review` | Korisnik ostavi recenziju za vozilo |

### 3.3 Gdje se bilježe akcije

Akcije se loguju pozivom `ISearchHistoryService.LogAsync(userId, actionType, vehicleId?, categoryId?)` direktno iz kontrolera:

| Endpoint | Akcija koja se bilježi |
|---|---|
| `GET /api/vehicles/{id}` | `VehicleView` (sa `vehicleId`) |
| `GET /api/vehicles?categoryId=X` | `CategorySearch` (sa `categoryId`) |
| `POST /api/reservations` | `Reservation` (sa `vehicleId`) |
| `POST /api/reviews` | `Review` (sa `vehicleId`) |

---

## 4. Algoritam preporuke

### 4.1 Priprema podataka

Prije pokretanja oba filtera, sistem priprema dva skupa podataka:

1. **Preferirane kategorije** — iz `SearchHistories` gdje je `CategoryId != null`, grupira se po kategoriji i uzimaju se **top 2** kategorije po frekvenciji pojavljivanja (najpre pregledanija = viši prioritet).
2. **Iznajmljene vozilo IDs** — iz `Reservations` sa statusom `Completed` za datog korisnika. Ova vozila se isključuju iz svih preporuka.

---

### 4.2 Content-Based Filtering

**Cilj:** preporučiti vozila iz kategorija koje korisnik preferira, a koja još nije iznajmio.

**Koraci:**

1. Dohvati dostupna vozila (`IsActive = true`, `Status = Available`) koja pripadaju nekom od preferiranih kategorija i čiji ID nije u skupu iznajmljenih vozila.
2. Za svako vozilo izračunaj score:

```
catScore = 1.0   (ako vozilo pripada najposjećenijoj kategoriji, rang = 0)
         = 0.5   (ako vozilo pripada drugoj po redu kategoriji, rang = 1)

avgRating = prosječna ocjena svih recenzija vozila (0 ako nema recenzija)

contentScore = catScore × 0.6 + (avgRating / 5.0) × 0.4
```

| Komponenta | Udio | Opis |
|---|---|---|
| Rang kategorije (`catScore`) | 60 % | Kategorija koja je češće pregledana nosi duplo veći doprinos |
| Prosječna ocjena | 40 % | Normalizovana na skalu [0, 1] dijeljenjem s 5 |

3. Sortiraj silazno po `contentScore` i uzmi **top 3** vozila.

---

### 4.3 Popularity-Based Filtering

**Cilj:** preporučiti globalno najpopularnija vozila u zadnjih 30 dana, isključujući ono što je korisnik već iznajmio i ono što je već ušlo u content-based listu.

**Koraci:**

1. Iz `Reservations` filtriraj one s `CreatedAt >= DateTime.UtcNow - 30 dana`.
2. Grupiraj po `VehicleId`, sortiraj silazno po broju rezervacija — uzmi **top 10** vozila.
3. Dohvati ta vozila koja su dostupna i koja korisnik nije iznajmio.
4. Za svako vozilo izračunaj score:

```
count         = broj rezervacija vozila u periodu
maxCount      = broj rezervacija najpopularnijeg vozila u periodu
popularityScore = count / maxCount   (normalizacija u interval [0, 1])

avgRating     = prosječna ocjena svih recenzija vozila

popularityScore = popularityScore × 0.7 + (avgRating / 5.0) × 0.3
```

| Komponenta | Udio | Opis |
|---|---|---|
| Normalizovana popularnost | 70 % | Relativna pozicija vozila u periodu od 30 dana |
| Prosječna ocjena | 30 % | Normalizovana na skalu [0, 1] |

5. Sortiraj silazno po `popularityScore`.

---

### 4.4 Hibridno spajanje rezultata

```
finalnaLista = content-based_top3
             + popularity-based_lista (MINUS vozila koja su već u content-based)
```

- Content-based preporuke uvijek dolaze prve.
- Popularity-based vozila dopunjuju listu bez duplikata.
- Svaka preporuka nosi `type` polje: `"content-based"` ili `"popularity-based"`.

**Rješenje hladnog starta (cold start):**  
Novi korisnici koji nemaju historiju kategorija neće imati content-based preporuke — prikazuju im se samo popularity-based rezultati.

---

## 5. API endpoint

### Zahtjev

```
GET /api/recommendations
Authorization: Bearer {jwt_token}
```

### Odgovor (`RecommendationResponse[]`)

```json
[
  {
    "id": 12,
    "vehicle": "Toyota RAV4",
    "name": "SUV",
    "pricePerDay": 85.00,
    "averageRating": 4.7,
    "primaryImageUrl": "http://localhost:5091/uploads/rav4.jpg",
    "reason": "Jer ste pregledali SUV kategoriju",
    "type": "content-based"
  },
  {
    "id": 7,
    "vehicle": "Volkswagen Golf",
    "name": "Hatchback",
    "pricePerDay": 45.00,
    "averageRating": 4.4,
    "primaryImageUrl": "http://localhost:5091/uploads/golf.jpg",
    "reason": "Top izbor ove sedmice",
    "type": "popularity-based"
  }
]
```

| Polje | Opis |
|---|---|
| `id` | ID vozila |
| `vehicle` | Naziv vozila (marka + model) |
| `name` | Naziv kategorije vozila |
| `pricePerDay` | Cijena po danu (BAM) |
| `averageRating` | Prosječna ocjena (zaokružena na 1 decimalu) |
| `primaryImageUrl` | URL primarne slike vozila |
| `reason` | Razlog preporuke prikazan korisniku |
| `type` | Izvor preporuke: `"content-based"` ili `"popularity-based"` |

---

## 6. Tabele baze podataka

| Tabela | Uloga |
|---|---|
| `SearchHistories` | Bilježi sve korisničke akcije na platformi |
| `Reservations` | Historija rezervacija; koristi se za isključivanje već iznajmljenih vozila i za popularnost |
| `VehicleReviews` | Ocjene vozila; koriste se za scoring u oba filtera |
| `Vehicles` | Katalog vozila s atributima (`CategoryId`, `Status`, `IsActive`, `PricePerDay`) |
| `VehicleImages` | Slike vozila; koristi se za `primaryImageUrl` u odgovoru |

---

## 7. Prikaz u mobilnoj aplikaciji

Preporuke su prikazane na početnom ekranu mobilne aplikacije (`HomeScreen`) u horizontalno skrolujućoj listi kartica. Svaka kartica prikazuje:

- Sliku vozila (thumbnail)
- Naziv vozila i kategoriju
- Cijenu po danu
- Prosječnu ocjenu (zvjezdice)
- Razlog preporuke (sitni tekst ispod naslova)

Poziv se upućuje na `GET /api/recommendations` pri svakom učitavanju početnog ekrana. Endpoint zahtijeva JWT token — neprijavljeni korisnici ne dobijaju preporuke.

---

## 8. Tehnologije

| Komponenta | Tehnologija |
|---|---|
| Backend | .NET 9, ASP.NET Core, C# |
| Baza podataka | SQL Server 2022 + Entity Framework Core 9 |
| Algoritam | Hibridni (Content-Based + Popularity-Based), implementiran u memoriji |
| Autentifikacija | JWT Bearer tokeni |
| Klijent | Flutter (Dart), Dio HTTP klijent |

---

## 9. Ograničenja i moguća poboljšanja

| Ograničenje | Opis |
|---|---|
| Cold start | Novi korisnici bez historije kategorija ne dobijaju content-based preporuke |
| Bez collaborative filteringa | Sistem ne uzima u obzir sličnost između korisnika |
| Samo kategorija kao dimenzija | Brand, tip goriva, cijena i drugi atributi nisu uključeni u content-based scoring |
| In-memory scoring | Vozila se učitavaju iz baze pa se scoring radi u memoriji; za veće skupove podataka preporučuje se SQL-based pristup s predhvatanjem skupova |
| Fiksni prozor popularnosti | Period od 30 dana je hardkodiran; moglo bi biti konfigurabilan parametar |
