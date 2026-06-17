# eRentaCar

Rent-a-car management system with a Flutter Desktop admin application, Flutter Mobile client application, and a .NET 9 REST API backed by SQL Server. RabbitMQ handles asynchronous email notifications via a separate Worker service.

---

## Architecture

| Service     | Technology            | Port  |
|-------------|----------------------|-------|
| API         | .NET 9 / ASP.NET Core | 5091  |
| Worker      | .NET 9 Background Worker | —  |
| Database    | SQL Server 2022       | 1433  |
| RabbitMQ    | RabbitMQ 3.13         | 5672 / 15672 |
| Desktop App | Flutter (Windows)     | —     |
| Mobile App  | Flutter (Android/iOS) | —     |

---

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (for Docker setup)
- [.NET 9 SDK](https://dotnet.microsoft.com/download) (for local dev)
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (for mobile/desktop apps)
- A copy of the `.env` file in the repository root (see `.env.example`)

---

## Quick Start — Docker (Recommended)

```bash
# 1. Clone the repository
git clone <repo-url>
cd eRentaCar

# 2. Copy and configure environment variables
cp .env.example .env
# Edit .env if needed (defaults work out of the box)

# 3. Start all services
docker compose up --build -d

# 4. Wait ~30 seconds for SQL Server to initialise, then the API seeds the database automatically.
```

The API is available at `http://localhost:5091`.  
Swagger UI: `http://localhost:5091/swagger`  
RabbitMQ Management: `http://localhost:15672` (guest / guest)

---

## Local Development (without Docker)

### 1. Database and RabbitMQ

Start only the infrastructure services:

```bash
docker compose up db rabbitmq -d
```

### 2. API

```bash
cd eRentaCar.API
dotnet run
```

The API reads configuration from the `.env` file in the repository root and environment variables. Ensure `CONNECTION_STRING`, `JWT_KEY`, `JWT_ISSUER`, `JWT_AUDIENCE` are set.

### 3. Worker

```bash
cd eRentaCar.Worker
dotnet run
```

The Worker connects to RabbitMQ and sends emails when notifications are published.

### 4. Flutter Desktop (Windows admin app)

```bash
cd erentacar_desktop
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5091
```

### 5. Flutter Mobile (Android/iOS client app)

```bash
cd erentacar_mobile
flutter pub get

# Android emulator (replace IP with your machine's LAN IP if using a physical device)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5091

# Physical device on the same network
flutter run --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:5091
```

---

## Environment Variables (`.env`)

| Variable            | Description                              | Default                    |
|---------------------|------------------------------------------|----------------------------|
| `CONNECTION_STRING` | SQL Server connection string             | *(required)*               |
| `JWT_KEY`           | JWT signing key (min. 32 chars)          | *(required)*               |
| `JWT_ISSUER`        | JWT issuer                               | `eRentaCar`                |
| `JWT_AUDIENCE`      | JWT audience                             | `eRentaCar`                |
| `RABBITMQ_HOST`     | RabbitMQ hostname                        | `localhost`                |
| `SMTP_HOST`         | SMTP server                              | *(required for emails)*    |
| `SMTP_PORT`         | SMTP port                                | `587`                      |
| `SMTP_USER`         | SMTP username                            | *(required for emails)*    |
| `SMTP_PASSWORD`     | SMTP password                            | *(required for emails)*    |
| `SA_PASSWORD`       | SQL Server SA password (Docker only)     | `eRentaCar_SA_2024!`       |
| `DB_NAME`           | Database name                            | `230290`                   |
| `ALLOWED_ORIGINS`   | CORS allowed origins (comma-separated)   | `*`                        |
| `STRIPE_SECRET_KEY`      | Stripe secret key for payments           | *(required for payments)*  |
| `STRIPE_WEBHOOK_SECRET`  | Stripe webhook signing secret (`whsec_…`) | *(required for webhook)*  |

---

## Test Credentials

| Application      | Role          | Email                  | Password    |
|------------------|---------------|------------------------|-------------|
| Desktop (admin)  | Administrator | `desktop@test.com`     | `Test1234!` |
| Mobile (client)  | Klijent       | `mobile@test.com`      | `Test1234!` |

These accounts are seeded automatically on first startup.

---

## API Endpoints — Key Routes

| Method | Route                              | Auth       | Description                    |
|--------|------------------------------------|------------|--------------------------------|
| POST   | `/api/auth/login`                  | Public     | Login, returns JWT             |
| POST   | `/api/auth/register`               | Public     | Register new client            |
| POST   | `/api/auth/logout`                 | JWT        | Invalidate token server-side   |
| GET    | `/api/vehicles`                    | Public     | List vehicles with filters     |
| POST   | `/api/reservations`                | Client     | Create reservation             |
| POST   | `/api/payments/create-payment-intent/{id}` | Client | Create Stripe payment intent |
| POST   | `/api/payments/confirm/{id}`       | Client     | Confirm payment (idempotent)   |
| POST   | `/api/payments/refund/{id}`        | Client     | Request refund                 |
| POST   | `/api/payments/webhook`            | Public     | Stripe webhook receiver        |
| GET    | `/api/reports/financial`           | Admin      | Financial report               |
| POST   | `/api/notifications/send`          | Admin      | Send notification to all users |

Full documentation available at `/swagger` when the API is running.

### Stripe Webhook Setup (local testing)

```bash
# Install Stripe CLI, then forward events to the local API:
stripe listen --forward-to localhost:5091/api/payments/webhook

# Copy the printed webhook signing secret (whsec_...) into your .env:
# STRIPE_WEBHOOK_SECRET=whsec_...
```

---

## Logs

- API logs: `eRentaCar.API/logs/api-<date>.log`
- Worker logs: `eRentaCar.Worker/logs/worker-<date>.log`
- Log retention: 14 days
