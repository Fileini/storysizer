# group-service

Microservizio Spring Boot che gestisce i **gruppi di stima collaborativa** di StorySizer. Permette agli utenti di creare gruppi, invitare membri via email, creare stime condivise e votare in modo anonimo.

## Stack

- Java 17, Spring Boot 3.4.2
- Spring Data JPA + PostgreSQL
- Resend API (inviti email)
- Spring Security (permit-all, autenticazione delegata al gateway)

## Struttura pacchetti

```
com.fileini.storysizer.service.group
├── controller/
│   ├── GroupController.java           # CRUD gruppi + gestione membri
│   ├── GroupEstimationController.java # CRUD stime + voti
│   └── InvitationController.java      # Accettazione inviti
├── service/
│   ├── GroupService.java
│   └── GroupEstimationService.java
├── model/                             # Entità JPA
├── repository/                        # Spring Data repositories
├── dto/                               # Response DTO
├── mail/
│   ├── ResendMailClient.java          # Client HTTP per Resend API
│   └── MailTemplates.java             # Template HTML + testo plain
└── util/
    └── TokenUtil.java                 # Generazione e hashing token
```

## Variabili d'ambiente

| Variabile | Descrizione |
|-----------|-------------|
| `POSTGRES_HOST` | Host PostgreSQL |
| `POSTGRES_PORT` | Porta PostgreSQL (default 5432) |
| `POSTGRES_DB` | Nome del database (es. `groupsdb`) |
| `POSTGRES_USER` | Utente del database |
| `POSTGRES_PASSWORD` | Password del database |
| `RESEND_API_KEY` | API key Resend (non committare mai) |
| `RESEND_FROM_EMAIL` | Indirizzo mittente email (es. `noreply@storysizer.org`) |
| `APP_BASE_URL` | URL pubblico del frontend (es. `https://app.storysizer.org`) — usato per costruire i link negli inviti |

Le variabili vengono iniettate in produzione tramite il secret Kubernetes `groups-db-secret` (vedi [infrastructure/backend/group-service/](../../infrastructure/backend/group-service/)).

## Sicurezza

Il servizio è accessibile **solo internamente al cluster** (`ClusterIP`). Non ha una rotta Traefik pubblica. L'autenticazione è gestita dal GraphQL Gateway, che verifica il JWT e propaga l'identità utente tramite gli header:

| Header | Contenuto |
|--------|-----------|
| `X-User-Id` | Subject del JWT (ID Keycloak) |
| `X-User-Name` | Display name dell'utente |
| `X-User-Email` | Email verificata dell'utente |

## Flusso di invito

### 1 — Admin invia l'invito

L'admin chiama `POST /groups/{id}/invite` con `{ "email": "..." }`.

Il servizio:
1. Verifica che il richiedente sia admin del gruppo
2. Controlla che l'email non sia già membro o abbia già un invito `PENDING`
3. Genera un token casuale a 32 byte (URL-safe base64) tramite `TokenUtil.generateRawToken()`
4. Salva in DB solo l'**hash SHA-256** del token (`tokenHash`) — il raw token non viene mai persistito
5. Costruisce il link: `APP_BASE_URL + "/join-group?token=<rawToken>"`
6. Chiama la Resend API per inviare l'email con il link — se la mail fallisce, la transazione fa rollback (nessun record orfano in DB)
7. L'invito ha scadenza **7 giorni**

### 2 — Invitato clicca il link

Il link apre il frontend su `/join-group?token=<rawToken>`. Il frontend chiama la mutazione GraphQL `acceptGroupInvite(token)`, che il gateway inoltro a `POST /invitations/accept` con il token nel body.

Il servizio:
1. Calcola `SHA-256(rawToken)` e cerca in DB il record con quel `tokenHash`
2. Verifica che lo stato sia `PENDING`
3. Verifica che non sia scaduto
4. **Verifica che l'email nel JWT corrisponda all'`invitedEmail`** — il link non è cedibile a terzi
5. Aggiunge l'utente come membro con ruolo `MEMBER`
6. Segna l'invito come `ACCEPTED`
7. Restituisce il `GroupDetailDTO` del gruppo

### 3 — Annullamento (admin)

`DELETE /groups/{id}/invitations/{invitationId}` — segna l'invito come `CANCELED`. Tentativi successivi di usare il link ricevono `410 Gone`.

### Sicurezza del token

| Aspetto | Dettaglio |
|---------|-----------|
| Entropia | 32 byte random → 256 bit |
| Persistenza | Solo hash SHA-256 in DB, il raw token è monouso |
| Email-binding | Il token è valido solo se usato dall'email destinataria |
| Scadenza | 7 giorni dal momento dell'invio |
| Rollback atomico | Mail fallita = nessun invito in DB |

## Avvio locale

```bash
# Copia e compila le variabili d'ambiente necessarie in application.properties o come env vars
cd backend/group-service
./mvnw spring-boot:run
```

Il servizio si avvia sulla porta `8080` (configurabile via `SERVER_PORT`).

## Endpoint principali

| Metodo | Path | Descrizione |
|--------|------|-------------|
| `GET` | `/groups/my` | Gruppi dell'utente corrente |
| `GET` | `/groups/{id}` | Dettaglio gruppo |
| `POST` | `/groups` | Crea gruppo |
| `PUT` | `/groups/{id}` | Rinomina gruppo |
| `DELETE` | `/groups/{id}` | Elimina gruppo (soft delete) |
| `POST` | `/groups/{id}/invite` | Invia invito email |
| `DELETE` | `/groups/{id}/invitations/{invId}` | Annulla invito |
| `PUT` | `/groups/{id}/members/{memberId}/promote` | Promuove membro ad admin |
| `DELETE` | `/groups/{id}/members/{memberId}` | Rimuove membro |
| `POST` | `/invitations/accept` | Accetta invito (token dal link email) |
| `GET` | `/estimations/group/{groupId}` | Stime di un gruppo |
| `POST` | `/estimations` | Crea stima di gruppo |
| `POST` | `/estimations/{id}/vote` | Sottomette il voto |
| `GET` | `/estimations/{id}/dashboard` | Dashboard con risultati aggregati |
| `POST` | `/estimations/{id}/restart` | Azzera i voti e riapre la stima |
