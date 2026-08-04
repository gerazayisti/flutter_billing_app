import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/shop_repository.dart';
import '../models/shop_model.dart';

class ShopRepositoryImpl implements ShopRepository {
  static const String shopKey = 'shop_details';

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<Either<Failure, Shop>> getShop() async {
    try {
      final box = HiveDatabase.shopBox;
      Shop? shop = box.get(shopKey);

      // Tenter de charger les informations à jour depuis la BD Supabase 'shops'
      try {
        final user = _client.auth.currentUser;
        if (user != null) {
          final memberRow = await _client
              .from('shop_members')
              .select('shop_id')
              .eq('user_id', user.id)
              .maybeSingle();

          final shopId = memberRow?['shop_id'] as String? ??
              (HiveDatabase.settingsBox.get('cloud_shop_id') as String?);

          if (shopId != null && shopId.isNotEmpty) {
            final shopRow = await _client
                .from('shops')
                .select()
                .eq('id', shopId)
                .maybeSingle();

            if (shopRow != null) {
              final remoteShop = Shop(
                name: shopRow['name'] as String? ?? '',
                addressLine1: shopRow['address1'] as String? ?? '',
                addressLine2: shopRow['address2'] as String? ?? '',
                phoneNumber: shopRow['phone'] as String? ?? '',
                upiId: shopRow['upi_id'] as String? ?? '',
                city: shopRow['city'] as String? ?? '',
                district: shopRow['district'] as String? ?? '',
                shopType: shopRow['shop_type'] as String? ?? '',
                taxId: shopRow['tax_id'] as String? ?? '',
                orangeMoneyMerchant: shopRow['orange_merchant'] as String? ?? '',
                mtnMomoMerchant: shopRow['mtn_merchant'] as String? ?? '',
                footerText: shopRow['receipt_footer'] as String? ?? '',
              );
              shop = remoteShop;
              await box.put(shopKey, ShopModel.fromEntity(remoteShop));
            }
          }
        }
      } catch (_) {}

      if (shop != null) {
        return Right(shop);
      } else {
        return const Right(Shop(
            name: 'G-SHOP',
            addressLine1: 'Ngoa-ekele, yaounde,cameroun',
            addressLine2: 'nope',
            phoneNumber: '+237695183768',
            upiId: 'gerazayisti@gmail.com',
            footerText: 'Merci pour votre achat !!!'));
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateShop(Shop shop) async {
    try {
      final box = HiveDatabase.shopBox;
      final model = ShopModel.fromEntity(shop);
      await box.put(shopKey, model);

      // Synchroniser immédiatement les modifications dans la table Supabase 'shops'
      try {
        final user = _client.auth.currentUser;
        if (user != null) {
          final memberRow = await _client
              .from('shop_members')
              .select('shop_id')
              .eq('user_id', user.id)
              .maybeSingle();

          final shopId = memberRow?['shop_id'] as String? ??
              (HiveDatabase.settingsBox.get('cloud_shop_id') as String?);

          if (shopId != null && shopId.isNotEmpty) {
            await _client.from('shops').update({
              'name': shop.name,
              'address1': shop.addressLine1,
              'address2': shop.addressLine2,
              'phone': shop.phoneNumber,
              'upi_id': shop.upiId,
              'city': shop.city,
              'district': shop.district,
              'shop_type': shop.shopType,
              'tax_id': shop.taxId,
              'orange_merchant': shop.orangeMoneyMerchant,
              'mtn_merchant': shop.mtnMomoMerchant,
              'receipt_footer': shop.footerText,
            }).eq('id', shopId);
          }
        }
      } catch (e) {
        print('Erreur mise à jour Supabase shops: $e');
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
