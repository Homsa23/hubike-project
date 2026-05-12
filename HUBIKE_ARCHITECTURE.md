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
