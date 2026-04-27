import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestock+'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de Bord'**
  String get dashboard;

  /// No description provided for @products.
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get products;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// No description provided for @users.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs'**
  String get users;

  /// No description provided for @inventory.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire & Stock'**
  String get inventory;

  /// No description provided for @shopInfo.
  ///
  /// In fr, this message translates to:
  /// **'Boutique & Reçus'**
  String get shopInfo;

  /// No description provided for @hardware.
  ///
  /// In fr, this message translates to:
  /// **'Hardware'**
  String get hardware;

  /// No description provided for @scanOrEnterBarcode.
  ///
  /// In fr, this message translates to:
  /// **'Scanner ou entrer le code-barres'**
  String get scanOrEnterBarcode;

  /// No description provided for @tapToOpenScanner.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur l\'icône pour ouvrir le scanner'**
  String get tapToOpenScanner;

  /// No description provided for @noProductsFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit trouvé. Ajoutez-en !'**
  String get noProductsFound;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @paymentMethod.
  ///
  /// In fr, this message translates to:
  /// **'Mode de paiement'**
  String get paymentMethod;

  /// No description provided for @cash.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get cash;

  /// No description provided for @mobileMoney.
  ///
  /// In fr, this message translates to:
  /// **'Mobile Money'**
  String get mobileMoney;

  /// No description provided for @card.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get card;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get name;

  /// No description provided for @price.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get price;

  /// No description provided for @barcode.
  ///
  /// In fr, this message translates to:
  /// **'Code-barres'**
  String get barcode;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @dailyRevenue.
  ///
  /// In fr, this message translates to:
  /// **'CA du Jour'**
  String get dailyRevenue;

  /// No description provided for @weeklySales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes Hebdo'**
  String get weeklySales;

  /// No description provided for @topProducts.
  ///
  /// In fr, this message translates to:
  /// **'Top Produits'**
  String get topProducts;

  /// No description provided for @generateReport.
  ///
  /// In fr, this message translates to:
  /// **'Générer Rapport Financier'**
  String get generateReport;

  /// No description provided for @dailyReport.
  ///
  /// In fr, this message translates to:
  /// **'Rapport Journalier (CA)'**
  String get dailyReport;

  /// No description provided for @weeklyReport.
  ///
  /// In fr, this message translates to:
  /// **'Rapport Hebdomadaire (CA)'**
  String get weeklyReport;

  /// No description provided for @monthlyReport.
  ///
  /// In fr, this message translates to:
  /// **'Rapport Mensuel (CA)'**
  String get monthlyReport;

  /// No description provided for @userManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des Utilisateurs'**
  String get userManagement;

  /// No description provided for @newUser.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau Caissier'**
  String get newUser;

  /// No description provided for @fullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom Complet'**
  String get fullName;

  /// No description provided for @pinCode.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN (4 chiffres)'**
  String get pinCode;

  /// No description provided for @role.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get role;

  /// No description provided for @admin.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get admin;

  /// No description provided for @cashier.
  ///
  /// In fr, this message translates to:
  /// **'Caissier'**
  String get cashier;

  /// No description provided for @connected.
  ///
  /// In fr, this message translates to:
  /// **'Connecté'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecté'**
  String get disconnected;

  /// No description provided for @printer.
  ///
  /// In fr, this message translates to:
  /// **'Imprimante'**
  String get printer;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get english;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @pos.
  ///
  /// In fr, this message translates to:
  /// **'Caisse / Ventes'**
  String get pos;

  /// No description provided for @user.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get user;

  /// No description provided for @checkout.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get checkout;

  /// No description provided for @productName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du Produit'**
  String get productName;

  /// No description provided for @variant.
  ///
  /// In fr, this message translates to:
  /// **'Variante'**
  String get variant;

  /// No description provided for @selectVariant.
  ///
  /// In fr, this message translates to:
  /// **'Choisir variante'**
  String get selectVariant;

  /// No description provided for @scanToPay.
  ///
  /// In fr, this message translates to:
  /// **'Scanner pour payer'**
  String get scanToPay;

  /// No description provided for @grandTotal.
  ///
  /// In fr, this message translates to:
  /// **'TOTAL GÉNÉRAL'**
  String get grandTotal;

  /// No description provided for @saveOnly.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer uniquement'**
  String get saveOnly;

  /// No description provided for @printReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer Reçu'**
  String get printReceipt;

  /// No description provided for @successOrder.
  ///
  /// In fr, this message translates to:
  /// **'Commande validée et sauvegardée avec succès !'**
  String get successOrder;

  /// No description provided for @stockAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes de Stock'**
  String get stockAlerts;

  /// No description provided for @revenueRecap.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif Chiffre d\'Affaires'**
  String get revenueRecap;

  /// No description provided for @recentHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique récent'**
  String get recentHistory;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette Semaine'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce Mois'**
  String get thisMonth;

  /// No description provided for @noData.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de données'**
  String get noData;

  /// No description provided for @recentSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes récentes'**
  String get recentSales;

  /// No description provided for @sold.
  ///
  /// In fr, this message translates to:
  /// **'vendu'**
  String get sold;

  /// No description provided for @deleteProduct.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le produit'**
  String get deleteProduct;

  /// No description provided for @deleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer'**
  String get deleteConfirm;

  /// No description provided for @noMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit ne correspond à votre recherche.'**
  String get noMatch;

  /// No description provided for @noUsersFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun utilisateur trouvé'**
  String get noUsersFound;

  /// No description provided for @addUserHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre premier caissier pour commencer.'**
  String get addUserHint;

  /// No description provided for @deleteUser.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'utilisateur'**
  String get deleteUser;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer le compte'**
  String get createAccount;

  /// No description provided for @updateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get updateAccount;

  /// No description provided for @orderHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des Ventes'**
  String get orderHistory;

  /// No description provided for @noSalesRecorded.
  ///
  /// In fr, this message translates to:
  /// **'Aucune vente enregistrée ce jour.'**
  String get noSalesRecorded;

  /// No description provided for @paymentMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode de paiement'**
  String get paymentMode;

  /// No description provided for @exportCAReport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter le Rapport CA'**
  String get exportCAReport;

  /// No description provided for @reviewOrder.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier la commande'**
  String get reviewOrder;

  /// No description provided for @scannedItems.
  ///
  /// In fr, this message translates to:
  /// **'Articles scannés'**
  String get scannedItems;

  /// No description provided for @itemsTotal.
  ///
  /// In fr, this message translates to:
  /// **'articles au total'**
  String get itemsTotal;

  /// No description provided for @totalPrice.
  ///
  /// In fr, this message translates to:
  /// **'PRIX TOTAL'**
  String get totalPrice;

  /// No description provided for @emptyList.
  ///
  /// In fr, this message translates to:
  /// **'La liste est vide'**
  String get emptyList;

  /// No description provided for @scanInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Les articles scannés apparaîtront ici au fur et à mesure que vous les scannez avec la caméra ci-dessus.'**
  String get scanInstruction;

  /// No description provided for @cameraOff.
  ///
  /// In fr, this message translates to:
  /// **'La caméra est éteinte'**
  String get cameraOff;

  /// No description provided for @cameraOffInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Activez votre caméra pour commencer à scanner les codes-barres automatiquement.'**
  String get cameraOffInstruction;

  /// No description provided for @turnOnCamera.
  ///
  /// In fr, this message translates to:
  /// **'Activer la caméra'**
  String get turnOnCamera;

  /// No description provided for @onHoldCart.
  ///
  /// In fr, this message translates to:
  /// **'Panier en attente'**
  String get onHoldCart;

  /// No description provided for @shopDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails de la Boutique'**
  String get shopDetails;

  /// No description provided for @generalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations Générales'**
  String get generalInfo;

  /// No description provided for @shopInfoInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Ces détails apparaîtront sur vos reçus numériques et imprimés.'**
  String get shopInfoInstruction;

  /// No description provided for @shopName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la boutique'**
  String get shopName;

  /// No description provided for @addressLine1.
  ///
  /// In fr, this message translates to:
  /// **'Adresse Ligne 1'**
  String get addressLine1;

  /// No description provided for @addressLine2.
  ///
  /// In fr, this message translates to:
  /// **'Adresse Ligne 2 (Optionnel)'**
  String get addressLine2;

  /// No description provided for @receiptFooter.
  ///
  /// In fr, this message translates to:
  /// **'Texte de pied de page du reçu'**
  String get receiptFooter;

  /// No description provided for @saveDetails.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les détails'**
  String get saveDetails;

  /// No description provided for @shopDetailsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Détails de la boutique enregistrés !'**
  String get shopDetailsSaved;

  /// No description provided for @addProduct.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un produit'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le produit'**
  String get editProduct;

  /// No description provided for @initialStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock Initial'**
  String get initialStock;

  /// No description provided for @alertThreshold.
  ///
  /// In fr, this message translates to:
  /// **'Seuil d\'alerte'**
  String get alertThreshold;

  /// No description provided for @variants.
  ///
  /// In fr, this message translates to:
  /// **'Variantes (Taille, Couleur, etc.)'**
  String get variants;

  /// No description provided for @addVariant.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une variante'**
  String get addVariant;

  /// No description provided for @barcodeExists.
  ///
  /// In fr, this message translates to:
  /// **'Le produit avec le code-barres existe déjà !'**
  String get barcodeExists;

  /// No description provided for @enterBarcode.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un code-barres'**
  String get enterBarcode;

  /// No description provided for @enterName.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un nom'**
  String get enterName;

  /// No description provided for @required.
  ///
  /// In fr, this message translates to:
  /// **'Requis'**
  String get required;

  /// No description provided for @saveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get saveChanges;

  /// No description provided for @stockQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité en stock'**
  String get stockQuantity;

  /// No description provided for @scanBarcode.
  ///
  /// In fr, this message translates to:
  /// **'Scanner le code-barres'**
  String get scanBarcode;

  /// No description provided for @alignBarcode.
  ///
  /// In fr, this message translates to:
  /// **'Aligner le code-barres dans le cadre'**
  String get alignBarcode;

  /// No description provided for @priceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un prix'**
  String get priceRequired;

  /// No description provided for @validNumberRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un nombre valide'**
  String get validNumberRequired;

  /// No description provided for @positivePriceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le prix ne peut pas être négatif'**
  String get positivePriceRequired;

  /// No description provided for @exportFailed.
  ///
  /// In fr, this message translates to:
  /// **'L\'exportation a échoué'**
  String get exportFailed;

  /// No description provided for @importSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Importation réussie ! Base restaurée.'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In fr, this message translates to:
  /// **'L\'importation a échoué'**
  String get importFailed;

  /// No description provided for @backupSubject.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde de la base de données POS'**
  String get backupSubject;

  /// No description provided for @generatedAt.
  ///
  /// In fr, this message translates to:
  /// **'Généré le'**
  String get generatedAt;

  /// No description provided for @totalRevenue.
  ///
  /// In fr, this message translates to:
  /// **'CHIFFRE D\'AFFAIRES TOTAL'**
  String get totalRevenue;

  /// No description provided for @categoryBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'Détail par Catégorie'**
  String get categoryBreakdown;

  /// No description provided for @periodRecap.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif Périodique'**
  String get periodRecap;

  /// No description provided for @transactionList.
  ///
  /// In fr, this message translates to:
  /// **'Liste des Transactions'**
  String get transactionList;

  /// No description provided for @categoryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get categoryLabel;

  /// No description provided for @revenueLabel.
  ///
  /// In fr, this message translates to:
  /// **'CA (XAF)'**
  String get revenueLabel;

  /// No description provided for @periodLabel.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get periodLabel;

  /// No description provided for @cumulativeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Cumul (XAF)'**
  String get cumulativeLabel;

  /// No description provided for @modeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mode'**
  String get modeLabel;

  /// No description provided for @amountLabel.
  ///
  /// In fr, this message translates to:
  /// **'Montant (XAF)'**
  String get amountLabel;

  /// No description provided for @dateHeader.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get dateHeader;

  /// No description provided for @phoneNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get phoneNumber;

  /// No description provided for @upiId.
  ///
  /// In fr, this message translates to:
  /// **'ID de paiement Mobile'**
  String get upiId;

  /// No description provided for @unknownCategory.
  ///
  /// In fr, this message translates to:
  /// **'Inconnue'**
  String get unknownCategory;

  /// No description provided for @receiptFooterGratitude.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre achat !'**
  String get receiptFooterGratitude;

  /// No description provided for @receiptSubject.
  ///
  /// In fr, this message translates to:
  /// **'Reçu'**
  String get receiptSubject;

  /// No description provided for @weekLabel.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get weekLabel;

  /// No description provided for @itemsHeader.
  ///
  /// In fr, this message translates to:
  /// **'Article'**
  String get itemsHeader;

  /// No description provided for @qtyHeader.
  ///
  /// In fr, this message translates to:
  /// **'Qté'**
  String get qtyHeader;

  /// No description provided for @priceHeader.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get priceHeader;

  /// No description provided for @totalHeader.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get totalHeader;

  /// No description provided for @telLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tél'**
  String get telLabel;

  /// No description provided for @restockLabel.
  ///
  /// In fr, this message translates to:
  /// **'REAPPRO.'**
  String get restockLabel;

  /// No description provided for @itemsLabel.
  ///
  /// In fr, this message translates to:
  /// **'articles'**
  String get itemsLabel;

  /// No description provided for @backup.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde'**
  String get backup;

  /// No description provided for @exportJson.
  ///
  /// In fr, this message translates to:
  /// **'Exporter (JSON)'**
  String get exportJson;

  /// No description provided for @importJson.
  ///
  /// In fr, this message translates to:
  /// **'Importer (JSON)'**
  String get importJson;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// No description provided for @themeColor.
  ///
  /// In fr, this message translates to:
  /// **'Couleur du thême'**
  String get themeColor;

  /// No description provided for @selectAccentColor.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la couleur d\'accentuation'**
  String get selectAccentColor;

  /// No description provided for @warning.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get warning;

  /// No description provided for @overwriteWarning.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr ? Cela écrasera vos données actuelles.'**
  String get overwriteWarning;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
