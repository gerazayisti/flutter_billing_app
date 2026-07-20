# Gestock+ : Matrice des Fonctionnalités & Roadmap V2.1

Ce document détaille la répartition des fonctionnalités par abonnement et par rôle utilisateur, ainsi que le plan de déploiement technique.

---

## 1. Matrice des Abonnements (Tiers)

| Fonctionnalité / Limite | Starter (Gratuit/Trial) | Pro (Croissance) | Business (Entreprise) |
| :--- | :--- | :--- | :--- |
| **Prix (Mensuel)** | 0 XAF (Trial) / 1 500 XAF | 3 500 XAF | 15 000 XAF |
| **Boutiques** | 1 seule | Jusqu'à 3 | Illimité |
| **Produits** | 100 max | 500 max | Illimité |
| **Employés** | 2 max | 10 max | Illimité |
| **Vente (POS)** | ✅ Oui | ✅ Oui | ✅ Oui |
| **Gestion de Stock** | ✅ Basique | ✅ Avancé | ✅ Complet |
| **Rapports PDF** | ❌ Non | ✅ Oui | ✅ Oui |
| **Synchronisation Cloud** | ❌ Non | ✅ Temps réel | ✅ Temps réel |
| **Paiements MoMo (API)** | ❌ Non | ✅ PawaPay V2 | ✅ Intégration Totale |
| **Support** | Standard | Prioritaire | Dédié 24/7 |

---

## 2. Accès par Rôles Utilisateurs (RBAC)

### 👑 Administrateur (Owner)
*   **Gestion Financière** : Accès complet au Wallet Gestock, historique des retraits, solde des boutiques.
*   **Configuration** : Gestion des abonnements, clés API, paramètres de l'imprimante.
*   **RH** : Ajout/Suppression de caissiers et gestionnaires de stock.
*   **Analyses** : Tableaux de bord de performance multi-boutiques.

### 💰 Caissier (Cashier)
*   **Ventes** : Interface POS, scan de codes-barres, encaissement (Cash/MoMo).
*   **Reçus** : Impression thermique via Bluetooth.
*   **Session** : Ouverture/Clôture de caisse journalière.
*   **Limitation** : Ne voit pas les marges bénéficiaires ni le solde global du propriétaire.

### 📦 Gestionnaire de Stock (Stock Manager)
*   **Inventaire** : Réception de marchandises, ajustement des stocks.
*   **Alertes** : Notifications de rupture de stock.
*   **Produits** : Création et modification des fiches articles (prix, catégories).

---

## 3. Roadmap d'Implémentation V2.1

### Étape 1 : Stabilisation du Cœur (Terminé ✅)
- [x] Correction métadonnées PawaPay V2 (Fields must have unique names).
- [x] Synchronisation Realtime de l'historique du Wallet (Supabase Stream).
- [x] Branding UI (Logo Gestock+ cliquable).
- [x] Unification du Callback PawaPay pour Dépôts & Retraits.

### Étape 2 : Gestion des Limites & Paywall (En cours 🏗️)
- [ ] **Locking System** : Bloquer l'ajout de produits/boutiques si la limite du plan est atteinte.
- [ ] **UI Subscription** : Refonte de la page d'abonnement avec sélection du cycle (Mensuel/Annuel).
- [ ] **Trial Logic** : Activation automatique de 14 jours pour les nouveaux comptes.

### Étape 3 : Expérience Utilisateur Avancée (Prochainement 🚀)
- [ ] **Mode Hors-ligne** : Synchronisation différée des ventes si connexion instable.
- [ ] **Reporting PDF** : Génération de rapports de fin de mois automatisés (Plan Pro/Business).
- [ ] **Multi-Boutiques** : Sélecteur de boutique rapide dans le Drawer pour les Owners.

### Étape 4 : Déploiement & Scalabilité
- [ ] Migration de la Sandbox PawaPay vers Production.
- [ ] Déploiement final des Edge Functions Supabase (V13.0).
- [ ] Monitoring des erreurs via Sentry/Log Snag.

---
*Dernière mise à jour : Mai 2024*
