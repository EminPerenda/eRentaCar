# Sistem preporuke — eRentaCar

## 1. Uvod

Sistem preporuke u platformi eRentaCar osmišljen je s ciljem poboljšanja korisničkog iskustva kroz personalizovane prijedloge vozila. Preporuke se generišu za svakog korisnika posebno pomoću hibridnog algoritma koji kombinuje **content-based filtering** i komponentu **popularnosti**.

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
        ▼
      Izgradnja korisničkog profila + feature vektora vozila
        │
        ▼
      Cosine similarity + popularity score
        │
        ▼
      Top-5 lista RecommendationResponse s objašnjenjem
```

---

## 3. Praćenje korisničkog ponašanja

### 3.1 Model podataka — `SearchHistory`

| Kolona       | Tip            | Opis                          |
| ------------ | -------------- | ----------------------------- |
| `Id`         | int            | Primarni ključ                |
| `UserId`     | int            | FK na korisnika               |
| `VehicleId`  | int?           | FK na vozilo (opcionalno)     |
| `CategoryId` | int?           | FK na kategoriju (opcionalno) |
| `ActionType` | enum           | Vrsta akcije korisnika        |
| `SearchedAt` | DateTime (UTC) | Timestamp akcije              |

### 3.2 Tipovi akcija (`SearchActionType`)

| Vrijednost | Naziv            | Trigger                                     |
| ---------- | ---------------- | ------------------------------------------- |
| 0          | `VehicleView`    | Korisnik otvori stranicu s detaljima vozila |
| 1          | `CategorySearch` | Korisnik filtrira vozila po kategoriji      |
| 2          | `Reservation`    | Korisnik kreira novu rezervaciju            |
| 3          | `Review`         | Korisnik ostavi recenziju za vozilo         |

### 3.3 Gdje se bilježe akcije

Akcije se loguju pozivom `ISearchHistoryService.LogAsync(userId, actionType, vehicleId?, categoryId?)` direktno iz kontrolera:

| Endpoint                         | Akcija koja se bilježi             |
| -------------------------------- | ---------------------------------- |
| `GET /api/vehicles/{id}`         | `VehicleView` (sa `vehicleId`)     |
| `GET /api/vehicles?categoryId=X` | `CategorySearch` (sa `categoryId`) |
| `POST /api/reservations`         | `Reservation` (sa `vehicleId`)     |
| `POST /api/reviews`              | `Review` (sa `vehicleId`)          |

---

## 4. Algoritam preporuke

### 4.1 Priprema feature prostora

Za svako vozilo sistem gradi feature vektor koji sadrži:

1. kategoriju vozila kao one-hot kodiranje,
2. tip goriva kao one-hot kodiranje,
3. tip mjenjača kao one-hot kodiranje,
4. normaliziranu cijenu po danu na raspon $[0,1]$.

Feature prostor se gradi nad svim relevantnim vozilima kako bi vektori korisnika i vozila bili u istom prostoru.

---

### 4.2 Korisnički profil

Korisnički profil se gradi kao ponderisani prosjek vektora vozila koja je korisnik:

1. pregledao,
2. iznajmio,
3. pozitivno ocijenio.

Težine zavise od vrste signala i svježine interakcije: noviji pregledi nose veću težinu, a pozitivnije ocjene dodatno pojačavaju značaj vozila u profilu.

---

### 4.3 Sličnost i popularnost

Sličnost korisničkog profila i svakog dostupnog vozila računa se kosinusnom mjerom:

$$
sim(u, v) = \frac{u \cdot v}{\|u\| \times \|v\|}
$$

Popularnost vozila se dobija kao normalizirana kombinacija:

1. prosječne ocjene vozila,
2. broja rezervacija u posljednja tri mjeseca.

---

### 4.4 Konačni score i rangiranje

Konačni score se računa formulom:

$$
score(v) = \alpha \times sim(u, v) + \beta \times popularity(v)
$$

gdje su $\alpha = 0.7$ i $\beta = 0.3$.

Sva dostupna vozila se rangiraju po `score(v)`, a korisniku se vraća **top 5** preporuka. Za svaku preporuku generiše se kratko objašnjenje na osnovu faktora koji je najviše doprinio rezultatu, npr.:

- „jer ste pregledali SUV kategoriju“
- „jer često birate vozila na dizel“
- „Top izbor ove sedmice“ kada dominira popularnost

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
    "pricePerDay": 85.0,
    "averageRating": 4.7,
    "primaryImageUrl": "http://localhost:5091/uploads/rav4.jpg",
    "reason": "jer ste pregledali SUV kategoriju",
    "type": "hybrid"
  },
  {
    "id": 7,
    "vehicle": "Volkswagen Golf",
    "name": "Hatchback",
    "pricePerDay": 45.0,
    "averageRating": 4.4,
    "primaryImageUrl": "http://localhost:5091/uploads/golf.jpg",
    "reason": "Top izbor ove sedmice",
    "type": "hybrid"
  }
]
```

| Polje             | Opis                                        |
| ----------------- | ------------------------------------------- |
| `id`              | ID vozila                                   |
| `vehicle`         | Naziv vozila (marka + model)                |
| `name`            | Naziv kategorije vozila                     |
| `pricePerDay`     | Cijena po danu (BAM)                        |
| `averageRating`   | Prosječna ocjena (zaokružena na 1 decimalu) |
| `primaryImageUrl` | URL primarne slike vozila                   |
| `reason`          | Razlog preporuke prikazan korisniku         |
| `type`            | Oznaka algoritma; trenutno `"hybrid"`       |

---

## 6. Tabele baze podataka

| Tabela            | Uloga                                                                                       |
| ----------------- | ------------------------------------------------------------------------------------------- |
| `SearchHistories` | Bilježi sve korisničke akcije na platformi                                                  |
| `Reservations`    | Historija rezervacija; koristi se za isključivanje već iznajmljenih vozila i za popularnost |
| `VehicleReviews`  | Ocjene vozila; koriste se za scoring u oba filtera                                          |
| `Vehicles`        | Katalog vozila s atributima (`CategoryId`, `Status`, `IsActive`, `PricePerDay`)             |
| `VehicleImages`   | Slike vozila; koristi se za `primaryImageUrl` u odgovoru                                    |

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

| Komponenta      | Tehnologija                                                           |
| --------------- | --------------------------------------------------------------------- |
| Backend         | .NET 9, ASP.NET Core, C#                                              |
| Baza podataka   | SQL Server 2022 + Entity Framework Core 9                             |
| Algoritam       | Hibridni content-based + popularity scoring, implementiran u memoriji |
| Autentifikacija | JWT Bearer tokeni                                                     |
| Klijent         | Flutter (Dart), Dio HTTP klijent                                      |

---

## 9. Ograničenja i moguća poboljšanja

| Ograničenje                  | Opis                                                                                                                                         |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Cold start                   | Novi korisnici bez historije kategorija ne dobijaju content-based preporuke                                                                  |
| Bez collaborative filteringa | Sistem ne uzima u obzir sličnost između korisnika                                                                                            |
| Bez collaborative filteringa | Sistem ne uzima u obzir sličnost između korisnika                                                                                            |
| Fiksni koeficijenti          | Težine $\alpha$ i $\beta$ su hardkodirane; mogli bi biti konfigurabilni                                                                      |
| In-memory scoring            | Vozila se učitavaju iz baze pa se scoring radi u memoriji; za veće skupove podataka preporučuje se SQL-based pristup s predhvatanjem skupova |
| Fiksni prozor popularnosti   | Period od tri mjeseca je hardkodiran; moglo bi biti konfigurabilan parametar                                                                 |
