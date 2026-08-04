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

  /// No description provided for @owner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get owner;

  /// No description provided for @stockManager.
  ///
  /// In fr, this message translates to:
  /// **'Gestionnaire de Stock'**
  String get stockManager;

  /// No description provided for @newUserBtn.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel utilisateur'**
  String get newUserBtn;

  /// No description provided for @city.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get city;

  /// No description provided for @district.
  ///
  /// In fr, this message translates to:
  /// **'Quartier / Arrondissement'**
  String get district;

  /// No description provided for @shopTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type de boutique'**
  String get shopTypeLabel;

  /// No description provided for @orangeMoneyCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Marchand Orange Money'**
  String get orangeMoneyCode;

  /// No description provided for @mtnMomoCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Marchand MTN MoMo'**
  String get mtnMomoCode;

  /// No description provided for @taxId.
  ///
  /// In fr, this message translates to:
  /// **'N° Contribuable (Optionnel)'**
  String get taxId;

  /// No description provided for @mobilePaymentSection.
  ///
  /// In fr, this message translates to:
  /// **'Paiements Mobile Money'**
  String get mobilePaymentSection;

  /// No description provided for @momoCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: CM-237-XXXXXX'**
  String get momoCodeHint;

  /// No description provided for @shopTypeEpicerie.
  ///
  /// In fr, this message translates to:
  /// **'Épicerie'**
  String get shopTypeEpicerie;

  /// No description provided for @shopTypeSupermarche.
  ///
  /// In fr, this message translates to:
  /// **'Supermarché'**
  String get shopTypeSupermarche;

  /// No description provided for @shopTypePharmacie.
  ///
  /// In fr, this message translates to:
  /// **'Pharmacie'**
  String get shopTypePharmacie;

  /// No description provided for @shopTypeBoulangerie.
  ///
  /// In fr, this message translates to:
  /// **'Boulangerie / Pâtisserie'**
  String get shopTypeBoulangerie;

  /// No description provided for @shopTypeQuincaillerie.
  ///
  /// In fr, this message translates to:
  /// **'Quincaillerie'**
  String get shopTypeQuincaillerie;

  /// No description provided for @shopTypeRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant / Fast-food'**
  String get shopTypeRestaurant;

  /// No description provided for @shopTypeVetements.
  ///
  /// In fr, this message translates to:
  /// **'Vêtements / Textiles'**
  String get shopTypeVetements;

  /// No description provided for @shopTypeInformatique.
  ///
  /// In fr, this message translates to:
  /// **'Informatique / Électronique'**
  String get shopTypeInformatique;

  /// No description provided for @shopTypeAutre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get shopTypeAutre;

  /// No description provided for @orangeMoney.
  ///
  /// In fr, this message translates to:
  /// **'Orange Money'**
  String get orangeMoney;

  /// No description provided for @mtnMomo.
  ///
  /// In fr, this message translates to:
  /// **'MTN MoMo'**
  String get mtnMomo;

  /// No description provided for @cashReceived.
  ///
  /// In fr, this message translates to:
  /// **'Montant reçu'**
  String get cashReceived;

  /// No description provided for @changeGiven.
  ///
  /// In fr, this message translates to:
  /// **'Monnaie à rendre'**
  String get changeGiven;

  /// No description provided for @momoMerchantCode.
  ///
  /// In fr, this message translates to:
  /// **'Code marchand'**
  String get momoMerchantCode;

  /// No description provided for @momoPayInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Demandez au client de composer ce code sur son téléphone'**
  String get momoPayInstruction;

  /// No description provided for @insufficientCash.
  ///
  /// In fr, this message translates to:
  /// **'Montant insuffisant'**
  String get insufficientCash;

  /// No description provided for @pinLocked.
  ///
  /// In fr, this message translates to:
  /// **'Accès bloqué après 3 tentatives. Réessayez dans 30 secondes.'**
  String get pinLocked;

  /// No description provided for @attemptsLeft.
  ///
  /// In fr, this message translates to:
  /// **'tentative(s) restante(s)'**
  String get attemptsLeft;

  /// No description provided for @momoPaymentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement Mobile Money'**
  String get momoPaymentTitle;

  /// No description provided for @enterCustomerPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro du client'**
  String get enterCustomerPhone;

  /// No description provided for @phoneHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 2376XXXXXXXX'**
  String get phoneHint;

  /// No description provided for @initiatePayment.
  ///
  /// In fr, this message translates to:
  /// **'Initier le paiement'**
  String get initiatePayment;

  /// No description provided for @waitingForPayment.
  ///
  /// In fr, this message translates to:
  /// **'En attente du paiement...'**
  String get waitingForPayment;

  /// No description provided for @paymentConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Paiement confirmé !'**
  String get paymentConfirmed;

  /// No description provided for @paymentFailed.
  ///
  /// In fr, this message translates to:
  /// **'Paiement échoué'**
  String get paymentFailed;

  /// No description provided for @enterRefManually.
  ///
  /// In fr, this message translates to:
  /// **'Saisir la référence manuellement'**
  String get enterRefManually;

  /// No description provided for @transactionRef.
  ///
  /// In fr, this message translates to:
  /// **'Référence de transaction'**
  String get transactionRef;

  /// No description provided for @manualConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer manuellement'**
  String get manualConfirmation;

  /// No description provided for @cancelPayment.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le paiement'**
  String get cancelPayment;

  /// No description provided for @dialUssdCode.
  ///
  /// In fr, this message translates to:
  /// **'Le client doit composer ce code'**
  String get dialUssdCode;

  /// No description provided for @mtnApiConfig.
  ///
  /// In fr, this message translates to:
  /// **'Configuration API MTN MoMo'**
  String get mtnApiConfig;

  /// No description provided for @apiUserIdLabel.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur API (UUID)'**
  String get apiUserIdLabel;

  /// No description provided for @apiKeyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Clé API'**
  String get apiKeyLabel;

  /// No description provided for @subscriptionKeyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Clé d\'abonnement'**
  String get subscriptionKeyLabel;

  /// No description provided for @targetEnvironment.
  ///
  /// In fr, this message translates to:
  /// **'Environnement'**
  String get targetEnvironment;

  /// No description provided for @sandboxMode.
  ///
  /// In fr, this message translates to:
  /// **'Sandbox (Test)'**
  String get sandboxMode;

  /// No description provided for @productionMode.
  ///
  /// In fr, this message translates to:
  /// **'Production'**
  String get productionMode;

  /// No description provided for @apiConfigSaved.
  ///
  /// In fr, this message translates to:
  /// **'Configuration API sauvegardée !'**
  String get apiConfigSaved;

  /// No description provided for @stockMovements.
  ///
  /// In fr, this message translates to:
  /// **'Mouvements de Stock'**
  String get stockMovements;

  /// No description provided for @movementsHistory.
  ///
  /// In fr, this message translates to:
  /// **'Mouvements'**
  String get movementsHistory;

  /// No description provided for @addRestock.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter mouvement'**
  String get addRestock;

  /// No description provided for @movementType.
  ///
  /// In fr, this message translates to:
  /// **'Type de mouvement'**
  String get movementType;

  /// No description provided for @moveSaleOut.
  ///
  /// In fr, this message translates to:
  /// **'Vente'**
  String get moveSaleOut;

  /// No description provided for @moveManualOut.
  ///
  /// In fr, this message translates to:
  /// **'Sortie manuelle'**
  String get moveManualOut;

  /// No description provided for @moveRestockIn.
  ///
  /// In fr, this message translates to:
  /// **'Réapprovisionnement'**
  String get moveRestockIn;

  /// No description provided for @moveAdjustIn.
  ///
  /// In fr, this message translates to:
  /// **'Ajustement +'**
  String get moveAdjustIn;

  /// No description provided for @moveAdjustOut.
  ///
  /// In fr, this message translates to:
  /// **'Ajustement −'**
  String get moveAdjustOut;

  /// No description provided for @moveReturnIn.
  ///
  /// In fr, this message translates to:
  /// **'Retour client'**
  String get moveReturnIn;

  /// No description provided for @supplier.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur'**
  String get supplier;

  /// No description provided for @suppliers.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseurs'**
  String get suppliers;

  /// No description provided for @addSupplier.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un fournisseur'**
  String get addSupplier;

  /// No description provided for @unitCost.
  ///
  /// In fr, this message translates to:
  /// **'Prix d\'achat unitaire'**
  String get unitCost;

  /// No description provided for @quantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get quantity;

  /// No description provided for @note.
  ///
  /// In fr, this message translates to:
  /// **'Note / Raison'**
  String get note;

  /// No description provided for @noMovements.
  ///
  /// In fr, this message translates to:
  /// **'Aucun mouvement enregistré'**
  String get noMovements;

  /// No description provided for @cashClosure.
  ///
  /// In fr, this message translates to:
  /// **'Clôture de Caisse'**
  String get cashClosure;

  /// No description provided for @closeCashRegister.
  ///
  /// In fr, this message translates to:
  /// **'Clôturer la caisse'**
  String get closeCashRegister;

  /// No description provided for @cashClosureTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif de Caisse'**
  String get cashClosureTitle;

  /// No description provided for @periodFrom.
  ///
  /// In fr, this message translates to:
  /// **'Depuis'**
  String get periodFrom;

  /// No description provided for @tvaLabel.
  ///
  /// In fr, this message translates to:
  /// **'TVA 19,25%'**
  String get tvaLabel;

  /// No description provided for @totalHTax.
  ///
  /// In fr, this message translates to:
  /// **'Total HT'**
  String get totalHTax;

  /// No description provided for @totalATax.
  ///
  /// In fr, this message translates to:
  /// **'Total TTC'**
  String get totalATax;

  /// No description provided for @closureSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Clôture enregistrée avec succès !'**
  String get closureSuccess;

  /// No description provided for @lastClosure.
  ///
  /// In fr, this message translates to:
  /// **'Historique des clôtures'**
  String get lastClosure;

  /// No description provided for @noClosure.
  ///
  /// In fr, this message translates to:
  /// **'Aucune clôture précédente'**
  String get noClosure;

  /// No description provided for @cashClosureConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Cette action enregistre la clôture de caisse. Continuer ?'**
  String get cashClosureConfirm;

  /// No description provided for @cloudSync.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation Cloud'**
  String get cloudSync;

  /// No description provided for @cloudConfigSaved.
  ///
  /// In fr, this message translates to:
  /// **'Configuration cloud sauvegardée !'**
  String get cloudConfigSaved;

  /// No description provided for @cloudConnected.
  ///
  /// In fr, this message translates to:
  /// **'Cloud connecté'**
  String get cloudConnected;

  /// No description provided for @cloudDisconnected.
  ///
  /// In fr, this message translates to:
  /// **'Cloud déconnecté'**
  String get cloudDisconnected;

  /// No description provided for @setupSupabase.
  ///
  /// In fr, this message translates to:
  /// **'Configurer Supabase'**
  String get setupSupabase;

  /// No description provided for @supabaseHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez l\'URL et la clé anon de votre projet Supabase'**
  String get supabaseHint;

  /// No description provided for @cloudUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL Supabase'**
  String get cloudUrl;

  /// No description provided for @anonKey.
  ///
  /// In fr, this message translates to:
  /// **'Clé anonyme (anon key)'**
  String get anonKey;

  /// No description provided for @ownerEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail propriétaire'**
  String get ownerEmail;

  /// No description provided for @ownerPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get ownerPassword;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get signOut;

  /// No description provided for @ownerSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Connexion propriétaire'**
  String get ownerSignIn;

  /// No description provided for @ownerSignInHint.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour activer la synchronisation'**
  String get ownerSignInHint;

  /// No description provided for @syncNow.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser'**
  String get syncNow;

  /// No description provided for @pullFromCloud.
  ///
  /// In fr, this message translates to:
  /// **'Récupérer du cloud'**
  String get pullFromCloud;

  /// No description provided for @lastSynced.
  ///
  /// In fr, this message translates to:
  /// **'Dernière synchro'**
  String get lastSynced;

  /// No description provided for @autoSync.
  ///
  /// In fr, this message translates to:
  /// **'Synchro auto'**
  String get autoSync;

  /// No description provided for @syncSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation réussie !'**
  String get syncSuccess;

  /// No description provided for @syncError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de synchro'**
  String get syncError;

  /// No description provided for @cloudAuthError.
  ///
  /// In fr, this message translates to:
  /// **'E-mail ou mot de passe incorrect'**
  String get cloudAuthError;

  /// No description provided for @sqlSchema.
  ///
  /// In fr, this message translates to:
  /// **'Schéma SQL (à exécuter dans Supabase)'**
  String get sqlSchema;

  /// No description provided for @copied.
  ///
  /// In fr, this message translates to:
  /// **'Copié !'**
  String get copied;

  /// No description provided for @appSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion de caisse & stock'**
  String get appSubtitle;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à votre boutique'**
  String get loginSubtitle;

  /// No description provided for @emailAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get noAccount;

  /// No description provided for @alreadyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get alreadyAccount;

  /// No description provided for @createBoutique.
  ///
  /// In fr, this message translates to:
  /// **'Créer ma boutique'**
  String get createBoutique;

  /// No description provided for @ownerInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations propriétaire'**
  String get ownerInfo;

  /// No description provided for @ownerName.
  ///
  /// In fr, this message translates to:
  /// **'Votre nom complet'**
  String get ownerName;

  /// No description provided for @boutiqueInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations boutique'**
  String get boutiqueInfo;

  /// No description provided for @loginError.
  ///
  /// In fr, this message translates to:
  /// **'E-mail ou mot de passe incorrect'**
  String get loginError;

  /// No description provided for @noShopMembership.
  ///
  /// In fr, this message translates to:
  /// **'Aucune boutique associée. Contactez le propriétaire.'**
  String get noShopMembership;

  /// No description provided for @requiredFields.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez remplir tous les champs'**
  String get requiredFields;

  /// No description provided for @passwordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordMismatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 6 caractères'**
  String get passwordTooShort;

  /// No description provided for @employeeEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail de l\'employé'**
  String get employeeEmail;

  /// No description provided for @tempPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe temporaire'**
  String get tempPassword;

  /// No description provided for @createEmployee.
  ///
  /// In fr, this message translates to:
  /// **'Créer le compte'**
  String get createEmployee;

  /// No description provided for @employeeCreated.
  ///
  /// In fr, this message translates to:
  /// **'Compte employé créé avec succès !'**
  String get employeeCreated;

  /// No description provided for @deleteEmployeeConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce compte ? Cette action est irréversible.'**
  String get deleteEmployeeConfirm;

  /// No description provided for @addBoutique.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une boutique'**
  String get addBoutique;

  /// No description provided for @outOfStock.
  ///
  /// In fr, this message translates to:
  /// **'Rupture de stock'**
  String get outOfStock;

  /// No description provided for @outOfStockMsg.
  ///
  /// In fr, this message translates to:
  /// **'{name} : produit épuisé'**
  String outOfStockMsg(String name);

  /// No description provided for @insufficientStock.
  ///
  /// In fr, this message translates to:
  /// **'{name} : stock insuffisant (max {max})'**
  String insufficientStock(String name, int max);

  /// No description provided for @onboardingTitle1.
  ///
  /// In fr, this message translates to:
  /// **'Modernité et Rapidité'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez Gestock+, votre nouvelle caisse enregistreuse et gestionnaire de stock ultra-rapide.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In fr, this message translates to:
  /// **'Vente et Inventaire'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In fr, this message translates to:
  /// **'Scannez vos articles, suivez vos stocks en temps réel et générez des reçus professionnels.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In fr, this message translates to:
  /// **'Fiabilité Hors-Ligne'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In fr, this message translates to:
  /// **'Continuez à vendre même sans internet. Tout se synchronise automatiquement au retour de la connexion !'**
  String get onboardingDesc3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In fr, this message translates to:
  /// **'Accepter Mobile Money'**
  String get onboardingTitle4;

  /// No description provided for @onboardingDesc4.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez vos paiements via Orange Money, MTN MoMo et plus en toute simplicité.'**
  String get onboardingDesc4;

  /// No description provided for @skip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get previous;

  /// No description provided for @finish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get finish;

  /// No description provided for @stepProgress.
  ///
  /// In fr, this message translates to:
  /// **'Étape {current} sur {total}'**
  String stepProgress(int current, int total);

  /// No description provided for @genericError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur s\'est produite, veuillez vérifier votre connexion et réessayer plus tard.'**
  String get genericError;

  /// No description provided for @helpCenter.
  ///
  /// In fr, this message translates to:
  /// **'Centre d\'Aide'**
  String get helpCenter;

  /// No description provided for @helpGuideTitle.
  ///
  /// In fr, this message translates to:
  /// **'Guide de configuration Gestock+'**
  String get helpGuideTitle;

  /// No description provided for @helpGuideDesc.
  ///
  /// In fr, this message translates to:
  /// **'Retrouvez ici les étapes indispensables pour configurer et utiliser l\'application selon vos droits.'**
  String get helpGuideDesc;

  /// No description provided for @keySteps.
  ///
  /// In fr, this message translates to:
  /// **'Vos étapes clés'**
  String get keySteps;

  /// No description provided for @guidedTour.
  ///
  /// In fr, this message translates to:
  /// **'Visite guidée interactive 🎬'**
  String get guidedTour;

  /// No description provided for @guidedTourDesc.
  ///
  /// In fr, this message translates to:
  /// **'Lancer le projecteur visuel pas-à-pas sur votre tableau de bord.'**
  String get guidedTourDesc;

  /// No description provided for @stepOwner1Title.
  ///
  /// In fr, this message translates to:
  /// **'Ajout de vos Produits'**
  String get stepOwner1Title;

  /// No description provided for @stepOwner1Desc.
  ///
  /// In fr, this message translates to:
  /// **'Allez dans \"Inventaire\" ou \"Produits\". Cliquez sur le bouton \"+\" pour ajouter vos articles avec leur prix d\'achat, prix de vente et niveau de stock initial.'**
  String get stepOwner1Desc;

  /// No description provided for @stepOwner2Title.
  ///
  /// In fr, this message translates to:
  /// **'Faire un Test de Vente'**
  String get stepOwner2Title;

  /// No description provided for @stepOwner2Desc.
  ///
  /// In fr, this message translates to:
  /// **'Allez sur l\'onglet \"Caisse\" (ou Ventes). Touchez vos produits pour les ajouter au panier. Validez la vente et choisissez le mode de règlement.'**
  String get stepOwner2Desc;

  /// No description provided for @stepOwner3Title.
  ///
  /// In fr, this message translates to:
  /// **'Configuration du Matériel'**
  String get stepOwner3Title;

  /// No description provided for @stepOwner3Desc.
  ///
  /// In fr, this message translates to:
  /// **'Accédez aux \"Paramètres\". Vous pourrez y jumeler votre imprimante de caisse thermique Bluetooth et personnaliser le texte de pied de page de vos reçus imprimés.'**
  String get stepOwner3Desc;

  /// No description provided for @stepOwner4Title.
  ///
  /// In fr, this message translates to:
  /// **'Ajout des Employés'**
  String get stepOwner4Title;

  /// No description provided for @stepOwner4Desc.
  ///
  /// In fr, this message translates to:
  /// **'Dans les \"Paramètres\", cliquez sur \"Gestion employés\" pour ajouter des comptes de Caissiers ou Gestionnaires de stock et leur assigner des droits spécifiques.'**
  String get stepOwner4Desc;

  /// No description provided for @spotlightHeaderTitle.
  ///
  /// In fr, this message translates to:
  /// **'En-tête Gestock+'**
  String get spotlightHeaderTitle;

  /// No description provided for @spotlightHeaderDesc.
  ///
  /// In fr, this message translates to:
  /// **'Voici le logo de votre application de caisse et votre centre de notifications pour rester alerté.'**
  String get spotlightHeaderDesc;

  /// No description provided for @spotlightSalesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques des Ventes'**
  String get spotlightSalesTitle;

  /// No description provided for @spotlightSalesDesc.
  ///
  /// In fr, this message translates to:
  /// **'Visualisez en temps réel votre chiffre d\'affaires journalier, le nombre de ventes et l\'évolution par rapport à la veille.'**
  String get spotlightSalesDesc;

  /// No description provided for @spotlightSubTitle.
  ///
  /// In fr, this message translates to:
  /// **'Statut de l\'Abonnement'**
  String get spotlightSubTitle;

  /// No description provided for @spotlightSubDesc.
  ///
  /// In fr, this message translates to:
  /// **'Suivez le statut de votre licence Gestock+ et accédez aux offres pour débloquer toutes les fonctionnalités.'**
  String get spotlightSubDesc;

  /// No description provided for @spotlightQuickTitle.
  ///
  /// In fr, this message translates to:
  /// **'Raccourcis d\'Actions Rapides'**
  String get spotlightQuickTitle;

  /// No description provided for @spotlightQuickDesc.
  ///
  /// In fr, this message translates to:
  /// **'Accédez rapidement à la caisse de vente, à l\'inventaire des produits, à la configuration de vos imprimantes ou à la gestion des employés.'**
  String get spotlightQuickDesc;

  /// No description provided for @stepCashier1Title.
  ///
  /// In fr, this message translates to:
  /// **'Effectuer un Test de Vente'**
  String get stepCashier1Title;

  /// No description provided for @stepCashier1Desc.
  ///
  /// In fr, this message translates to:
  /// **'Allez sur la caisse, scannez ou ajoutez des articles au panier puis encaissez le règlement.'**
  String get stepCashier1Desc;

  /// No description provided for @stepCashier2Title.
  ///
  /// In fr, this message translates to:
  /// **'Associer votre Imprimante Bluetooth'**
  String get stepCashier2Title;

  /// No description provided for @stepCashier2Desc.
  ///
  /// In fr, this message translates to:
  /// **'Jumelez votre imprimante thermique Bluetooth pour imprimer des reçus physiques pour vos clients.'**
  String get stepCashier2Desc;

  /// No description provided for @stepCashier3Title.
  ///
  /// In fr, this message translates to:
  /// **'Consulter l\'Historique de vos Ventes'**
  String get stepCashier3Title;

  /// No description provided for @stepCashier3Desc.
  ///
  /// In fr, this message translates to:
  /// **'Accédez à l\'historique de vos facturations pour faire le point sur vos ventes journalières ou ré-imprimer un reçu.'**
  String get stepCashier3Desc;

  /// No description provided for @stepManager1Title.
  ///
  /// In fr, this message translates to:
  /// **'Consulter l\'État des Stocks'**
  String get stepManager1Title;

  /// No description provided for @stepManager1Desc.
  ///
  /// In fr, this message translates to:
  /// **'Accédez à l\'inventaire complet pour surveiller les quantités de vos articles et repérer les alertes de stock minimal.'**
  String get stepManager1Desc;

  /// No description provided for @stepManager2Title.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des Entrées/Sorties de Stock'**
  String get stepManager2Title;

  /// No description provided for @stepManager2Desc.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez les nouveaux approvisionnements, les pertes ou les ajustements manuels d\'inventaire.'**
  String get stepManager2Desc;

  /// No description provided for @stepManager3Title.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un Fournisseur'**
  String get stepManager3Title;

  /// No description provided for @stepManager3Desc.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez vos fournisseurs partenaires pour mieux assurer le suivi de vos bons de commande et entrées d\'inventaire.'**
  String get stepManager3Desc;

  /// No description provided for @quickStartGuide.
  ///
  /// In fr, this message translates to:
  /// **'Guide de démarrage rapide'**
  String get quickStartGuide;

  /// No description provided for @hide.
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get hide;

  /// No description provided for @congratulations.
  ///
  /// In fr, this message translates to:
  /// **'Félicitations ! 🎉'**
  String get congratulations;

  /// No description provided for @allStepsCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez complété l\'ensemble des étapes clés de configuration.'**
  String get allStepsCompleted;

  /// No description provided for @continueToPayment.
  ///
  /// In fr, this message translates to:
  /// **'Continuer vers paiement'**
  String get continueToPayment;

  /// No description provided for @putOnHold.
  ///
  /// In fr, this message translates to:
  /// **'Mettre en attente'**
  String get putOnHold;

  /// No description provided for @paymentTimeoutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement Mobile Money expiré'**
  String get paymentTimeoutTitle;

  /// No description provided for @paymentTimeoutBody.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement de {amount} FCFA est resté en attente pendant 15 minutes et a été annulé.'**
  String paymentTimeoutBody(Object amount);

  /// No description provided for @pendingPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en cours...'**
  String get pendingPayment;

  /// No description provided for @inventoryReport.
  ///
  /// In fr, this message translates to:
  /// **'Rapport d\'Inventaire'**
  String get inventoryReport;

  /// No description provided for @selectPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner la période'**
  String get selectPeriod;

  /// No description provided for @customPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période Personnalisée...'**
  String get customPeriod;

  /// No description provided for @periodOverview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu de la période'**
  String get periodOverview;

  /// No description provided for @downloadReport.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le Rapport'**
  String get downloadReport;

  /// No description provided for @exportPdf.
  ///
  /// In fr, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @exportExcel.
  ///
  /// In fr, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// No description provided for @movements.
  ///
  /// In fr, this message translates to:
  /// **'Mouvements'**
  String get movements;

  /// No description provided for @entries.
  ///
  /// In fr, this message translates to:
  /// **'Entrées'**
  String get entries;

  /// No description provided for @exits.
  ///
  /// In fr, this message translates to:
  /// **'Sorties'**
  String get exits;
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
