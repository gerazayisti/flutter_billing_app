# Gestock+ : Matrice des Fonctionnalités & Roadmap Stratégique

Ce document sert de référence pour la segmentation de l'offre Gestock+ par **Abonnement** et la gestion des accès par **Rôle**.

---

## 1. Segmentation par Abonnement (Subscription Tiers)

Gestock+ adapte ses capacités en fonction du plan choisi par l'utilisateur (Owner).

| Fonctionnalité / Limite | **STARTER** (TPE) | **PRO** (Croissance) | **BUSINESS** (Réseau) |
| :--- | :--- | :--- | :--- |
| **Tarif Mensuel** | 1 500 XAF | 3 500 XAF | 15 000 XAF |
| **Tarif Annuel (-25%)** | 13 000 XAF | 35 000 XAF | 165 000 XAF |
| **Nombre de Boutiques** | 1 Boutique | Jusqu'à 3 Boutiques | Illimité |
| **Nombre de Produits** | 100 max | 500 max | Illimité |
| **Nombre d'Employés** | 2 max | 10 max | Illimité |
| **Synchronisation Cloud** | ❌ Non (Local) | ✅ Temps réel | ✅ Temps réel |
| **Rapports PDF** | ❌ Non | ✅ Inclus | ✅ Personnalisés |
| **API pawaPay MoMo** | ❌ Non | ✅ Inclus | ✅ Inclus |
| **Support Technique** | Standard | Prioritaire | Dédié |

---

## 2. Accès par Rôle Utilisateur (RBAC)

Les permissions sont transversales aux abonnements mais limitées par les quotas du plan.

### 👑 Administrateur (Owner)
*   **Périmètre** : Propriétaire du compte.
*   **Fonctions Exclusives** :
    *   Gestion du **Wallet Gestock** (Retrait d'argent vers MoMo).
    *   Paiement de l'abonnement et changement de plan.
    *   Gestion des boutiques et des employés.
    *   Accès aux rapports financiers et marges bénéficiaires.

### 💰 Caissier (Cashier)
*   **Périmètre** : Affecté à une boutique spécifique.
*   **Fonctions** :
    *   Interface de vente (POS) et scan.
    *   Encaissement Client (Cash ou MoMo via pawaPay).
    *   Impression de tickets Bluetooth.
*   **Restrictions** : Aucune vue sur le solde global du propriétaire ni sur les prix d'achat/marges.

### 📦 Gestionnaire de Stock (Stock Manager)
*   **Périmètre** : Affecté à une ou plusieurs boutiques.
*   **Fonctions** :
    *   Entrées/sorties de stock et inventaires.
    *   Création de produits et catégories.
    *   Alertes de rupture (Plan Pro/Business).
*   **Restrictions** : Pas d'accès au module de vente ni aux finances.

---

## 3. Roadmap d'Implémentation Technique

L'objectif est d'atteindre la version **Gestock+ 2.1 STABLE**.

### Phase 1 : Consolidation & Realtime (Terminé ✅)
- [x] **Format Metadata pawaPay V2** : Mise à jour des Edge Functions pour éviter les erreurs de doublons.
- [x] **Wallet Realtime** : Migration du polling vers les flux Supabase (`Stream`) pour le solde et les retraits.
- [x] **Identité Visuelle** : Intégration du logo Gestock+ et personnalisation de l'App Drawer.

### Phase 2 : Système de Paywall & Quotas (Priorité Haute 🏗️)
- [ ] **Middleware de Validation** : Bloquer l'ajout de produits/employés si le quota du plan est dépassé.
- [ ] **UI Abonnement** : Intégration de la page de sélection des plans avec liens de paiement Freemopay.
- [ ] **Logique Trial** : Activation d'un essai "Pro" de 14 jours pour tout nouveau compte.

### Phase 3 : Mobilité & Reporting (Prochainement 🚀)
- [ ] **Générateur de Rapports PDF** : Création d'une Edge Function utilisant `puppeteer` ou une lib PDF pour les rapports Pro.
- [ ] **Mode Hors-ligne (Offline First)** : Optimisation du cache Hive pour garantir la vente même sans internet.
- [ ] **Notifications Push** : Alertes de stock et confirmations de paiement MoMo.

### Phase 4 : Mise en Production
- [ ] Basculement des credentials pawaPay de `Sandbox` à `Live`.
- [ ] Audit de sécurité des RLS (Row Level Security) sur Supabase.
- [ ] Lancement de la version Alpha fermée sur Google Play.

---
*Document mis à jour le : 22 Mai 2024*
