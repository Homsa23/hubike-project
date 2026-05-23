HUBIKE App Architecture & Context
Tech Stack: Flutter, Firebase (Firestore, Auth).
Core Concept: A cycling event platform where users can browse rides, join them, validate their physical presence via QR code, and earn Hubike Coins to spend in an in-app shop.

The Active Mission: The Post-Join Flow
Based on our UML diagrams, users can view events without logging in (Lazy Registration). When they click 'Join', the following architecture must be respected:

Authentication: User must be logged in.

Database Write: A new document is created in the participations collection.

The Participation Model Rules: It must include id, userId, eventId, registrationDate (timestamp), ispresent (boolean, defaults to FALSE), joinedbycoins (boolean), winnedCoins (int), and status (string, 'Registered').

Digital Ticket UI: User is navigated to a Ticket Page showing event details and a QR Code representing their participation ID. The Group Leader will scan this to change ispresent to TRUE.

## User Roles & Shop Logic

Users have an isGroupLeader boolean field in their Firestore users document.

Normal Riders (isGroupLeader: false) can join events and buy from shops.

Group Leaders (isGroupLeader: true) have access to hidden UI to scan QR tickets and manage their specific shop inventory. Products in the shop are linked via a leaderId to prevent coin fraud across different groups.

**Split Database Architecture:** When a Group Leader signs up, their profile is saved in the standard users collection AND duplicated into an isolated group_leader collection using the same uid. This allows home.dart to read isGroupLeader from users for UI routing, while the backend uses group_leader for leader-specific operations.

## Authentication

Standard Email/Password registration.

The Firestore users document is created immediately after successful Firebase Auth registration.

## Shop Architecture

### Product Data Model

The shop uses a `products` collection in Firestore with the following schema:

- `id` (string): Auto-generated document ID
- `groupLeaderId` (string): Links product to specific Group Leader (marketplace scoping)
- `name` (string): Product name
- `brand` (string): Product brand
- `category` (string): Product category
- `condition` (string): Product condition (e.g., "New", "Used", "Refurbished")
- `description` (string): Detailed product description
- `price` (double): Price in Algerian Dinars (DZD)
- `quantity` (int): Stock quantity available
- `discountCoins` (int): Maximum Hubike Coins allowed for discount
- `imageUrl` (string): Cloudinary hosted image URL
- `createdAt` (timestamp): Auto-generated creation timestamp

### Cloudinary Unsigned Upload Integration

Product images are uploaded directly to Cloudinary using their unsigned upload endpoint:

- **Upload URL**: `https://api.cloudinary.com/v1_1/dopk2m742/image/upload`
- **Upload Preset**: `hubike_shop`
- **Method**: POST multipart/form-data
- **Required Fields**:
  - `upload_preset`: Set to 'hubike_shop'
  - `file`: Image file bytes/path
- **Response**: JSON containing `secure_url` which is saved to Firestore

The upload process:
1. User selects image from gallery using `image_picker` package
2. Image is uploaded to Cloudinary via `http` package
3. Loading spinner shown during upload
4. `secure_url` extracted from JSON response
5. URL saved to Firestore product document

### Group Leader Marketplace Scoping

Each Group Leader only manages their own products through the `groupLeaderId` field:

- **Query Pattern**: `products.where('groupLeaderId', isEqualTo: currentUser.uid)`
- **Security**: Products are scoped to prevent cross-leader access
- **Admin Dashboard**: Only shows products where `groupLeaderId` matches current user
- **Marketplace Model**: Multiple independent shops managed by different Group Leaders

### Shop UI Components

- **Product Form** (`widgets/product_form.dart`): Add/Edit products with image upload
- **Admin Shop Page** (`screens/admin_shop_page.dart`): StreamBuilder displaying leader's products with edit/delete actions
- **Dark Theme**: All shop UI follows established neon green/cyan aesthetic on dark backgrounds

## Order & Checkout Flow

The Hubike shop supports a flexible checkout system utilizing the `orders` collection in Firestore.

### Dual Checkout Paths

1. **Direct Buy**: 
   - A user clicks "Buy Equipment" directly from a product card.
   - The app navigates to the `OrderFormScreen`, passing the single product. It bypasses the cart state entirely.
2. **Cart Checkout**:
   - A user clicks the "Add to Cart" icon on multiple products.
   - The user opens the `CartScreen` to review their items.
   - Upon clicking "Buy" in the cart, the app navigates to the `OrderFormScreen`, passing the entire list of products in the cart.
   - If the order completes successfully from this path, the global `CartState` is automatically cleared.

### Order Data Model (`orders` collection)

When an order is successfully submitted, a new document is written to the `orders` collection containing the following fields:

- `name` (string): User's first name
- `lastName` (string): User's last name
- `phone` (string): User's contact phone number
- `wilaya` (string): Shipping destination (State/Province)
- `orderDate` (timestamp): The exact date and time the order was placed
- `products` (array of objects): Complete details of all purchased products (reusing the product schema)
- `totalAmount` (double): The calculated total cost of the order in DZD
