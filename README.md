# UniSwap Campus Marketplace

UniSwap is a Flutter marketplace prototype for students to buy and sell second-hand items near their residence. It focuses on making local exchanges easier, especially when students need to find nearby items or sell belongings before moving.

## Project scope

UniSwap connects student members and administrators through a reviewed marketplace.

### Student members

- Register with student details and a campus or nearby residence. New accounts wait for administrator approval before they can sign in.
- Browse and search available listings, with category, price, and location filters.
- Create listings with a title, description, category, price, condition, urgency, pickup details, and multiple photos.
- Use their registered residence as the listing's pickup location. They can add a note such as which entrance to meet at.
- Edit their listings, check review feedback, and manage items they have listed.
- Place orders, view order and payment status, arrange a meetup time, and mark an order received.
- Update their profile or residence, and request a residence that is not already in the list.

### Administrators

- View an overview of registered users, live listings, and items or residence requests needing attention.
- Approve, reject, suspend, or restore member accounts.
- Review listings by approving them, requesting changes, or rejecting them with a reason.
- Manage marketplace categories and residences.
- Review requests to add or merge a residence.

## Main marketplace flow

1. A student registers. An administrator approves the account before the student can sign in.
2. A seller creates a listing using their registered residence and adds any helpful pickup instructions.
3. The listing waits for administrator review. Once approved, it becomes visible to buyers.
4. A buyer places an order for an available item. The item is reserved while payment is pending.
5. The buyer confirms the demo payment within 30 minutes. The app records the payment status and the order moves to meetup.
6. The buyer and seller meet at the seller's listed residence. The buyer marks the item received to complete the order.

## Important prototype limits

- Payment is simulated: the app records a paid status, but it does not charge a card, transfer money, or pay out sellers.
- A 5% seller commission is recorded for demonstration; no real commission is collected.
- There is no in-app chat, map-based pickup, courier, or delivery service.
- Pickup uses the seller's registered residence, with an optional text note for meetup details.

## Presentation notes

> UniSwap is a campus-focused second-hand marketplace for students. Sellers can post items with photos and pickup details at their registered residence. Administrators review student accounts and listings, and manage the marketplace's categories and residences. Buyers can search for nearby items, place an order, confirm a simulated payment, and arrange a meetup. The goal is to make local buying and selling easier; real payments, chat, and delivery are outside this prototype's scope.

## Technology

- **Mobile app:** Flutter and Dart
- **Backend API:** Node.js and Express
- **Database:** MySQL
- **Connection:** The Flutter app calls the Express API, which reads and updates the MySQL database.

## Run locally

### Requirements

- Flutter SDK
- Node.js and npm
- MySQL
- An editor such as VS Code or Android Studio

### 1. Set up the database

Create a MySQL database named `project_mobile_app`, select it, and import [`project_mobile_app.sql`](./project_mobile_app.sql). Update the local connection settings in `db_config.js` to match your MySQL installation.

### 2. Start the backend

From the project root, install the Node.js packages and start the API:

```bash
npm install
npm start
```

The API listens on port `3000` by default.

### 3. Start the Flutter app

In another terminal:

```bash
flutter pub get
flutter run
```

By default, the app connects to `http://localhost:3000/api`. For an Android emulator, use the host machine address:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

For a physical device, set `API_BASE_URL` to an address the device can reach on your local network.

## Tests

```bash
flutter test
npm test
```

The Node.js `npm test` script currently checks the syntax of `app.js`. Flutter tests cover app models and controllers; update the older image-upload test calls to the current bytes-based API before expecting the full Flutter suite to pass.
