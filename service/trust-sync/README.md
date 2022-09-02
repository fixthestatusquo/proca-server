test

curl -d '{"email":"test@example.org"}' -H "Content-Type: application/json" -X POST http://localhost:3000/lookup-trust
curl -d '{"email":"sebastian.srb@palasthotel.de"}' -H "Content-Type: application/json" -X POST http://localhost:3000/lookup-trust

