# Gestock+ - Prévisualisation de l'Architecture Logicielle

## Vue d'ensemble de l'Architecture

Gestock+ est une application Flutter de Point de Vente (POS) hors-ligne avec synchronisation cloud, construite selon les principes de **Clean Architecture** et **Feature-Driven Design**. L'architecture garantit la séparation des préoccupations, la testabilité et l'évolutivité.

### Principes Architecturaux

- **Offline-First** : Priorité au stockage local avec synchronisation cloud en arrière-plan
- **Clean Architecture** : Séparation stricte entre Domain, Data et Presentation layers
- **Feature-First** : Organisation par modules fonctionnels indépendants
- **Dependency Injection** : Inversion de dépendances via GetIt
- **State Management** : Pattern BLoC pour la gestion d'état réactive

---

## Structure des Couches (Clean Architecture)

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Pages      │  │    Widgets   │  │    BLoCs     │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  Entities    │  │  Use Cases   │  │ Repositories │       │
│  │  (Models)    │  │  (Business)  │  │  (Interfaces)│       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                       DATA LAYER                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ Repositories │  │ Data Sources │  │   Models     │       │
│  │ (Impl)       │  │ (Local/Cloud)│  │  (DTOs)      │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

---

## Structure du Projet

### Organisation des Dossiers

```
lib/
├── core/                           # Utilitaires et composants partagés
│   ├── cloud/                      # Services de synchronisation cloud
│   │   ├── cloud_sync_service.dart
│   │   ├── supabase_auth_service.dart
│   │   ├── supabase_subscription_service.dart
│   │   └── supabase_sync_service.dart
│   ├── config/                     # Configuration de l'application
│   ├── data/                       # Data sources globaux
│   ├── error/                      # Gestion des erreurs
│   ├── notifications/              # Système de notifications
│   ├── service_locator.dart        # Injection de dépendances (GetIt)
│   ├── services/                   # Services métier globaux
│   ├── theme/                      # Thème et styling
│   ├── usecase/                    # Use cases de base
│   ├── utils/                      # Helpers et utilitaires
│   └── widgets/                    # Widgets réutilisables
│
├── features/                       # Modules fonctionnels
│   ├── auth/                       # Authentification & RBAC
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├──                            # Structure identique pour chaque feature
│   ├── billing/                    # POS, Panier, Commandes
│   ├── boutiques/                  # Gestion multi-boutiques
│   ├── dashboard/                  # Analytics & Reporting
│   ├── notifications/              # Gestion des notifications
│   ├── onboarding/                 # Premier lancement
│   ├── payment/                    # Intégration PawaPay (MoMo)
│   ├── product/                    # Gestion des produits
│   ├── settings/                   # Configuration & Paramètres
│   ├── shop/                       # Informations boutique
│   ├── stock/                      # Gestion des stocks
│   ├── subscription/               # Gestion des abonnements
│   └── sync/                       # Interface de synchronisation
│
├── l10n/                          # Internationalisation
│   ├── app_en.arb                 # Anglais
│   ├── app_fr.arb                 # Français
│   └── app_localizations.dart
│
└── main.dart                      # Point d'entrée
```

---

## Stack Technique

### Core Framework

- **Flutter** (SDK >=3.1.0) - Framework UI cross-platform
- **Dart** (>=3.1.0 <4.0.0) - Langage de programmation

### Architecture & State Management

- **flutter_bloc** (^8.1.5) - Pattern BLoC pour state management
- **get_it** (^7.6.7) - Service Locator / Dependency Injection
- **equatable** (^2.0.5) - Comparaison d'objets pour les états

### Programmation Fonctionnelle

- **fpdart** (^1.1.0) - Programmation fonctionnelle (Either, Option)

### Navigation

- **go_router** (^14.0.0) - Navigation déclarative

### Base de Données Locale

- **hive** (^2.2.3) - Base NoSQL locale ultra-rapide
- **hive_flutter** (^1.1.0) - Intégration Flutter pour Hive

### Cloud & Backend

- **supabase_flutter** (^2.5.0) - Backend-as-a-Service (Auth, DB, Realtime)
- **connectivity_plus** (^6.0.3) - Détection de connectivité

### Sécurité

- **crypto** (^3.0.3) - Hashage des PINs

### Réseau

- **http** (^1.2.0) - Client HTTP pour APIs externes

### UI & UX

- **google_fonts** (^6.1.0) - Typographie
- **fl_chart** (^0.69.2) - Graphiques pour dashboard
- **lottie** (^3.3.3) - Animations
- **smooth_page_indicator** (^2.0.1) - Indicateurs de page
- **vibration** (^3.1.8) - Retour haptique

### Hardware Integration

- **mobile_scanner** (^5.1.0) - Scan de codes-barres
- **print_bluetooth_thermal** (^1.1.2) - Impression thermique Bluetooth
- **pretty_qr_code** (^3.3.0) - Génération QR codes
- **permission_handler** (^11.3.1) - Gestion des permissions

### Utilitaires

- **intl** (0.20.2) - Internationalisation & formatage
- **uuid** (^4.5.2) - Génération d'UUIDs
- **app_settings** (^7.0.0) - Ouverture settings système
- **url_launcher** (^6.3.0) - Ouverture URLs/links
- **home_widget** (^0.7.0) - Widgets écran d'accueil
- **share_plus** (^10.1.3) - Partage de fichiers
- **file_picker** (^11.0.2) - Sélection de fichiers
- **path_provider** (^2.1.5) - Chemins système

### Reporting & Documents

- **pdf** (^3.11.2) - Génération PDF
- **printing** (^5.13.2) - Impression de documents
- **mailer** (^7.1.0) - Envoi d'emails

### Code Generation

- **build_runner** (^2.4.8) - Générateur de code
- **json_serializable** (^6.7.1) - Sérialisation JSON
- **hive_generator** (^2.0.1) - Générateurs Hive
- **json_annotation** (^4.9.0) - Annotations JSON

---

## Modules Fonctionnels

### 1. Auth Module (`features/auth/`)

**Responsabilité** : Authentification, Gestion des utilisateurs, RBAC

**Composants** :

- **Data Layer** : Stockage local des utilisateurs, hashage PINs
- **Domain Layer** : Cas d'utilisation login/logout, validation PIN
- **Presentation Layer** : Pages de login, gestion des utilisateurs

**Rôles gérés** :

- **Owner/Admin** : Accès complet
- **Cashier** : Ventes uniquement
- **Stock Manager** : Gestion inventaire

---

### 2. Billing Module (`features/billing/`)

**Responsabilité** : Cœur du POS, gestion du panier, commandes

**Composants** :

- **Data Layer** :
  - `OrderRepository` : Persistance des commandes
  - `HeldOrderRepository` : Commandes mises en attente
- **Domain Layer** :
  - Calculs de totaux
  - Gestion des remises
  - Validation de panier
- **Presentation Layer** :
  - Interface POS
  - Historique des ventes
  - Gestion des commandes en attente

**Flux** :

1. Scan/ajout produit → Panier
2. Sélection mode paiement (Cash/MoMo)
3. Validation → Sauvegarde commande
4. Impression reçu

---

### 3. Product Module (`features/product/`)

**Responsabilité** : Gestion CRUD du catalogue produits

**Composants** :

- **Data Layer** : `ProductRepositoryImpl` avec Hive
- **Domain Layer** : Use cases CRUD, recherche par barcode
- **Presentation Layer** : Interface gestion produits

**Fonctionnalités** :

- Ajout/modification/suppression produits
- Scan codes-barres pour ajout rapide
- Gestion des catégories
- Prix et stocks

---

### 4. Stock Module (`features/stock/`)

**Responsabilité** : Gestion des inventaires et mouvements de stock

**Composants** :

- **Data Layer** : `StockRepositoryImpl`
- **Domain Layer** : Calculs de stock, alertes rupture
- **Presentation Layer** : Interface gestion stock

**Fonctionnalités** :

- Réception marchandises
- Ajustements manuels
- Alertes stock low
- Historique mouvements

---

### 5. Payment Module (`features/payment/`)

**Responsabilité** : Intégration Mobile Money via PawaPay

**Composants** :

- **Data Layer** :
  - `PawaPayRemoteDataSource` : API PawaPay
  - `PaymentRepositoryImpl`
- **Domain Layer** : Initiation dépôts/retraits, vérification statut
- **Presentation Layer** : Interface paiement MoMo

**Intégrations** :

- **PawaPay API** : Dépôts et retraits Mobile Money
- **Supabase Edge Functions** : Callbacks et webhooks
- **Wallet Gestock** : Solde virtuel interne

---

### 6. Dashboard Module (`features/dashboard/`)

**Responsabilité** : Analytics et reporting financier

**Composants** :

- **Data Layer** : Agrégation des données de ventes
- **Domain Layer** :
  - Calculs revenus journaliers/hebdomadaires
  - Top produits vendus
  - Statistiques par catégorie
- **Presentation Layer** :
  - Graphiques (fl_chart)
  - Rapports PDF

**Métriques** :

- Revenus journaliers/hebdomadaires/mensuels
- Top produits
- Performance par catégorie
- Historique des transactions

---

### 7. Shop Module (`features/shop/`)

**Responsabilité** : Configuration des informations boutique

**Composants** :

- **Data Layer** : `ShopRepositoryImpl`
- **Domain Layer** : Gestion infos boutique
- **Presentation Layer** : Formulaire configuration

**Données gérées** :

- Nom boutique
- Adresse
- Téléphone
- Logo
- Informations reçus

---

### 8. Settings Module (`features/settings/`)

**Responsabilité** : Configuration application et périphériques

**Composants** :

- **Data Layer** : `PrinterRepositoryImpl`
- **Domain Layer** : Gestion paramètres
- **Presentation Layer** : Interface settings

**Fonctionnalités** :

- Connexion imprimante Bluetooth
- Paramètres langue (FR/EN)
- Export/Import base de données
- Configuration thème

---

### 9. Subscription Module (`features/subscription/`)

**Responsabilité** : Gestion des abonnements et limitations

**Composants** :

- **Data Layer** : `SupabaseSubscriptionService`
- **Domain Layer** : Validation limits, vérification statut
- **Presentation Layer** : Page abonnement

**Tiers gérés** :

- **Starter** : Gratuit (100 produits, 1 boutique)
- **Pro** : 3 500 XAF/mois (500 produits, 3 boutiques)
- **Business** : 15 000 XAF/mois (Illimité)

---

### 10. Sync Module (`features/sync/`)

**Responsabilité** : Interface de synchronisation cloud

**Composants** :

- **Data Layer** : Intégration avec SupabaseSyncService
- **Domain Layer** : Gestion conflits, priorité
- **Presentation Layer** : Interface setup sync

**Fonctionnalités** :

- Setup initial cloud
- Statut synchronisation
- Résolution conflits
- Mode hors-ligne

---

## ☁️ Services Cloud (Core/Cloud)

### SupabaseAuthService

**Responsabilité** : Authentification cloud Supabase

**Fonctionnalités** :

- Login/Logout
- Gestion sessions
- Refresh tokens
- Récupération mot de passe

---

### SupabaseSyncService

**Responsabilité** : Synchronisation bidirectionnelle des données

**Stratégie** :

- **Push** : Modifications locales → Supabase
- **Pull** : Modifications Supabase → Local
- **Realtime** : Écoute des changements via Supabase Stream
- **Conflict Resolution** : Last-write-wins avec timestamps

**Données synchronisées** :

- Produits
- Commandes
- Utilisateurs
- Stocks
- Paramètres boutique

---

### SupabaseSubscriptionService

**Responsabilité** : Gestion des abonnements côté backend

**Fonctionnalités** :

- Vérification statut abonnement
- Validation des limits
- Gestion des cycles (mensuel/annuel)
- Webhooks PawaPay

---

### CloudSyncService (Interface)

**Responsabilité** : Abstraction pour les services de cloud

**Avantages** :

- Permet de changer de backend sans modifier le code métier
- Facilite les tests avec mocks
- Interface unifiée pour tous les modules

---

## 🔄 Flux de Données

### Exemple : Processus de Vente (Billing)

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION                             │
│  User scan barcode → BillingBloc.addProductToCart()         │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                       DOMAIN                                 │
│  BillingBloc → GetProductByBarcodeUseCase → ProductRepo     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                        DATA                                 │
│  ProductRepositoryImpl → Hive (Local DB)                    │
└─────────────────────────────────────────────────────────────┘
                              ↓
                        Retour produit
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION                            │
│  StateUpdated → UI rebuild avec produit ajouté              │
└─────────────────────────────────────────────────────────────┘
```

### Exemple : Synchronisation Cloud

```
┌─────────────────────────────────────────────────────────────┐
│              DÉTECTION CHANGEMENT LOCAL                     │
│  ProductBloc.addProduct() → Hive update                     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              SYNC SERVICE BACKGROUND                        │
│  SupabaseSyncService.pushChanges()                          │
│  → Sérialisation données                                    │
│  → Envoi vers Supabase                                      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              SUPABASE REALTIME STREAM                       │
│  Écoute changements d'autres devices                        │
│  → Pull automatique si conflit détecté                      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              MISE À JOUR LOCAL                              │
│  Hive update → BLoC emit new state → UI refresh             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔐 Sécurité

### Authentification

- **PIN Hashing** : Utilisation de `crypto` pour hashage des PINs
- **Session Management** : Tokens Supabase avec refresh automatique
- **RBAC** : Contrôle d'accès basé sur les rôles (Owner/Cashier/Stock Manager)

### Données

- **Local Encryption** : Hive avec encryption optionnelle
- **HTTPS** : Toutes les communications cloud en HTTPS
- **API Keys** : Stockées dans environment variables, jamais hardcodées

---

## 📊 Gestion d'État (State Management)

### Pattern BLoC

Chaque feature possède son propre BLoC gérant son état :

```dart
// Exemple générique
abstract class BlocEvent {}
abstract class BlocState {}

class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  final UseCase useCase;

  FeatureBloc({required this.useCase}) : super(InitialState()) {
    on<SomeEvent>(_handleSomeEvent);
  }

  Future<void> _handleSomeEvent(
    SomeEvent event,
    Emitter<FeatureState> emit
  ) async {
    emit(LoadingState());
    final result = await useCase(event.params);
    result.fold(
      (error) => emit(ErrorState(error)),
      (data) => emit(SuccessState(data)),
    );
  }
}
```

### Avantages

- **Immutabilité** : États immuables (equatable)
- **Testabilité** : Logique isolée de l'UI
- **Réactivité** : UI se reconstruit automatiquement
- **Débogage** : Transition d'états traçable

---

## 🧪 Testabilité

### Stratégie de Tests

L'architecture facilite les tests à plusieurs niveaux :

**Unit Tests** :

- Use Cases (Domain Layer)
- Repositories (Data Layer)
- BLoCs (Presentation Layer)

**Widget Tests** :

- Pages et composants UI
- Interactions utilisateur

**Integration Tests** :

- Flux complets (ex: processus de vente)
- Synchronisation cloud

### Mocking

Grâce à l'injection de dépendances (GetIt), tous les composants peuvent être mockés :

```dart
// Exemple de test
test('should get product by barcode', () async {
  // Arrange
  when(mockRepository.getProductByBarcode('123'))
    .thenAnswer((_) async => Right(testProduct));

  // Act
  final result = await useCase('123');

  // Assert
  expect(result, Right(testProduct));
});
```

---

## 🚀 Déploiement

### Backend (Supabase)

- **Database** : PostgreSQL avec migrations SQL
- **Auth** : Supabase Auth
- **Realtime** : Supabase Realtime pour sync
- **Edge Functions** : TypeScript pour callbacks PawaPay
- **Storage** : Stockage fichiers (logos, reçus)

### Frontend (Flutter)

- **Android** : APK via Android Studio
- **iOS** : IPA via Xcode
- **Web** : Déploiement sur hosting statique

### CI/CD (Recommandé)

- GitHub Actions pour builds automatisés
- Tests automatisés sur chaque PR
- Déploiement automatisé sur merge main

---

## 📈 Scalabilité

### Points d'Extension

**Nouvelles Features** :

- Créer nouveau dossier dans `features/`
- Structure data/domain/presentation
- Enregistrer dans `service_locator.dart`

**Nouveaux Rôles** :

- Étendre enum des rôles
- Ajouter règles RBAC dans AuthBloc

**Nouveaux Paiements** :

- Créer nouveau RemoteDataSource
- Implémenter interface PaymentRepository
- Ajouter UI dans Payment Module

**Nouveau Backend** :

- Implémenter interface CloudSyncService
- Remplacer SupabaseSyncService
- Aucun changement dans features

---

## 🎯 Conclusion

L'architecture de Gestock+ est conçue pour :

- **Maintenabilité** : Code organisé et modulaire
- **Évolutivité** : Facile d'ajouter de nouvelles features
- **Performance** : Offline-first avec sync intelligent
- **Sécurité** : RBAC et encryption des données sensibles
- **Testabilité** : Architecture propice aux tests

Cette structure permet à l'équipe de développement de travailler efficacement sur différentes features en parallèle tout en maintenant une cohérence globale de l'application.

---

_Document généré le 26 Juin 2026_
_Version : 1.1.0+2_
