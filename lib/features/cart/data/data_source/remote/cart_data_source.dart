import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app/core/error/failure.dart';
import 'package:e_commerce_app/features/e_commerce_clean/data/models/product_model.dart';

abstract class CartDataSource {
  Future<Either<Failure, Unit>> addToCart(String userId, ProductModel product);
  Future<Either<Failure, bool>> checkAdded(String userId, ProductModel product);
  Future<Either<Failure, Unit>> deleteFromCart(String userId, ProductModel product);
  Future<Either<Failure, List<ProductModel>>> getCartProducts(String userId);
}

class FireStore implements CartDataSource {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Future<Either<Failure, Unit>> addToCart(String userId, ProductModel product) async {
    try {
      DocumentReference userCartRef = firestore.collection('carts').doc(userId);
      DocumentSnapshot userCartSnapshot = await userCartRef.get();

      if (!userCartSnapshot.exists) {
        await userCartRef.set({'productsId': []});
      }

      await userCartRef.update({
        'productsId': FieldValue.arrayUnion([product.toJson()])
      });
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteFromCart(String userId, ProductModel product) async {
    try {
      DocumentReference userCartRef = firestore.collection('carts').doc(userId);
      DocumentSnapshot userCartSnapshot = await userCartRef.get();

      if (!userCartSnapshot.exists || userCartSnapshot.data() == null) {
        return const Left(DatabaseFailure("Cart not found"));
      }

      await userCartRef.update({
        'productsId': FieldValue.arrayRemove([product.toJson()])
      });
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductModel>>> getCartProducts(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> data =
          await firestore.collection('carts').doc(userId).get();

      if (!data.exists || data.data() == null || !data.data()!.containsKey('productsId')) {
        return const Left(DatabaseFailure("Cart not found"));
      }

      List<dynamic> productsDataList = data.data()!['productsId'] as List<dynamic>;
      List<ProductModel> products = productsDataList.map((productData) => ProductModel.fromJson(productData)).toList();

      return Right(products);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkAdded(String userId, ProductModel product) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> data =
          await firestore.collection('carts').doc(userId).get();

      if (!data.exists || data.data() == null || !data.data()!.containsKey('productsId')) {
        return const Right(false);
      }

      List<dynamic> productsList = data.data()!['productsId'] as List<dynamic>;
      bool isAdded = productsList.any((p) => p['id'] == product.id);

      return Right(isAdded);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}