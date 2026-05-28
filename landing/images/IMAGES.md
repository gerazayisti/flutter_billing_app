# Images à placer ici

Ajoutez vos captures d'écran dans ce dossier, puis remplacez les blocs
`<div class="img-ph">` correspondants dans `index.html` par des `<img>`.

## Liste des images attendues

| Fichier suggéré          | Remplace le placeholder                          | Format conseillé    |
|--------------------------|--------------------------------------------------|---------------------|
| `hero-screen.png`        | Hero — écran principal / caisse                  | 9:19, PNG, 540×1140 |
| `screen-home.png`        | Galerie slide 1 — Accueil                        | 9:19, PNG, 540×1140 |
| `screen-caisse.png`      | Galerie slide 2 — Caisse / Panier                | 9:19, PNG, 540×1140 |
| `screen-momo.png`        | Galerie slide 3 — Paiement Mobile Money          | 9:19, PNG, 540×1140 |
| `screen-stock.png`       | Galerie slide 4 + phone arrière section Download | 9:19, PNG, 540×1140 |
| `screen-dashboard.png`   | Galerie slide 5 — Tableau de bord                | 9:19, PNG, 540×1140 |
| `screen-orders.png`      | Galerie slide 6 — Historique commandes           | 9:19, PNG, 540×1140 |
| `dashboard-tablet.png`   | Section "Comment ça marche" — vue large          | 4:3,  PNG, 1200×900 |
| `screen-checkout.png`    | Section Download — phone avant                   | 9:19, PNG, 540×1140 |
| `qr-code.png`            | QR Code de téléchargement                        | carré, PNG, 120×120 |

## Comment remplacer un placeholder

```html
<!-- AVANT -->
<div class="img-ph">
  <span class="img-ph__icon">📱</span>
  <span class="img-ph__label">ÉCRAN PRINCIPAL</span>
</div>

<!-- APRÈS -->
<img src="images/hero-screen.png"
     alt="Écran principal Gestock+"
     style="width:100%;height:100%;object-fit:cover;">
```

## Conseils pour les captures

- Prenez les captures sur un fond sombre ou neutre
- Utilisez l'émulateur Flutter (Pixel 7, 1080×2400) pour une résolution optimale
- Retirez la barre de statut système si possible (mode immersif)
- Exportez en PNG pour la qualité, WebP pour la performance
