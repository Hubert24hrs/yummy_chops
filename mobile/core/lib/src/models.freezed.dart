// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GeoPoint {

 double get lat; double get lng;
/// Create a copy of GeoPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeoPointCopyWith<GeoPoint> get copyWith => _$GeoPointCopyWithImpl<GeoPoint>(this as GeoPoint, _$identity);

  /// Serializes this GeoPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GeoPoint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeoPoint&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.lng, _this.lng) || other.lng == _this.lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GeoPoint;
  return Object.hash(runtimeType,_this.lat,_this.lng);
}

@override
String toString() {
  final _this = this as GeoPoint;
  return 'GeoPoint(lat: ${_this.lat}, lng: ${_this.lng})';
}


}

/// @nodoc
abstract mixin class $GeoPointCopyWith<$Res>  {
  factory $GeoPointCopyWith(GeoPoint value, $Res Function(GeoPoint) _then) = _$GeoPointCopyWithImpl;
@useResult
$Res call({
 double lat, double lng
});




}
/// @nodoc
class _$GeoPointCopyWithImpl<$Res>
    implements $GeoPointCopyWith<$Res> {
  _$GeoPointCopyWithImpl(this._self, this._then);

  final GeoPoint _self;
  final $Res Function(GeoPoint) _then;

/// Create a copy of GeoPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,}) {
  return _then(GeoPoint(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [GeoPoint].
extension GeoPointPatterns on GeoPoint {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GeoPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GeoPoint() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GeoPoint value)  $default,){
final _that = this;
switch (_that) {
case _GeoPoint():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GeoPoint value)?  $default,){
final _that = this;
switch (_that) {
case _GeoPoint() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GeoPoint() when $default != null:
return $default(_that.lat,_that.lng);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng)  $default,) {final _that = this;
switch (_that) {
case _GeoPoint():
return $default(_that.lat,_that.lng);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng)?  $default,) {final _that = this;
switch (_that) {
case _GeoPoint() when $default != null:
return $default(_that.lat,_that.lng);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GeoPoint implements GeoPoint {
  const _GeoPoint({required this.lat, required this.lng});
  factory _GeoPoint.fromJson(Map<String, dynamic> json) => _$GeoPointFromJson(json);

@override final  double lat;
@override final  double lng;

/// Create a copy of GeoPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GeoPointCopyWith<_GeoPoint> get copyWith => __$GeoPointCopyWithImpl<_GeoPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GeoPointToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GeoPoint&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,lat,lng);
}

@override
String toString() {
    return 'GeoPoint(lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class _$GeoPointCopyWith<$Res> implements $GeoPointCopyWith<$Res> {
  factory _$GeoPointCopyWith(_GeoPoint value, $Res Function(_GeoPoint) _then) = __$GeoPointCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng
});




}
/// @nodoc
class __$GeoPointCopyWithImpl<$Res>
    implements _$GeoPointCopyWith<$Res> {
  __$GeoPointCopyWithImpl(this._self, this._then);

  final _GeoPoint _self;
  final $Res Function(_GeoPoint) _then;

/// Create a copy of GeoPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,}) {
  return _then(_GeoPoint(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$RestaurantCard {

 String get id; String get vertical; String get city; String get name; String get description; List<String> get cuisines; String get area; double get rating; int get ratingCount; bool get isOpen; bool get isAcceptingOrders; bool get isFeatured; String? get coverUrl; double? get distanceKm; int? get etaMinutes; int? get deliveryFeeKobo; bool? get deliversToLocation; bool get supportsPickup; bool get supportsDelivery; List<PromoBadge> get promotions;/// e.g. "Shopper" on a market: someone buys the items for the customer.
 String? get badge;
/// Create a copy of RestaurantCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestaurantCardCopyWith<RestaurantCard> get copyWith => _$RestaurantCardCopyWithImpl<RestaurantCard>(this as RestaurantCard, _$identity);

  /// Serializes this RestaurantCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RestaurantCard;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RestaurantCard&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.vertical, _this.vertical) || other.vertical == _this.vertical)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.cuisines, _this.cuisines)&&(identical(other.area, _this.area) || other.area == _this.area)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.ratingCount, _this.ratingCount) || other.ratingCount == _this.ratingCount)&&(identical(other.isOpen, _this.isOpen) || other.isOpen == _this.isOpen)&&(identical(other.isAcceptingOrders, _this.isAcceptingOrders) || other.isAcceptingOrders == _this.isAcceptingOrders)&&(identical(other.isFeatured, _this.isFeatured) || other.isFeatured == _this.isFeatured)&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl)&&(identical(other.distanceKm, _this.distanceKm) || other.distanceKm == _this.distanceKm)&&(identical(other.etaMinutes, _this.etaMinutes) || other.etaMinutes == _this.etaMinutes)&&(identical(other.deliveryFeeKobo, _this.deliveryFeeKobo) || other.deliveryFeeKobo == _this.deliveryFeeKobo)&&(identical(other.deliversToLocation, _this.deliversToLocation) || other.deliversToLocation == _this.deliversToLocation)&&(identical(other.supportsPickup, _this.supportsPickup) || other.supportsPickup == _this.supportsPickup)&&(identical(other.supportsDelivery, _this.supportsDelivery) || other.supportsDelivery == _this.supportsDelivery)&&const DeepCollectionEquality().equals(other.promotions, _this.promotions)&&(identical(other.badge, _this.badge) || other.badge == _this.badge));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RestaurantCard;
  return Object.hashAll([runtimeType,_this.id,_this.vertical,_this.city,_this.name,_this.description,const DeepCollectionEquality().hash(_this.cuisines),_this.area,_this.rating,_this.ratingCount,_this.isOpen,_this.isAcceptingOrders,_this.isFeatured,_this.coverUrl,_this.distanceKm,_this.etaMinutes,_this.deliveryFeeKobo,_this.deliversToLocation,_this.supportsPickup,_this.supportsDelivery,const DeepCollectionEquality().hash(_this.promotions),_this.badge]);
}

@override
String toString() {
  final _this = this as RestaurantCard;
  return 'RestaurantCard(id: ${_this.id}, vertical: ${_this.vertical}, city: ${_this.city}, name: ${_this.name}, description: ${_this.description}, cuisines: ${_this.cuisines}, area: ${_this.area}, rating: ${_this.rating}, ratingCount: ${_this.ratingCount}, isOpen: ${_this.isOpen}, isAcceptingOrders: ${_this.isAcceptingOrders}, isFeatured: ${_this.isFeatured}, coverUrl: ${_this.coverUrl}, distanceKm: ${_this.distanceKm}, etaMinutes: ${_this.etaMinutes}, deliveryFeeKobo: ${_this.deliveryFeeKobo}, deliversToLocation: ${_this.deliversToLocation}, supportsPickup: ${_this.supportsPickup}, supportsDelivery: ${_this.supportsDelivery}, promotions: ${_this.promotions}, badge: ${_this.badge})';
}


}

/// @nodoc
abstract mixin class $RestaurantCardCopyWith<$Res>  {
  factory $RestaurantCardCopyWith(RestaurantCard value, $Res Function(RestaurantCard) _then) = _$RestaurantCardCopyWithImpl;
@useResult
$Res call({
 String id, String vertical, String city, String name, String description, List<String> cuisines, String area, double rating, int ratingCount, bool isOpen, bool isAcceptingOrders, bool isFeatured, String? coverUrl, double? distanceKm, int? etaMinutes, int? deliveryFeeKobo, bool? deliversToLocation, bool supportsPickup, bool supportsDelivery, List<PromoBadge> promotions, String? badge
});




}
/// @nodoc
class _$RestaurantCardCopyWithImpl<$Res>
    implements $RestaurantCardCopyWith<$Res> {
  _$RestaurantCardCopyWithImpl(this._self, this._then);

  final RestaurantCard _self;
  final $Res Function(RestaurantCard) _then;

/// Create a copy of RestaurantCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vertical = null,Object? city = null,Object? name = null,Object? description = null,Object? cuisines = null,Object? area = null,Object? rating = null,Object? ratingCount = null,Object? isOpen = null,Object? isAcceptingOrders = null,Object? isFeatured = null,Object? coverUrl = freezed,Object? distanceKm = freezed,Object? etaMinutes = freezed,Object? deliveryFeeKobo = freezed,Object? deliversToLocation = freezed,Object? supportsPickup = null,Object? supportsDelivery = null,Object? promotions = null,Object? badge = freezed,}) {
  return _then(RestaurantCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vertical: null == vertical ? _self.vertical : vertical // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,cuisines: null == cuisines ? _self.cuisines : cuisines // ignore: cast_nullable_to_non_nullable
as List<String>,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,isAcceptingOrders: null == isAcceptingOrders ? _self.isAcceptingOrders : isAcceptingOrders // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,etaMinutes: freezed == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as int?,deliveryFeeKobo: freezed == deliveryFeeKobo ? _self.deliveryFeeKobo : deliveryFeeKobo // ignore: cast_nullable_to_non_nullable
as int?,deliversToLocation: freezed == deliversToLocation ? _self.deliversToLocation : deliversToLocation // ignore: cast_nullable_to_non_nullable
as bool?,supportsPickup: null == supportsPickup ? _self.supportsPickup : supportsPickup // ignore: cast_nullable_to_non_nullable
as bool,supportsDelivery: null == supportsDelivery ? _self.supportsDelivery : supportsDelivery // ignore: cast_nullable_to_non_nullable
as bool,promotions: null == promotions ? _self.promotions : promotions // ignore: cast_nullable_to_non_nullable
as List<PromoBadge>,badge: freezed == badge ? _self.badge : badge // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RestaurantCard].
extension RestaurantCardPatterns on RestaurantCard {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RestaurantCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RestaurantCard() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RestaurantCard value)  $default,){
final _that = this;
switch (_that) {
case _RestaurantCard():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RestaurantCard value)?  $default,){
final _that = this;
switch (_that) {
case _RestaurantCard() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String vertical,  String city,  String name,  String description,  List<String> cuisines,  String area,  double rating,  int ratingCount,  bool isOpen,  bool isAcceptingOrders,  bool isFeatured,  String? coverUrl,  double? distanceKm,  int? etaMinutes,  int? deliveryFeeKobo,  bool? deliversToLocation,  bool supportsPickup,  bool supportsDelivery,  List<PromoBadge> promotions,  String? badge)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RestaurantCard() when $default != null:
return $default(_that.id,_that.vertical,_that.city,_that.name,_that.description,_that.cuisines,_that.area,_that.rating,_that.ratingCount,_that.isOpen,_that.isAcceptingOrders,_that.isFeatured,_that.coverUrl,_that.distanceKm,_that.etaMinutes,_that.deliveryFeeKobo,_that.deliversToLocation,_that.supportsPickup,_that.supportsDelivery,_that.promotions,_that.badge);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String vertical,  String city,  String name,  String description,  List<String> cuisines,  String area,  double rating,  int ratingCount,  bool isOpen,  bool isAcceptingOrders,  bool isFeatured,  String? coverUrl,  double? distanceKm,  int? etaMinutes,  int? deliveryFeeKobo,  bool? deliversToLocation,  bool supportsPickup,  bool supportsDelivery,  List<PromoBadge> promotions,  String? badge)  $default,) {final _that = this;
switch (_that) {
case _RestaurantCard():
return $default(_that.id,_that.vertical,_that.city,_that.name,_that.description,_that.cuisines,_that.area,_that.rating,_that.ratingCount,_that.isOpen,_that.isAcceptingOrders,_that.isFeatured,_that.coverUrl,_that.distanceKm,_that.etaMinutes,_that.deliveryFeeKobo,_that.deliversToLocation,_that.supportsPickup,_that.supportsDelivery,_that.promotions,_that.badge);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String vertical,  String city,  String name,  String description,  List<String> cuisines,  String area,  double rating,  int ratingCount,  bool isOpen,  bool isAcceptingOrders,  bool isFeatured,  String? coverUrl,  double? distanceKm,  int? etaMinutes,  int? deliveryFeeKobo,  bool? deliversToLocation,  bool supportsPickup,  bool supportsDelivery,  List<PromoBadge> promotions,  String? badge)?  $default,) {final _that = this;
switch (_that) {
case _RestaurantCard() when $default != null:
return $default(_that.id,_that.vertical,_that.city,_that.name,_that.description,_that.cuisines,_that.area,_that.rating,_that.ratingCount,_that.isOpen,_that.isAcceptingOrders,_that.isFeatured,_that.coverUrl,_that.distanceKm,_that.etaMinutes,_that.deliveryFeeKobo,_that.deliversToLocation,_that.supportsPickup,_that.supportsDelivery,_that.promotions,_that.badge);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RestaurantCard implements RestaurantCard {
  const _RestaurantCard({required this.id, this.vertical = 'food', this.city = 'lagos', required this.name, this.description = '',  List<String> cuisines = const <String>[], this.area = '', this.rating = 0, this.ratingCount = 0, this.isOpen = false, this.isAcceptingOrders = true, this.isFeatured = false, this.coverUrl, this.distanceKm, this.etaMinutes, this.deliveryFeeKobo, this.deliversToLocation, this.supportsPickup = true, this.supportsDelivery = true,  List<PromoBadge> promotions = const <PromoBadge>[], this.badge}): _cuisines = cuisines,_promotions = promotions;
  factory _RestaurantCard.fromJson(Map<String, dynamic> json) => _$RestaurantCardFromJson(json);

@override final  String id;
@override@JsonKey() final  String vertical;
@override@JsonKey() final  String city;
@override final  String name;
@override@JsonKey() final  String description;
 final  List<String> _cuisines;
@override@JsonKey() List<String> get cuisines {
  if (_cuisines is EqualUnmodifiableListView) return _cuisines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cuisines);
}

@override@JsonKey() final  String area;
@override@JsonKey() final  double rating;
@override@JsonKey() final  int ratingCount;
@override@JsonKey() final  bool isOpen;
@override@JsonKey() final  bool isAcceptingOrders;
@override@JsonKey() final  bool isFeatured;
@override final  String? coverUrl;
@override final  double? distanceKm;
@override final  int? etaMinutes;
@override final  int? deliveryFeeKobo;
@override final  bool? deliversToLocation;
@override@JsonKey() final  bool supportsPickup;
@override@JsonKey() final  bool supportsDelivery;
 final  List<PromoBadge> _promotions;
@override@JsonKey() List<PromoBadge> get promotions {
  if (_promotions is EqualUnmodifiableListView) return _promotions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_promotions);
}

/// e.g. "Shopper" on a market: someone buys the items for the customer.
@override final  String? badge;

/// Create a copy of RestaurantCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestaurantCardCopyWith<_RestaurantCard> get copyWith => __$RestaurantCardCopyWithImpl<_RestaurantCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RestaurantCardToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RestaurantCard&&(identical(other.id, id) || other.id == id)&&(identical(other.vertical, vertical) || other.vertical == vertical)&&(identical(other.city, city) || other.city == city)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.cuisines, _cuisines)&&(identical(other.area, area) || other.area == area)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.isAcceptingOrders, isAcceptingOrders) || other.isAcceptingOrders == isAcceptingOrders)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.etaMinutes, etaMinutes) || other.etaMinutes == etaMinutes)&&(identical(other.deliveryFeeKobo, deliveryFeeKobo) || other.deliveryFeeKobo == deliveryFeeKobo)&&(identical(other.deliversToLocation, deliversToLocation) || other.deliversToLocation == deliversToLocation)&&(identical(other.supportsPickup, supportsPickup) || other.supportsPickup == supportsPickup)&&(identical(other.supportsDelivery, supportsDelivery) || other.supportsDelivery == supportsDelivery)&&const DeepCollectionEquality().equals(other.promotions, _promotions)&&(identical(other.badge, badge) || other.badge == badge));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,vertical,city,name,description,const DeepCollectionEquality().hash(_cuisines),area,rating,ratingCount,isOpen,isAcceptingOrders,isFeatured,coverUrl,distanceKm,etaMinutes,deliveryFeeKobo,deliversToLocation,supportsPickup,supportsDelivery,const DeepCollectionEquality().hash(_promotions),badge]);
}

@override
String toString() {
    return 'RestaurantCard(id: $id, vertical: $vertical, city: $city, name: $name, description: $description, cuisines: $cuisines, area: $area, rating: $rating, ratingCount: $ratingCount, isOpen: $isOpen, isAcceptingOrders: $isAcceptingOrders, isFeatured: $isFeatured, coverUrl: $coverUrl, distanceKm: $distanceKm, etaMinutes: $etaMinutes, deliveryFeeKobo: $deliveryFeeKobo, deliversToLocation: $deliversToLocation, supportsPickup: $supportsPickup, supportsDelivery: $supportsDelivery, promotions: $promotions, badge: $badge)';
}


}

/// @nodoc
abstract mixin class _$RestaurantCardCopyWith<$Res> implements $RestaurantCardCopyWith<$Res> {
  factory _$RestaurantCardCopyWith(_RestaurantCard value, $Res Function(_RestaurantCard) _then) = __$RestaurantCardCopyWithImpl;
@override @useResult
$Res call({
 String id, String vertical, String city, String name, String description, List<String> cuisines, String area, double rating, int ratingCount, bool isOpen, bool isAcceptingOrders, bool isFeatured, String? coverUrl, double? distanceKm, int? etaMinutes, int? deliveryFeeKobo, bool? deliversToLocation, bool supportsPickup, bool supportsDelivery, List<PromoBadge> promotions, String? badge
});




}
/// @nodoc
class __$RestaurantCardCopyWithImpl<$Res>
    implements _$RestaurantCardCopyWith<$Res> {
  __$RestaurantCardCopyWithImpl(this._self, this._then);

  final _RestaurantCard _self;
  final $Res Function(_RestaurantCard) _then;

/// Create a copy of RestaurantCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vertical = null,Object? city = null,Object? name = null,Object? description = null,Object? cuisines = null,Object? area = null,Object? rating = null,Object? ratingCount = null,Object? isOpen = null,Object? isAcceptingOrders = null,Object? isFeatured = null,Object? coverUrl = freezed,Object? distanceKm = freezed,Object? etaMinutes = freezed,Object? deliveryFeeKobo = freezed,Object? deliversToLocation = freezed,Object? supportsPickup = null,Object? supportsDelivery = null,Object? promotions = null,Object? badge = freezed,}) {
  return _then(_RestaurantCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vertical: null == vertical ? _self.vertical : vertical // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,cuisines: null == cuisines ? _self._cuisines : cuisines // ignore: cast_nullable_to_non_nullable
as List<String>,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,isAcceptingOrders: null == isAcceptingOrders ? _self.isAcceptingOrders : isAcceptingOrders // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,etaMinutes: freezed == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as int?,deliveryFeeKobo: freezed == deliveryFeeKobo ? _self.deliveryFeeKobo : deliveryFeeKobo // ignore: cast_nullable_to_non_nullable
as int?,deliversToLocation: freezed == deliversToLocation ? _self.deliversToLocation : deliversToLocation // ignore: cast_nullable_to_non_nullable
as bool?,supportsPickup: null == supportsPickup ? _self.supportsPickup : supportsPickup // ignore: cast_nullable_to_non_nullable
as bool,supportsDelivery: null == supportsDelivery ? _self.supportsDelivery : supportsDelivery // ignore: cast_nullable_to_non_nullable
as bool,promotions: null == promotions ? _self._promotions : promotions // ignore: cast_nullable_to_non_nullable
as List<PromoBadge>,badge: freezed == badge ? _self.badge : badge // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$OptionChoice {

 String get id; String get name; int get priceDeltaKobo; bool get isAvailable;
/// Create a copy of OptionChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OptionChoiceCopyWith<OptionChoice> get copyWith => _$OptionChoiceCopyWithImpl<OptionChoice>(this as OptionChoice, _$identity);

  /// Serializes this OptionChoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OptionChoice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OptionChoice&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.priceDeltaKobo, _this.priceDeltaKobo) || other.priceDeltaKobo == _this.priceDeltaKobo)&&(identical(other.isAvailable, _this.isAvailable) || other.isAvailable == _this.isAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OptionChoice;
  return Object.hash(runtimeType,_this.id,_this.name,_this.priceDeltaKobo,_this.isAvailable);
}

@override
String toString() {
  final _this = this as OptionChoice;
  return 'OptionChoice(id: ${_this.id}, name: ${_this.name}, priceDeltaKobo: ${_this.priceDeltaKobo}, isAvailable: ${_this.isAvailable})';
}


}

/// @nodoc
abstract mixin class $OptionChoiceCopyWith<$Res>  {
  factory $OptionChoiceCopyWith(OptionChoice value, $Res Function(OptionChoice) _then) = _$OptionChoiceCopyWithImpl;
@useResult
$Res call({
 String id, String name, int priceDeltaKobo, bool isAvailable
});




}
/// @nodoc
class _$OptionChoiceCopyWithImpl<$Res>
    implements $OptionChoiceCopyWith<$Res> {
  _$OptionChoiceCopyWithImpl(this._self, this._then);

  final OptionChoice _self;
  final $Res Function(OptionChoice) _then;

/// Create a copy of OptionChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? priceDeltaKobo = null,Object? isAvailable = null,}) {
  return _then(OptionChoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,priceDeltaKobo: null == priceDeltaKobo ? _self.priceDeltaKobo : priceDeltaKobo // ignore: cast_nullable_to_non_nullable
as int,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OptionChoice].
extension OptionChoicePatterns on OptionChoice {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OptionChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OptionChoice() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OptionChoice value)  $default,){
final _that = this;
switch (_that) {
case _OptionChoice():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OptionChoice value)?  $default,){
final _that = this;
switch (_that) {
case _OptionChoice() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int priceDeltaKobo,  bool isAvailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OptionChoice() when $default != null:
return $default(_that.id,_that.name,_that.priceDeltaKobo,_that.isAvailable);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int priceDeltaKobo,  bool isAvailable)  $default,) {final _that = this;
switch (_that) {
case _OptionChoice():
return $default(_that.id,_that.name,_that.priceDeltaKobo,_that.isAvailable);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int priceDeltaKobo,  bool isAvailable)?  $default,) {final _that = this;
switch (_that) {
case _OptionChoice() when $default != null:
return $default(_that.id,_that.name,_that.priceDeltaKobo,_that.isAvailable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OptionChoice implements OptionChoice {
  const _OptionChoice({required this.id, required this.name, this.priceDeltaKobo = 0, this.isAvailable = true});
  factory _OptionChoice.fromJson(Map<String, dynamic> json) => _$OptionChoiceFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  int priceDeltaKobo;
@override@JsonKey() final  bool isAvailable;

/// Create a copy of OptionChoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OptionChoiceCopyWith<_OptionChoice> get copyWith => __$OptionChoiceCopyWithImpl<_OptionChoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OptionChoiceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OptionChoice&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.priceDeltaKobo, priceDeltaKobo) || other.priceDeltaKobo == priceDeltaKobo)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,priceDeltaKobo,isAvailable);
}

@override
String toString() {
    return 'OptionChoice(id: $id, name: $name, priceDeltaKobo: $priceDeltaKobo, isAvailable: $isAvailable)';
}


}

/// @nodoc
abstract mixin class _$OptionChoiceCopyWith<$Res> implements $OptionChoiceCopyWith<$Res> {
  factory _$OptionChoiceCopyWith(_OptionChoice value, $Res Function(_OptionChoice) _then) = __$OptionChoiceCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int priceDeltaKobo, bool isAvailable
});




}
/// @nodoc
class __$OptionChoiceCopyWithImpl<$Res>
    implements _$OptionChoiceCopyWith<$Res> {
  __$OptionChoiceCopyWithImpl(this._self, this._then);

  final _OptionChoice _self;
  final $Res Function(_OptionChoice) _then;

/// Create a copy of OptionChoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? priceDeltaKobo = null,Object? isAvailable = null,}) {
  return _then(_OptionChoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,priceDeltaKobo: null == priceDeltaKobo ? _self.priceDeltaKobo : priceDeltaKobo // ignore: cast_nullable_to_non_nullable
as int,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$OptionGroup {

 String get id; String get name; int get minSelect; int get maxSelect; List<OptionChoice> get choices;
/// Create a copy of OptionGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OptionGroupCopyWith<OptionGroup> get copyWith => _$OptionGroupCopyWithImpl<OptionGroup>(this as OptionGroup, _$identity);

  /// Serializes this OptionGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OptionGroup;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OptionGroup&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.minSelect, _this.minSelect) || other.minSelect == _this.minSelect)&&(identical(other.maxSelect, _this.maxSelect) || other.maxSelect == _this.maxSelect)&&const DeepCollectionEquality().equals(other.choices, _this.choices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OptionGroup;
  return Object.hash(runtimeType,_this.id,_this.name,_this.minSelect,_this.maxSelect,const DeepCollectionEquality().hash(_this.choices));
}

@override
String toString() {
  final _this = this as OptionGroup;
  return 'OptionGroup(id: ${_this.id}, name: ${_this.name}, minSelect: ${_this.minSelect}, maxSelect: ${_this.maxSelect}, choices: ${_this.choices})';
}


}

/// @nodoc
abstract mixin class $OptionGroupCopyWith<$Res>  {
  factory $OptionGroupCopyWith(OptionGroup value, $Res Function(OptionGroup) _then) = _$OptionGroupCopyWithImpl;
@useResult
$Res call({
 String id, String name, int minSelect, int maxSelect, List<OptionChoice> choices
});




}
/// @nodoc
class _$OptionGroupCopyWithImpl<$Res>
    implements $OptionGroupCopyWith<$Res> {
  _$OptionGroupCopyWithImpl(this._self, this._then);

  final OptionGroup _self;
  final $Res Function(OptionGroup) _then;

/// Create a copy of OptionGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? minSelect = null,Object? maxSelect = null,Object? choices = null,}) {
  return _then(OptionGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,minSelect: null == minSelect ? _self.minSelect : minSelect // ignore: cast_nullable_to_non_nullable
as int,maxSelect: null == maxSelect ? _self.maxSelect : maxSelect // ignore: cast_nullable_to_non_nullable
as int,choices: null == choices ? _self.choices : choices // ignore: cast_nullable_to_non_nullable
as List<OptionChoice>,
  ));
}

}


/// Adds pattern-matching-related methods to [OptionGroup].
extension OptionGroupPatterns on OptionGroup {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OptionGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OptionGroup() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OptionGroup value)  $default,){
final _that = this;
switch (_that) {
case _OptionGroup():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OptionGroup value)?  $default,){
final _that = this;
switch (_that) {
case _OptionGroup() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int minSelect,  int maxSelect,  List<OptionChoice> choices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OptionGroup() when $default != null:
return $default(_that.id,_that.name,_that.minSelect,_that.maxSelect,_that.choices);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int minSelect,  int maxSelect,  List<OptionChoice> choices)  $default,) {final _that = this;
switch (_that) {
case _OptionGroup():
return $default(_that.id,_that.name,_that.minSelect,_that.maxSelect,_that.choices);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int minSelect,  int maxSelect,  List<OptionChoice> choices)?  $default,) {final _that = this;
switch (_that) {
case _OptionGroup() when $default != null:
return $default(_that.id,_that.name,_that.minSelect,_that.maxSelect,_that.choices);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OptionGroup implements OptionGroup {
  const _OptionGroup({required this.id, required this.name, this.minSelect = 0, this.maxSelect = 1,  List<OptionChoice> choices = const <OptionChoice>[]}): _choices = choices;
  factory _OptionGroup.fromJson(Map<String, dynamic> json) => _$OptionGroupFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  int minSelect;
@override@JsonKey() final  int maxSelect;
 final  List<OptionChoice> _choices;
@override@JsonKey() List<OptionChoice> get choices {
  if (_choices is EqualUnmodifiableListView) return _choices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_choices);
}


/// Create a copy of OptionGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OptionGroupCopyWith<_OptionGroup> get copyWith => __$OptionGroupCopyWithImpl<_OptionGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OptionGroupToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OptionGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.minSelect, minSelect) || other.minSelect == minSelect)&&(identical(other.maxSelect, maxSelect) || other.maxSelect == maxSelect)&&const DeepCollectionEquality().equals(other.choices, _choices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,minSelect,maxSelect,const DeepCollectionEquality().hash(_choices));
}

@override
String toString() {
    return 'OptionGroup(id: $id, name: $name, minSelect: $minSelect, maxSelect: $maxSelect, choices: $choices)';
}


}

/// @nodoc
abstract mixin class _$OptionGroupCopyWith<$Res> implements $OptionGroupCopyWith<$Res> {
  factory _$OptionGroupCopyWith(_OptionGroup value, $Res Function(_OptionGroup) _then) = __$OptionGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int minSelect, int maxSelect, List<OptionChoice> choices
});




}
/// @nodoc
class __$OptionGroupCopyWithImpl<$Res>
    implements _$OptionGroupCopyWith<$Res> {
  __$OptionGroupCopyWithImpl(this._self, this._then);

  final _OptionGroup _self;
  final $Res Function(_OptionGroup) _then;

/// Create a copy of OptionGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? minSelect = null,Object? maxSelect = null,Object? choices = null,}) {
  return _then(_OptionGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,minSelect: null == minSelect ? _self.minSelect : minSelect // ignore: cast_nullable_to_non_nullable
as int,maxSelect: null == maxSelect ? _self.maxSelect : maxSelect // ignore: cast_nullable_to_non_nullable
as int,choices: null == choices ? _self._choices : choices // ignore: cast_nullable_to_non_nullable
as List<OptionChoice>,
  ));
}


}


/// @nodoc
mixin _$MenuItem {

 String get id; String get restaurantId; String get name; String get description; int get priceKobo; String get kind; List<String> get allergens; List<String> get dietary; int get serves; int get spiceLevel; bool get isAvailable; List<String> get optionGroupIds; String? get unitLabel;/// Products (shops, pharmacies, markets): brand, a picture placeholder and how popular the product is.
 String? get brand; String? get emoji; int get popularity;
/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuItemCopyWith<MenuItem> get copyWith => _$MenuItemCopyWithImpl<MenuItem>(this as MenuItem, _$identity);

  /// Serializes this MenuItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MenuItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.restaurantId, _this.restaurantId) || other.restaurantId == _this.restaurantId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.priceKobo, _this.priceKobo) || other.priceKobo == _this.priceKobo)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&const DeepCollectionEquality().equals(other.allergens, _this.allergens)&&const DeepCollectionEquality().equals(other.dietary, _this.dietary)&&(identical(other.serves, _this.serves) || other.serves == _this.serves)&&(identical(other.spiceLevel, _this.spiceLevel) || other.spiceLevel == _this.spiceLevel)&&(identical(other.isAvailable, _this.isAvailable) || other.isAvailable == _this.isAvailable)&&const DeepCollectionEquality().equals(other.optionGroupIds, _this.optionGroupIds)&&(identical(other.unitLabel, _this.unitLabel) || other.unitLabel == _this.unitLabel)&&(identical(other.brand, _this.brand) || other.brand == _this.brand)&&(identical(other.emoji, _this.emoji) || other.emoji == _this.emoji)&&(identical(other.popularity, _this.popularity) || other.popularity == _this.popularity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MenuItem;
  return Object.hash(runtimeType,_this.id,_this.restaurantId,_this.name,_this.description,_this.priceKobo,_this.kind,const DeepCollectionEquality().hash(_this.allergens),const DeepCollectionEquality().hash(_this.dietary),_this.serves,_this.spiceLevel,_this.isAvailable,const DeepCollectionEquality().hash(_this.optionGroupIds),_this.unitLabel,_this.brand,_this.emoji,_this.popularity);
}

@override
String toString() {
  final _this = this as MenuItem;
  return 'MenuItem(id: ${_this.id}, restaurantId: ${_this.restaurantId}, name: ${_this.name}, description: ${_this.description}, priceKobo: ${_this.priceKobo}, kind: ${_this.kind}, allergens: ${_this.allergens}, dietary: ${_this.dietary}, serves: ${_this.serves}, spiceLevel: ${_this.spiceLevel}, isAvailable: ${_this.isAvailable}, optionGroupIds: ${_this.optionGroupIds}, unitLabel: ${_this.unitLabel}, brand: ${_this.brand}, emoji: ${_this.emoji}, popularity: ${_this.popularity})';
}


}

/// @nodoc
abstract mixin class $MenuItemCopyWith<$Res>  {
  factory $MenuItemCopyWith(MenuItem value, $Res Function(MenuItem) _then) = _$MenuItemCopyWithImpl;
@useResult
$Res call({
 String id, String restaurantId, String name, String description, int priceKobo, String kind, List<String> allergens, List<String> dietary, int serves, int spiceLevel, bool isAvailable, List<String> optionGroupIds, String? unitLabel, String? brand, String? emoji, int popularity
});




}
/// @nodoc
class _$MenuItemCopyWithImpl<$Res>
    implements $MenuItemCopyWith<$Res> {
  _$MenuItemCopyWithImpl(this._self, this._then);

  final MenuItem _self;
  final $Res Function(MenuItem) _then;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? restaurantId = null,Object? name = null,Object? description = null,Object? priceKobo = null,Object? kind = null,Object? allergens = null,Object? dietary = null,Object? serves = null,Object? spiceLevel = null,Object? isAvailable = null,Object? optionGroupIds = null,Object? unitLabel = freezed,Object? brand = freezed,Object? emoji = freezed,Object? popularity = null,}) {
  return _then(MenuItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,restaurantId: null == restaurantId ? _self.restaurantId : restaurantId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priceKobo: null == priceKobo ? _self.priceKobo : priceKobo // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,allergens: null == allergens ? _self.allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<String>,dietary: null == dietary ? _self.dietary : dietary // ignore: cast_nullable_to_non_nullable
as List<String>,serves: null == serves ? _self.serves : serves // ignore: cast_nullable_to_non_nullable
as int,spiceLevel: null == spiceLevel ? _self.spiceLevel : spiceLevel // ignore: cast_nullable_to_non_nullable
as int,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,optionGroupIds: null == optionGroupIds ? _self.optionGroupIds : optionGroupIds // ignore: cast_nullable_to_non_nullable
as List<String>,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,emoji: freezed == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String?,popularity: null == popularity ? _self.popularity : popularity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuItem].
extension MenuItemPatterns on MenuItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuItem value)  $default,){
final _that = this;
switch (_that) {
case _MenuItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuItem value)?  $default,){
final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String restaurantId,  String name,  String description,  int priceKobo,  String kind,  List<String> allergens,  List<String> dietary,  int serves,  int spiceLevel,  bool isAvailable,  List<String> optionGroupIds,  String? unitLabel,  String? brand,  String? emoji,  int popularity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
return $default(_that.id,_that.restaurantId,_that.name,_that.description,_that.priceKobo,_that.kind,_that.allergens,_that.dietary,_that.serves,_that.spiceLevel,_that.isAvailable,_that.optionGroupIds,_that.unitLabel,_that.brand,_that.emoji,_that.popularity);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String restaurantId,  String name,  String description,  int priceKobo,  String kind,  List<String> allergens,  List<String> dietary,  int serves,  int spiceLevel,  bool isAvailable,  List<String> optionGroupIds,  String? unitLabel,  String? brand,  String? emoji,  int popularity)  $default,) {final _that = this;
switch (_that) {
case _MenuItem():
return $default(_that.id,_that.restaurantId,_that.name,_that.description,_that.priceKobo,_that.kind,_that.allergens,_that.dietary,_that.serves,_that.spiceLevel,_that.isAvailable,_that.optionGroupIds,_that.unitLabel,_that.brand,_that.emoji,_that.popularity);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String restaurantId,  String name,  String description,  int priceKobo,  String kind,  List<String> allergens,  List<String> dietary,  int serves,  int spiceLevel,  bool isAvailable,  List<String> optionGroupIds,  String? unitLabel,  String? brand,  String? emoji,  int popularity)?  $default,) {final _that = this;
switch (_that) {
case _MenuItem() when $default != null:
return $default(_that.id,_that.restaurantId,_that.name,_that.description,_that.priceKobo,_that.kind,_that.allergens,_that.dietary,_that.serves,_that.spiceLevel,_that.isAvailable,_that.optionGroupIds,_that.unitLabel,_that.brand,_that.emoji,_that.popularity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuItem implements MenuItem {
  const _MenuItem({required this.id, required this.restaurantId, required this.name, this.description = '', required this.priceKobo, this.kind = 'main',  List<String> allergens = const <String>[],  List<String> dietary = const <String>[], this.serves = 1, this.spiceLevel = 0, this.isAvailable = true,  List<String> optionGroupIds = const <String>[], this.unitLabel, this.brand, this.emoji, this.popularity = 0}): _allergens = allergens,_dietary = dietary,_optionGroupIds = optionGroupIds;
  factory _MenuItem.fromJson(Map<String, dynamic> json) => _$MenuItemFromJson(json);

@override final  String id;
@override final  String restaurantId;
@override final  String name;
@override@JsonKey() final  String description;
@override final  int priceKobo;
@override@JsonKey() final  String kind;
 final  List<String> _allergens;
@override@JsonKey() List<String> get allergens {
  if (_allergens is EqualUnmodifiableListView) return _allergens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allergens);
}

 final  List<String> _dietary;
@override@JsonKey() List<String> get dietary {
  if (_dietary is EqualUnmodifiableListView) return _dietary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dietary);
}

@override@JsonKey() final  int serves;
@override@JsonKey() final  int spiceLevel;
@override@JsonKey() final  bool isAvailable;
 final  List<String> _optionGroupIds;
@override@JsonKey() List<String> get optionGroupIds {
  if (_optionGroupIds is EqualUnmodifiableListView) return _optionGroupIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_optionGroupIds);
}

@override final  String? unitLabel;
/// Products (shops, pharmacies, markets): brand, a picture placeholder and how popular the product is.
@override final  String? brand;
@override final  String? emoji;
@override@JsonKey() final  int popularity;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuItemCopyWith<_MenuItem> get copyWith => __$MenuItemCopyWithImpl<_MenuItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuItem&&(identical(other.id, id) || other.id == id)&&(identical(other.restaurantId, restaurantId) || other.restaurantId == restaurantId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.priceKobo, priceKobo) || other.priceKobo == priceKobo)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.allergens, _allergens)&&const DeepCollectionEquality().equals(other.dietary, _dietary)&&(identical(other.serves, serves) || other.serves == serves)&&(identical(other.spiceLevel, spiceLevel) || other.spiceLevel == spiceLevel)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&const DeepCollectionEquality().equals(other.optionGroupIds, _optionGroupIds)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.popularity, popularity) || other.popularity == popularity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,restaurantId,name,description,priceKobo,kind,const DeepCollectionEquality().hash(_allergens),const DeepCollectionEquality().hash(_dietary),serves,spiceLevel,isAvailable,const DeepCollectionEquality().hash(_optionGroupIds),unitLabel,brand,emoji,popularity);
}

@override
String toString() {
    return 'MenuItem(id: $id, restaurantId: $restaurantId, name: $name, description: $description, priceKobo: $priceKobo, kind: $kind, allergens: $allergens, dietary: $dietary, serves: $serves, spiceLevel: $spiceLevel, isAvailable: $isAvailable, optionGroupIds: $optionGroupIds, unitLabel: $unitLabel, brand: $brand, emoji: $emoji, popularity: $popularity)';
}


}

/// @nodoc
abstract mixin class _$MenuItemCopyWith<$Res> implements $MenuItemCopyWith<$Res> {
  factory _$MenuItemCopyWith(_MenuItem value, $Res Function(_MenuItem) _then) = __$MenuItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String restaurantId, String name, String description, int priceKobo, String kind, List<String> allergens, List<String> dietary, int serves, int spiceLevel, bool isAvailable, List<String> optionGroupIds, String? unitLabel, String? brand, String? emoji, int popularity
});




}
/// @nodoc
class __$MenuItemCopyWithImpl<$Res>
    implements _$MenuItemCopyWith<$Res> {
  __$MenuItemCopyWithImpl(this._self, this._then);

  final _MenuItem _self;
  final $Res Function(_MenuItem) _then;

/// Create a copy of MenuItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? restaurantId = null,Object? name = null,Object? description = null,Object? priceKobo = null,Object? kind = null,Object? allergens = null,Object? dietary = null,Object? serves = null,Object? spiceLevel = null,Object? isAvailable = null,Object? optionGroupIds = null,Object? unitLabel = freezed,Object? brand = freezed,Object? emoji = freezed,Object? popularity = null,}) {
  return _then(_MenuItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,restaurantId: null == restaurantId ? _self.restaurantId : restaurantId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priceKobo: null == priceKobo ? _self.priceKobo : priceKobo // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,allergens: null == allergens ? _self._allergens : allergens // ignore: cast_nullable_to_non_nullable
as List<String>,dietary: null == dietary ? _self._dietary : dietary // ignore: cast_nullable_to_non_nullable
as List<String>,serves: null == serves ? _self.serves : serves // ignore: cast_nullable_to_non_nullable
as int,spiceLevel: null == spiceLevel ? _self.spiceLevel : spiceLevel // ignore: cast_nullable_to_non_nullable
as int,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,optionGroupIds: null == optionGroupIds ? _self._optionGroupIds : optionGroupIds // ignore: cast_nullable_to_non_nullable
as List<String>,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,emoji: freezed == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String?,popularity: null == popularity ? _self.popularity : popularity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MenuCategory {

 String get id; String get name;
/// Create a copy of MenuCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuCategoryCopyWith<MenuCategory> get copyWith => _$MenuCategoryCopyWithImpl<MenuCategory>(this as MenuCategory, _$identity);

  /// Serializes this MenuCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MenuCategory;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuCategory&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MenuCategory;
  return Object.hash(runtimeType,_this.id,_this.name);
}

@override
String toString() {
  final _this = this as MenuCategory;
  return 'MenuCategory(id: ${_this.id}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $MenuCategoryCopyWith<$Res>  {
  factory $MenuCategoryCopyWith(MenuCategory value, $Res Function(MenuCategory) _then) = _$MenuCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$MenuCategoryCopyWithImpl<$Res>
    implements $MenuCategoryCopyWith<$Res> {
  _$MenuCategoryCopyWithImpl(this._self, this._then);

  final MenuCategory _self;
  final $Res Function(MenuCategory) _then;

/// Create a copy of MenuCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(MenuCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MenuCategory].
extension MenuCategoryPatterns on MenuCategory {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuCategory() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuCategory value)  $default,){
final _that = this;
switch (_that) {
case _MenuCategory():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuCategory value)?  $default,){
final _that = this;
switch (_that) {
case _MenuCategory() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuCategory() when $default != null:
return $default(_that.id,_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _MenuCategory():
return $default(_that.id,_that.name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _MenuCategory() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuCategory implements MenuCategory {
  const _MenuCategory({required this.id, required this.name});
  factory _MenuCategory.fromJson(Map<String, dynamic> json) => _$MenuCategoryFromJson(json);

@override final  String id;
@override final  String name;

/// Create a copy of MenuCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuCategoryCopyWith<_MenuCategory> get copyWith => __$MenuCategoryCopyWithImpl<_MenuCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name);
}

@override
String toString() {
    return 'MenuCategory(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$MenuCategoryCopyWith<$Res> implements $MenuCategoryCopyWith<$Res> {
  factory _$MenuCategoryCopyWith(_MenuCategory value, $Res Function(_MenuCategory) _then) = __$MenuCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$MenuCategoryCopyWithImpl<$Res>
    implements _$MenuCategoryCopyWith<$Res> {
  __$MenuCategoryCopyWithImpl(this._self, this._then);

  final _MenuCategory _self;
  final $Res Function(_MenuCategory) _then;

/// Create a copy of MenuCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_MenuCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MenuSection {

 MenuCategory get category; List<MenuItem> get items;
/// Create a copy of MenuSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MenuSectionCopyWith<MenuSection> get copyWith => _$MenuSectionCopyWithImpl<MenuSection>(this as MenuSection, _$identity);

  /// Serializes this MenuSection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MenuSection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MenuSection&&(identical(other.category, _this.category) || other.category == _this.category)&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MenuSection;
  return Object.hash(runtimeType,_this.category,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as MenuSection;
  return 'MenuSection(category: ${_this.category}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $MenuSectionCopyWith<$Res>  {
  factory $MenuSectionCopyWith(MenuSection value, $Res Function(MenuSection) _then) = _$MenuSectionCopyWithImpl;
@useResult
$Res call({
 MenuCategory category, List<MenuItem> items
});


$MenuCategoryCopyWith<$Res> get category;

}
/// @nodoc
class _$MenuSectionCopyWithImpl<$Res>
    implements $MenuSectionCopyWith<$Res> {
  _$MenuSectionCopyWithImpl(this._self, this._then);

  final MenuSection _self;
  final $Res Function(MenuSection) _then;

/// Create a copy of MenuSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? items = null,}) {
  return _then(MenuSection(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as MenuCategory,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MenuItem>,
  ));
}
/// Create a copy of MenuSection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MenuCategoryCopyWith<$Res> get category {
  
  return $MenuCategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [MenuSection].
extension MenuSectionPatterns on MenuSection {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MenuSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MenuSection() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MenuSection value)  $default,){
final _that = this;
switch (_that) {
case _MenuSection():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MenuSection value)?  $default,){
final _that = this;
switch (_that) {
case _MenuSection() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MenuCategory category,  List<MenuItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MenuSection() when $default != null:
return $default(_that.category,_that.items);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MenuCategory category,  List<MenuItem> items)  $default,) {final _that = this;
switch (_that) {
case _MenuSection():
return $default(_that.category,_that.items);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MenuCategory category,  List<MenuItem> items)?  $default,) {final _that = this;
switch (_that) {
case _MenuSection() when $default != null:
return $default(_that.category,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MenuSection implements MenuSection {
  const _MenuSection({required this.category,  List<MenuItem> items = const <MenuItem>[]}): _items = items;
  factory _MenuSection.fromJson(Map<String, dynamic> json) => _$MenuSectionFromJson(json);

@override final  MenuCategory category;
 final  List<MenuItem> _items;
@override@JsonKey() List<MenuItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of MenuSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MenuSectionCopyWith<_MenuSection> get copyWith => __$MenuSectionCopyWithImpl<_MenuSection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MenuSectionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MenuSection&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,category,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'MenuSection(category: $category, items: $items)';
}


}

/// @nodoc
abstract mixin class _$MenuSectionCopyWith<$Res> implements $MenuSectionCopyWith<$Res> {
  factory _$MenuSectionCopyWith(_MenuSection value, $Res Function(_MenuSection) _then) = __$MenuSectionCopyWithImpl;
@override @useResult
$Res call({
 MenuCategory category, List<MenuItem> items
});


@override $MenuCategoryCopyWith<$Res> get category;

}
/// @nodoc
class __$MenuSectionCopyWithImpl<$Res>
    implements _$MenuSectionCopyWith<$Res> {
  __$MenuSectionCopyWithImpl(this._self, this._then);

  final _MenuSection _self;
  final $Res Function(_MenuSection) _then;

/// Create a copy of MenuSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? items = null,}) {
  return _then(_MenuSection(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as MenuCategory,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MenuItem>,
  ));
}

/// Create a copy of MenuSection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MenuCategoryCopyWith<$Res> get category {
  
  return $MenuCategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// @nodoc
mixin _$RestaurantDetail {

 RestaurantCard get restaurant; String get address; int get avgPrepMinutes; List<MenuSection> get sections; Map<String, OptionGroup> get optionGroups;
/// Create a copy of RestaurantDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestaurantDetailCopyWith<RestaurantDetail> get copyWith => _$RestaurantDetailCopyWithImpl<RestaurantDetail>(this as RestaurantDetail, _$identity);

  /// Serializes this RestaurantDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RestaurantDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RestaurantDetail&&(identical(other.restaurant, _this.restaurant) || other.restaurant == _this.restaurant)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.avgPrepMinutes, _this.avgPrepMinutes) || other.avgPrepMinutes == _this.avgPrepMinutes)&&const DeepCollectionEquality().equals(other.sections, _this.sections)&&const DeepCollectionEquality().equals(other.optionGroups, _this.optionGroups));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RestaurantDetail;
  return Object.hash(runtimeType,_this.restaurant,_this.address,_this.avgPrepMinutes,const DeepCollectionEquality().hash(_this.sections),const DeepCollectionEquality().hash(_this.optionGroups));
}

@override
String toString() {
  final _this = this as RestaurantDetail;
  return 'RestaurantDetail(restaurant: ${_this.restaurant}, address: ${_this.address}, avgPrepMinutes: ${_this.avgPrepMinutes}, sections: ${_this.sections}, optionGroups: ${_this.optionGroups})';
}


}

/// @nodoc
abstract mixin class $RestaurantDetailCopyWith<$Res>  {
  factory $RestaurantDetailCopyWith(RestaurantDetail value, $Res Function(RestaurantDetail) _then) = _$RestaurantDetailCopyWithImpl;
@useResult
$Res call({
 RestaurantCard restaurant, String address, int avgPrepMinutes, List<MenuSection> sections, Map<String, OptionGroup> optionGroups
});


$RestaurantCardCopyWith<$Res> get restaurant;

}
/// @nodoc
class _$RestaurantDetailCopyWithImpl<$Res>
    implements $RestaurantDetailCopyWith<$Res> {
  _$RestaurantDetailCopyWithImpl(this._self, this._then);

  final RestaurantDetail _self;
  final $Res Function(RestaurantDetail) _then;

/// Create a copy of RestaurantDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? restaurant = null,Object? address = null,Object? avgPrepMinutes = null,Object? sections = null,Object? optionGroups = null,}) {
  return _then(RestaurantDetail(
restaurant: null == restaurant ? _self.restaurant : restaurant // ignore: cast_nullable_to_non_nullable
as RestaurantCard,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,avgPrepMinutes: null == avgPrepMinutes ? _self.avgPrepMinutes : avgPrepMinutes // ignore: cast_nullable_to_non_nullable
as int,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<MenuSection>,optionGroups: null == optionGroups ? _self.optionGroups : optionGroups // ignore: cast_nullable_to_non_nullable
as Map<String, OptionGroup>,
  ));
}
/// Create a copy of RestaurantDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RestaurantCardCopyWith<$Res> get restaurant {
  
  return $RestaurantCardCopyWith<$Res>(_self.restaurant, (value) {
    return _then(_self.copyWith(restaurant: value));
  });
}
}


/// Adds pattern-matching-related methods to [RestaurantDetail].
extension RestaurantDetailPatterns on RestaurantDetail {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RestaurantDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RestaurantDetail() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RestaurantDetail value)  $default,){
final _that = this;
switch (_that) {
case _RestaurantDetail():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RestaurantDetail value)?  $default,){
final _that = this;
switch (_that) {
case _RestaurantDetail() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RestaurantCard restaurant,  String address,  int avgPrepMinutes,  List<MenuSection> sections,  Map<String, OptionGroup> optionGroups)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RestaurantDetail() when $default != null:
return $default(_that.restaurant,_that.address,_that.avgPrepMinutes,_that.sections,_that.optionGroups);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RestaurantCard restaurant,  String address,  int avgPrepMinutes,  List<MenuSection> sections,  Map<String, OptionGroup> optionGroups)  $default,) {final _that = this;
switch (_that) {
case _RestaurantDetail():
return $default(_that.restaurant,_that.address,_that.avgPrepMinutes,_that.sections,_that.optionGroups);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RestaurantCard restaurant,  String address,  int avgPrepMinutes,  List<MenuSection> sections,  Map<String, OptionGroup> optionGroups)?  $default,) {final _that = this;
switch (_that) {
case _RestaurantDetail() when $default != null:
return $default(_that.restaurant,_that.address,_that.avgPrepMinutes,_that.sections,_that.optionGroups);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RestaurantDetail implements RestaurantDetail {
  const _RestaurantDetail({required this.restaurant, this.address = '', this.avgPrepMinutes = 20,  List<MenuSection> sections = const <MenuSection>[],  Map<String, OptionGroup> optionGroups = const <String, OptionGroup>{}}): _sections = sections,_optionGroups = optionGroups;
  factory _RestaurantDetail.fromJson(Map<String, dynamic> json) => _$RestaurantDetailFromJson(json);

@override final  RestaurantCard restaurant;
@override@JsonKey() final  String address;
@override@JsonKey() final  int avgPrepMinutes;
 final  List<MenuSection> _sections;
@override@JsonKey() List<MenuSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

 final  Map<String, OptionGroup> _optionGroups;
@override@JsonKey() Map<String, OptionGroup> get optionGroups {
  if (_optionGroups is EqualUnmodifiableMapView) return _optionGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_optionGroups);
}


/// Create a copy of RestaurantDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestaurantDetailCopyWith<_RestaurantDetail> get copyWith => __$RestaurantDetailCopyWithImpl<_RestaurantDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RestaurantDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RestaurantDetail&&(identical(other.restaurant, restaurant) || other.restaurant == restaurant)&&(identical(other.address, address) || other.address == address)&&(identical(other.avgPrepMinutes, avgPrepMinutes) || other.avgPrepMinutes == avgPrepMinutes)&&const DeepCollectionEquality().equals(other.sections, _sections)&&const DeepCollectionEquality().equals(other.optionGroups, _optionGroups));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,restaurant,address,avgPrepMinutes,const DeepCollectionEquality().hash(_sections),const DeepCollectionEquality().hash(_optionGroups));
}

@override
String toString() {
    return 'RestaurantDetail(restaurant: $restaurant, address: $address, avgPrepMinutes: $avgPrepMinutes, sections: $sections, optionGroups: $optionGroups)';
}


}

/// @nodoc
abstract mixin class _$RestaurantDetailCopyWith<$Res> implements $RestaurantDetailCopyWith<$Res> {
  factory _$RestaurantDetailCopyWith(_RestaurantDetail value, $Res Function(_RestaurantDetail) _then) = __$RestaurantDetailCopyWithImpl;
@override @useResult
$Res call({
 RestaurantCard restaurant, String address, int avgPrepMinutes, List<MenuSection> sections, Map<String, OptionGroup> optionGroups
});


@override $RestaurantCardCopyWith<$Res> get restaurant;

}
/// @nodoc
class __$RestaurantDetailCopyWithImpl<$Res>
    implements _$RestaurantDetailCopyWith<$Res> {
  __$RestaurantDetailCopyWithImpl(this._self, this._then);

  final _RestaurantDetail _self;
  final $Res Function(_RestaurantDetail) _then;

/// Create a copy of RestaurantDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? restaurant = null,Object? address = null,Object? avgPrepMinutes = null,Object? sections = null,Object? optionGroups = null,}) {
  return _then(_RestaurantDetail(
restaurant: null == restaurant ? _self.restaurant : restaurant // ignore: cast_nullable_to_non_nullable
as RestaurantCard,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,avgPrepMinutes: null == avgPrepMinutes ? _self.avgPrepMinutes : avgPrepMinutes // ignore: cast_nullable_to_non_nullable
as int,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<MenuSection>,optionGroups: null == optionGroups ? _self._optionGroups : optionGroups // ignore: cast_nullable_to_non_nullable
as Map<String, OptionGroup>,
  ));
}

/// Create a copy of RestaurantDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RestaurantCardCopyWith<$Res> get restaurant {
  
  return $RestaurantCardCopyWith<$Res>(_self.restaurant, (value) {
    return _then(_self.copyWith(restaurant: value));
  });
}
}


/// @nodoc
mixin _$OptionSelection {

 String get groupId; List<String> get choiceIds;
/// Create a copy of OptionSelection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OptionSelectionCopyWith<OptionSelection> get copyWith => _$OptionSelectionCopyWithImpl<OptionSelection>(this as OptionSelection, _$identity);

  /// Serializes this OptionSelection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OptionSelection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OptionSelection&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&const DeepCollectionEquality().equals(other.choiceIds, _this.choiceIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OptionSelection;
  return Object.hash(runtimeType,_this.groupId,const DeepCollectionEquality().hash(_this.choiceIds));
}

@override
String toString() {
  final _this = this as OptionSelection;
  return 'OptionSelection(groupId: ${_this.groupId}, choiceIds: ${_this.choiceIds})';
}


}

/// @nodoc
abstract mixin class $OptionSelectionCopyWith<$Res>  {
  factory $OptionSelectionCopyWith(OptionSelection value, $Res Function(OptionSelection) _then) = _$OptionSelectionCopyWithImpl;
@useResult
$Res call({
 String groupId, List<String> choiceIds
});




}
/// @nodoc
class _$OptionSelectionCopyWithImpl<$Res>
    implements $OptionSelectionCopyWith<$Res> {
  _$OptionSelectionCopyWithImpl(this._self, this._then);

  final OptionSelection _self;
  final $Res Function(OptionSelection) _then;

/// Create a copy of OptionSelection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupId = null,Object? choiceIds = null,}) {
  return _then(OptionSelection(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,choiceIds: null == choiceIds ? _self.choiceIds : choiceIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [OptionSelection].
extension OptionSelectionPatterns on OptionSelection {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OptionSelection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OptionSelection() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OptionSelection value)  $default,){
final _that = this;
switch (_that) {
case _OptionSelection():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OptionSelection value)?  $default,){
final _that = this;
switch (_that) {
case _OptionSelection() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String groupId,  List<String> choiceIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OptionSelection() when $default != null:
return $default(_that.groupId,_that.choiceIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String groupId,  List<String> choiceIds)  $default,) {final _that = this;
switch (_that) {
case _OptionSelection():
return $default(_that.groupId,_that.choiceIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String groupId,  List<String> choiceIds)?  $default,) {final _that = this;
switch (_that) {
case _OptionSelection() when $default != null:
return $default(_that.groupId,_that.choiceIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OptionSelection implements OptionSelection {
  const _OptionSelection({required this.groupId,  List<String> choiceIds = const <String>[]}): _choiceIds = choiceIds;
  factory _OptionSelection.fromJson(Map<String, dynamic> json) => _$OptionSelectionFromJson(json);

@override final  String groupId;
 final  List<String> _choiceIds;
@override@JsonKey() List<String> get choiceIds {
  if (_choiceIds is EqualUnmodifiableListView) return _choiceIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_choiceIds);
}


/// Create a copy of OptionSelection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OptionSelectionCopyWith<_OptionSelection> get copyWith => __$OptionSelectionCopyWithImpl<_OptionSelection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OptionSelectionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OptionSelection&&(identical(other.groupId, groupId) || other.groupId == groupId)&&const DeepCollectionEquality().equals(other.choiceIds, _choiceIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,groupId,const DeepCollectionEquality().hash(_choiceIds));
}

@override
String toString() {
    return 'OptionSelection(groupId: $groupId, choiceIds: $choiceIds)';
}


}

/// @nodoc
abstract mixin class _$OptionSelectionCopyWith<$Res> implements $OptionSelectionCopyWith<$Res> {
  factory _$OptionSelectionCopyWith(_OptionSelection value, $Res Function(_OptionSelection) _then) = __$OptionSelectionCopyWithImpl;
@override @useResult
$Res call({
 String groupId, List<String> choiceIds
});




}
/// @nodoc
class __$OptionSelectionCopyWithImpl<$Res>
    implements _$OptionSelectionCopyWith<$Res> {
  __$OptionSelectionCopyWithImpl(this._self, this._then);

  final _OptionSelection _self;
  final $Res Function(_OptionSelection) _then;

/// Create a copy of OptionSelection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? choiceIds = null,}) {
  return _then(_OptionSelection(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,choiceIds: null == choiceIds ? _self._choiceIds : choiceIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$CartLine {

 String get itemId; int get quantity; List<OptionSelection> get selections; String? get notes;
/// Create a copy of CartLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartLineCopyWith<CartLine> get copyWith => _$CartLineCopyWithImpl<CartLine>(this as CartLine, _$identity);

  /// Serializes this CartLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CartLine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartLine&&(identical(other.itemId, _this.itemId) || other.itemId == _this.itemId)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&const DeepCollectionEquality().equals(other.selections, _this.selections)&&(identical(other.notes, _this.notes) || other.notes == _this.notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CartLine;
  return Object.hash(runtimeType,_this.itemId,_this.quantity,const DeepCollectionEquality().hash(_this.selections),_this.notes);
}

@override
String toString() {
  final _this = this as CartLine;
  return 'CartLine(itemId: ${_this.itemId}, quantity: ${_this.quantity}, selections: ${_this.selections}, notes: ${_this.notes})';
}


}

/// @nodoc
abstract mixin class $CartLineCopyWith<$Res>  {
  factory $CartLineCopyWith(CartLine value, $Res Function(CartLine) _then) = _$CartLineCopyWithImpl;
@useResult
$Res call({
 String itemId, int quantity, List<OptionSelection> selections, String? notes
});




}
/// @nodoc
class _$CartLineCopyWithImpl<$Res>
    implements $CartLineCopyWith<$Res> {
  _$CartLineCopyWithImpl(this._self, this._then);

  final CartLine _self;
  final $Res Function(CartLine) _then;

/// Create a copy of CartLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? quantity = null,Object? selections = null,Object? notes = freezed,}) {
  return _then(CartLine(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,selections: null == selections ? _self.selections : selections // ignore: cast_nullable_to_non_nullable
as List<OptionSelection>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CartLine].
extension CartLinePatterns on CartLine {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartLine() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartLine value)  $default,){
final _that = this;
switch (_that) {
case _CartLine():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartLine value)?  $default,){
final _that = this;
switch (_that) {
case _CartLine() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId,  int quantity,  List<OptionSelection> selections,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartLine() when $default != null:
return $default(_that.itemId,_that.quantity,_that.selections,_that.notes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId,  int quantity,  List<OptionSelection> selections,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _CartLine():
return $default(_that.itemId,_that.quantity,_that.selections,_that.notes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId,  int quantity,  List<OptionSelection> selections,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _CartLine() when $default != null:
return $default(_that.itemId,_that.quantity,_that.selections,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CartLine implements CartLine {
  const _CartLine({required this.itemId, required this.quantity,  List<OptionSelection> selections = const <OptionSelection>[], this.notes}): _selections = selections;
  factory _CartLine.fromJson(Map<String, dynamic> json) => _$CartLineFromJson(json);

@override final  String itemId;
@override final  int quantity;
 final  List<OptionSelection> _selections;
@override@JsonKey() List<OptionSelection> get selections {
  if (_selections is EqualUnmodifiableListView) return _selections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selections);
}

@override final  String? notes;

/// Create a copy of CartLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartLineCopyWith<_CartLine> get copyWith => __$CartLineCopyWithImpl<_CartLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CartLineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartLine&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&const DeepCollectionEquality().equals(other.selections, _selections)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,itemId,quantity,const DeepCollectionEquality().hash(_selections),notes);
}

@override
String toString() {
    return 'CartLine(itemId: $itemId, quantity: $quantity, selections: $selections, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$CartLineCopyWith<$Res> implements $CartLineCopyWith<$Res> {
  factory _$CartLineCopyWith(_CartLine value, $Res Function(_CartLine) _then) = __$CartLineCopyWithImpl;
@override @useResult
$Res call({
 String itemId, int quantity, List<OptionSelection> selections, String? notes
});




}
/// @nodoc
class __$CartLineCopyWithImpl<$Res>
    implements _$CartLineCopyWith<$Res> {
  __$CartLineCopyWithImpl(this._self, this._then);

  final _CartLine _self;
  final $Res Function(_CartLine) _then;

/// Create a copy of CartLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? quantity = null,Object? selections = null,Object? notes = freezed,}) {
  return _then(_CartLine(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,selections: null == selections ? _self._selections : selections // ignore: cast_nullable_to_non_nullable
as List<OptionSelection>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DeliveryAddress {

 String? get label; String get line1; String? get area; String get city; String get state; GeoPoint get location; String? get instructions; String? get contactPhone;/// The id of an address saved in the customer's address book (`GET /v1/me/addresses`); never sent back with a
/// quote or a saved address (the id goes in the path of `PUT /v1/me/addresses/{id}`).
@JsonKey(includeToJson: false) String? get id;
/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryAddressCopyWith<DeliveryAddress> get copyWith => _$DeliveryAddressCopyWithImpl<DeliveryAddress>(this as DeliveryAddress, _$identity);

  /// Serializes this DeliveryAddress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DeliveryAddress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryAddress&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.line1, _this.line1) || other.line1 == _this.line1)&&(identical(other.area, _this.area) || other.area == _this.area)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.instructions, _this.instructions) || other.instructions == _this.instructions)&&(identical(other.contactPhone, _this.contactPhone) || other.contactPhone == _this.contactPhone)&&(identical(other.id, _this.id) || other.id == _this.id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DeliveryAddress;
  return Object.hash(runtimeType,_this.label,_this.line1,_this.area,_this.city,_this.state,_this.location,_this.instructions,_this.contactPhone,_this.id);
}

@override
String toString() {
  final _this = this as DeliveryAddress;
  return 'DeliveryAddress(label: ${_this.label}, line1: ${_this.line1}, area: ${_this.area}, city: ${_this.city}, state: ${_this.state}, location: ${_this.location}, instructions: ${_this.instructions}, contactPhone: ${_this.contactPhone}, id: ${_this.id})';
}


}

/// @nodoc
abstract mixin class $DeliveryAddressCopyWith<$Res>  {
  factory $DeliveryAddressCopyWith(DeliveryAddress value, $Res Function(DeliveryAddress) _then) = _$DeliveryAddressCopyWithImpl;
@useResult
$Res call({
 String? label, String line1, String? area, String city, String state, GeoPoint location, String? instructions, String? contactPhone,@JsonKey(includeToJson: false) String? id
});


$GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class _$DeliveryAddressCopyWithImpl<$Res>
    implements $DeliveryAddressCopyWith<$Res> {
  _$DeliveryAddressCopyWithImpl(this._self, this._then);

  final DeliveryAddress _self;
  final $Res Function(DeliveryAddress) _then;

/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = freezed,Object? line1 = null,Object? area = freezed,Object? city = null,Object? state = null,Object? location = null,Object? instructions = freezed,Object? contactPhone = freezed,Object? id = freezed,}) {
  return _then(DeliveryAddress(
label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,line1: null == line1 ? _self.line1 : line1 // ignore: cast_nullable_to_non_nullable
as String,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [DeliveryAddress].
extension DeliveryAddressPatterns on DeliveryAddress {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryAddress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryAddress() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryAddress value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryAddress():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryAddress value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryAddress() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? label,  String line1,  String? area,  String city,  String state,  GeoPoint location,  String? instructions,  String? contactPhone, @JsonKey(includeToJson: false)  String? id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryAddress() when $default != null:
return $default(_that.label,_that.line1,_that.area,_that.city,_that.state,_that.location,_that.instructions,_that.contactPhone,_that.id);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? label,  String line1,  String? area,  String city,  String state,  GeoPoint location,  String? instructions,  String? contactPhone, @JsonKey(includeToJson: false)  String? id)  $default,) {final _that = this;
switch (_that) {
case _DeliveryAddress():
return $default(_that.label,_that.line1,_that.area,_that.city,_that.state,_that.location,_that.instructions,_that.contactPhone,_that.id);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? label,  String line1,  String? area,  String city,  String state,  GeoPoint location,  String? instructions,  String? contactPhone, @JsonKey(includeToJson: false)  String? id)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryAddress() when $default != null:
return $default(_that.label,_that.line1,_that.area,_that.city,_that.state,_that.location,_that.instructions,_that.contactPhone,_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeliveryAddress implements DeliveryAddress {
  const _DeliveryAddress({this.label, required this.line1, this.area, this.city = 'Lagos', this.state = 'Lagos', required this.location, this.instructions, this.contactPhone, @JsonKey(includeToJson: false) this.id});
  factory _DeliveryAddress.fromJson(Map<String, dynamic> json) => _$DeliveryAddressFromJson(json);

@override final  String? label;
@override final  String line1;
@override final  String? area;
@override@JsonKey() final  String city;
@override@JsonKey() final  String state;
@override final  GeoPoint location;
@override final  String? instructions;
@override final  String? contactPhone;
/// The id of an address saved in the customer's address book (`GET /v1/me/addresses`); never sent back with a
/// quote or a saved address (the id goes in the path of `PUT /v1/me/addresses/{id}`).
@override@JsonKey(includeToJson: false) final  String? id;

/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryAddressCopyWith<_DeliveryAddress> get copyWith => __$DeliveryAddressCopyWithImpl<_DeliveryAddress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeliveryAddressToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryAddress&&(identical(other.label, label) || other.label == label)&&(identical(other.line1, line1) || other.line1 == line1)&&(identical(other.area, area) || other.area == area)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.location, location) || other.location == location)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.contactPhone, contactPhone) || other.contactPhone == contactPhone)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,label,line1,area,city,state,location,instructions,contactPhone,id);
}

@override
String toString() {
    return 'DeliveryAddress(label: $label, line1: $line1, area: $area, city: $city, state: $state, location: $location, instructions: $instructions, contactPhone: $contactPhone, id: $id)';
}


}

/// @nodoc
abstract mixin class _$DeliveryAddressCopyWith<$Res> implements $DeliveryAddressCopyWith<$Res> {
  factory _$DeliveryAddressCopyWith(_DeliveryAddress value, $Res Function(_DeliveryAddress) _then) = __$DeliveryAddressCopyWithImpl;
@override @useResult
$Res call({
 String? label, String line1, String? area, String city, String state, GeoPoint location, String? instructions, String? contactPhone,@JsonKey(includeToJson: false) String? id
});


@override $GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class __$DeliveryAddressCopyWithImpl<$Res>
    implements _$DeliveryAddressCopyWith<$Res> {
  __$DeliveryAddressCopyWithImpl(this._self, this._then);

  final _DeliveryAddress _self;
  final $Res Function(_DeliveryAddress) _then;

/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = freezed,Object? line1 = null,Object? area = freezed,Object? city = null,Object? state = null,Object? location = null,Object? instructions = freezed,Object? contactPhone = freezed,Object? id = freezed,}) {
  return _then(_DeliveryAddress(
label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,line1: null == line1 ? _self.line1 : line1 // ignore: cast_nullable_to_non_nullable
as String,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,contactPhone: freezed == contactPhone ? _self.contactPhone : contactPhone // ignore: cast_nullable_to_non_nullable
as String?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of DeliveryAddress
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// @nodoc
mixin _$PricedLine {

 String get itemId; String get name; int get quantity; int get lineTotalKobo; List<String> get selectionLabels;
/// Create a copy of PricedLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PricedLineCopyWith<PricedLine> get copyWith => _$PricedLineCopyWithImpl<PricedLine>(this as PricedLine, _$identity);

  /// Serializes this PricedLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PricedLine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PricedLine&&(identical(other.itemId, _this.itemId) || other.itemId == _this.itemId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.lineTotalKobo, _this.lineTotalKobo) || other.lineTotalKobo == _this.lineTotalKobo)&&const DeepCollectionEquality().equals(other.selectionLabels, _this.selectionLabels));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PricedLine;
  return Object.hash(runtimeType,_this.itemId,_this.name,_this.quantity,_this.lineTotalKobo,const DeepCollectionEquality().hash(_this.selectionLabels));
}

@override
String toString() {
  final _this = this as PricedLine;
  return 'PricedLine(itemId: ${_this.itemId}, name: ${_this.name}, quantity: ${_this.quantity}, lineTotalKobo: ${_this.lineTotalKobo}, selectionLabels: ${_this.selectionLabels})';
}


}

/// @nodoc
abstract mixin class $PricedLineCopyWith<$Res>  {
  factory $PricedLineCopyWith(PricedLine value, $Res Function(PricedLine) _then) = _$PricedLineCopyWithImpl;
@useResult
$Res call({
 String itemId, String name, int quantity, int lineTotalKobo, List<String> selectionLabels
});




}
/// @nodoc
class _$PricedLineCopyWithImpl<$Res>
    implements $PricedLineCopyWith<$Res> {
  _$PricedLineCopyWithImpl(this._self, this._then);

  final PricedLine _self;
  final $Res Function(PricedLine) _then;

/// Create a copy of PricedLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? name = null,Object? quantity = null,Object? lineTotalKobo = null,Object? selectionLabels = null,}) {
  return _then(PricedLine(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,lineTotalKobo: null == lineTotalKobo ? _self.lineTotalKobo : lineTotalKobo // ignore: cast_nullable_to_non_nullable
as int,selectionLabels: null == selectionLabels ? _self.selectionLabels : selectionLabels // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PricedLine].
extension PricedLinePatterns on PricedLine {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PricedLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PricedLine() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PricedLine value)  $default,){
final _that = this;
switch (_that) {
case _PricedLine():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PricedLine value)?  $default,){
final _that = this;
switch (_that) {
case _PricedLine() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId,  String name,  int quantity,  int lineTotalKobo,  List<String> selectionLabels)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PricedLine() when $default != null:
return $default(_that.itemId,_that.name,_that.quantity,_that.lineTotalKobo,_that.selectionLabels);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId,  String name,  int quantity,  int lineTotalKobo,  List<String> selectionLabels)  $default,) {final _that = this;
switch (_that) {
case _PricedLine():
return $default(_that.itemId,_that.name,_that.quantity,_that.lineTotalKobo,_that.selectionLabels);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId,  String name,  int quantity,  int lineTotalKobo,  List<String> selectionLabels)?  $default,) {final _that = this;
switch (_that) {
case _PricedLine() when $default != null:
return $default(_that.itemId,_that.name,_that.quantity,_that.lineTotalKobo,_that.selectionLabels);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PricedLine implements PricedLine {
  const _PricedLine({required this.itemId, required this.name, required this.quantity, required this.lineTotalKobo,  List<String> selectionLabels = const <String>[]}): _selectionLabels = selectionLabels;
  factory _PricedLine.fromJson(Map<String, dynamic> json) => _$PricedLineFromJson(json);

@override final  String itemId;
@override final  String name;
@override final  int quantity;
@override final  int lineTotalKobo;
 final  List<String> _selectionLabels;
@override@JsonKey() List<String> get selectionLabels {
  if (_selectionLabels is EqualUnmodifiableListView) return _selectionLabels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectionLabels);
}


/// Create a copy of PricedLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PricedLineCopyWith<_PricedLine> get copyWith => __$PricedLineCopyWithImpl<_PricedLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PricedLineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PricedLine&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.lineTotalKobo, lineTotalKobo) || other.lineTotalKobo == lineTotalKobo)&&const DeepCollectionEquality().equals(other.selectionLabels, _selectionLabels));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,itemId,name,quantity,lineTotalKobo,const DeepCollectionEquality().hash(_selectionLabels));
}

@override
String toString() {
    return 'PricedLine(itemId: $itemId, name: $name, quantity: $quantity, lineTotalKobo: $lineTotalKobo, selectionLabels: $selectionLabels)';
}


}

/// @nodoc
abstract mixin class _$PricedLineCopyWith<$Res> implements $PricedLineCopyWith<$Res> {
  factory _$PricedLineCopyWith(_PricedLine value, $Res Function(_PricedLine) _then) = __$PricedLineCopyWithImpl;
@override @useResult
$Res call({
 String itemId, String name, int quantity, int lineTotalKobo, List<String> selectionLabels
});




}
/// @nodoc
class __$PricedLineCopyWithImpl<$Res>
    implements _$PricedLineCopyWith<$Res> {
  __$PricedLineCopyWithImpl(this._self, this._then);

  final _PricedLine _self;
  final $Res Function(_PricedLine) _then;

/// Create a copy of PricedLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? name = null,Object? quantity = null,Object? lineTotalKobo = null,Object? selectionLabels = null,}) {
  return _then(_PricedLine(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,lineTotalKobo: null == lineTotalKobo ? _self.lineTotalKobo : lineTotalKobo // ignore: cast_nullable_to_non_nullable
as int,selectionLabels: null == selectionLabels ? _self._selectionLabels : selectionLabels // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$OrderItem {

 String get name; int get quantity;
/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderItemCopyWith<OrderItem> get copyWith => _$OrderItemCopyWithImpl<OrderItem>(this as OrderItem, _$identity);

  /// Serializes this OrderItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OrderItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderItem&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OrderItem;
  return Object.hash(runtimeType,_this.name,_this.quantity);
}

@override
String toString() {
  final _this = this as OrderItem;
  return 'OrderItem(name: ${_this.name}, quantity: ${_this.quantity})';
}


}

/// @nodoc
abstract mixin class $OrderItemCopyWith<$Res>  {
  factory $OrderItemCopyWith(OrderItem value, $Res Function(OrderItem) _then) = _$OrderItemCopyWithImpl;
@useResult
$Res call({
 String name, int quantity
});




}
/// @nodoc
class _$OrderItemCopyWithImpl<$Res>
    implements $OrderItemCopyWith<$Res> {
  _$OrderItemCopyWithImpl(this._self, this._then);

  final OrderItem _self;
  final $Res Function(OrderItem) _then;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? quantity = null,}) {
  return _then(OrderItem(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderItem].
extension OrderItemPatterns on OrderItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderItem value)  $default,){
final _that = this;
switch (_that) {
case _OrderItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderItem value)?  $default,){
final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int quantity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that.name,_that.quantity);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int quantity)  $default,) {final _that = this;
switch (_that) {
case _OrderItem():
return $default(_that.name,_that.quantity);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int quantity)?  $default,) {final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that.name,_that.quantity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderItem implements OrderItem {
  const _OrderItem({required this.name, this.quantity = 1});
  factory _OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);

@override final  String name;
@override@JsonKey() final  int quantity;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderItemCopyWith<_OrderItem> get copyWith => __$OrderItemCopyWithImpl<_OrderItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderItem&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,quantity);
}

@override
String toString() {
    return 'OrderItem(name: $name, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class _$OrderItemCopyWith<$Res> implements $OrderItemCopyWith<$Res> {
  factory _$OrderItemCopyWith(_OrderItem value, $Res Function(_OrderItem) _then) = __$OrderItemCopyWithImpl;
@override @useResult
$Res call({
 String name, int quantity
});




}
/// @nodoc
class __$OrderItemCopyWithImpl<$Res>
    implements _$OrderItemCopyWith<$Res> {
  __$OrderItemCopyWithImpl(this._self, this._then);

  final _OrderItem _self;
  final $Res Function(_OrderItem) _then;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? quantity = null,}) {
  return _then(_OrderItem(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PriceBreakdown {

 int get subtotalKobo; int get deliveryFeeKobo; int get serviceFeeKobo; int get smallOrderFeeKobo; int get vatKobo; int get discountKobo; int get codFeeKobo; int get linehaulFeeKobo; int get pickupFeeKobo;/// Yummy Chops Plus: fees and VAT the member did not pay (informational).
 int get plusSavingsKobo; int get totalKobo; String? get voucherCode;
/// Create a copy of PriceBreakdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceBreakdownCopyWith<PriceBreakdown> get copyWith => _$PriceBreakdownCopyWithImpl<PriceBreakdown>(this as PriceBreakdown, _$identity);

  /// Serializes this PriceBreakdown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PriceBreakdown;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceBreakdown&&(identical(other.subtotalKobo, _this.subtotalKobo) || other.subtotalKobo == _this.subtotalKobo)&&(identical(other.deliveryFeeKobo, _this.deliveryFeeKobo) || other.deliveryFeeKobo == _this.deliveryFeeKobo)&&(identical(other.serviceFeeKobo, _this.serviceFeeKobo) || other.serviceFeeKobo == _this.serviceFeeKobo)&&(identical(other.smallOrderFeeKobo, _this.smallOrderFeeKobo) || other.smallOrderFeeKobo == _this.smallOrderFeeKobo)&&(identical(other.vatKobo, _this.vatKobo) || other.vatKobo == _this.vatKobo)&&(identical(other.discountKobo, _this.discountKobo) || other.discountKobo == _this.discountKobo)&&(identical(other.codFeeKobo, _this.codFeeKobo) || other.codFeeKobo == _this.codFeeKobo)&&(identical(other.linehaulFeeKobo, _this.linehaulFeeKobo) || other.linehaulFeeKobo == _this.linehaulFeeKobo)&&(identical(other.pickupFeeKobo, _this.pickupFeeKobo) || other.pickupFeeKobo == _this.pickupFeeKobo)&&(identical(other.plusSavingsKobo, _this.plusSavingsKobo) || other.plusSavingsKobo == _this.plusSavingsKobo)&&(identical(other.totalKobo, _this.totalKobo) || other.totalKobo == _this.totalKobo)&&(identical(other.voucherCode, _this.voucherCode) || other.voucherCode == _this.voucherCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PriceBreakdown;
  return Object.hash(runtimeType,_this.subtotalKobo,_this.deliveryFeeKobo,_this.serviceFeeKobo,_this.smallOrderFeeKobo,_this.vatKobo,_this.discountKobo,_this.codFeeKobo,_this.linehaulFeeKobo,_this.pickupFeeKobo,_this.plusSavingsKobo,_this.totalKobo,_this.voucherCode);
}

@override
String toString() {
  final _this = this as PriceBreakdown;
  return 'PriceBreakdown(subtotalKobo: ${_this.subtotalKobo}, deliveryFeeKobo: ${_this.deliveryFeeKobo}, serviceFeeKobo: ${_this.serviceFeeKobo}, smallOrderFeeKobo: ${_this.smallOrderFeeKobo}, vatKobo: ${_this.vatKobo}, discountKobo: ${_this.discountKobo}, codFeeKobo: ${_this.codFeeKobo}, linehaulFeeKobo: ${_this.linehaulFeeKobo}, pickupFeeKobo: ${_this.pickupFeeKobo}, plusSavingsKobo: ${_this.plusSavingsKobo}, totalKobo: ${_this.totalKobo}, voucherCode: ${_this.voucherCode})';
}


}

/// @nodoc
abstract mixin class $PriceBreakdownCopyWith<$Res>  {
  factory $PriceBreakdownCopyWith(PriceBreakdown value, $Res Function(PriceBreakdown) _then) = _$PriceBreakdownCopyWithImpl;
@useResult
$Res call({
 int subtotalKobo, int deliveryFeeKobo, int serviceFeeKobo, int smallOrderFeeKobo, int vatKobo, int discountKobo, int codFeeKobo, int linehaulFeeKobo, int pickupFeeKobo, int plusSavingsKobo, int totalKobo, String? voucherCode
});




}
/// @nodoc
class _$PriceBreakdownCopyWithImpl<$Res>
    implements $PriceBreakdownCopyWith<$Res> {
  _$PriceBreakdownCopyWithImpl(this._self, this._then);

  final PriceBreakdown _self;
  final $Res Function(PriceBreakdown) _then;

/// Create a copy of PriceBreakdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subtotalKobo = null,Object? deliveryFeeKobo = null,Object? serviceFeeKobo = null,Object? smallOrderFeeKobo = null,Object? vatKobo = null,Object? discountKobo = null,Object? codFeeKobo = null,Object? linehaulFeeKobo = null,Object? pickupFeeKobo = null,Object? plusSavingsKobo = null,Object? totalKobo = null,Object? voucherCode = freezed,}) {
  return _then(PriceBreakdown(
subtotalKobo: null == subtotalKobo ? _self.subtotalKobo : subtotalKobo // ignore: cast_nullable_to_non_nullable
as int,deliveryFeeKobo: null == deliveryFeeKobo ? _self.deliveryFeeKobo : deliveryFeeKobo // ignore: cast_nullable_to_non_nullable
as int,serviceFeeKobo: null == serviceFeeKobo ? _self.serviceFeeKobo : serviceFeeKobo // ignore: cast_nullable_to_non_nullable
as int,smallOrderFeeKobo: null == smallOrderFeeKobo ? _self.smallOrderFeeKobo : smallOrderFeeKobo // ignore: cast_nullable_to_non_nullable
as int,vatKobo: null == vatKobo ? _self.vatKobo : vatKobo // ignore: cast_nullable_to_non_nullable
as int,discountKobo: null == discountKobo ? _self.discountKobo : discountKobo // ignore: cast_nullable_to_non_nullable
as int,codFeeKobo: null == codFeeKobo ? _self.codFeeKobo : codFeeKobo // ignore: cast_nullable_to_non_nullable
as int,linehaulFeeKobo: null == linehaulFeeKobo ? _self.linehaulFeeKobo : linehaulFeeKobo // ignore: cast_nullable_to_non_nullable
as int,pickupFeeKobo: null == pickupFeeKobo ? _self.pickupFeeKobo : pickupFeeKobo // ignore: cast_nullable_to_non_nullable
as int,plusSavingsKobo: null == plusSavingsKobo ? _self.plusSavingsKobo : plusSavingsKobo // ignore: cast_nullable_to_non_nullable
as int,totalKobo: null == totalKobo ? _self.totalKobo : totalKobo // ignore: cast_nullable_to_non_nullable
as int,voucherCode: freezed == voucherCode ? _self.voucherCode : voucherCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PriceBreakdown].
extension PriceBreakdownPatterns on PriceBreakdown {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PriceBreakdown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PriceBreakdown() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PriceBreakdown value)  $default,){
final _that = this;
switch (_that) {
case _PriceBreakdown():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PriceBreakdown value)?  $default,){
final _that = this;
switch (_that) {
case _PriceBreakdown() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int subtotalKobo,  int deliveryFeeKobo,  int serviceFeeKobo,  int smallOrderFeeKobo,  int vatKobo,  int discountKobo,  int codFeeKobo,  int linehaulFeeKobo,  int pickupFeeKobo,  int plusSavingsKobo,  int totalKobo,  String? voucherCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PriceBreakdown() when $default != null:
return $default(_that.subtotalKobo,_that.deliveryFeeKobo,_that.serviceFeeKobo,_that.smallOrderFeeKobo,_that.vatKobo,_that.discountKobo,_that.codFeeKobo,_that.linehaulFeeKobo,_that.pickupFeeKobo,_that.plusSavingsKobo,_that.totalKobo,_that.voucherCode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int subtotalKobo,  int deliveryFeeKobo,  int serviceFeeKobo,  int smallOrderFeeKobo,  int vatKobo,  int discountKobo,  int codFeeKobo,  int linehaulFeeKobo,  int pickupFeeKobo,  int plusSavingsKobo,  int totalKobo,  String? voucherCode)  $default,) {final _that = this;
switch (_that) {
case _PriceBreakdown():
return $default(_that.subtotalKobo,_that.deliveryFeeKobo,_that.serviceFeeKobo,_that.smallOrderFeeKobo,_that.vatKobo,_that.discountKobo,_that.codFeeKobo,_that.linehaulFeeKobo,_that.pickupFeeKobo,_that.plusSavingsKobo,_that.totalKobo,_that.voucherCode);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int subtotalKobo,  int deliveryFeeKobo,  int serviceFeeKobo,  int smallOrderFeeKobo,  int vatKobo,  int discountKobo,  int codFeeKobo,  int linehaulFeeKobo,  int pickupFeeKobo,  int plusSavingsKobo,  int totalKobo,  String? voucherCode)?  $default,) {final _that = this;
switch (_that) {
case _PriceBreakdown() when $default != null:
return $default(_that.subtotalKobo,_that.deliveryFeeKobo,_that.serviceFeeKobo,_that.smallOrderFeeKobo,_that.vatKobo,_that.discountKobo,_that.codFeeKobo,_that.linehaulFeeKobo,_that.pickupFeeKobo,_that.plusSavingsKobo,_that.totalKobo,_that.voucherCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PriceBreakdown implements PriceBreakdown {
  const _PriceBreakdown({required this.subtotalKobo, this.deliveryFeeKobo = 0, this.serviceFeeKobo = 0, this.smallOrderFeeKobo = 0, this.vatKobo = 0, this.discountKobo = 0, this.codFeeKobo = 0, this.linehaulFeeKobo = 0, this.pickupFeeKobo = 0, this.plusSavingsKobo = 0, required this.totalKobo, this.voucherCode});
  factory _PriceBreakdown.fromJson(Map<String, dynamic> json) => _$PriceBreakdownFromJson(json);

@override final  int subtotalKobo;
@override@JsonKey() final  int deliveryFeeKobo;
@override@JsonKey() final  int serviceFeeKobo;
@override@JsonKey() final  int smallOrderFeeKobo;
@override@JsonKey() final  int vatKobo;
@override@JsonKey() final  int discountKobo;
@override@JsonKey() final  int codFeeKobo;
@override@JsonKey() final  int linehaulFeeKobo;
@override@JsonKey() final  int pickupFeeKobo;
/// Yummy Chops Plus: fees and VAT the member did not pay (informational).
@override@JsonKey() final  int plusSavingsKobo;
@override final  int totalKobo;
@override final  String? voucherCode;

/// Create a copy of PriceBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceBreakdownCopyWith<_PriceBreakdown> get copyWith => __$PriceBreakdownCopyWithImpl<_PriceBreakdown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PriceBreakdownToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriceBreakdown&&(identical(other.subtotalKobo, subtotalKobo) || other.subtotalKobo == subtotalKobo)&&(identical(other.deliveryFeeKobo, deliveryFeeKobo) || other.deliveryFeeKobo == deliveryFeeKobo)&&(identical(other.serviceFeeKobo, serviceFeeKobo) || other.serviceFeeKobo == serviceFeeKobo)&&(identical(other.smallOrderFeeKobo, smallOrderFeeKobo) || other.smallOrderFeeKobo == smallOrderFeeKobo)&&(identical(other.vatKobo, vatKobo) || other.vatKobo == vatKobo)&&(identical(other.discountKobo, discountKobo) || other.discountKobo == discountKobo)&&(identical(other.codFeeKobo, codFeeKobo) || other.codFeeKobo == codFeeKobo)&&(identical(other.linehaulFeeKobo, linehaulFeeKobo) || other.linehaulFeeKobo == linehaulFeeKobo)&&(identical(other.pickupFeeKobo, pickupFeeKobo) || other.pickupFeeKobo == pickupFeeKobo)&&(identical(other.plusSavingsKobo, plusSavingsKobo) || other.plusSavingsKobo == plusSavingsKobo)&&(identical(other.totalKobo, totalKobo) || other.totalKobo == totalKobo)&&(identical(other.voucherCode, voucherCode) || other.voucherCode == voucherCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,subtotalKobo,deliveryFeeKobo,serviceFeeKobo,smallOrderFeeKobo,vatKobo,discountKobo,codFeeKobo,linehaulFeeKobo,pickupFeeKobo,plusSavingsKobo,totalKobo,voucherCode);
}

@override
String toString() {
    return 'PriceBreakdown(subtotalKobo: $subtotalKobo, deliveryFeeKobo: $deliveryFeeKobo, serviceFeeKobo: $serviceFeeKobo, smallOrderFeeKobo: $smallOrderFeeKobo, vatKobo: $vatKobo, discountKobo: $discountKobo, codFeeKobo: $codFeeKobo, linehaulFeeKobo: $linehaulFeeKobo, pickupFeeKobo: $pickupFeeKobo, plusSavingsKobo: $plusSavingsKobo, totalKobo: $totalKobo, voucherCode: $voucherCode)';
}


}

/// @nodoc
abstract mixin class _$PriceBreakdownCopyWith<$Res> implements $PriceBreakdownCopyWith<$Res> {
  factory _$PriceBreakdownCopyWith(_PriceBreakdown value, $Res Function(_PriceBreakdown) _then) = __$PriceBreakdownCopyWithImpl;
@override @useResult
$Res call({
 int subtotalKobo, int deliveryFeeKobo, int serviceFeeKobo, int smallOrderFeeKobo, int vatKobo, int discountKobo, int codFeeKobo, int linehaulFeeKobo, int pickupFeeKobo, int plusSavingsKobo, int totalKobo, String? voucherCode
});




}
/// @nodoc
class __$PriceBreakdownCopyWithImpl<$Res>
    implements _$PriceBreakdownCopyWith<$Res> {
  __$PriceBreakdownCopyWithImpl(this._self, this._then);

  final _PriceBreakdown _self;
  final $Res Function(_PriceBreakdown) _then;

/// Create a copy of PriceBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subtotalKobo = null,Object? deliveryFeeKobo = null,Object? serviceFeeKobo = null,Object? smallOrderFeeKobo = null,Object? vatKobo = null,Object? discountKobo = null,Object? codFeeKobo = null,Object? linehaulFeeKobo = null,Object? pickupFeeKobo = null,Object? plusSavingsKobo = null,Object? totalKobo = null,Object? voucherCode = freezed,}) {
  return _then(_PriceBreakdown(
subtotalKobo: null == subtotalKobo ? _self.subtotalKobo : subtotalKobo // ignore: cast_nullable_to_non_nullable
as int,deliveryFeeKobo: null == deliveryFeeKobo ? _self.deliveryFeeKobo : deliveryFeeKobo // ignore: cast_nullable_to_non_nullable
as int,serviceFeeKobo: null == serviceFeeKobo ? _self.serviceFeeKobo : serviceFeeKobo // ignore: cast_nullable_to_non_nullable
as int,smallOrderFeeKobo: null == smallOrderFeeKobo ? _self.smallOrderFeeKobo : smallOrderFeeKobo // ignore: cast_nullable_to_non_nullable
as int,vatKobo: null == vatKobo ? _self.vatKobo : vatKobo // ignore: cast_nullable_to_non_nullable
as int,discountKobo: null == discountKobo ? _self.discountKobo : discountKobo // ignore: cast_nullable_to_non_nullable
as int,codFeeKobo: null == codFeeKobo ? _self.codFeeKobo : codFeeKobo // ignore: cast_nullable_to_non_nullable
as int,linehaulFeeKobo: null == linehaulFeeKobo ? _self.linehaulFeeKobo : linehaulFeeKobo // ignore: cast_nullable_to_non_nullable
as int,pickupFeeKobo: null == pickupFeeKobo ? _self.pickupFeeKobo : pickupFeeKobo // ignore: cast_nullable_to_non_nullable
as int,plusSavingsKobo: null == plusSavingsKobo ? _self.plusSavingsKobo : plusSavingsKobo // ignore: cast_nullable_to_non_nullable
as int,totalKobo: null == totalKobo ? _self.totalKobo : totalKobo // ignore: cast_nullable_to_non_nullable
as int,voucherCode: freezed == voucherCode ? _self.voucherCode : voucherCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Quote {

 String get id; String get restaurantName; List<PricedLine> get lines; PriceBreakdown get breakdown; String get fulfillment; int get etaMinutes; DateTime get estimatedDeliveryAt; DateTime get expiresAt;
/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuoteCopyWith<Quote> get copyWith => _$QuoteCopyWithImpl<Quote>(this as Quote, _$identity);

  /// Serializes this Quote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Quote;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Quote&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.restaurantName, _this.restaurantName) || other.restaurantName == _this.restaurantName)&&const DeepCollectionEquality().equals(other.lines, _this.lines)&&(identical(other.breakdown, _this.breakdown) || other.breakdown == _this.breakdown)&&(identical(other.fulfillment, _this.fulfillment) || other.fulfillment == _this.fulfillment)&&(identical(other.etaMinutes, _this.etaMinutes) || other.etaMinutes == _this.etaMinutes)&&(identical(other.estimatedDeliveryAt, _this.estimatedDeliveryAt) || other.estimatedDeliveryAt == _this.estimatedDeliveryAt)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Quote;
  return Object.hash(runtimeType,_this.id,_this.restaurantName,const DeepCollectionEquality().hash(_this.lines),_this.breakdown,_this.fulfillment,_this.etaMinutes,_this.estimatedDeliveryAt,_this.expiresAt);
}

@override
String toString() {
  final _this = this as Quote;
  return 'Quote(id: ${_this.id}, restaurantName: ${_this.restaurantName}, lines: ${_this.lines}, breakdown: ${_this.breakdown}, fulfillment: ${_this.fulfillment}, etaMinutes: ${_this.etaMinutes}, estimatedDeliveryAt: ${_this.estimatedDeliveryAt}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $QuoteCopyWith<$Res>  {
  factory $QuoteCopyWith(Quote value, $Res Function(Quote) _then) = _$QuoteCopyWithImpl;
@useResult
$Res call({
 String id, String restaurantName, List<PricedLine> lines, PriceBreakdown breakdown, String fulfillment, int etaMinutes, DateTime estimatedDeliveryAt, DateTime expiresAt
});


$PriceBreakdownCopyWith<$Res> get breakdown;

}
/// @nodoc
class _$QuoteCopyWithImpl<$Res>
    implements $QuoteCopyWith<$Res> {
  _$QuoteCopyWithImpl(this._self, this._then);

  final Quote _self;
  final $Res Function(Quote) _then;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? restaurantName = null,Object? lines = null,Object? breakdown = null,Object? fulfillment = null,Object? etaMinutes = null,Object? estimatedDeliveryAt = null,Object? expiresAt = null,}) {
  return _then(Quote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,restaurantName: null == restaurantName ? _self.restaurantName : restaurantName // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<PricedLine>,breakdown: null == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as PriceBreakdown,fulfillment: null == fulfillment ? _self.fulfillment : fulfillment // ignore: cast_nullable_to_non_nullable
as String,etaMinutes: null == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as int,estimatedDeliveryAt: null == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceBreakdownCopyWith<$Res> get breakdown {
  
  return $PriceBreakdownCopyWith<$Res>(_self.breakdown, (value) {
    return _then(_self.copyWith(breakdown: value));
  });
}
}


/// Adds pattern-matching-related methods to [Quote].
extension QuotePatterns on Quote {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Quote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Quote value)  $default,){
final _that = this;
switch (_that) {
case _Quote():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Quote value)?  $default,){
final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String restaurantName,  List<PricedLine> lines,  PriceBreakdown breakdown,  String fulfillment,  int etaMinutes,  DateTime estimatedDeliveryAt,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that.id,_that.restaurantName,_that.lines,_that.breakdown,_that.fulfillment,_that.etaMinutes,_that.estimatedDeliveryAt,_that.expiresAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String restaurantName,  List<PricedLine> lines,  PriceBreakdown breakdown,  String fulfillment,  int etaMinutes,  DateTime estimatedDeliveryAt,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _Quote():
return $default(_that.id,_that.restaurantName,_that.lines,_that.breakdown,_that.fulfillment,_that.etaMinutes,_that.estimatedDeliveryAt,_that.expiresAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String restaurantName,  List<PricedLine> lines,  PriceBreakdown breakdown,  String fulfillment,  int etaMinutes,  DateTime estimatedDeliveryAt,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that.id,_that.restaurantName,_that.lines,_that.breakdown,_that.fulfillment,_that.etaMinutes,_that.estimatedDeliveryAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Quote implements Quote {
  const _Quote({required this.id, required this.restaurantName,  List<PricedLine> lines = const <PricedLine>[], required this.breakdown, required this.fulfillment, required this.etaMinutes, required this.estimatedDeliveryAt, required this.expiresAt}): _lines = lines;
  factory _Quote.fromJson(Map<String, dynamic> json) => _$QuoteFromJson(json);

@override final  String id;
@override final  String restaurantName;
 final  List<PricedLine> _lines;
@override@JsonKey() List<PricedLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

@override final  PriceBreakdown breakdown;
@override final  String fulfillment;
@override final  int etaMinutes;
@override final  DateTime estimatedDeliveryAt;
@override final  DateTime expiresAt;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuoteCopyWith<_Quote> get copyWith => __$QuoteCopyWithImpl<_Quote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuoteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Quote&&(identical(other.id, id) || other.id == id)&&(identical(other.restaurantName, restaurantName) || other.restaurantName == restaurantName)&&const DeepCollectionEquality().equals(other.lines, _lines)&&(identical(other.breakdown, breakdown) || other.breakdown == breakdown)&&(identical(other.fulfillment, fulfillment) || other.fulfillment == fulfillment)&&(identical(other.etaMinutes, etaMinutes) || other.etaMinutes == etaMinutes)&&(identical(other.estimatedDeliveryAt, estimatedDeliveryAt) || other.estimatedDeliveryAt == estimatedDeliveryAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,restaurantName,const DeepCollectionEquality().hash(_lines),breakdown,fulfillment,etaMinutes,estimatedDeliveryAt,expiresAt);
}

@override
String toString() {
    return 'Quote(id: $id, restaurantName: $restaurantName, lines: $lines, breakdown: $breakdown, fulfillment: $fulfillment, etaMinutes: $etaMinutes, estimatedDeliveryAt: $estimatedDeliveryAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$QuoteCopyWith<$Res> implements $QuoteCopyWith<$Res> {
  factory _$QuoteCopyWith(_Quote value, $Res Function(_Quote) _then) = __$QuoteCopyWithImpl;
@override @useResult
$Res call({
 String id, String restaurantName, List<PricedLine> lines, PriceBreakdown breakdown, String fulfillment, int etaMinutes, DateTime estimatedDeliveryAt, DateTime expiresAt
});


@override $PriceBreakdownCopyWith<$Res> get breakdown;

}
/// @nodoc
class __$QuoteCopyWithImpl<$Res>
    implements _$QuoteCopyWith<$Res> {
  __$QuoteCopyWithImpl(this._self, this._then);

  final _Quote _self;
  final $Res Function(_Quote) _then;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? restaurantName = null,Object? lines = null,Object? breakdown = null,Object? fulfillment = null,Object? etaMinutes = null,Object? estimatedDeliveryAt = null,Object? expiresAt = null,}) {
  return _then(_Quote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,restaurantName: null == restaurantName ? _self.restaurantName : restaurantName // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<PricedLine>,breakdown: null == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as PriceBreakdown,fulfillment: null == fulfillment ? _self.fulfillment : fulfillment // ignore: cast_nullable_to_non_nullable
as String,etaMinutes: null == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as int,estimatedDeliveryAt: null == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceBreakdownCopyWith<$Res> get breakdown {
  
  return $PriceBreakdownCopyWith<$Res>(_self.breakdown, (value) {
    return _then(_self.copyWith(breakdown: value));
  });
}
}


/// @nodoc
mixin _$OrderProgress {

 int get step; int get totalSteps; String get label;/// Waybills use their own steps (Booked, At the hub, On the way, Arrived, Delivered).
 List<String> get steps;
/// Create a copy of OrderProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderProgressCopyWith<OrderProgress> get copyWith => _$OrderProgressCopyWithImpl<OrderProgress>(this as OrderProgress, _$identity);

  /// Serializes this OrderProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OrderProgress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderProgress&&(identical(other.step, _this.step) || other.step == _this.step)&&(identical(other.totalSteps, _this.totalSteps) || other.totalSteps == _this.totalSteps)&&(identical(other.label, _this.label) || other.label == _this.label)&&const DeepCollectionEquality().equals(other.steps, _this.steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OrderProgress;
  return Object.hash(runtimeType,_this.step,_this.totalSteps,_this.label,const DeepCollectionEquality().hash(_this.steps));
}

@override
String toString() {
  final _this = this as OrderProgress;
  return 'OrderProgress(step: ${_this.step}, totalSteps: ${_this.totalSteps}, label: ${_this.label}, steps: ${_this.steps})';
}


}

/// @nodoc
abstract mixin class $OrderProgressCopyWith<$Res>  {
  factory $OrderProgressCopyWith(OrderProgress value, $Res Function(OrderProgress) _then) = _$OrderProgressCopyWithImpl;
@useResult
$Res call({
 int step, int totalSteps, String label, List<String> steps
});




}
/// @nodoc
class _$OrderProgressCopyWithImpl<$Res>
    implements $OrderProgressCopyWith<$Res> {
  _$OrderProgressCopyWithImpl(this._self, this._then);

  final OrderProgress _self;
  final $Res Function(OrderProgress) _then;

/// Create a copy of OrderProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? totalSteps = null,Object? label = null,Object? steps = null,}) {
  return _then(OrderProgress(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,totalSteps: null == totalSteps ? _self.totalSteps : totalSteps // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderProgress].
extension OrderProgressPatterns on OrderProgress {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderProgress() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderProgress value)  $default,){
final _that = this;
switch (_that) {
case _OrderProgress():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderProgress value)?  $default,){
final _that = this;
switch (_that) {
case _OrderProgress() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int step,  int totalSteps,  String label,  List<String> steps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderProgress() when $default != null:
return $default(_that.step,_that.totalSteps,_that.label,_that.steps);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int step,  int totalSteps,  String label,  List<String> steps)  $default,) {final _that = this;
switch (_that) {
case _OrderProgress():
return $default(_that.step,_that.totalSteps,_that.label,_that.steps);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int step,  int totalSteps,  String label,  List<String> steps)?  $default,) {final _that = this;
switch (_that) {
case _OrderProgress() when $default != null:
return $default(_that.step,_that.totalSteps,_that.label,_that.steps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderProgress implements OrderProgress {
  const _OrderProgress({required this.step, this.totalSteps = 5, required this.label,  List<String> steps = const <String>[]}): _steps = steps;
  factory _OrderProgress.fromJson(Map<String, dynamic> json) => _$OrderProgressFromJson(json);

@override final  int step;
@override@JsonKey() final  int totalSteps;
@override final  String label;
/// Waybills use their own steps (Booked, At the hub, On the way, Arrived, Delivered).
 final  List<String> _steps;
/// Waybills use their own steps (Booked, At the hub, On the way, Arrived, Delivered).
@override@JsonKey() List<String> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}


/// Create a copy of OrderProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderProgressCopyWith<_OrderProgress> get copyWith => __$OrderProgressCopyWithImpl<_OrderProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderProgressToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderProgress&&(identical(other.step, step) || other.step == step)&&(identical(other.totalSteps, totalSteps) || other.totalSteps == totalSteps)&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other.steps, _steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,step,totalSteps,label,const DeepCollectionEquality().hash(_steps));
}

@override
String toString() {
    return 'OrderProgress(step: $step, totalSteps: $totalSteps, label: $label, steps: $steps)';
}


}

/// @nodoc
abstract mixin class _$OrderProgressCopyWith<$Res> implements $OrderProgressCopyWith<$Res> {
  factory _$OrderProgressCopyWith(_OrderProgress value, $Res Function(_OrderProgress) _then) = __$OrderProgressCopyWithImpl;
@override @useResult
$Res call({
 int step, int totalSteps, String label, List<String> steps
});




}
/// @nodoc
class __$OrderProgressCopyWithImpl<$Res>
    implements _$OrderProgressCopyWith<$Res> {
  __$OrderProgressCopyWithImpl(this._self, this._then);

  final _OrderProgress _self;
  final $Res Function(_OrderProgress) _then;

/// Create a copy of OrderProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? totalSteps = null,Object? label = null,Object? steps = null,}) {
  return _then(_OrderProgress(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,totalSteps: null == totalSteps ? _self.totalSteps : totalSteps // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$Order {

 String get id; String get shortCode; String get vertical; String get status; String get restaurantName; String get fulfillment; List<PricedLine> get lines;/// The rider's view: what to collect, as names and quantities (riders never see prices, so no `lines`).
 List<OrderItem> get items; PriceBreakdown? get breakdown; DeliveryAddress? get deliveryAddress; OrderProgress? get progress; String? get riderName; String? get customerName; String? get restaurantAddress; GeoPoint? get restaurantLocation; DateTime? get estimatedDeliveryAt; DateTime? get readyAt; DateTime? get createdAt; int? get riderPayKobo; bool get reviewed; ParcelDetails? get parcel; int get refundTotalKobo; OrderPayment get payment; DateTime? get cashCollectedAt; String? get paymentMethod; int get collectCashKobo;/// Interstate waybill details (vertical 'waybill').
 WaybillDetails? get waybill;/// Rider view of a waybill's rider job: 'first_mile' ends with hub staff, 'last_mile' at the door.
 String? get legKind; bool get hubHandover;/// Placed by the host of a group order.
 String? get groupOrderId;/// Rider view: the number to call at the shop (branch manager, else the shop, else the business).
 String? get restaurantPhone;/// Orders paid together from one mixed cart share a trip: one rider, one delivery code (ADR-0030).
 String? get tripId;
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderCopyWith<Order> get copyWith => _$OrderCopyWithImpl<Order>(this as Order, _$identity);

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Order;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Order&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.shortCode, _this.shortCode) || other.shortCode == _this.shortCode)&&(identical(other.vertical, _this.vertical) || other.vertical == _this.vertical)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.restaurantName, _this.restaurantName) || other.restaurantName == _this.restaurantName)&&(identical(other.fulfillment, _this.fulfillment) || other.fulfillment == _this.fulfillment)&&const DeepCollectionEquality().equals(other.lines, _this.lines)&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.breakdown, _this.breakdown) || other.breakdown == _this.breakdown)&&(identical(other.deliveryAddress, _this.deliveryAddress) || other.deliveryAddress == _this.deliveryAddress)&&(identical(other.progress, _this.progress) || other.progress == _this.progress)&&(identical(other.riderName, _this.riderName) || other.riderName == _this.riderName)&&(identical(other.customerName, _this.customerName) || other.customerName == _this.customerName)&&(identical(other.restaurantAddress, _this.restaurantAddress) || other.restaurantAddress == _this.restaurantAddress)&&(identical(other.restaurantLocation, _this.restaurantLocation) || other.restaurantLocation == _this.restaurantLocation)&&(identical(other.estimatedDeliveryAt, _this.estimatedDeliveryAt) || other.estimatedDeliveryAt == _this.estimatedDeliveryAt)&&(identical(other.readyAt, _this.readyAt) || other.readyAt == _this.readyAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.riderPayKobo, _this.riderPayKobo) || other.riderPayKobo == _this.riderPayKobo)&&(identical(other.reviewed, _this.reviewed) || other.reviewed == _this.reviewed)&&(identical(other.parcel, _this.parcel) || other.parcel == _this.parcel)&&(identical(other.refundTotalKobo, _this.refundTotalKobo) || other.refundTotalKobo == _this.refundTotalKobo)&&(identical(other.payment, _this.payment) || other.payment == _this.payment)&&(identical(other.cashCollectedAt, _this.cashCollectedAt) || other.cashCollectedAt == _this.cashCollectedAt)&&(identical(other.paymentMethod, _this.paymentMethod) || other.paymentMethod == _this.paymentMethod)&&(identical(other.collectCashKobo, _this.collectCashKobo) || other.collectCashKobo == _this.collectCashKobo)&&(identical(other.waybill, _this.waybill) || other.waybill == _this.waybill)&&(identical(other.legKind, _this.legKind) || other.legKind == _this.legKind)&&(identical(other.hubHandover, _this.hubHandover) || other.hubHandover == _this.hubHandover)&&(identical(other.groupOrderId, _this.groupOrderId) || other.groupOrderId == _this.groupOrderId)&&(identical(other.restaurantPhone, _this.restaurantPhone) || other.restaurantPhone == _this.restaurantPhone)&&(identical(other.tripId, _this.tripId) || other.tripId == _this.tripId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Order;
  return Object.hashAll([runtimeType,_this.id,_this.shortCode,_this.vertical,_this.status,_this.restaurantName,_this.fulfillment,const DeepCollectionEquality().hash(_this.lines),const DeepCollectionEquality().hash(_this.items),_this.breakdown,_this.deliveryAddress,_this.progress,_this.riderName,_this.customerName,_this.restaurantAddress,_this.restaurantLocation,_this.estimatedDeliveryAt,_this.readyAt,_this.createdAt,_this.riderPayKobo,_this.reviewed,_this.parcel,_this.refundTotalKobo,_this.payment,_this.cashCollectedAt,_this.paymentMethod,_this.collectCashKobo,_this.waybill,_this.legKind,_this.hubHandover,_this.groupOrderId,_this.restaurantPhone,_this.tripId]);
}

@override
String toString() {
  final _this = this as Order;
  return 'Order(id: ${_this.id}, shortCode: ${_this.shortCode}, vertical: ${_this.vertical}, status: ${_this.status}, restaurantName: ${_this.restaurantName}, fulfillment: ${_this.fulfillment}, lines: ${_this.lines}, items: ${_this.items}, breakdown: ${_this.breakdown}, deliveryAddress: ${_this.deliveryAddress}, progress: ${_this.progress}, riderName: ${_this.riderName}, customerName: ${_this.customerName}, restaurantAddress: ${_this.restaurantAddress}, restaurantLocation: ${_this.restaurantLocation}, estimatedDeliveryAt: ${_this.estimatedDeliveryAt}, readyAt: ${_this.readyAt}, createdAt: ${_this.createdAt}, riderPayKobo: ${_this.riderPayKobo}, reviewed: ${_this.reviewed}, parcel: ${_this.parcel}, refundTotalKobo: ${_this.refundTotalKobo}, payment: ${_this.payment}, cashCollectedAt: ${_this.cashCollectedAt}, paymentMethod: ${_this.paymentMethod}, collectCashKobo: ${_this.collectCashKobo}, waybill: ${_this.waybill}, legKind: ${_this.legKind}, hubHandover: ${_this.hubHandover}, groupOrderId: ${_this.groupOrderId}, restaurantPhone: ${_this.restaurantPhone}, tripId: ${_this.tripId})';
}


}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res>  {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) = _$OrderCopyWithImpl;
@useResult
$Res call({
 String id, String shortCode, String vertical, String status, String restaurantName, String fulfillment, List<PricedLine> lines, List<OrderItem> items, PriceBreakdown? breakdown, DeliveryAddress? deliveryAddress, OrderProgress? progress, String? riderName, String? customerName, String? restaurantAddress, GeoPoint? restaurantLocation, DateTime? estimatedDeliveryAt, DateTime? readyAt, DateTime? createdAt, int? riderPayKobo, bool reviewed, ParcelDetails? parcel, int refundTotalKobo, OrderPayment payment, DateTime? cashCollectedAt, String? paymentMethod, int collectCashKobo, WaybillDetails? waybill, String? legKind, bool hubHandover, String? groupOrderId, String? restaurantPhone, String? tripId
});


$PriceBreakdownCopyWith<$Res>? get breakdown;$DeliveryAddressCopyWith<$Res>? get deliveryAddress;$OrderProgressCopyWith<$Res>? get progress;$GeoPointCopyWith<$Res>? get restaurantLocation;$ParcelDetailsCopyWith<$Res>? get parcel;$OrderPaymentCopyWith<$Res> get payment;$WaybillDetailsCopyWith<$Res>? get waybill;

}
/// @nodoc
class _$OrderCopyWithImpl<$Res>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? shortCode = null,Object? vertical = null,Object? status = null,Object? restaurantName = null,Object? fulfillment = null,Object? lines = null,Object? items = null,Object? breakdown = freezed,Object? deliveryAddress = freezed,Object? progress = freezed,Object? riderName = freezed,Object? customerName = freezed,Object? restaurantAddress = freezed,Object? restaurantLocation = freezed,Object? estimatedDeliveryAt = freezed,Object? readyAt = freezed,Object? createdAt = freezed,Object? riderPayKobo = freezed,Object? reviewed = null,Object? parcel = freezed,Object? refundTotalKobo = null,Object? payment = null,Object? cashCollectedAt = freezed,Object? paymentMethod = freezed,Object? collectCashKobo = null,Object? waybill = freezed,Object? legKind = freezed,Object? hubHandover = null,Object? groupOrderId = freezed,Object? restaurantPhone = freezed,Object? tripId = freezed,}) {
  return _then(Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shortCode: null == shortCode ? _self.shortCode : shortCode // ignore: cast_nullable_to_non_nullable
as String,vertical: null == vertical ? _self.vertical : vertical // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,restaurantName: null == restaurantName ? _self.restaurantName : restaurantName // ignore: cast_nullable_to_non_nullable
as String,fulfillment: null == fulfillment ? _self.fulfillment : fulfillment // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<PricedLine>,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<OrderItem>,breakdown: freezed == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as PriceBreakdown?,deliveryAddress: freezed == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as DeliveryAddress?,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as OrderProgress?,riderName: freezed == riderName ? _self.riderName : riderName // ignore: cast_nullable_to_non_nullable
as String?,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,restaurantAddress: freezed == restaurantAddress ? _self.restaurantAddress : restaurantAddress // ignore: cast_nullable_to_non_nullable
as String?,restaurantLocation: freezed == restaurantLocation ? _self.restaurantLocation : restaurantLocation // ignore: cast_nullable_to_non_nullable
as GeoPoint?,estimatedDeliveryAt: freezed == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime?,readyAt: freezed == readyAt ? _self.readyAt : readyAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,riderPayKobo: freezed == riderPayKobo ? _self.riderPayKobo : riderPayKobo // ignore: cast_nullable_to_non_nullable
as int?,reviewed: null == reviewed ? _self.reviewed : reviewed // ignore: cast_nullable_to_non_nullable
as bool,parcel: freezed == parcel ? _self.parcel : parcel // ignore: cast_nullable_to_non_nullable
as ParcelDetails?,refundTotalKobo: null == refundTotalKobo ? _self.refundTotalKobo : refundTotalKobo // ignore: cast_nullable_to_non_nullable
as int,payment: null == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as OrderPayment,cashCollectedAt: freezed == cashCollectedAt ? _self.cashCollectedAt : cashCollectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,collectCashKobo: null == collectCashKobo ? _self.collectCashKobo : collectCashKobo // ignore: cast_nullable_to_non_nullable
as int,waybill: freezed == waybill ? _self.waybill : waybill // ignore: cast_nullable_to_non_nullable
as WaybillDetails?,legKind: freezed == legKind ? _self.legKind : legKind // ignore: cast_nullable_to_non_nullable
as String?,hubHandover: null == hubHandover ? _self.hubHandover : hubHandover // ignore: cast_nullable_to_non_nullable
as bool,groupOrderId: freezed == groupOrderId ? _self.groupOrderId : groupOrderId // ignore: cast_nullable_to_non_nullable
as String?,restaurantPhone: freezed == restaurantPhone ? _self.restaurantPhone : restaurantPhone // ignore: cast_nullable_to_non_nullable
as String?,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceBreakdownCopyWith<$Res>? get breakdown {
    if (_self.breakdown == null) {
    return null;
  }

  return $PriceBreakdownCopyWith<$Res>(_self.breakdown!, (value) {
    return _then(_self.copyWith(breakdown: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeliveryAddressCopyWith<$Res>? get deliveryAddress {
    if (_self.deliveryAddress == null) {
    return null;
  }

  return $DeliveryAddressCopyWith<$Res>(_self.deliveryAddress!, (value) {
    return _then(_self.copyWith(deliveryAddress: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderProgressCopyWith<$Res>? get progress {
    if (_self.progress == null) {
    return null;
  }

  return $OrderProgressCopyWith<$Res>(_self.progress!, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get restaurantLocation {
    if (_self.restaurantLocation == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.restaurantLocation!, (value) {
    return _then(_self.copyWith(restaurantLocation: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParcelDetailsCopyWith<$Res>? get parcel {
    if (_self.parcel == null) {
    return null;
  }

  return $ParcelDetailsCopyWith<$Res>(_self.parcel!, (value) {
    return _then(_self.copyWith(parcel: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderPaymentCopyWith<$Res> get payment {
  
  return $OrderPaymentCopyWith<$Res>(_self.payment, (value) {
    return _then(_self.copyWith(payment: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WaybillDetailsCopyWith<$Res>? get waybill {
    if (_self.waybill == null) {
    return null;
  }

  return $WaybillDetailsCopyWith<$Res>(_self.waybill!, (value) {
    return _then(_self.copyWith(waybill: value));
  });
}
}


/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Order value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Order value)  $default,){
final _that = this;
switch (_that) {
case _Order():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Order value)?  $default,){
final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String shortCode,  String vertical,  String status,  String restaurantName,  String fulfillment,  List<PricedLine> lines,  List<OrderItem> items,  PriceBreakdown? breakdown,  DeliveryAddress? deliveryAddress,  OrderProgress? progress,  String? riderName,  String? customerName,  String? restaurantAddress,  GeoPoint? restaurantLocation,  DateTime? estimatedDeliveryAt,  DateTime? readyAt,  DateTime? createdAt,  int? riderPayKobo,  bool reviewed,  ParcelDetails? parcel,  int refundTotalKobo,  OrderPayment payment,  DateTime? cashCollectedAt,  String? paymentMethod,  int collectCashKobo,  WaybillDetails? waybill,  String? legKind,  bool hubHandover,  String? groupOrderId,  String? restaurantPhone,  String? tripId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.shortCode,_that.vertical,_that.status,_that.restaurantName,_that.fulfillment,_that.lines,_that.items,_that.breakdown,_that.deliveryAddress,_that.progress,_that.riderName,_that.customerName,_that.restaurantAddress,_that.restaurantLocation,_that.estimatedDeliveryAt,_that.readyAt,_that.createdAt,_that.riderPayKobo,_that.reviewed,_that.parcel,_that.refundTotalKobo,_that.payment,_that.cashCollectedAt,_that.paymentMethod,_that.collectCashKobo,_that.waybill,_that.legKind,_that.hubHandover,_that.groupOrderId,_that.restaurantPhone,_that.tripId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String shortCode,  String vertical,  String status,  String restaurantName,  String fulfillment,  List<PricedLine> lines,  List<OrderItem> items,  PriceBreakdown? breakdown,  DeliveryAddress? deliveryAddress,  OrderProgress? progress,  String? riderName,  String? customerName,  String? restaurantAddress,  GeoPoint? restaurantLocation,  DateTime? estimatedDeliveryAt,  DateTime? readyAt,  DateTime? createdAt,  int? riderPayKobo,  bool reviewed,  ParcelDetails? parcel,  int refundTotalKobo,  OrderPayment payment,  DateTime? cashCollectedAt,  String? paymentMethod,  int collectCashKobo,  WaybillDetails? waybill,  String? legKind,  bool hubHandover,  String? groupOrderId,  String? restaurantPhone,  String? tripId)  $default,) {final _that = this;
switch (_that) {
case _Order():
return $default(_that.id,_that.shortCode,_that.vertical,_that.status,_that.restaurantName,_that.fulfillment,_that.lines,_that.items,_that.breakdown,_that.deliveryAddress,_that.progress,_that.riderName,_that.customerName,_that.restaurantAddress,_that.restaurantLocation,_that.estimatedDeliveryAt,_that.readyAt,_that.createdAt,_that.riderPayKobo,_that.reviewed,_that.parcel,_that.refundTotalKobo,_that.payment,_that.cashCollectedAt,_that.paymentMethod,_that.collectCashKobo,_that.waybill,_that.legKind,_that.hubHandover,_that.groupOrderId,_that.restaurantPhone,_that.tripId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String shortCode,  String vertical,  String status,  String restaurantName,  String fulfillment,  List<PricedLine> lines,  List<OrderItem> items,  PriceBreakdown? breakdown,  DeliveryAddress? deliveryAddress,  OrderProgress? progress,  String? riderName,  String? customerName,  String? restaurantAddress,  GeoPoint? restaurantLocation,  DateTime? estimatedDeliveryAt,  DateTime? readyAt,  DateTime? createdAt,  int? riderPayKobo,  bool reviewed,  ParcelDetails? parcel,  int refundTotalKobo,  OrderPayment payment,  DateTime? cashCollectedAt,  String? paymentMethod,  int collectCashKobo,  WaybillDetails? waybill,  String? legKind,  bool hubHandover,  String? groupOrderId,  String? restaurantPhone,  String? tripId)?  $default,) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.shortCode,_that.vertical,_that.status,_that.restaurantName,_that.fulfillment,_that.lines,_that.items,_that.breakdown,_that.deliveryAddress,_that.progress,_that.riderName,_that.customerName,_that.restaurantAddress,_that.restaurantLocation,_that.estimatedDeliveryAt,_that.readyAt,_that.createdAt,_that.riderPayKobo,_that.reviewed,_that.parcel,_that.refundTotalKobo,_that.payment,_that.cashCollectedAt,_that.paymentMethod,_that.collectCashKobo,_that.waybill,_that.legKind,_that.hubHandover,_that.groupOrderId,_that.restaurantPhone,_that.tripId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Order implements Order {
  const _Order({required this.id, required this.shortCode, this.vertical = 'food', required this.status, required this.restaurantName, this.fulfillment = 'delivery',  List<PricedLine> lines = const <PricedLine>[],  List<OrderItem> items = const <OrderItem>[], this.breakdown, this.deliveryAddress, this.progress, this.riderName, this.customerName, this.restaurantAddress, this.restaurantLocation, this.estimatedDeliveryAt, this.readyAt, this.createdAt, this.riderPayKobo, this.reviewed = false, this.parcel, this.refundTotalKobo = 0, this.payment = const OrderPayment(), this.cashCollectedAt, this.paymentMethod, this.collectCashKobo = 0, this.waybill, this.legKind, this.hubHandover = false, this.groupOrderId, this.restaurantPhone, this.tripId}): _lines = lines,_items = items;
  factory _Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

@override final  String id;
@override final  String shortCode;
@override@JsonKey() final  String vertical;
@override final  String status;
@override final  String restaurantName;
@override@JsonKey() final  String fulfillment;
 final  List<PricedLine> _lines;
@override@JsonKey() List<PricedLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

/// The rider's view: what to collect, as names and quantities (riders never see prices, so no `lines`).
 final  List<OrderItem> _items;
/// The rider's view: what to collect, as names and quantities (riders never see prices, so no `lines`).
@override@JsonKey() List<OrderItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  PriceBreakdown? breakdown;
@override final  DeliveryAddress? deliveryAddress;
@override final  OrderProgress? progress;
@override final  String? riderName;
@override final  String? customerName;
@override final  String? restaurantAddress;
@override final  GeoPoint? restaurantLocation;
@override final  DateTime? estimatedDeliveryAt;
@override final  DateTime? readyAt;
@override final  DateTime? createdAt;
@override final  int? riderPayKobo;
@override@JsonKey() final  bool reviewed;
@override final  ParcelDetails? parcel;
@override@JsonKey() final  int refundTotalKobo;
@override@JsonKey() final  OrderPayment payment;
@override final  DateTime? cashCollectedAt;
@override final  String? paymentMethod;
@override@JsonKey() final  int collectCashKobo;
/// Interstate waybill details (vertical 'waybill').
@override final  WaybillDetails? waybill;
/// Rider view of a waybill's rider job: 'first_mile' ends with hub staff, 'last_mile' at the door.
@override final  String? legKind;
@override@JsonKey() final  bool hubHandover;
/// Placed by the host of a group order.
@override final  String? groupOrderId;
/// Rider view: the number to call at the shop (branch manager, else the shop, else the business).
@override final  String? restaurantPhone;
/// Orders paid together from one mixed cart share a trip: one rider, one delivery code (ADR-0030).
@override final  String? tripId;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderCopyWith<_Order> get copyWith => __$OrderCopyWithImpl<_Order>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Order&&(identical(other.id, id) || other.id == id)&&(identical(other.shortCode, shortCode) || other.shortCode == shortCode)&&(identical(other.vertical, vertical) || other.vertical == vertical)&&(identical(other.status, status) || other.status == status)&&(identical(other.restaurantName, restaurantName) || other.restaurantName == restaurantName)&&(identical(other.fulfillment, fulfillment) || other.fulfillment == fulfillment)&&const DeepCollectionEquality().equals(other.lines, _lines)&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.breakdown, breakdown) || other.breakdown == breakdown)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.riderName, riderName) || other.riderName == riderName)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.restaurantAddress, restaurantAddress) || other.restaurantAddress == restaurantAddress)&&(identical(other.restaurantLocation, restaurantLocation) || other.restaurantLocation == restaurantLocation)&&(identical(other.estimatedDeliveryAt, estimatedDeliveryAt) || other.estimatedDeliveryAt == estimatedDeliveryAt)&&(identical(other.readyAt, readyAt) || other.readyAt == readyAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.riderPayKobo, riderPayKobo) || other.riderPayKobo == riderPayKobo)&&(identical(other.reviewed, reviewed) || other.reviewed == reviewed)&&(identical(other.parcel, parcel) || other.parcel == parcel)&&(identical(other.refundTotalKobo, refundTotalKobo) || other.refundTotalKobo == refundTotalKobo)&&(identical(other.payment, payment) || other.payment == payment)&&(identical(other.cashCollectedAt, cashCollectedAt) || other.cashCollectedAt == cashCollectedAt)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.collectCashKobo, collectCashKobo) || other.collectCashKobo == collectCashKobo)&&(identical(other.waybill, waybill) || other.waybill == waybill)&&(identical(other.legKind, legKind) || other.legKind == legKind)&&(identical(other.hubHandover, hubHandover) || other.hubHandover == hubHandover)&&(identical(other.groupOrderId, groupOrderId) || other.groupOrderId == groupOrderId)&&(identical(other.restaurantPhone, restaurantPhone) || other.restaurantPhone == restaurantPhone)&&(identical(other.tripId, tripId) || other.tripId == tripId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,shortCode,vertical,status,restaurantName,fulfillment,const DeepCollectionEquality().hash(_lines),const DeepCollectionEquality().hash(_items),breakdown,deliveryAddress,progress,riderName,customerName,restaurantAddress,restaurantLocation,estimatedDeliveryAt,readyAt,createdAt,riderPayKobo,reviewed,parcel,refundTotalKobo,payment,cashCollectedAt,paymentMethod,collectCashKobo,waybill,legKind,hubHandover,groupOrderId,restaurantPhone,tripId]);
}

@override
String toString() {
    return 'Order(id: $id, shortCode: $shortCode, vertical: $vertical, status: $status, restaurantName: $restaurantName, fulfillment: $fulfillment, lines: $lines, items: $items, breakdown: $breakdown, deliveryAddress: $deliveryAddress, progress: $progress, riderName: $riderName, customerName: $customerName, restaurantAddress: $restaurantAddress, restaurantLocation: $restaurantLocation, estimatedDeliveryAt: $estimatedDeliveryAt, readyAt: $readyAt, createdAt: $createdAt, riderPayKobo: $riderPayKobo, reviewed: $reviewed, parcel: $parcel, refundTotalKobo: $refundTotalKobo, payment: $payment, cashCollectedAt: $cashCollectedAt, paymentMethod: $paymentMethod, collectCashKobo: $collectCashKobo, waybill: $waybill, legKind: $legKind, hubHandover: $hubHandover, groupOrderId: $groupOrderId, restaurantPhone: $restaurantPhone, tripId: $tripId)';
}


}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) = __$OrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String shortCode, String vertical, String status, String restaurantName, String fulfillment, List<PricedLine> lines, List<OrderItem> items, PriceBreakdown? breakdown, DeliveryAddress? deliveryAddress, OrderProgress? progress, String? riderName, String? customerName, String? restaurantAddress, GeoPoint? restaurantLocation, DateTime? estimatedDeliveryAt, DateTime? readyAt, DateTime? createdAt, int? riderPayKobo, bool reviewed, ParcelDetails? parcel, int refundTotalKobo, OrderPayment payment, DateTime? cashCollectedAt, String? paymentMethod, int collectCashKobo, WaybillDetails? waybill, String? legKind, bool hubHandover, String? groupOrderId, String? restaurantPhone, String? tripId
});


@override $PriceBreakdownCopyWith<$Res>? get breakdown;@override $DeliveryAddressCopyWith<$Res>? get deliveryAddress;@override $OrderProgressCopyWith<$Res>? get progress;@override $GeoPointCopyWith<$Res>? get restaurantLocation;@override $ParcelDetailsCopyWith<$Res>? get parcel;@override $OrderPaymentCopyWith<$Res> get payment;@override $WaybillDetailsCopyWith<$Res>? get waybill;

}
/// @nodoc
class __$OrderCopyWithImpl<$Res>
    implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? shortCode = null,Object? vertical = null,Object? status = null,Object? restaurantName = null,Object? fulfillment = null,Object? lines = null,Object? items = null,Object? breakdown = freezed,Object? deliveryAddress = freezed,Object? progress = freezed,Object? riderName = freezed,Object? customerName = freezed,Object? restaurantAddress = freezed,Object? restaurantLocation = freezed,Object? estimatedDeliveryAt = freezed,Object? readyAt = freezed,Object? createdAt = freezed,Object? riderPayKobo = freezed,Object? reviewed = null,Object? parcel = freezed,Object? refundTotalKobo = null,Object? payment = null,Object? cashCollectedAt = freezed,Object? paymentMethod = freezed,Object? collectCashKobo = null,Object? waybill = freezed,Object? legKind = freezed,Object? hubHandover = null,Object? groupOrderId = freezed,Object? restaurantPhone = freezed,Object? tripId = freezed,}) {
  return _then(_Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shortCode: null == shortCode ? _self.shortCode : shortCode // ignore: cast_nullable_to_non_nullable
as String,vertical: null == vertical ? _self.vertical : vertical // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,restaurantName: null == restaurantName ? _self.restaurantName : restaurantName // ignore: cast_nullable_to_non_nullable
as String,fulfillment: null == fulfillment ? _self.fulfillment : fulfillment // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<PricedLine>,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<OrderItem>,breakdown: freezed == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as PriceBreakdown?,deliveryAddress: freezed == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as DeliveryAddress?,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as OrderProgress?,riderName: freezed == riderName ? _self.riderName : riderName // ignore: cast_nullable_to_non_nullable
as String?,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,restaurantAddress: freezed == restaurantAddress ? _self.restaurantAddress : restaurantAddress // ignore: cast_nullable_to_non_nullable
as String?,restaurantLocation: freezed == restaurantLocation ? _self.restaurantLocation : restaurantLocation // ignore: cast_nullable_to_non_nullable
as GeoPoint?,estimatedDeliveryAt: freezed == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime?,readyAt: freezed == readyAt ? _self.readyAt : readyAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,riderPayKobo: freezed == riderPayKobo ? _self.riderPayKobo : riderPayKobo // ignore: cast_nullable_to_non_nullable
as int?,reviewed: null == reviewed ? _self.reviewed : reviewed // ignore: cast_nullable_to_non_nullable
as bool,parcel: freezed == parcel ? _self.parcel : parcel // ignore: cast_nullable_to_non_nullable
as ParcelDetails?,refundTotalKobo: null == refundTotalKobo ? _self.refundTotalKobo : refundTotalKobo // ignore: cast_nullable_to_non_nullable
as int,payment: null == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as OrderPayment,cashCollectedAt: freezed == cashCollectedAt ? _self.cashCollectedAt : cashCollectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,collectCashKobo: null == collectCashKobo ? _self.collectCashKobo : collectCashKobo // ignore: cast_nullable_to_non_nullable
as int,waybill: freezed == waybill ? _self.waybill : waybill // ignore: cast_nullable_to_non_nullable
as WaybillDetails?,legKind: freezed == legKind ? _self.legKind : legKind // ignore: cast_nullable_to_non_nullable
as String?,hubHandover: null == hubHandover ? _self.hubHandover : hubHandover // ignore: cast_nullable_to_non_nullable
as bool,groupOrderId: freezed == groupOrderId ? _self.groupOrderId : groupOrderId // ignore: cast_nullable_to_non_nullable
as String?,restaurantPhone: freezed == restaurantPhone ? _self.restaurantPhone : restaurantPhone // ignore: cast_nullable_to_non_nullable
as String?,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceBreakdownCopyWith<$Res>? get breakdown {
    if (_self.breakdown == null) {
    return null;
  }

  return $PriceBreakdownCopyWith<$Res>(_self.breakdown!, (value) {
    return _then(_self.copyWith(breakdown: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeliveryAddressCopyWith<$Res>? get deliveryAddress {
    if (_self.deliveryAddress == null) {
    return null;
  }

  return $DeliveryAddressCopyWith<$Res>(_self.deliveryAddress!, (value) {
    return _then(_self.copyWith(deliveryAddress: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderProgressCopyWith<$Res>? get progress {
    if (_self.progress == null) {
    return null;
  }

  return $OrderProgressCopyWith<$Res>(_self.progress!, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get restaurantLocation {
    if (_self.restaurantLocation == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.restaurantLocation!, (value) {
    return _then(_self.copyWith(restaurantLocation: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParcelDetailsCopyWith<$Res>? get parcel {
    if (_self.parcel == null) {
    return null;
  }

  return $ParcelDetailsCopyWith<$Res>(_self.parcel!, (value) {
    return _then(_self.copyWith(parcel: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderPaymentCopyWith<$Res> get payment {
  
  return $OrderPaymentCopyWith<$Res>(_self.payment, (value) {
    return _then(_self.copyWith(payment: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WaybillDetailsCopyWith<$Res>? get waybill {
    if (_self.waybill == null) {
    return null;
  }

  return $WaybillDetailsCopyWith<$Res>(_self.waybill!, (value) {
    return _then(_self.copyWith(waybill: value));
  });
}
}


/// @nodoc
mixin _$OrderPayment {

 String? get provider; String? get reference; String get status; DateTime? get paidAt;
/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderPaymentCopyWith<OrderPayment> get copyWith => _$OrderPaymentCopyWithImpl<OrderPayment>(this as OrderPayment, _$identity);

  /// Serializes this OrderPayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OrderPayment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderPayment&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.paidAt, _this.paidAt) || other.paidAt == _this.paidAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OrderPayment;
  return Object.hash(runtimeType,_this.provider,_this.reference,_this.status,_this.paidAt);
}

@override
String toString() {
  final _this = this as OrderPayment;
  return 'OrderPayment(provider: ${_this.provider}, reference: ${_this.reference}, status: ${_this.status}, paidAt: ${_this.paidAt})';
}


}

/// @nodoc
abstract mixin class $OrderPaymentCopyWith<$Res>  {
  factory $OrderPaymentCopyWith(OrderPayment value, $Res Function(OrderPayment) _then) = _$OrderPaymentCopyWithImpl;
@useResult
$Res call({
 String? provider, String? reference, String status, DateTime? paidAt
});




}
/// @nodoc
class _$OrderPaymentCopyWithImpl<$Res>
    implements $OrderPaymentCopyWith<$Res> {
  _$OrderPaymentCopyWithImpl(this._self, this._then);

  final OrderPayment _self;
  final $Res Function(OrderPayment) _then;

/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = freezed,Object? reference = freezed,Object? status = null,Object? paidAt = freezed,}) {
  return _then(OrderPayment(
provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderPayment].
extension OrderPaymentPatterns on OrderPayment {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderPayment() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderPayment value)  $default,){
final _that = this;
switch (_that) {
case _OrderPayment():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderPayment value)?  $default,){
final _that = this;
switch (_that) {
case _OrderPayment() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? provider,  String? reference,  String status,  DateTime? paidAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderPayment() when $default != null:
return $default(_that.provider,_that.reference,_that.status,_that.paidAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? provider,  String? reference,  String status,  DateTime? paidAt)  $default,) {final _that = this;
switch (_that) {
case _OrderPayment():
return $default(_that.provider,_that.reference,_that.status,_that.paidAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? provider,  String? reference,  String status,  DateTime? paidAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderPayment() when $default != null:
return $default(_that.provider,_that.reference,_that.status,_that.paidAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderPayment implements OrderPayment {
  const _OrderPayment({this.provider, this.reference, this.status = 'unpaid', this.paidAt});
  factory _OrderPayment.fromJson(Map<String, dynamic> json) => _$OrderPaymentFromJson(json);

@override final  String? provider;
@override final  String? reference;
@override@JsonKey() final  String status;
@override final  DateTime? paidAt;

/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderPaymentCopyWith<_OrderPayment> get copyWith => __$OrderPaymentCopyWithImpl<_OrderPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderPayment&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.status, status) || other.status == status)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,provider,reference,status,paidAt);
}

@override
String toString() {
    return 'OrderPayment(provider: $provider, reference: $reference, status: $status, paidAt: $paidAt)';
}


}

/// @nodoc
abstract mixin class _$OrderPaymentCopyWith<$Res> implements $OrderPaymentCopyWith<$Res> {
  factory _$OrderPaymentCopyWith(_OrderPayment value, $Res Function(_OrderPayment) _then) = __$OrderPaymentCopyWithImpl;
@override @useResult
$Res call({
 String? provider, String? reference, String status, DateTime? paidAt
});




}
/// @nodoc
class __$OrderPaymentCopyWithImpl<$Res>
    implements _$OrderPaymentCopyWith<$Res> {
  __$OrderPaymentCopyWithImpl(this._self, this._then);

  final _OrderPayment _self;
  final $Res Function(_OrderPayment) _then;

/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = freezed,Object? reference = freezed,Object? status = null,Object? paidAt = freezed,}) {
  return _then(_OrderPayment(
provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CheckoutResult {

 String get orderId; String get status; String get reference;/// Null for wallet and pay-on-delivery checkouts: the order is already placed.
 String? get authorizationUrl; int get amountKobo; String get provider; String? get failoverFrom;
/// Create a copy of CheckoutResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutResultCopyWith<CheckoutResult> get copyWith => _$CheckoutResultCopyWithImpl<CheckoutResult>(this as CheckoutResult, _$identity);

  /// Serializes this CheckoutResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CheckoutResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckoutResult&&(identical(other.orderId, _this.orderId) || other.orderId == _this.orderId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.authorizationUrl, _this.authorizationUrl) || other.authorizationUrl == _this.authorizationUrl)&&(identical(other.amountKobo, _this.amountKobo) || other.amountKobo == _this.amountKobo)&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.failoverFrom, _this.failoverFrom) || other.failoverFrom == _this.failoverFrom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CheckoutResult;
  return Object.hash(runtimeType,_this.orderId,_this.status,_this.reference,_this.authorizationUrl,_this.amountKobo,_this.provider,_this.failoverFrom);
}

@override
String toString() {
  final _this = this as CheckoutResult;
  return 'CheckoutResult(orderId: ${_this.orderId}, status: ${_this.status}, reference: ${_this.reference}, authorizationUrl: ${_this.authorizationUrl}, amountKobo: ${_this.amountKobo}, provider: ${_this.provider}, failoverFrom: ${_this.failoverFrom})';
}


}

/// @nodoc
abstract mixin class $CheckoutResultCopyWith<$Res>  {
  factory $CheckoutResultCopyWith(CheckoutResult value, $Res Function(CheckoutResult) _then) = _$CheckoutResultCopyWithImpl;
@useResult
$Res call({
 String orderId, String status, String reference, String? authorizationUrl, int amountKobo, String provider, String? failoverFrom
});




}
/// @nodoc
class _$CheckoutResultCopyWithImpl<$Res>
    implements $CheckoutResultCopyWith<$Res> {
  _$CheckoutResultCopyWithImpl(this._self, this._then);

  final CheckoutResult _self;
  final $Res Function(CheckoutResult) _then;

/// Create a copy of CheckoutResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? status = null,Object? reference = null,Object? authorizationUrl = freezed,Object? amountKobo = null,Object? provider = null,Object? failoverFrom = freezed,}) {
  return _then(CheckoutResult(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,authorizationUrl: freezed == authorizationUrl ? _self.authorizationUrl : authorizationUrl // ignore: cast_nullable_to_non_nullable
as String?,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,failoverFrom: freezed == failoverFrom ? _self.failoverFrom : failoverFrom // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckoutResult].
extension CheckoutResultPatterns on CheckoutResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckoutResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckoutResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckoutResult value)  $default,){
final _that = this;
switch (_that) {
case _CheckoutResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckoutResult value)?  $default,){
final _that = this;
switch (_that) {
case _CheckoutResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String orderId,  String status,  String reference,  String? authorizationUrl,  int amountKobo,  String provider,  String? failoverFrom)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckoutResult() when $default != null:
return $default(_that.orderId,_that.status,_that.reference,_that.authorizationUrl,_that.amountKobo,_that.provider,_that.failoverFrom);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String orderId,  String status,  String reference,  String? authorizationUrl,  int amountKobo,  String provider,  String? failoverFrom)  $default,) {final _that = this;
switch (_that) {
case _CheckoutResult():
return $default(_that.orderId,_that.status,_that.reference,_that.authorizationUrl,_that.amountKobo,_that.provider,_that.failoverFrom);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String orderId,  String status,  String reference,  String? authorizationUrl,  int amountKobo,  String provider,  String? failoverFrom)?  $default,) {final _that = this;
switch (_that) {
case _CheckoutResult() when $default != null:
return $default(_that.orderId,_that.status,_that.reference,_that.authorizationUrl,_that.amountKobo,_that.provider,_that.failoverFrom);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckoutResult implements CheckoutResult {
  const _CheckoutResult({required this.orderId, this.status = '', required this.reference, this.authorizationUrl, required this.amountKobo, required this.provider, this.failoverFrom});
  factory _CheckoutResult.fromJson(Map<String, dynamic> json) => _$CheckoutResultFromJson(json);

@override final  String orderId;
@override@JsonKey() final  String status;
@override final  String reference;
/// Null for wallet and pay-on-delivery checkouts: the order is already placed.
@override final  String? authorizationUrl;
@override final  int amountKobo;
@override final  String provider;
@override final  String? failoverFrom;

/// Create a copy of CheckoutResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckoutResultCopyWith<_CheckoutResult> get copyWith => __$CheckoutResultCopyWithImpl<_CheckoutResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckoutResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckoutResult&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.status, status) || other.status == status)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.authorizationUrl, authorizationUrl) || other.authorizationUrl == authorizationUrl)&&(identical(other.amountKobo, amountKobo) || other.amountKobo == amountKobo)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.failoverFrom, failoverFrom) || other.failoverFrom == failoverFrom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,orderId,status,reference,authorizationUrl,amountKobo,provider,failoverFrom);
}

@override
String toString() {
    return 'CheckoutResult(orderId: $orderId, status: $status, reference: $reference, authorizationUrl: $authorizationUrl, amountKobo: $amountKobo, provider: $provider, failoverFrom: $failoverFrom)';
}


}

/// @nodoc
abstract mixin class _$CheckoutResultCopyWith<$Res> implements $CheckoutResultCopyWith<$Res> {
  factory _$CheckoutResultCopyWith(_CheckoutResult value, $Res Function(_CheckoutResult) _then) = __$CheckoutResultCopyWithImpl;
@override @useResult
$Res call({
 String orderId, String status, String reference, String? authorizationUrl, int amountKobo, String provider, String? failoverFrom
});




}
/// @nodoc
class __$CheckoutResultCopyWithImpl<$Res>
    implements _$CheckoutResultCopyWith<$Res> {
  __$CheckoutResultCopyWithImpl(this._self, this._then);

  final _CheckoutResult _self;
  final $Res Function(_CheckoutResult) _then;

/// Create a copy of CheckoutResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? status = null,Object? reference = null,Object? authorizationUrl = freezed,Object? amountKobo = null,Object? provider = null,Object? failoverFrom = freezed,}) {
  return _then(_CheckoutResult(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,authorizationUrl: freezed == authorizationUrl ? _self.authorizationUrl : authorizationUrl // ignore: cast_nullable_to_non_nullable
as String?,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,failoverFrom: freezed == failoverFrom ? _self.failoverFrom : failoverFrom // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MultiCheckoutResult {

 List<String> get orderIds; String get provider; String? get reference; String? get authorizationUrl; int get amountKobo; String get paymentStatus; List<MultiCheckoutOrder> get orders;
/// Create a copy of MultiCheckoutResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MultiCheckoutResultCopyWith<MultiCheckoutResult> get copyWith => _$MultiCheckoutResultCopyWithImpl<MultiCheckoutResult>(this as MultiCheckoutResult, _$identity);

  /// Serializes this MultiCheckoutResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MultiCheckoutResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MultiCheckoutResult&&const DeepCollectionEquality().equals(other.orderIds, _this.orderIds)&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.authorizationUrl, _this.authorizationUrl) || other.authorizationUrl == _this.authorizationUrl)&&(identical(other.amountKobo, _this.amountKobo) || other.amountKobo == _this.amountKobo)&&(identical(other.paymentStatus, _this.paymentStatus) || other.paymentStatus == _this.paymentStatus)&&const DeepCollectionEquality().equals(other.orders, _this.orders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MultiCheckoutResult;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.orderIds),_this.provider,_this.reference,_this.authorizationUrl,_this.amountKobo,_this.paymentStatus,const DeepCollectionEquality().hash(_this.orders));
}

@override
String toString() {
  final _this = this as MultiCheckoutResult;
  return 'MultiCheckoutResult(orderIds: ${_this.orderIds}, provider: ${_this.provider}, reference: ${_this.reference}, authorizationUrl: ${_this.authorizationUrl}, amountKobo: ${_this.amountKobo}, paymentStatus: ${_this.paymentStatus}, orders: ${_this.orders})';
}


}

/// @nodoc
abstract mixin class $MultiCheckoutResultCopyWith<$Res>  {
  factory $MultiCheckoutResultCopyWith(MultiCheckoutResult value, $Res Function(MultiCheckoutResult) _then) = _$MultiCheckoutResultCopyWithImpl;
@useResult
$Res call({
 List<String> orderIds, String provider, String? reference, String? authorizationUrl, int amountKobo, String paymentStatus, List<MultiCheckoutOrder> orders
});




}
/// @nodoc
class _$MultiCheckoutResultCopyWithImpl<$Res>
    implements $MultiCheckoutResultCopyWith<$Res> {
  _$MultiCheckoutResultCopyWithImpl(this._self, this._then);

  final MultiCheckoutResult _self;
  final $Res Function(MultiCheckoutResult) _then;

/// Create a copy of MultiCheckoutResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderIds = null,Object? provider = null,Object? reference = freezed,Object? authorizationUrl = freezed,Object? amountKobo = null,Object? paymentStatus = null,Object? orders = null,}) {
  return _then(MultiCheckoutResult(
orderIds: null == orderIds ? _self.orderIds : orderIds // ignore: cast_nullable_to_non_nullable
as List<String>,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,authorizationUrl: freezed == authorizationUrl ? _self.authorizationUrl : authorizationUrl // ignore: cast_nullable_to_non_nullable
as String?,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String,orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as List<MultiCheckoutOrder>,
  ));
}

}


/// Adds pattern-matching-related methods to [MultiCheckoutResult].
extension MultiCheckoutResultPatterns on MultiCheckoutResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MultiCheckoutResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MultiCheckoutResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MultiCheckoutResult value)  $default,){
final _that = this;
switch (_that) {
case _MultiCheckoutResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MultiCheckoutResult value)?  $default,){
final _that = this;
switch (_that) {
case _MultiCheckoutResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> orderIds,  String provider,  String? reference,  String? authorizationUrl,  int amountKobo,  String paymentStatus,  List<MultiCheckoutOrder> orders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MultiCheckoutResult() when $default != null:
return $default(_that.orderIds,_that.provider,_that.reference,_that.authorizationUrl,_that.amountKobo,_that.paymentStatus,_that.orders);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> orderIds,  String provider,  String? reference,  String? authorizationUrl,  int amountKobo,  String paymentStatus,  List<MultiCheckoutOrder> orders)  $default,) {final _that = this;
switch (_that) {
case _MultiCheckoutResult():
return $default(_that.orderIds,_that.provider,_that.reference,_that.authorizationUrl,_that.amountKobo,_that.paymentStatus,_that.orders);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> orderIds,  String provider,  String? reference,  String? authorizationUrl,  int amountKobo,  String paymentStatus,  List<MultiCheckoutOrder> orders)?  $default,) {final _that = this;
switch (_that) {
case _MultiCheckoutResult() when $default != null:
return $default(_that.orderIds,_that.provider,_that.reference,_that.authorizationUrl,_that.amountKobo,_that.paymentStatus,_that.orders);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MultiCheckoutResult implements MultiCheckoutResult {
  const _MultiCheckoutResult({required  List<String> orderIds, required this.provider, this.reference, this.authorizationUrl, required this.amountKobo, this.paymentStatus = '',  List<MultiCheckoutOrder> orders = const []}): _orderIds = orderIds,_orders = orders;
  factory _MultiCheckoutResult.fromJson(Map<String, dynamic> json) => _$MultiCheckoutResultFromJson(json);

 final  List<String> _orderIds;
@override List<String> get orderIds {
  if (_orderIds is EqualUnmodifiableListView) return _orderIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orderIds);
}

@override final  String provider;
@override final  String? reference;
@override final  String? authorizationUrl;
@override final  int amountKobo;
@override@JsonKey() final  String paymentStatus;
 final  List<MultiCheckoutOrder> _orders;
@override@JsonKey() List<MultiCheckoutOrder> get orders {
  if (_orders is EqualUnmodifiableListView) return _orders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orders);
}


/// Create a copy of MultiCheckoutResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MultiCheckoutResultCopyWith<_MultiCheckoutResult> get copyWith => __$MultiCheckoutResultCopyWithImpl<_MultiCheckoutResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MultiCheckoutResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MultiCheckoutResult&&const DeepCollectionEquality().equals(other.orderIds, _orderIds)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.authorizationUrl, authorizationUrl) || other.authorizationUrl == authorizationUrl)&&(identical(other.amountKobo, amountKobo) || other.amountKobo == amountKobo)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&const DeepCollectionEquality().equals(other.orders, _orders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_orderIds),provider,reference,authorizationUrl,amountKobo,paymentStatus,const DeepCollectionEquality().hash(_orders));
}

@override
String toString() {
    return 'MultiCheckoutResult(orderIds: $orderIds, provider: $provider, reference: $reference, authorizationUrl: $authorizationUrl, amountKobo: $amountKobo, paymentStatus: $paymentStatus, orders: $orders)';
}


}

/// @nodoc
abstract mixin class _$MultiCheckoutResultCopyWith<$Res> implements $MultiCheckoutResultCopyWith<$Res> {
  factory _$MultiCheckoutResultCopyWith(_MultiCheckoutResult value, $Res Function(_MultiCheckoutResult) _then) = __$MultiCheckoutResultCopyWithImpl;
@override @useResult
$Res call({
 List<String> orderIds, String provider, String? reference, String? authorizationUrl, int amountKobo, String paymentStatus, List<MultiCheckoutOrder> orders
});




}
/// @nodoc
class __$MultiCheckoutResultCopyWithImpl<$Res>
    implements _$MultiCheckoutResultCopyWith<$Res> {
  __$MultiCheckoutResultCopyWithImpl(this._self, this._then);

  final _MultiCheckoutResult _self;
  final $Res Function(_MultiCheckoutResult) _then;

/// Create a copy of MultiCheckoutResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderIds = null,Object? provider = null,Object? reference = freezed,Object? authorizationUrl = freezed,Object? amountKobo = null,Object? paymentStatus = null,Object? orders = null,}) {
  return _then(_MultiCheckoutResult(
orderIds: null == orderIds ? _self._orderIds : orderIds // ignore: cast_nullable_to_non_nullable
as List<String>,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,authorizationUrl: freezed == authorizationUrl ? _self.authorizationUrl : authorizationUrl // ignore: cast_nullable_to_non_nullable
as String?,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String,orders: null == orders ? _self._orders : orders // ignore: cast_nullable_to_non_nullable
as List<MultiCheckoutOrder>,
  ));
}


}


/// @nodoc
mixin _$MultiCheckoutOrder {

 String get orderId; String get status; int get amountKobo;
/// Create a copy of MultiCheckoutOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MultiCheckoutOrderCopyWith<MultiCheckoutOrder> get copyWith => _$MultiCheckoutOrderCopyWithImpl<MultiCheckoutOrder>(this as MultiCheckoutOrder, _$identity);

  /// Serializes this MultiCheckoutOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MultiCheckoutOrder;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MultiCheckoutOrder&&(identical(other.orderId, _this.orderId) || other.orderId == _this.orderId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.amountKobo, _this.amountKobo) || other.amountKobo == _this.amountKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MultiCheckoutOrder;
  return Object.hash(runtimeType,_this.orderId,_this.status,_this.amountKobo);
}

@override
String toString() {
  final _this = this as MultiCheckoutOrder;
  return 'MultiCheckoutOrder(orderId: ${_this.orderId}, status: ${_this.status}, amountKobo: ${_this.amountKobo})';
}


}

/// @nodoc
abstract mixin class $MultiCheckoutOrderCopyWith<$Res>  {
  factory $MultiCheckoutOrderCopyWith(MultiCheckoutOrder value, $Res Function(MultiCheckoutOrder) _then) = _$MultiCheckoutOrderCopyWithImpl;
@useResult
$Res call({
 String orderId, String status, int amountKobo
});




}
/// @nodoc
class _$MultiCheckoutOrderCopyWithImpl<$Res>
    implements $MultiCheckoutOrderCopyWith<$Res> {
  _$MultiCheckoutOrderCopyWithImpl(this._self, this._then);

  final MultiCheckoutOrder _self;
  final $Res Function(MultiCheckoutOrder) _then;

/// Create a copy of MultiCheckoutOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? status = null,Object? amountKobo = null,}) {
  return _then(MultiCheckoutOrder(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MultiCheckoutOrder].
extension MultiCheckoutOrderPatterns on MultiCheckoutOrder {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MultiCheckoutOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MultiCheckoutOrder() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MultiCheckoutOrder value)  $default,){
final _that = this;
switch (_that) {
case _MultiCheckoutOrder():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MultiCheckoutOrder value)?  $default,){
final _that = this;
switch (_that) {
case _MultiCheckoutOrder() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String orderId,  String status,  int amountKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MultiCheckoutOrder() when $default != null:
return $default(_that.orderId,_that.status,_that.amountKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String orderId,  String status,  int amountKobo)  $default,) {final _that = this;
switch (_that) {
case _MultiCheckoutOrder():
return $default(_that.orderId,_that.status,_that.amountKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String orderId,  String status,  int amountKobo)?  $default,) {final _that = this;
switch (_that) {
case _MultiCheckoutOrder() when $default != null:
return $default(_that.orderId,_that.status,_that.amountKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MultiCheckoutOrder implements MultiCheckoutOrder {
  const _MultiCheckoutOrder({required this.orderId, this.status = '', this.amountKobo = 0});
  factory _MultiCheckoutOrder.fromJson(Map<String, dynamic> json) => _$MultiCheckoutOrderFromJson(json);

@override final  String orderId;
@override@JsonKey() final  String status;
@override@JsonKey() final  int amountKobo;

/// Create a copy of MultiCheckoutOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MultiCheckoutOrderCopyWith<_MultiCheckoutOrder> get copyWith => __$MultiCheckoutOrderCopyWithImpl<_MultiCheckoutOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MultiCheckoutOrderToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MultiCheckoutOrder&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.status, status) || other.status == status)&&(identical(other.amountKobo, amountKobo) || other.amountKobo == amountKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,orderId,status,amountKobo);
}

@override
String toString() {
    return 'MultiCheckoutOrder(orderId: $orderId, status: $status, amountKobo: $amountKobo)';
}


}

/// @nodoc
abstract mixin class _$MultiCheckoutOrderCopyWith<$Res> implements $MultiCheckoutOrderCopyWith<$Res> {
  factory _$MultiCheckoutOrderCopyWith(_MultiCheckoutOrder value, $Res Function(_MultiCheckoutOrder) _then) = __$MultiCheckoutOrderCopyWithImpl;
@override @useResult
$Res call({
 String orderId, String status, int amountKobo
});




}
/// @nodoc
class __$MultiCheckoutOrderCopyWithImpl<$Res>
    implements _$MultiCheckoutOrderCopyWith<$Res> {
  __$MultiCheckoutOrderCopyWithImpl(this._self, this._then);

  final _MultiCheckoutOrder _self;
  final $Res Function(_MultiCheckoutOrder) _then;

/// Create a copy of MultiCheckoutOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? status = null,Object? amountKobo = null,}) {
  return _then(_MultiCheckoutOrder(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PaymentMethodOption {

 String get id; String get label; bool get available; String? get reason; int? get balanceKobo; int? get shortByKobo;
/// Create a copy of PaymentMethodOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentMethodOptionCopyWith<PaymentMethodOption> get copyWith => _$PaymentMethodOptionCopyWithImpl<PaymentMethodOption>(this as PaymentMethodOption, _$identity);

  /// Serializes this PaymentMethodOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaymentMethodOption;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentMethodOption&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.available, _this.available) || other.available == _this.available)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.balanceKobo, _this.balanceKobo) || other.balanceKobo == _this.balanceKobo)&&(identical(other.shortByKobo, _this.shortByKobo) || other.shortByKobo == _this.shortByKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaymentMethodOption;
  return Object.hash(runtimeType,_this.id,_this.label,_this.available,_this.reason,_this.balanceKobo,_this.shortByKobo);
}

@override
String toString() {
  final _this = this as PaymentMethodOption;
  return 'PaymentMethodOption(id: ${_this.id}, label: ${_this.label}, available: ${_this.available}, reason: ${_this.reason}, balanceKobo: ${_this.balanceKobo}, shortByKobo: ${_this.shortByKobo})';
}


}

/// @nodoc
abstract mixin class $PaymentMethodOptionCopyWith<$Res>  {
  factory $PaymentMethodOptionCopyWith(PaymentMethodOption value, $Res Function(PaymentMethodOption) _then) = _$PaymentMethodOptionCopyWithImpl;
@useResult
$Res call({
 String id, String label, bool available, String? reason, int? balanceKobo, int? shortByKobo
});




}
/// @nodoc
class _$PaymentMethodOptionCopyWithImpl<$Res>
    implements $PaymentMethodOptionCopyWith<$Res> {
  _$PaymentMethodOptionCopyWithImpl(this._self, this._then);

  final PaymentMethodOption _self;
  final $Res Function(PaymentMethodOption) _then;

/// Create a copy of PaymentMethodOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? available = null,Object? reason = freezed,Object? balanceKobo = freezed,Object? shortByKobo = freezed,}) {
  return _then(PaymentMethodOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,balanceKobo: freezed == balanceKobo ? _self.balanceKobo : balanceKobo // ignore: cast_nullable_to_non_nullable
as int?,shortByKobo: freezed == shortByKobo ? _self.shortByKobo : shortByKobo // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentMethodOption].
extension PaymentMethodOptionPatterns on PaymentMethodOption {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentMethodOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentMethodOption() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentMethodOption value)  $default,){
final _that = this;
switch (_that) {
case _PaymentMethodOption():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentMethodOption value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentMethodOption() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  bool available,  String? reason,  int? balanceKobo,  int? shortByKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentMethodOption() when $default != null:
return $default(_that.id,_that.label,_that.available,_that.reason,_that.balanceKobo,_that.shortByKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  bool available,  String? reason,  int? balanceKobo,  int? shortByKobo)  $default,) {final _that = this;
switch (_that) {
case _PaymentMethodOption():
return $default(_that.id,_that.label,_that.available,_that.reason,_that.balanceKobo,_that.shortByKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  bool available,  String? reason,  int? balanceKobo,  int? shortByKobo)?  $default,) {final _that = this;
switch (_that) {
case _PaymentMethodOption() when $default != null:
return $default(_that.id,_that.label,_that.available,_that.reason,_that.balanceKobo,_that.shortByKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentMethodOption implements PaymentMethodOption {
  const _PaymentMethodOption({required this.id, required this.label, this.available = false, this.reason, this.balanceKobo, this.shortByKobo});
  factory _PaymentMethodOption.fromJson(Map<String, dynamic> json) => _$PaymentMethodOptionFromJson(json);

@override final  String id;
@override final  String label;
@override@JsonKey() final  bool available;
@override final  String? reason;
@override final  int? balanceKobo;
@override final  int? shortByKobo;

/// Create a copy of PaymentMethodOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentMethodOptionCopyWith<_PaymentMethodOption> get copyWith => __$PaymentMethodOptionCopyWithImpl<_PaymentMethodOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentMethodOptionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentMethodOption&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.available, available) || other.available == available)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.balanceKobo, balanceKobo) || other.balanceKobo == balanceKobo)&&(identical(other.shortByKobo, shortByKobo) || other.shortByKobo == shortByKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,label,available,reason,balanceKobo,shortByKobo);
}

@override
String toString() {
    return 'PaymentMethodOption(id: $id, label: $label, available: $available, reason: $reason, balanceKobo: $balanceKobo, shortByKobo: $shortByKobo)';
}


}

/// @nodoc
abstract mixin class _$PaymentMethodOptionCopyWith<$Res> implements $PaymentMethodOptionCopyWith<$Res> {
  factory _$PaymentMethodOptionCopyWith(_PaymentMethodOption value, $Res Function(_PaymentMethodOption) _then) = __$PaymentMethodOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, bool available, String? reason, int? balanceKobo, int? shortByKobo
});




}
/// @nodoc
class __$PaymentMethodOptionCopyWithImpl<$Res>
    implements _$PaymentMethodOptionCopyWith<$Res> {
  __$PaymentMethodOptionCopyWithImpl(this._self, this._then);

  final _PaymentMethodOption _self;
  final $Res Function(_PaymentMethodOption) _then;

/// Create a copy of PaymentMethodOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? available = null,Object? reason = freezed,Object? balanceKobo = freezed,Object? shortByKobo = freezed,}) {
  return _then(_PaymentMethodOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,balanceKobo: freezed == balanceKobo ? _self.balanceKobo : balanceKobo // ignore: cast_nullable_to_non_nullable
as int?,shortByKobo: freezed == shortByKobo ? _self.shortByKobo : shortByKobo // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$PaymentOptions {

 String get orderId; int get totalKobo; List<PaymentMethodOption> get methods;
/// Create a copy of PaymentOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentOptionsCopyWith<PaymentOptions> get copyWith => _$PaymentOptionsCopyWithImpl<PaymentOptions>(this as PaymentOptions, _$identity);

  /// Serializes this PaymentOptions to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaymentOptions;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentOptions&&(identical(other.orderId, _this.orderId) || other.orderId == _this.orderId)&&(identical(other.totalKobo, _this.totalKobo) || other.totalKobo == _this.totalKobo)&&const DeepCollectionEquality().equals(other.methods, _this.methods));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaymentOptions;
  return Object.hash(runtimeType,_this.orderId,_this.totalKobo,const DeepCollectionEquality().hash(_this.methods));
}

@override
String toString() {
  final _this = this as PaymentOptions;
  return 'PaymentOptions(orderId: ${_this.orderId}, totalKobo: ${_this.totalKobo}, methods: ${_this.methods})';
}


}

/// @nodoc
abstract mixin class $PaymentOptionsCopyWith<$Res>  {
  factory $PaymentOptionsCopyWith(PaymentOptions value, $Res Function(PaymentOptions) _then) = _$PaymentOptionsCopyWithImpl;
@useResult
$Res call({
 String orderId, int totalKobo, List<PaymentMethodOption> methods
});




}
/// @nodoc
class _$PaymentOptionsCopyWithImpl<$Res>
    implements $PaymentOptionsCopyWith<$Res> {
  _$PaymentOptionsCopyWithImpl(this._self, this._then);

  final PaymentOptions _self;
  final $Res Function(PaymentOptions) _then;

/// Create a copy of PaymentOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? totalKobo = null,Object? methods = null,}) {
  return _then(PaymentOptions(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,totalKobo: null == totalKobo ? _self.totalKobo : totalKobo // ignore: cast_nullable_to_non_nullable
as int,methods: null == methods ? _self.methods : methods // ignore: cast_nullable_to_non_nullable
as List<PaymentMethodOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentOptions].
extension PaymentOptionsPatterns on PaymentOptions {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentOptions() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentOptions value)  $default,){
final _that = this;
switch (_that) {
case _PaymentOptions():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentOptions value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentOptions() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String orderId,  int totalKobo,  List<PaymentMethodOption> methods)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentOptions() when $default != null:
return $default(_that.orderId,_that.totalKobo,_that.methods);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String orderId,  int totalKobo,  List<PaymentMethodOption> methods)  $default,) {final _that = this;
switch (_that) {
case _PaymentOptions():
return $default(_that.orderId,_that.totalKobo,_that.methods);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String orderId,  int totalKobo,  List<PaymentMethodOption> methods)?  $default,) {final _that = this;
switch (_that) {
case _PaymentOptions() when $default != null:
return $default(_that.orderId,_that.totalKobo,_that.methods);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentOptions implements PaymentOptions {
  const _PaymentOptions({required this.orderId, required this.totalKobo,  List<PaymentMethodOption> methods = const <PaymentMethodOption>[]}): _methods = methods;
  factory _PaymentOptions.fromJson(Map<String, dynamic> json) => _$PaymentOptionsFromJson(json);

@override final  String orderId;
@override final  int totalKobo;
 final  List<PaymentMethodOption> _methods;
@override@JsonKey() List<PaymentMethodOption> get methods {
  if (_methods is EqualUnmodifiableListView) return _methods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_methods);
}


/// Create a copy of PaymentOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentOptionsCopyWith<_PaymentOptions> get copyWith => __$PaymentOptionsCopyWithImpl<_PaymentOptions>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentOptionsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentOptions&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.totalKobo, totalKobo) || other.totalKobo == totalKobo)&&const DeepCollectionEquality().equals(other.methods, _methods));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,orderId,totalKobo,const DeepCollectionEquality().hash(_methods));
}

@override
String toString() {
    return 'PaymentOptions(orderId: $orderId, totalKobo: $totalKobo, methods: $methods)';
}


}

/// @nodoc
abstract mixin class _$PaymentOptionsCopyWith<$Res> implements $PaymentOptionsCopyWith<$Res> {
  factory _$PaymentOptionsCopyWith(_PaymentOptions value, $Res Function(_PaymentOptions) _then) = __$PaymentOptionsCopyWithImpl;
@override @useResult
$Res call({
 String orderId, int totalKobo, List<PaymentMethodOption> methods
});




}
/// @nodoc
class __$PaymentOptionsCopyWithImpl<$Res>
    implements _$PaymentOptionsCopyWith<$Res> {
  __$PaymentOptionsCopyWithImpl(this._self, this._then);

  final _PaymentOptions _self;
  final $Res Function(_PaymentOptions) _then;

/// Create a copy of PaymentOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? totalKobo = null,Object? methods = null,}) {
  return _then(_PaymentOptions(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,totalKobo: null == totalKobo ? _self.totalKobo : totalKobo // ignore: cast_nullable_to_non_nullable
as int,methods: null == methods ? _self._methods : methods // ignore: cast_nullable_to_non_nullable
as List<PaymentMethodOption>,
  ));
}


}


/// @nodoc
mixin _$WalletTransaction {

 String get id; String get kind; String get description; String? get reference; String? get orderId; DateTime get createdAt; String get direction; int get amountKobo;
/// Create a copy of WalletTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletTransactionCopyWith<WalletTransaction> get copyWith => _$WalletTransactionCopyWithImpl<WalletTransaction>(this as WalletTransaction, _$identity);

  /// Serializes this WalletTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WalletTransaction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletTransaction&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.orderId, _this.orderId) || other.orderId == _this.orderId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.direction, _this.direction) || other.direction == _this.direction)&&(identical(other.amountKobo, _this.amountKobo) || other.amountKobo == _this.amountKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WalletTransaction;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.description,_this.reference,_this.orderId,_this.createdAt,_this.direction,_this.amountKobo);
}

@override
String toString() {
  final _this = this as WalletTransaction;
  return 'WalletTransaction(id: ${_this.id}, kind: ${_this.kind}, description: ${_this.description}, reference: ${_this.reference}, orderId: ${_this.orderId}, createdAt: ${_this.createdAt}, direction: ${_this.direction}, amountKobo: ${_this.amountKobo})';
}


}

/// @nodoc
abstract mixin class $WalletTransactionCopyWith<$Res>  {
  factory $WalletTransactionCopyWith(WalletTransaction value, $Res Function(WalletTransaction) _then) = _$WalletTransactionCopyWithImpl;
@useResult
$Res call({
 String id, String kind, String description, String? reference, String? orderId, DateTime createdAt, String direction, int amountKobo
});




}
/// @nodoc
class _$WalletTransactionCopyWithImpl<$Res>
    implements $WalletTransactionCopyWith<$Res> {
  _$WalletTransactionCopyWithImpl(this._self, this._then);

  final WalletTransaction _self;
  final $Res Function(WalletTransaction) _then;

/// Create a copy of WalletTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? description = null,Object? reference = freezed,Object? orderId = freezed,Object? createdAt = null,Object? direction = null,Object? amountKobo = null,}) {
  return _then(WalletTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletTransaction].
extension WalletTransactionPatterns on WalletTransaction {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletTransaction() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletTransaction value)  $default,){
final _that = this;
switch (_that) {
case _WalletTransaction():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _WalletTransaction() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  String description,  String? reference,  String? orderId,  DateTime createdAt,  String direction,  int amountKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletTransaction() when $default != null:
return $default(_that.id,_that.kind,_that.description,_that.reference,_that.orderId,_that.createdAt,_that.direction,_that.amountKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  String description,  String? reference,  String? orderId,  DateTime createdAt,  String direction,  int amountKobo)  $default,) {final _that = this;
switch (_that) {
case _WalletTransaction():
return $default(_that.id,_that.kind,_that.description,_that.reference,_that.orderId,_that.createdAt,_that.direction,_that.amountKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  String description,  String? reference,  String? orderId,  DateTime createdAt,  String direction,  int amountKobo)?  $default,) {final _that = this;
switch (_that) {
case _WalletTransaction() when $default != null:
return $default(_that.id,_that.kind,_that.description,_that.reference,_that.orderId,_that.createdAt,_that.direction,_that.amountKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletTransaction implements WalletTransaction {
  const _WalletTransaction({required this.id, required this.kind, this.description = '', this.reference, this.orderId, required this.createdAt, this.direction = 'in', required this.amountKobo});
  factory _WalletTransaction.fromJson(Map<String, dynamic> json) => _$WalletTransactionFromJson(json);

@override final  String id;
@override final  String kind;
@override@JsonKey() final  String description;
@override final  String? reference;
@override final  String? orderId;
@override final  DateTime createdAt;
@override@JsonKey() final  String direction;
@override final  int amountKobo;

/// Create a copy of WalletTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletTransactionCopyWith<_WalletTransaction> get copyWith => __$WalletTransactionCopyWithImpl<_WalletTransaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletTransactionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.description, description) || other.description == description)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.amountKobo, amountKobo) || other.amountKobo == amountKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,description,reference,orderId,createdAt,direction,amountKobo);
}

@override
String toString() {
    return 'WalletTransaction(id: $id, kind: $kind, description: $description, reference: $reference, orderId: $orderId, createdAt: $createdAt, direction: $direction, amountKobo: $amountKobo)';
}


}

/// @nodoc
abstract mixin class _$WalletTransactionCopyWith<$Res> implements $WalletTransactionCopyWith<$Res> {
  factory _$WalletTransactionCopyWith(_WalletTransaction value, $Res Function(_WalletTransaction) _then) = __$WalletTransactionCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, String description, String? reference, String? orderId, DateTime createdAt, String direction, int amountKobo
});




}
/// @nodoc
class __$WalletTransactionCopyWithImpl<$Res>
    implements _$WalletTransactionCopyWith<$Res> {
  __$WalletTransactionCopyWithImpl(this._self, this._then);

  final _WalletTransaction _self;
  final $Res Function(_WalletTransaction) _then;

/// Create a copy of WalletTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? description = null,Object? reference = freezed,Object? orderId = freezed,Object? createdAt = null,Object? direction = null,Object? amountKobo = null,}) {
  return _then(_WalletTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$WalletLimits {

 int get minTopupKobo; int get maxTopupKobo; int get maxBalanceKobo;
/// Create a copy of WalletLimits
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletLimitsCopyWith<WalletLimits> get copyWith => _$WalletLimitsCopyWithImpl<WalletLimits>(this as WalletLimits, _$identity);

  /// Serializes this WalletLimits to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WalletLimits;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletLimits&&(identical(other.minTopupKobo, _this.minTopupKobo) || other.minTopupKobo == _this.minTopupKobo)&&(identical(other.maxTopupKobo, _this.maxTopupKobo) || other.maxTopupKobo == _this.maxTopupKobo)&&(identical(other.maxBalanceKobo, _this.maxBalanceKobo) || other.maxBalanceKobo == _this.maxBalanceKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WalletLimits;
  return Object.hash(runtimeType,_this.minTopupKobo,_this.maxTopupKobo,_this.maxBalanceKobo);
}

@override
String toString() {
  final _this = this as WalletLimits;
  return 'WalletLimits(minTopupKobo: ${_this.minTopupKobo}, maxTopupKobo: ${_this.maxTopupKobo}, maxBalanceKobo: ${_this.maxBalanceKobo})';
}


}

/// @nodoc
abstract mixin class $WalletLimitsCopyWith<$Res>  {
  factory $WalletLimitsCopyWith(WalletLimits value, $Res Function(WalletLimits) _then) = _$WalletLimitsCopyWithImpl;
@useResult
$Res call({
 int minTopupKobo, int maxTopupKobo, int maxBalanceKobo
});




}
/// @nodoc
class _$WalletLimitsCopyWithImpl<$Res>
    implements $WalletLimitsCopyWith<$Res> {
  _$WalletLimitsCopyWithImpl(this._self, this._then);

  final WalletLimits _self;
  final $Res Function(WalletLimits) _then;

/// Create a copy of WalletLimits
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minTopupKobo = null,Object? maxTopupKobo = null,Object? maxBalanceKobo = null,}) {
  return _then(WalletLimits(
minTopupKobo: null == minTopupKobo ? _self.minTopupKobo : minTopupKobo // ignore: cast_nullable_to_non_nullable
as int,maxTopupKobo: null == maxTopupKobo ? _self.maxTopupKobo : maxTopupKobo // ignore: cast_nullable_to_non_nullable
as int,maxBalanceKobo: null == maxBalanceKobo ? _self.maxBalanceKobo : maxBalanceKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletLimits].
extension WalletLimitsPatterns on WalletLimits {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletLimits value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletLimits() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletLimits value)  $default,){
final _that = this;
switch (_that) {
case _WalletLimits():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletLimits value)?  $default,){
final _that = this;
switch (_that) {
case _WalletLimits() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int minTopupKobo,  int maxTopupKobo,  int maxBalanceKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletLimits() when $default != null:
return $default(_that.minTopupKobo,_that.maxTopupKobo,_that.maxBalanceKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int minTopupKobo,  int maxTopupKobo,  int maxBalanceKobo)  $default,) {final _that = this;
switch (_that) {
case _WalletLimits():
return $default(_that.minTopupKobo,_that.maxTopupKobo,_that.maxBalanceKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int minTopupKobo,  int maxTopupKobo,  int maxBalanceKobo)?  $default,) {final _that = this;
switch (_that) {
case _WalletLimits() when $default != null:
return $default(_that.minTopupKobo,_that.maxTopupKobo,_that.maxBalanceKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletLimits implements WalletLimits {
  const _WalletLimits({this.minTopupKobo = 50000, this.maxTopupKobo = 10000000, this.maxBalanceKobo = 30000000});
  factory _WalletLimits.fromJson(Map<String, dynamic> json) => _$WalletLimitsFromJson(json);

@override@JsonKey() final  int minTopupKobo;
@override@JsonKey() final  int maxTopupKobo;
@override@JsonKey() final  int maxBalanceKobo;

/// Create a copy of WalletLimits
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletLimitsCopyWith<_WalletLimits> get copyWith => __$WalletLimitsCopyWithImpl<_WalletLimits>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletLimitsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletLimits&&(identical(other.minTopupKobo, minTopupKobo) || other.minTopupKobo == minTopupKobo)&&(identical(other.maxTopupKobo, maxTopupKobo) || other.maxTopupKobo == maxTopupKobo)&&(identical(other.maxBalanceKobo, maxBalanceKobo) || other.maxBalanceKobo == maxBalanceKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,minTopupKobo,maxTopupKobo,maxBalanceKobo);
}

@override
String toString() {
    return 'WalletLimits(minTopupKobo: $minTopupKobo, maxTopupKobo: $maxTopupKobo, maxBalanceKobo: $maxBalanceKobo)';
}


}

/// @nodoc
abstract mixin class _$WalletLimitsCopyWith<$Res> implements $WalletLimitsCopyWith<$Res> {
  factory _$WalletLimitsCopyWith(_WalletLimits value, $Res Function(_WalletLimits) _then) = __$WalletLimitsCopyWithImpl;
@override @useResult
$Res call({
 int minTopupKobo, int maxTopupKobo, int maxBalanceKobo
});




}
/// @nodoc
class __$WalletLimitsCopyWithImpl<$Res>
    implements _$WalletLimitsCopyWith<$Res> {
  __$WalletLimitsCopyWithImpl(this._self, this._then);

  final _WalletLimits _self;
  final $Res Function(_WalletLimits) _then;

/// Create a copy of WalletLimits
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minTopupKobo = null,Object? maxTopupKobo = null,Object? maxBalanceKobo = null,}) {
  return _then(_WalletLimits(
minTopupKobo: null == minTopupKobo ? _self.minTopupKobo : minTopupKobo // ignore: cast_nullable_to_non_nullable
as int,maxTopupKobo: null == maxTopupKobo ? _self.maxTopupKobo : maxTopupKobo // ignore: cast_nullable_to_non_nullable
as int,maxBalanceKobo: null == maxBalanceKobo ? _self.maxBalanceKobo : maxBalanceKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SellerSummary {

 int get codBalanceKobo; int get pendingPayoutsKobo; int get availableKobo; int get minPayoutKobo;
/// Create a copy of SellerSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SellerSummaryCopyWith<SellerSummary> get copyWith => _$SellerSummaryCopyWithImpl<SellerSummary>(this as SellerSummary, _$identity);

  /// Serializes this SellerSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SellerSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SellerSummary&&(identical(other.codBalanceKobo, _this.codBalanceKobo) || other.codBalanceKobo == _this.codBalanceKobo)&&(identical(other.pendingPayoutsKobo, _this.pendingPayoutsKobo) || other.pendingPayoutsKobo == _this.pendingPayoutsKobo)&&(identical(other.availableKobo, _this.availableKobo) || other.availableKobo == _this.availableKobo)&&(identical(other.minPayoutKobo, _this.minPayoutKobo) || other.minPayoutKobo == _this.minPayoutKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SellerSummary;
  return Object.hash(runtimeType,_this.codBalanceKobo,_this.pendingPayoutsKobo,_this.availableKobo,_this.minPayoutKobo);
}

@override
String toString() {
  final _this = this as SellerSummary;
  return 'SellerSummary(codBalanceKobo: ${_this.codBalanceKobo}, pendingPayoutsKobo: ${_this.pendingPayoutsKobo}, availableKobo: ${_this.availableKobo}, minPayoutKobo: ${_this.minPayoutKobo})';
}


}

/// @nodoc
abstract mixin class $SellerSummaryCopyWith<$Res>  {
  factory $SellerSummaryCopyWith(SellerSummary value, $Res Function(SellerSummary) _then) = _$SellerSummaryCopyWithImpl;
@useResult
$Res call({
 int codBalanceKobo, int pendingPayoutsKobo, int availableKobo, int minPayoutKobo
});




}
/// @nodoc
class _$SellerSummaryCopyWithImpl<$Res>
    implements $SellerSummaryCopyWith<$Res> {
  _$SellerSummaryCopyWithImpl(this._self, this._then);

  final SellerSummary _self;
  final $Res Function(SellerSummary) _then;

/// Create a copy of SellerSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? codBalanceKobo = null,Object? pendingPayoutsKobo = null,Object? availableKobo = null,Object? minPayoutKobo = null,}) {
  return _then(SellerSummary(
codBalanceKobo: null == codBalanceKobo ? _self.codBalanceKobo : codBalanceKobo // ignore: cast_nullable_to_non_nullable
as int,pendingPayoutsKobo: null == pendingPayoutsKobo ? _self.pendingPayoutsKobo : pendingPayoutsKobo // ignore: cast_nullable_to_non_nullable
as int,availableKobo: null == availableKobo ? _self.availableKobo : availableKobo // ignore: cast_nullable_to_non_nullable
as int,minPayoutKobo: null == minPayoutKobo ? _self.minPayoutKobo : minPayoutKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SellerSummary].
extension SellerSummaryPatterns on SellerSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SellerSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SellerSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SellerSummary value)  $default,){
final _that = this;
switch (_that) {
case _SellerSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SellerSummary value)?  $default,){
final _that = this;
switch (_that) {
case _SellerSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int codBalanceKobo,  int pendingPayoutsKobo,  int availableKobo,  int minPayoutKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SellerSummary() when $default != null:
return $default(_that.codBalanceKobo,_that.pendingPayoutsKobo,_that.availableKobo,_that.minPayoutKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int codBalanceKobo,  int pendingPayoutsKobo,  int availableKobo,  int minPayoutKobo)  $default,) {final _that = this;
switch (_that) {
case _SellerSummary():
return $default(_that.codBalanceKobo,_that.pendingPayoutsKobo,_that.availableKobo,_that.minPayoutKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int codBalanceKobo,  int pendingPayoutsKobo,  int availableKobo,  int minPayoutKobo)?  $default,) {final _that = this;
switch (_that) {
case _SellerSummary() when $default != null:
return $default(_that.codBalanceKobo,_that.pendingPayoutsKobo,_that.availableKobo,_that.minPayoutKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SellerSummary implements SellerSummary {
  const _SellerSummary({this.codBalanceKobo = 0, this.pendingPayoutsKobo = 0, this.availableKobo = 0, this.minPayoutKobo = 100000});
  factory _SellerSummary.fromJson(Map<String, dynamic> json) => _$SellerSummaryFromJson(json);

@override@JsonKey() final  int codBalanceKobo;
@override@JsonKey() final  int pendingPayoutsKobo;
@override@JsonKey() final  int availableKobo;
@override@JsonKey() final  int minPayoutKobo;

/// Create a copy of SellerSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SellerSummaryCopyWith<_SellerSummary> get copyWith => __$SellerSummaryCopyWithImpl<_SellerSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SellerSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SellerSummary&&(identical(other.codBalanceKobo, codBalanceKobo) || other.codBalanceKobo == codBalanceKobo)&&(identical(other.pendingPayoutsKobo, pendingPayoutsKobo) || other.pendingPayoutsKobo == pendingPayoutsKobo)&&(identical(other.availableKobo, availableKobo) || other.availableKobo == availableKobo)&&(identical(other.minPayoutKobo, minPayoutKobo) || other.minPayoutKobo == minPayoutKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,codBalanceKobo,pendingPayoutsKobo,availableKobo,minPayoutKobo);
}

@override
String toString() {
    return 'SellerSummary(codBalanceKobo: $codBalanceKobo, pendingPayoutsKobo: $pendingPayoutsKobo, availableKobo: $availableKobo, minPayoutKobo: $minPayoutKobo)';
}


}

/// @nodoc
abstract mixin class _$SellerSummaryCopyWith<$Res> implements $SellerSummaryCopyWith<$Res> {
  factory _$SellerSummaryCopyWith(_SellerSummary value, $Res Function(_SellerSummary) _then) = __$SellerSummaryCopyWithImpl;
@override @useResult
$Res call({
 int codBalanceKobo, int pendingPayoutsKobo, int availableKobo, int minPayoutKobo
});




}
/// @nodoc
class __$SellerSummaryCopyWithImpl<$Res>
    implements _$SellerSummaryCopyWith<$Res> {
  __$SellerSummaryCopyWithImpl(this._self, this._then);

  final _SellerSummary _self;
  final $Res Function(_SellerSummary) _then;

/// Create a copy of SellerSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? codBalanceKobo = null,Object? pendingPayoutsKobo = null,Object? availableKobo = null,Object? minPayoutKobo = null,}) {
  return _then(_SellerSummary(
codBalanceKobo: null == codBalanceKobo ? _self.codBalanceKobo : codBalanceKobo // ignore: cast_nullable_to_non_nullable
as int,pendingPayoutsKobo: null == pendingPayoutsKobo ? _self.pendingPayoutsKobo : pendingPayoutsKobo // ignore: cast_nullable_to_non_nullable
as int,availableKobo: null == availableKobo ? _self.availableKobo : availableKobo // ignore: cast_nullable_to_non_nullable
as int,minPayoutKobo: null == minPayoutKobo ? _self.minPayoutKobo : minPayoutKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$WalletOverview {

 int get balanceKobo; bool get enabled; WalletLimits get limits; bool get refundToWallet; List<WalletTransaction> get transactions; SellerSummary? get seller;
/// Create a copy of WalletOverview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletOverviewCopyWith<WalletOverview> get copyWith => _$WalletOverviewCopyWithImpl<WalletOverview>(this as WalletOverview, _$identity);

  /// Serializes this WalletOverview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WalletOverview;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletOverview&&(identical(other.balanceKobo, _this.balanceKobo) || other.balanceKobo == _this.balanceKobo)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.limits, _this.limits) || other.limits == _this.limits)&&(identical(other.refundToWallet, _this.refundToWallet) || other.refundToWallet == _this.refundToWallet)&&const DeepCollectionEquality().equals(other.transactions, _this.transactions)&&(identical(other.seller, _this.seller) || other.seller == _this.seller));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WalletOverview;
  return Object.hash(runtimeType,_this.balanceKobo,_this.enabled,_this.limits,_this.refundToWallet,const DeepCollectionEquality().hash(_this.transactions),_this.seller);
}

@override
String toString() {
  final _this = this as WalletOverview;
  return 'WalletOverview(balanceKobo: ${_this.balanceKobo}, enabled: ${_this.enabled}, limits: ${_this.limits}, refundToWallet: ${_this.refundToWallet}, transactions: ${_this.transactions}, seller: ${_this.seller})';
}


}

/// @nodoc
abstract mixin class $WalletOverviewCopyWith<$Res>  {
  factory $WalletOverviewCopyWith(WalletOverview value, $Res Function(WalletOverview) _then) = _$WalletOverviewCopyWithImpl;
@useResult
$Res call({
 int balanceKobo, bool enabled, WalletLimits limits, bool refundToWallet, List<WalletTransaction> transactions, SellerSummary? seller
});


$WalletLimitsCopyWith<$Res> get limits;$SellerSummaryCopyWith<$Res>? get seller;

}
/// @nodoc
class _$WalletOverviewCopyWithImpl<$Res>
    implements $WalletOverviewCopyWith<$Res> {
  _$WalletOverviewCopyWithImpl(this._self, this._then);

  final WalletOverview _self;
  final $Res Function(WalletOverview) _then;

/// Create a copy of WalletOverview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? balanceKobo = null,Object? enabled = null,Object? limits = null,Object? refundToWallet = null,Object? transactions = null,Object? seller = freezed,}) {
  return _then(WalletOverview(
balanceKobo: null == balanceKobo ? _self.balanceKobo : balanceKobo // ignore: cast_nullable_to_non_nullable
as int,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,limits: null == limits ? _self.limits : limits // ignore: cast_nullable_to_non_nullable
as WalletLimits,refundToWallet: null == refundToWallet ? _self.refundToWallet : refundToWallet // ignore: cast_nullable_to_non_nullable
as bool,transactions: null == transactions ? _self.transactions : transactions // ignore: cast_nullable_to_non_nullable
as List<WalletTransaction>,seller: freezed == seller ? _self.seller : seller // ignore: cast_nullable_to_non_nullable
as SellerSummary?,
  ));
}
/// Create a copy of WalletOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletLimitsCopyWith<$Res> get limits {
  
  return $WalletLimitsCopyWith<$Res>(_self.limits, (value) {
    return _then(_self.copyWith(limits: value));
  });
}/// Create a copy of WalletOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SellerSummaryCopyWith<$Res>? get seller {
    if (_self.seller == null) {
    return null;
  }

  return $SellerSummaryCopyWith<$Res>(_self.seller!, (value) {
    return _then(_self.copyWith(seller: value));
  });
}
}


/// Adds pattern-matching-related methods to [WalletOverview].
extension WalletOverviewPatterns on WalletOverview {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletOverview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletOverview() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletOverview value)  $default,){
final _that = this;
switch (_that) {
case _WalletOverview():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletOverview value)?  $default,){
final _that = this;
switch (_that) {
case _WalletOverview() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int balanceKobo,  bool enabled,  WalletLimits limits,  bool refundToWallet,  List<WalletTransaction> transactions,  SellerSummary? seller)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletOverview() when $default != null:
return $default(_that.balanceKobo,_that.enabled,_that.limits,_that.refundToWallet,_that.transactions,_that.seller);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int balanceKobo,  bool enabled,  WalletLimits limits,  bool refundToWallet,  List<WalletTransaction> transactions,  SellerSummary? seller)  $default,) {final _that = this;
switch (_that) {
case _WalletOverview():
return $default(_that.balanceKobo,_that.enabled,_that.limits,_that.refundToWallet,_that.transactions,_that.seller);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int balanceKobo,  bool enabled,  WalletLimits limits,  bool refundToWallet,  List<WalletTransaction> transactions,  SellerSummary? seller)?  $default,) {final _that = this;
switch (_that) {
case _WalletOverview() when $default != null:
return $default(_that.balanceKobo,_that.enabled,_that.limits,_that.refundToWallet,_that.transactions,_that.seller);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletOverview implements WalletOverview {
  const _WalletOverview({this.balanceKobo = 0, this.enabled = true, this.limits = const WalletLimits(), this.refundToWallet = false,  List<WalletTransaction> transactions = const <WalletTransaction>[], this.seller}): _transactions = transactions;
  factory _WalletOverview.fromJson(Map<String, dynamic> json) => _$WalletOverviewFromJson(json);

@override@JsonKey() final  int balanceKobo;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  WalletLimits limits;
@override@JsonKey() final  bool refundToWallet;
 final  List<WalletTransaction> _transactions;
@override@JsonKey() List<WalletTransaction> get transactions {
  if (_transactions is EqualUnmodifiableListView) return _transactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transactions);
}

@override final  SellerSummary? seller;

/// Create a copy of WalletOverview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletOverviewCopyWith<_WalletOverview> get copyWith => __$WalletOverviewCopyWithImpl<_WalletOverview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletOverviewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletOverview&&(identical(other.balanceKobo, balanceKobo) || other.balanceKobo == balanceKobo)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.limits, limits) || other.limits == limits)&&(identical(other.refundToWallet, refundToWallet) || other.refundToWallet == refundToWallet)&&const DeepCollectionEquality().equals(other.transactions, _transactions)&&(identical(other.seller, seller) || other.seller == seller));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,balanceKobo,enabled,limits,refundToWallet,const DeepCollectionEquality().hash(_transactions),seller);
}

@override
String toString() {
    return 'WalletOverview(balanceKobo: $balanceKobo, enabled: $enabled, limits: $limits, refundToWallet: $refundToWallet, transactions: $transactions, seller: $seller)';
}


}

/// @nodoc
abstract mixin class _$WalletOverviewCopyWith<$Res> implements $WalletOverviewCopyWith<$Res> {
  factory _$WalletOverviewCopyWith(_WalletOverview value, $Res Function(_WalletOverview) _then) = __$WalletOverviewCopyWithImpl;
@override @useResult
$Res call({
 int balanceKobo, bool enabled, WalletLimits limits, bool refundToWallet, List<WalletTransaction> transactions, SellerSummary? seller
});


@override $WalletLimitsCopyWith<$Res> get limits;@override $SellerSummaryCopyWith<$Res>? get seller;

}
/// @nodoc
class __$WalletOverviewCopyWithImpl<$Res>
    implements _$WalletOverviewCopyWith<$Res> {
  __$WalletOverviewCopyWithImpl(this._self, this._then);

  final _WalletOverview _self;
  final $Res Function(_WalletOverview) _then;

/// Create a copy of WalletOverview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? balanceKobo = null,Object? enabled = null,Object? limits = null,Object? refundToWallet = null,Object? transactions = null,Object? seller = freezed,}) {
  return _then(_WalletOverview(
balanceKobo: null == balanceKobo ? _self.balanceKobo : balanceKobo // ignore: cast_nullable_to_non_nullable
as int,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,limits: null == limits ? _self.limits : limits // ignore: cast_nullable_to_non_nullable
as WalletLimits,refundToWallet: null == refundToWallet ? _self.refundToWallet : refundToWallet // ignore: cast_nullable_to_non_nullable
as bool,transactions: null == transactions ? _self._transactions : transactions // ignore: cast_nullable_to_non_nullable
as List<WalletTransaction>,seller: freezed == seller ? _self.seller : seller // ignore: cast_nullable_to_non_nullable
as SellerSummary?,
  ));
}

/// Create a copy of WalletOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletLimitsCopyWith<$Res> get limits {
  
  return $WalletLimitsCopyWith<$Res>(_self.limits, (value) {
    return _then(_self.copyWith(limits: value));
  });
}/// Create a copy of WalletOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SellerSummaryCopyWith<$Res>? get seller {
    if (_self.seller == null) {
    return null;
  }

  return $SellerSummaryCopyWith<$Res>(_self.seller!, (value) {
    return _then(_self.copyWith(seller: value));
  });
}
}


/// @nodoc
mixin _$WaybillParty {

 String get name; String get phone; String? get line1; String? get area; GeoPoint? get location; String? get instructions;
/// Create a copy of WaybillParty
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaybillPartyCopyWith<WaybillParty> get copyWith => _$WaybillPartyCopyWithImpl<WaybillParty>(this as WaybillParty, _$identity);

  /// Serializes this WaybillParty to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WaybillParty;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaybillParty&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.line1, _this.line1) || other.line1 == _this.line1)&&(identical(other.area, _this.area) || other.area == _this.area)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.instructions, _this.instructions) || other.instructions == _this.instructions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WaybillParty;
  return Object.hash(runtimeType,_this.name,_this.phone,_this.line1,_this.area,_this.location,_this.instructions);
}

@override
String toString() {
  final _this = this as WaybillParty;
  return 'WaybillParty(name: ${_this.name}, phone: ${_this.phone}, line1: ${_this.line1}, area: ${_this.area}, location: ${_this.location}, instructions: ${_this.instructions})';
}


}

/// @nodoc
abstract mixin class $WaybillPartyCopyWith<$Res>  {
  factory $WaybillPartyCopyWith(WaybillParty value, $Res Function(WaybillParty) _then) = _$WaybillPartyCopyWithImpl;
@useResult
$Res call({
 String name, String phone, String? line1, String? area, GeoPoint? location, String? instructions
});


$GeoPointCopyWith<$Res>? get location;

}
/// @nodoc
class _$WaybillPartyCopyWithImpl<$Res>
    implements $WaybillPartyCopyWith<$Res> {
  _$WaybillPartyCopyWithImpl(this._self, this._then);

  final WaybillParty _self;
  final $Res Function(WaybillParty) _then;

/// Create a copy of WaybillParty
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? phone = null,Object? line1 = freezed,Object? area = freezed,Object? location = freezed,Object? instructions = freezed,}) {
  return _then(WaybillParty(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,line1: freezed == line1 ? _self.line1 : line1 // ignore: cast_nullable_to_non_nullable
as String?,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint?,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of WaybillParty
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [WaybillParty].
extension WaybillPartyPatterns on WaybillParty {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaybillParty value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaybillParty() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaybillParty value)  $default,){
final _that = this;
switch (_that) {
case _WaybillParty():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaybillParty value)?  $default,){
final _that = this;
switch (_that) {
case _WaybillParty() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String phone,  String? line1,  String? area,  GeoPoint? location,  String? instructions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaybillParty() when $default != null:
return $default(_that.name,_that.phone,_that.line1,_that.area,_that.location,_that.instructions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String phone,  String? line1,  String? area,  GeoPoint? location,  String? instructions)  $default,) {final _that = this;
switch (_that) {
case _WaybillParty():
return $default(_that.name,_that.phone,_that.line1,_that.area,_that.location,_that.instructions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String phone,  String? line1,  String? area,  GeoPoint? location,  String? instructions)?  $default,) {final _that = this;
switch (_that) {
case _WaybillParty() when $default != null:
return $default(_that.name,_that.phone,_that.line1,_that.area,_that.location,_that.instructions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaybillParty implements WaybillParty {
  const _WaybillParty({required this.name, required this.phone, this.line1, this.area, this.location, this.instructions});
  factory _WaybillParty.fromJson(Map<String, dynamic> json) => _$WaybillPartyFromJson(json);

@override final  String name;
@override final  String phone;
@override final  String? line1;
@override final  String? area;
@override final  GeoPoint? location;
@override final  String? instructions;

/// Create a copy of WaybillParty
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaybillPartyCopyWith<_WaybillParty> get copyWith => __$WaybillPartyCopyWithImpl<_WaybillParty>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaybillPartyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaybillParty&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.line1, line1) || other.line1 == line1)&&(identical(other.area, area) || other.area == area)&&(identical(other.location, location) || other.location == location)&&(identical(other.instructions, instructions) || other.instructions == instructions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,phone,line1,area,location,instructions);
}

@override
String toString() {
    return 'WaybillParty(name: $name, phone: $phone, line1: $line1, area: $area, location: $location, instructions: $instructions)';
}


}

/// @nodoc
abstract mixin class _$WaybillPartyCopyWith<$Res> implements $WaybillPartyCopyWith<$Res> {
  factory _$WaybillPartyCopyWith(_WaybillParty value, $Res Function(_WaybillParty) _then) = __$WaybillPartyCopyWithImpl;
@override @useResult
$Res call({
 String name, String phone, String? line1, String? area, GeoPoint? location, String? instructions
});


@override $GeoPointCopyWith<$Res>? get location;

}
/// @nodoc
class __$WaybillPartyCopyWithImpl<$Res>
    implements _$WaybillPartyCopyWith<$Res> {
  __$WaybillPartyCopyWithImpl(this._self, this._then);

  final _WaybillParty _self;
  final $Res Function(_WaybillParty) _then;

/// Create a copy of WaybillParty
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? phone = null,Object? line1 = freezed,Object? area = freezed,Object? location = freezed,Object? instructions = freezed,}) {
  return _then(_WaybillParty(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,line1: freezed == line1 ? _self.line1 : line1 // ignore: cast_nullable_to_non_nullable
as String?,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint?,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of WaybillParty
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// @nodoc
mixin _$WaybillDetails {

 String? get trackingCode; String get originCity; String get destinationCity; String get originCityName; String get destinationCityName; String get originHubId; String get destinationHubId; String get originHubName; String get destinationHubName; String get destinationHubAddress; String get destinationHubHours; String get firstMile; String get lastMile; WaybillParty get sender; WaybillParty get recipient; String get size; double get weightKg; String get category; String get description; int? get codAmountKobo; String get carrierName; String? get stage; String? get etaFrom; String? get etaTo;
/// Create a copy of WaybillDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaybillDetailsCopyWith<WaybillDetails> get copyWith => _$WaybillDetailsCopyWithImpl<WaybillDetails>(this as WaybillDetails, _$identity);

  /// Serializes this WaybillDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WaybillDetails;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaybillDetails&&(identical(other.trackingCode, _this.trackingCode) || other.trackingCode == _this.trackingCode)&&(identical(other.originCity, _this.originCity) || other.originCity == _this.originCity)&&(identical(other.destinationCity, _this.destinationCity) || other.destinationCity == _this.destinationCity)&&(identical(other.originCityName, _this.originCityName) || other.originCityName == _this.originCityName)&&(identical(other.destinationCityName, _this.destinationCityName) || other.destinationCityName == _this.destinationCityName)&&(identical(other.originHubId, _this.originHubId) || other.originHubId == _this.originHubId)&&(identical(other.destinationHubId, _this.destinationHubId) || other.destinationHubId == _this.destinationHubId)&&(identical(other.originHubName, _this.originHubName) || other.originHubName == _this.originHubName)&&(identical(other.destinationHubName, _this.destinationHubName) || other.destinationHubName == _this.destinationHubName)&&(identical(other.destinationHubAddress, _this.destinationHubAddress) || other.destinationHubAddress == _this.destinationHubAddress)&&(identical(other.destinationHubHours, _this.destinationHubHours) || other.destinationHubHours == _this.destinationHubHours)&&(identical(other.firstMile, _this.firstMile) || other.firstMile == _this.firstMile)&&(identical(other.lastMile, _this.lastMile) || other.lastMile == _this.lastMile)&&(identical(other.sender, _this.sender) || other.sender == _this.sender)&&(identical(other.recipient, _this.recipient) || other.recipient == _this.recipient)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.weightKg, _this.weightKg) || other.weightKg == _this.weightKg)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.codAmountKobo, _this.codAmountKobo) || other.codAmountKobo == _this.codAmountKobo)&&(identical(other.carrierName, _this.carrierName) || other.carrierName == _this.carrierName)&&(identical(other.stage, _this.stage) || other.stage == _this.stage)&&(identical(other.etaFrom, _this.etaFrom) || other.etaFrom == _this.etaFrom)&&(identical(other.etaTo, _this.etaTo) || other.etaTo == _this.etaTo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WaybillDetails;
  return Object.hashAll([runtimeType,_this.trackingCode,_this.originCity,_this.destinationCity,_this.originCityName,_this.destinationCityName,_this.originHubId,_this.destinationHubId,_this.originHubName,_this.destinationHubName,_this.destinationHubAddress,_this.destinationHubHours,_this.firstMile,_this.lastMile,_this.sender,_this.recipient,_this.size,_this.weightKg,_this.category,_this.description,_this.codAmountKobo,_this.carrierName,_this.stage,_this.etaFrom,_this.etaTo]);
}

@override
String toString() {
  final _this = this as WaybillDetails;
  return 'WaybillDetails(trackingCode: ${_this.trackingCode}, originCity: ${_this.originCity}, destinationCity: ${_this.destinationCity}, originCityName: ${_this.originCityName}, destinationCityName: ${_this.destinationCityName}, originHubId: ${_this.originHubId}, destinationHubId: ${_this.destinationHubId}, originHubName: ${_this.originHubName}, destinationHubName: ${_this.destinationHubName}, destinationHubAddress: ${_this.destinationHubAddress}, destinationHubHours: ${_this.destinationHubHours}, firstMile: ${_this.firstMile}, lastMile: ${_this.lastMile}, sender: ${_this.sender}, recipient: ${_this.recipient}, size: ${_this.size}, weightKg: ${_this.weightKg}, category: ${_this.category}, description: ${_this.description}, codAmountKobo: ${_this.codAmountKobo}, carrierName: ${_this.carrierName}, stage: ${_this.stage}, etaFrom: ${_this.etaFrom}, etaTo: ${_this.etaTo})';
}


}

/// @nodoc
abstract mixin class $WaybillDetailsCopyWith<$Res>  {
  factory $WaybillDetailsCopyWith(WaybillDetails value, $Res Function(WaybillDetails) _then) = _$WaybillDetailsCopyWithImpl;
@useResult
$Res call({
 String? trackingCode, String originCity, String destinationCity, String originCityName, String destinationCityName, String originHubId, String destinationHubId, String originHubName, String destinationHubName, String destinationHubAddress, String destinationHubHours, String firstMile, String lastMile, WaybillParty sender, WaybillParty recipient, String size, double weightKg, String category, String description, int? codAmountKobo, String carrierName, String? stage, String? etaFrom, String? etaTo
});


$WaybillPartyCopyWith<$Res> get sender;$WaybillPartyCopyWith<$Res> get recipient;

}
/// @nodoc
class _$WaybillDetailsCopyWithImpl<$Res>
    implements $WaybillDetailsCopyWith<$Res> {
  _$WaybillDetailsCopyWithImpl(this._self, this._then);

  final WaybillDetails _self;
  final $Res Function(WaybillDetails) _then;

/// Create a copy of WaybillDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trackingCode = freezed,Object? originCity = null,Object? destinationCity = null,Object? originCityName = null,Object? destinationCityName = null,Object? originHubId = null,Object? destinationHubId = null,Object? originHubName = null,Object? destinationHubName = null,Object? destinationHubAddress = null,Object? destinationHubHours = null,Object? firstMile = null,Object? lastMile = null,Object? sender = null,Object? recipient = null,Object? size = null,Object? weightKg = null,Object? category = null,Object? description = null,Object? codAmountKobo = freezed,Object? carrierName = null,Object? stage = freezed,Object? etaFrom = freezed,Object? etaTo = freezed,}) {
  return _then(WaybillDetails(
trackingCode: freezed == trackingCode ? _self.trackingCode : trackingCode // ignore: cast_nullable_to_non_nullable
as String?,originCity: null == originCity ? _self.originCity : originCity // ignore: cast_nullable_to_non_nullable
as String,destinationCity: null == destinationCity ? _self.destinationCity : destinationCity // ignore: cast_nullable_to_non_nullable
as String,originCityName: null == originCityName ? _self.originCityName : originCityName // ignore: cast_nullable_to_non_nullable
as String,destinationCityName: null == destinationCityName ? _self.destinationCityName : destinationCityName // ignore: cast_nullable_to_non_nullable
as String,originHubId: null == originHubId ? _self.originHubId : originHubId // ignore: cast_nullable_to_non_nullable
as String,destinationHubId: null == destinationHubId ? _self.destinationHubId : destinationHubId // ignore: cast_nullable_to_non_nullable
as String,originHubName: null == originHubName ? _self.originHubName : originHubName // ignore: cast_nullable_to_non_nullable
as String,destinationHubName: null == destinationHubName ? _self.destinationHubName : destinationHubName // ignore: cast_nullable_to_non_nullable
as String,destinationHubAddress: null == destinationHubAddress ? _self.destinationHubAddress : destinationHubAddress // ignore: cast_nullable_to_non_nullable
as String,destinationHubHours: null == destinationHubHours ? _self.destinationHubHours : destinationHubHours // ignore: cast_nullable_to_non_nullable
as String,firstMile: null == firstMile ? _self.firstMile : firstMile // ignore: cast_nullable_to_non_nullable
as String,lastMile: null == lastMile ? _self.lastMile : lastMile // ignore: cast_nullable_to_non_nullable
as String,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as WaybillParty,recipient: null == recipient ? _self.recipient : recipient // ignore: cast_nullable_to_non_nullable
as WaybillParty,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,codAmountKobo: freezed == codAmountKobo ? _self.codAmountKobo : codAmountKobo // ignore: cast_nullable_to_non_nullable
as int?,carrierName: null == carrierName ? _self.carrierName : carrierName // ignore: cast_nullable_to_non_nullable
as String,stage: freezed == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String?,etaFrom: freezed == etaFrom ? _self.etaFrom : etaFrom // ignore: cast_nullable_to_non_nullable
as String?,etaTo: freezed == etaTo ? _self.etaTo : etaTo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of WaybillDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WaybillPartyCopyWith<$Res> get sender {
  
  return $WaybillPartyCopyWith<$Res>(_self.sender, (value) {
    return _then(_self.copyWith(sender: value));
  });
}/// Create a copy of WaybillDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WaybillPartyCopyWith<$Res> get recipient {
  
  return $WaybillPartyCopyWith<$Res>(_self.recipient, (value) {
    return _then(_self.copyWith(recipient: value));
  });
}
}


/// Adds pattern-matching-related methods to [WaybillDetails].
extension WaybillDetailsPatterns on WaybillDetails {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaybillDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaybillDetails() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaybillDetails value)  $default,){
final _that = this;
switch (_that) {
case _WaybillDetails():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaybillDetails value)?  $default,){
final _that = this;
switch (_that) {
case _WaybillDetails() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? trackingCode,  String originCity,  String destinationCity,  String originCityName,  String destinationCityName,  String originHubId,  String destinationHubId,  String originHubName,  String destinationHubName,  String destinationHubAddress,  String destinationHubHours,  String firstMile,  String lastMile,  WaybillParty sender,  WaybillParty recipient,  String size,  double weightKg,  String category,  String description,  int? codAmountKobo,  String carrierName,  String? stage,  String? etaFrom,  String? etaTo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaybillDetails() when $default != null:
return $default(_that.trackingCode,_that.originCity,_that.destinationCity,_that.originCityName,_that.destinationCityName,_that.originHubId,_that.destinationHubId,_that.originHubName,_that.destinationHubName,_that.destinationHubAddress,_that.destinationHubHours,_that.firstMile,_that.lastMile,_that.sender,_that.recipient,_that.size,_that.weightKg,_that.category,_that.description,_that.codAmountKobo,_that.carrierName,_that.stage,_that.etaFrom,_that.etaTo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? trackingCode,  String originCity,  String destinationCity,  String originCityName,  String destinationCityName,  String originHubId,  String destinationHubId,  String originHubName,  String destinationHubName,  String destinationHubAddress,  String destinationHubHours,  String firstMile,  String lastMile,  WaybillParty sender,  WaybillParty recipient,  String size,  double weightKg,  String category,  String description,  int? codAmountKobo,  String carrierName,  String? stage,  String? etaFrom,  String? etaTo)  $default,) {final _that = this;
switch (_that) {
case _WaybillDetails():
return $default(_that.trackingCode,_that.originCity,_that.destinationCity,_that.originCityName,_that.destinationCityName,_that.originHubId,_that.destinationHubId,_that.originHubName,_that.destinationHubName,_that.destinationHubAddress,_that.destinationHubHours,_that.firstMile,_that.lastMile,_that.sender,_that.recipient,_that.size,_that.weightKg,_that.category,_that.description,_that.codAmountKobo,_that.carrierName,_that.stage,_that.etaFrom,_that.etaTo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? trackingCode,  String originCity,  String destinationCity,  String originCityName,  String destinationCityName,  String originHubId,  String destinationHubId,  String originHubName,  String destinationHubName,  String destinationHubAddress,  String destinationHubHours,  String firstMile,  String lastMile,  WaybillParty sender,  WaybillParty recipient,  String size,  double weightKg,  String category,  String description,  int? codAmountKobo,  String carrierName,  String? stage,  String? etaFrom,  String? etaTo)?  $default,) {final _that = this;
switch (_that) {
case _WaybillDetails() when $default != null:
return $default(_that.trackingCode,_that.originCity,_that.destinationCity,_that.originCityName,_that.destinationCityName,_that.originHubId,_that.destinationHubId,_that.originHubName,_that.destinationHubName,_that.destinationHubAddress,_that.destinationHubHours,_that.firstMile,_that.lastMile,_that.sender,_that.recipient,_that.size,_that.weightKg,_that.category,_that.description,_that.codAmountKobo,_that.carrierName,_that.stage,_that.etaFrom,_that.etaTo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaybillDetails implements WaybillDetails {
  const _WaybillDetails({this.trackingCode, this.originCity = '', this.destinationCity = '', this.originCityName = '', this.destinationCityName = '', this.originHubId = '', this.destinationHubId = '', this.originHubName = '', this.destinationHubName = '', this.destinationHubAddress = '', this.destinationHubHours = '', this.firstMile = 'pickup', this.lastMile = 'door', required this.sender, required this.recipient, this.size = 'small', this.weightKg = 1, this.category = 'other', this.description = '', this.codAmountKobo, this.carrierName = '', this.stage, this.etaFrom, this.etaTo});
  factory _WaybillDetails.fromJson(Map<String, dynamic> json) => _$WaybillDetailsFromJson(json);

@override final  String? trackingCode;
@override@JsonKey() final  String originCity;
@override@JsonKey() final  String destinationCity;
@override@JsonKey() final  String originCityName;
@override@JsonKey() final  String destinationCityName;
@override@JsonKey() final  String originHubId;
@override@JsonKey() final  String destinationHubId;
@override@JsonKey() final  String originHubName;
@override@JsonKey() final  String destinationHubName;
@override@JsonKey() final  String destinationHubAddress;
@override@JsonKey() final  String destinationHubHours;
@override@JsonKey() final  String firstMile;
@override@JsonKey() final  String lastMile;
@override final  WaybillParty sender;
@override final  WaybillParty recipient;
@override@JsonKey() final  String size;
@override@JsonKey() final  double weightKg;
@override@JsonKey() final  String category;
@override@JsonKey() final  String description;
@override final  int? codAmountKobo;
@override@JsonKey() final  String carrierName;
@override final  String? stage;
@override final  String? etaFrom;
@override final  String? etaTo;

/// Create a copy of WaybillDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaybillDetailsCopyWith<_WaybillDetails> get copyWith => __$WaybillDetailsCopyWithImpl<_WaybillDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaybillDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaybillDetails&&(identical(other.trackingCode, trackingCode) || other.trackingCode == trackingCode)&&(identical(other.originCity, originCity) || other.originCity == originCity)&&(identical(other.destinationCity, destinationCity) || other.destinationCity == destinationCity)&&(identical(other.originCityName, originCityName) || other.originCityName == originCityName)&&(identical(other.destinationCityName, destinationCityName) || other.destinationCityName == destinationCityName)&&(identical(other.originHubId, originHubId) || other.originHubId == originHubId)&&(identical(other.destinationHubId, destinationHubId) || other.destinationHubId == destinationHubId)&&(identical(other.originHubName, originHubName) || other.originHubName == originHubName)&&(identical(other.destinationHubName, destinationHubName) || other.destinationHubName == destinationHubName)&&(identical(other.destinationHubAddress, destinationHubAddress) || other.destinationHubAddress == destinationHubAddress)&&(identical(other.destinationHubHours, destinationHubHours) || other.destinationHubHours == destinationHubHours)&&(identical(other.firstMile, firstMile) || other.firstMile == firstMile)&&(identical(other.lastMile, lastMile) || other.lastMile == lastMile)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.recipient, recipient) || other.recipient == recipient)&&(identical(other.size, size) || other.size == size)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.codAmountKobo, codAmountKobo) || other.codAmountKobo == codAmountKobo)&&(identical(other.carrierName, carrierName) || other.carrierName == carrierName)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.etaFrom, etaFrom) || other.etaFrom == etaFrom)&&(identical(other.etaTo, etaTo) || other.etaTo == etaTo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,trackingCode,originCity,destinationCity,originCityName,destinationCityName,originHubId,destinationHubId,originHubName,destinationHubName,destinationHubAddress,destinationHubHours,firstMile,lastMile,sender,recipient,size,weightKg,category,description,codAmountKobo,carrierName,stage,etaFrom,etaTo]);
}

@override
String toString() {
    return 'WaybillDetails(trackingCode: $trackingCode, originCity: $originCity, destinationCity: $destinationCity, originCityName: $originCityName, destinationCityName: $destinationCityName, originHubId: $originHubId, destinationHubId: $destinationHubId, originHubName: $originHubName, destinationHubName: $destinationHubName, destinationHubAddress: $destinationHubAddress, destinationHubHours: $destinationHubHours, firstMile: $firstMile, lastMile: $lastMile, sender: $sender, recipient: $recipient, size: $size, weightKg: $weightKg, category: $category, description: $description, codAmountKobo: $codAmountKobo, carrierName: $carrierName, stage: $stage, etaFrom: $etaFrom, etaTo: $etaTo)';
}


}

/// @nodoc
abstract mixin class _$WaybillDetailsCopyWith<$Res> implements $WaybillDetailsCopyWith<$Res> {
  factory _$WaybillDetailsCopyWith(_WaybillDetails value, $Res Function(_WaybillDetails) _then) = __$WaybillDetailsCopyWithImpl;
@override @useResult
$Res call({
 String? trackingCode, String originCity, String destinationCity, String originCityName, String destinationCityName, String originHubId, String destinationHubId, String originHubName, String destinationHubName, String destinationHubAddress, String destinationHubHours, String firstMile, String lastMile, WaybillParty sender, WaybillParty recipient, String size, double weightKg, String category, String description, int? codAmountKobo, String carrierName, String? stage, String? etaFrom, String? etaTo
});


@override $WaybillPartyCopyWith<$Res> get sender;@override $WaybillPartyCopyWith<$Res> get recipient;

}
/// @nodoc
class __$WaybillDetailsCopyWithImpl<$Res>
    implements _$WaybillDetailsCopyWith<$Res> {
  __$WaybillDetailsCopyWithImpl(this._self, this._then);

  final _WaybillDetails _self;
  final $Res Function(_WaybillDetails) _then;

/// Create a copy of WaybillDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trackingCode = freezed,Object? originCity = null,Object? destinationCity = null,Object? originCityName = null,Object? destinationCityName = null,Object? originHubId = null,Object? destinationHubId = null,Object? originHubName = null,Object? destinationHubName = null,Object? destinationHubAddress = null,Object? destinationHubHours = null,Object? firstMile = null,Object? lastMile = null,Object? sender = null,Object? recipient = null,Object? size = null,Object? weightKg = null,Object? category = null,Object? description = null,Object? codAmountKobo = freezed,Object? carrierName = null,Object? stage = freezed,Object? etaFrom = freezed,Object? etaTo = freezed,}) {
  return _then(_WaybillDetails(
trackingCode: freezed == trackingCode ? _self.trackingCode : trackingCode // ignore: cast_nullable_to_non_nullable
as String?,originCity: null == originCity ? _self.originCity : originCity // ignore: cast_nullable_to_non_nullable
as String,destinationCity: null == destinationCity ? _self.destinationCity : destinationCity // ignore: cast_nullable_to_non_nullable
as String,originCityName: null == originCityName ? _self.originCityName : originCityName // ignore: cast_nullable_to_non_nullable
as String,destinationCityName: null == destinationCityName ? _self.destinationCityName : destinationCityName // ignore: cast_nullable_to_non_nullable
as String,originHubId: null == originHubId ? _self.originHubId : originHubId // ignore: cast_nullable_to_non_nullable
as String,destinationHubId: null == destinationHubId ? _self.destinationHubId : destinationHubId // ignore: cast_nullable_to_non_nullable
as String,originHubName: null == originHubName ? _self.originHubName : originHubName // ignore: cast_nullable_to_non_nullable
as String,destinationHubName: null == destinationHubName ? _self.destinationHubName : destinationHubName // ignore: cast_nullable_to_non_nullable
as String,destinationHubAddress: null == destinationHubAddress ? _self.destinationHubAddress : destinationHubAddress // ignore: cast_nullable_to_non_nullable
as String,destinationHubHours: null == destinationHubHours ? _self.destinationHubHours : destinationHubHours // ignore: cast_nullable_to_non_nullable
as String,firstMile: null == firstMile ? _self.firstMile : firstMile // ignore: cast_nullable_to_non_nullable
as String,lastMile: null == lastMile ? _self.lastMile : lastMile // ignore: cast_nullable_to_non_nullable
as String,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as WaybillParty,recipient: null == recipient ? _self.recipient : recipient // ignore: cast_nullable_to_non_nullable
as WaybillParty,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,codAmountKobo: freezed == codAmountKobo ? _self.codAmountKobo : codAmountKobo // ignore: cast_nullable_to_non_nullable
as int?,carrierName: null == carrierName ? _self.carrierName : carrierName // ignore: cast_nullable_to_non_nullable
as String,stage: freezed == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String?,etaFrom: freezed == etaFrom ? _self.etaFrom : etaFrom // ignore: cast_nullable_to_non_nullable
as String?,etaTo: freezed == etaTo ? _self.etaTo : etaTo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of WaybillDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WaybillPartyCopyWith<$Res> get sender {
  
  return $WaybillPartyCopyWith<$Res>(_self.sender, (value) {
    return _then(_self.copyWith(sender: value));
  });
}/// Create a copy of WaybillDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WaybillPartyCopyWith<$Res> get recipient {
  
  return $WaybillPartyCopyWith<$Res>(_self.recipient, (value) {
    return _then(_self.copyWith(recipient: value));
  });
}
}


/// @nodoc
mixin _$WaybillQuote {

 String get id; WaybillDetails get details; PriceBreakdown get breakdown; String get etaText; DateTime get expiresAt;
/// Create a copy of WaybillQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaybillQuoteCopyWith<WaybillQuote> get copyWith => _$WaybillQuoteCopyWithImpl<WaybillQuote>(this as WaybillQuote, _$identity);

  /// Serializes this WaybillQuote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WaybillQuote;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaybillQuote&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.details, _this.details) || other.details == _this.details)&&(identical(other.breakdown, _this.breakdown) || other.breakdown == _this.breakdown)&&(identical(other.etaText, _this.etaText) || other.etaText == _this.etaText)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WaybillQuote;
  return Object.hash(runtimeType,_this.id,_this.details,_this.breakdown,_this.etaText,_this.expiresAt);
}

@override
String toString() {
  final _this = this as WaybillQuote;
  return 'WaybillQuote(id: ${_this.id}, details: ${_this.details}, breakdown: ${_this.breakdown}, etaText: ${_this.etaText}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $WaybillQuoteCopyWith<$Res>  {
  factory $WaybillQuoteCopyWith(WaybillQuote value, $Res Function(WaybillQuote) _then) = _$WaybillQuoteCopyWithImpl;
@useResult
$Res call({
 String id, WaybillDetails details, PriceBreakdown breakdown, String etaText, DateTime expiresAt
});


$WaybillDetailsCopyWith<$Res> get details;$PriceBreakdownCopyWith<$Res> get breakdown;

}
/// @nodoc
class _$WaybillQuoteCopyWithImpl<$Res>
    implements $WaybillQuoteCopyWith<$Res> {
  _$WaybillQuoteCopyWithImpl(this._self, this._then);

  final WaybillQuote _self;
  final $Res Function(WaybillQuote) _then;

/// Create a copy of WaybillQuote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? details = null,Object? breakdown = null,Object? etaText = null,Object? expiresAt = null,}) {
  return _then(WaybillQuote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as WaybillDetails,breakdown: null == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as PriceBreakdown,etaText: null == etaText ? _self.etaText : etaText // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of WaybillQuote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WaybillDetailsCopyWith<$Res> get details {
  
  return $WaybillDetailsCopyWith<$Res>(_self.details, (value) {
    return _then(_self.copyWith(details: value));
  });
}/// Create a copy of WaybillQuote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceBreakdownCopyWith<$Res> get breakdown {
  
  return $PriceBreakdownCopyWith<$Res>(_self.breakdown, (value) {
    return _then(_self.copyWith(breakdown: value));
  });
}
}


/// Adds pattern-matching-related methods to [WaybillQuote].
extension WaybillQuotePatterns on WaybillQuote {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaybillQuote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaybillQuote() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaybillQuote value)  $default,){
final _that = this;
switch (_that) {
case _WaybillQuote():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaybillQuote value)?  $default,){
final _that = this;
switch (_that) {
case _WaybillQuote() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  WaybillDetails details,  PriceBreakdown breakdown,  String etaText,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaybillQuote() when $default != null:
return $default(_that.id,_that.details,_that.breakdown,_that.etaText,_that.expiresAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  WaybillDetails details,  PriceBreakdown breakdown,  String etaText,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _WaybillQuote():
return $default(_that.id,_that.details,_that.breakdown,_that.etaText,_that.expiresAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  WaybillDetails details,  PriceBreakdown breakdown,  String etaText,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _WaybillQuote() when $default != null:
return $default(_that.id,_that.details,_that.breakdown,_that.etaText,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaybillQuote implements WaybillQuote {
  const _WaybillQuote({required this.id, required this.details, required this.breakdown, this.etaText = '', required this.expiresAt});
  factory _WaybillQuote.fromJson(Map<String, dynamic> json) => _$WaybillQuoteFromJson(json);

@override final  String id;
@override final  WaybillDetails details;
@override final  PriceBreakdown breakdown;
@override@JsonKey() final  String etaText;
@override final  DateTime expiresAt;

/// Create a copy of WaybillQuote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaybillQuoteCopyWith<_WaybillQuote> get copyWith => __$WaybillQuoteCopyWithImpl<_WaybillQuote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaybillQuoteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaybillQuote&&(identical(other.id, id) || other.id == id)&&(identical(other.details, details) || other.details == details)&&(identical(other.breakdown, breakdown) || other.breakdown == breakdown)&&(identical(other.etaText, etaText) || other.etaText == etaText)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,details,breakdown,etaText,expiresAt);
}

@override
String toString() {
    return 'WaybillQuote(id: $id, details: $details, breakdown: $breakdown, etaText: $etaText, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$WaybillQuoteCopyWith<$Res> implements $WaybillQuoteCopyWith<$Res> {
  factory _$WaybillQuoteCopyWith(_WaybillQuote value, $Res Function(_WaybillQuote) _then) = __$WaybillQuoteCopyWithImpl;
@override @useResult
$Res call({
 String id, WaybillDetails details, PriceBreakdown breakdown, String etaText, DateTime expiresAt
});


@override $WaybillDetailsCopyWith<$Res> get details;@override $PriceBreakdownCopyWith<$Res> get breakdown;

}
/// @nodoc
class __$WaybillQuoteCopyWithImpl<$Res>
    implements _$WaybillQuoteCopyWith<$Res> {
  __$WaybillQuoteCopyWithImpl(this._self, this._then);

  final _WaybillQuote _self;
  final $Res Function(_WaybillQuote) _then;

/// Create a copy of WaybillQuote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? details = null,Object? breakdown = null,Object? etaText = null,Object? expiresAt = null,}) {
  return _then(_WaybillQuote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as WaybillDetails,breakdown: null == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as PriceBreakdown,etaText: null == etaText ? _self.etaText : etaText // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of WaybillQuote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WaybillDetailsCopyWith<$Res> get details {
  
  return $WaybillDetailsCopyWith<$Res>(_self.details, (value) {
    return _then(_self.copyWith(details: value));
  });
}/// Create a copy of WaybillQuote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceBreakdownCopyWith<$Res> get breakdown {
  
  return $PriceBreakdownCopyWith<$Res>(_self.breakdown, (value) {
    return _then(_self.copyWith(breakdown: value));
  });
}
}


/// @nodoc
mixin _$WaybillHub {

 String get id; String get name; String get city; String get address; String get hours; bool get isSample;
/// Create a copy of WaybillHub
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaybillHubCopyWith<WaybillHub> get copyWith => _$WaybillHubCopyWithImpl<WaybillHub>(this as WaybillHub, _$identity);

  /// Serializes this WaybillHub to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WaybillHub;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaybillHub&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.hours, _this.hours) || other.hours == _this.hours)&&(identical(other.isSample, _this.isSample) || other.isSample == _this.isSample));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WaybillHub;
  return Object.hash(runtimeType,_this.id,_this.name,_this.city,_this.address,_this.hours,_this.isSample);
}

@override
String toString() {
  final _this = this as WaybillHub;
  return 'WaybillHub(id: ${_this.id}, name: ${_this.name}, city: ${_this.city}, address: ${_this.address}, hours: ${_this.hours}, isSample: ${_this.isSample})';
}


}

/// @nodoc
abstract mixin class $WaybillHubCopyWith<$Res>  {
  factory $WaybillHubCopyWith(WaybillHub value, $Res Function(WaybillHub) _then) = _$WaybillHubCopyWithImpl;
@useResult
$Res call({
 String id, String name, String city, String address, String hours, bool isSample
});




}
/// @nodoc
class _$WaybillHubCopyWithImpl<$Res>
    implements $WaybillHubCopyWith<$Res> {
  _$WaybillHubCopyWithImpl(this._self, this._then);

  final WaybillHub _self;
  final $Res Function(WaybillHub) _then;

/// Create a copy of WaybillHub
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? city = null,Object? address = null,Object? hours = null,Object? isSample = null,}) {
  return _then(WaybillHub(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as String,isSample: null == isSample ? _self.isSample : isSample // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WaybillHub].
extension WaybillHubPatterns on WaybillHub {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaybillHub value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaybillHub() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaybillHub value)  $default,){
final _that = this;
switch (_that) {
case _WaybillHub():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaybillHub value)?  $default,){
final _that = this;
switch (_that) {
case _WaybillHub() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String city,  String address,  String hours,  bool isSample)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaybillHub() when $default != null:
return $default(_that.id,_that.name,_that.city,_that.address,_that.hours,_that.isSample);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String city,  String address,  String hours,  bool isSample)  $default,) {final _that = this;
switch (_that) {
case _WaybillHub():
return $default(_that.id,_that.name,_that.city,_that.address,_that.hours,_that.isSample);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String city,  String address,  String hours,  bool isSample)?  $default,) {final _that = this;
switch (_that) {
case _WaybillHub() when $default != null:
return $default(_that.id,_that.name,_that.city,_that.address,_that.hours,_that.isSample);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaybillHub implements WaybillHub {
  const _WaybillHub({required this.id, required this.name, required this.city, this.address = '', this.hours = '', this.isSample = true});
  factory _WaybillHub.fromJson(Map<String, dynamic> json) => _$WaybillHubFromJson(json);

@override final  String id;
@override final  String name;
@override final  String city;
@override@JsonKey() final  String address;
@override@JsonKey() final  String hours;
@override@JsonKey() final  bool isSample;

/// Create a copy of WaybillHub
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaybillHubCopyWith<_WaybillHub> get copyWith => __$WaybillHubCopyWithImpl<_WaybillHub>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaybillHubToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaybillHub&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.address, address) || other.address == address)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.isSample, isSample) || other.isSample == isSample));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,city,address,hours,isSample);
}

@override
String toString() {
    return 'WaybillHub(id: $id, name: $name, city: $city, address: $address, hours: $hours, isSample: $isSample)';
}


}

/// @nodoc
abstract mixin class _$WaybillHubCopyWith<$Res> implements $WaybillHubCopyWith<$Res> {
  factory _$WaybillHubCopyWith(_WaybillHub value, $Res Function(_WaybillHub) _then) = __$WaybillHubCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String city, String address, String hours, bool isSample
});




}
/// @nodoc
class __$WaybillHubCopyWithImpl<$Res>
    implements _$WaybillHubCopyWith<$Res> {
  __$WaybillHubCopyWithImpl(this._self, this._then);

  final _WaybillHub _self;
  final $Res Function(_WaybillHub) _then;

/// Create a copy of WaybillHub
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? city = null,Object? address = null,Object? hours = null,Object? isSample = null,}) {
  return _then(_WaybillHub(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as String,isSample: null == isSample ? _self.isSample : isSample // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$WaybillOrigin {

 String get id; String get name; bool get homePickup; List<WaybillHub> get dropoffHubs;
/// Create a copy of WaybillOrigin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaybillOriginCopyWith<WaybillOrigin> get copyWith => _$WaybillOriginCopyWithImpl<WaybillOrigin>(this as WaybillOrigin, _$identity);

  /// Serializes this WaybillOrigin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WaybillOrigin;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaybillOrigin&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.homePickup, _this.homePickup) || other.homePickup == _this.homePickup)&&const DeepCollectionEquality().equals(other.dropoffHubs, _this.dropoffHubs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WaybillOrigin;
  return Object.hash(runtimeType,_this.id,_this.name,_this.homePickup,const DeepCollectionEquality().hash(_this.dropoffHubs));
}

@override
String toString() {
  final _this = this as WaybillOrigin;
  return 'WaybillOrigin(id: ${_this.id}, name: ${_this.name}, homePickup: ${_this.homePickup}, dropoffHubs: ${_this.dropoffHubs})';
}


}

/// @nodoc
abstract mixin class $WaybillOriginCopyWith<$Res>  {
  factory $WaybillOriginCopyWith(WaybillOrigin value, $Res Function(WaybillOrigin) _then) = _$WaybillOriginCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool homePickup, List<WaybillHub> dropoffHubs
});




}
/// @nodoc
class _$WaybillOriginCopyWithImpl<$Res>
    implements $WaybillOriginCopyWith<$Res> {
  _$WaybillOriginCopyWithImpl(this._self, this._then);

  final WaybillOrigin _self;
  final $Res Function(WaybillOrigin) _then;

/// Create a copy of WaybillOrigin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? homePickup = null,Object? dropoffHubs = null,}) {
  return _then(WaybillOrigin(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,homePickup: null == homePickup ? _self.homePickup : homePickup // ignore: cast_nullable_to_non_nullable
as bool,dropoffHubs: null == dropoffHubs ? _self.dropoffHubs : dropoffHubs // ignore: cast_nullable_to_non_nullable
as List<WaybillHub>,
  ));
}

}


/// Adds pattern-matching-related methods to [WaybillOrigin].
extension WaybillOriginPatterns on WaybillOrigin {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaybillOrigin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaybillOrigin() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaybillOrigin value)  $default,){
final _that = this;
switch (_that) {
case _WaybillOrigin():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaybillOrigin value)?  $default,){
final _that = this;
switch (_that) {
case _WaybillOrigin() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  bool homePickup,  List<WaybillHub> dropoffHubs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaybillOrigin() when $default != null:
return $default(_that.id,_that.name,_that.homePickup,_that.dropoffHubs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  bool homePickup,  List<WaybillHub> dropoffHubs)  $default,) {final _that = this;
switch (_that) {
case _WaybillOrigin():
return $default(_that.id,_that.name,_that.homePickup,_that.dropoffHubs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  bool homePickup,  List<WaybillHub> dropoffHubs)?  $default,) {final _that = this;
switch (_that) {
case _WaybillOrigin() when $default != null:
return $default(_that.id,_that.name,_that.homePickup,_that.dropoffHubs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaybillOrigin implements WaybillOrigin {
  const _WaybillOrigin({required this.id, required this.name, this.homePickup = false,  List<WaybillHub> dropoffHubs = const <WaybillHub>[]}): _dropoffHubs = dropoffHubs;
  factory _WaybillOrigin.fromJson(Map<String, dynamic> json) => _$WaybillOriginFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  bool homePickup;
 final  List<WaybillHub> _dropoffHubs;
@override@JsonKey() List<WaybillHub> get dropoffHubs {
  if (_dropoffHubs is EqualUnmodifiableListView) return _dropoffHubs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dropoffHubs);
}


/// Create a copy of WaybillOrigin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaybillOriginCopyWith<_WaybillOrigin> get copyWith => __$WaybillOriginCopyWithImpl<_WaybillOrigin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaybillOriginToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaybillOrigin&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.homePickup, homePickup) || other.homePickup == homePickup)&&const DeepCollectionEquality().equals(other.dropoffHubs, _dropoffHubs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,homePickup,const DeepCollectionEquality().hash(_dropoffHubs));
}

@override
String toString() {
    return 'WaybillOrigin(id: $id, name: $name, homePickup: $homePickup, dropoffHubs: $dropoffHubs)';
}


}

/// @nodoc
abstract mixin class _$WaybillOriginCopyWith<$Res> implements $WaybillOriginCopyWith<$Res> {
  factory _$WaybillOriginCopyWith(_WaybillOrigin value, $Res Function(_WaybillOrigin) _then) = __$WaybillOriginCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool homePickup, List<WaybillHub> dropoffHubs
});




}
/// @nodoc
class __$WaybillOriginCopyWithImpl<$Res>
    implements _$WaybillOriginCopyWith<$Res> {
  __$WaybillOriginCopyWithImpl(this._self, this._then);

  final _WaybillOrigin _self;
  final $Res Function(_WaybillOrigin) _then;

/// Create a copy of WaybillOrigin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? homePickup = null,Object? dropoffHubs = null,}) {
  return _then(_WaybillOrigin(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,homePickup: null == homePickup ? _self.homePickup : homePickup // ignore: cast_nullable_to_non_nullable
as bool,dropoffHubs: null == dropoffHubs ? _self._dropoffHubs : dropoffHubs // ignore: cast_nullable_to_non_nullable
as List<WaybillHub>,
  ));
}


}


/// @nodoc
mixin _$WaybillDestination {

 String get city; String get name; bool get doorDelivery; List<int> get transitDays; int get fromKobo; String get carrier; List<WaybillHub> get collectionHubs;
/// Create a copy of WaybillDestination
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaybillDestinationCopyWith<WaybillDestination> get copyWith => _$WaybillDestinationCopyWithImpl<WaybillDestination>(this as WaybillDestination, _$identity);

  /// Serializes this WaybillDestination to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WaybillDestination;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaybillDestination&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.doorDelivery, _this.doorDelivery) || other.doorDelivery == _this.doorDelivery)&&const DeepCollectionEquality().equals(other.transitDays, _this.transitDays)&&(identical(other.fromKobo, _this.fromKobo) || other.fromKobo == _this.fromKobo)&&(identical(other.carrier, _this.carrier) || other.carrier == _this.carrier)&&const DeepCollectionEquality().equals(other.collectionHubs, _this.collectionHubs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WaybillDestination;
  return Object.hash(runtimeType,_this.city,_this.name,_this.doorDelivery,const DeepCollectionEquality().hash(_this.transitDays),_this.fromKobo,_this.carrier,const DeepCollectionEquality().hash(_this.collectionHubs));
}

@override
String toString() {
  final _this = this as WaybillDestination;
  return 'WaybillDestination(city: ${_this.city}, name: ${_this.name}, doorDelivery: ${_this.doorDelivery}, transitDays: ${_this.transitDays}, fromKobo: ${_this.fromKobo}, carrier: ${_this.carrier}, collectionHubs: ${_this.collectionHubs})';
}


}

/// @nodoc
abstract mixin class $WaybillDestinationCopyWith<$Res>  {
  factory $WaybillDestinationCopyWith(WaybillDestination value, $Res Function(WaybillDestination) _then) = _$WaybillDestinationCopyWithImpl;
@useResult
$Res call({
 String city, String name, bool doorDelivery, List<int> transitDays, int fromKobo, String carrier, List<WaybillHub> collectionHubs
});




}
/// @nodoc
class _$WaybillDestinationCopyWithImpl<$Res>
    implements $WaybillDestinationCopyWith<$Res> {
  _$WaybillDestinationCopyWithImpl(this._self, this._then);

  final WaybillDestination _self;
  final $Res Function(WaybillDestination) _then;

/// Create a copy of WaybillDestination
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? city = null,Object? name = null,Object? doorDelivery = null,Object? transitDays = null,Object? fromKobo = null,Object? carrier = null,Object? collectionHubs = null,}) {
  return _then(WaybillDestination(
city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,doorDelivery: null == doorDelivery ? _self.doorDelivery : doorDelivery // ignore: cast_nullable_to_non_nullable
as bool,transitDays: null == transitDays ? _self.transitDays : transitDays // ignore: cast_nullable_to_non_nullable
as List<int>,fromKobo: null == fromKobo ? _self.fromKobo : fromKobo // ignore: cast_nullable_to_non_nullable
as int,carrier: null == carrier ? _self.carrier : carrier // ignore: cast_nullable_to_non_nullable
as String,collectionHubs: null == collectionHubs ? _self.collectionHubs : collectionHubs // ignore: cast_nullable_to_non_nullable
as List<WaybillHub>,
  ));
}

}


/// Adds pattern-matching-related methods to [WaybillDestination].
extension WaybillDestinationPatterns on WaybillDestination {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaybillDestination value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaybillDestination() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaybillDestination value)  $default,){
final _that = this;
switch (_that) {
case _WaybillDestination():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaybillDestination value)?  $default,){
final _that = this;
switch (_that) {
case _WaybillDestination() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String city,  String name,  bool doorDelivery,  List<int> transitDays,  int fromKobo,  String carrier,  List<WaybillHub> collectionHubs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaybillDestination() when $default != null:
return $default(_that.city,_that.name,_that.doorDelivery,_that.transitDays,_that.fromKobo,_that.carrier,_that.collectionHubs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String city,  String name,  bool doorDelivery,  List<int> transitDays,  int fromKobo,  String carrier,  List<WaybillHub> collectionHubs)  $default,) {final _that = this;
switch (_that) {
case _WaybillDestination():
return $default(_that.city,_that.name,_that.doorDelivery,_that.transitDays,_that.fromKobo,_that.carrier,_that.collectionHubs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String city,  String name,  bool doorDelivery,  List<int> transitDays,  int fromKobo,  String carrier,  List<WaybillHub> collectionHubs)?  $default,) {final _that = this;
switch (_that) {
case _WaybillDestination() when $default != null:
return $default(_that.city,_that.name,_that.doorDelivery,_that.transitDays,_that.fromKobo,_that.carrier,_that.collectionHubs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaybillDestination implements WaybillDestination {
  const _WaybillDestination({required this.city, required this.name, this.doorDelivery = false,  List<int> transitDays = const <int>[1, 2], this.fromKobo = 0, this.carrier = '',  List<WaybillHub> collectionHubs = const <WaybillHub>[]}): _transitDays = transitDays,_collectionHubs = collectionHubs;
  factory _WaybillDestination.fromJson(Map<String, dynamic> json) => _$WaybillDestinationFromJson(json);

@override final  String city;
@override final  String name;
@override@JsonKey() final  bool doorDelivery;
 final  List<int> _transitDays;
@override@JsonKey() List<int> get transitDays {
  if (_transitDays is EqualUnmodifiableListView) return _transitDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transitDays);
}

@override@JsonKey() final  int fromKobo;
@override@JsonKey() final  String carrier;
 final  List<WaybillHub> _collectionHubs;
@override@JsonKey() List<WaybillHub> get collectionHubs {
  if (_collectionHubs is EqualUnmodifiableListView) return _collectionHubs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_collectionHubs);
}


/// Create a copy of WaybillDestination
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaybillDestinationCopyWith<_WaybillDestination> get copyWith => __$WaybillDestinationCopyWithImpl<_WaybillDestination>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaybillDestinationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaybillDestination&&(identical(other.city, city) || other.city == city)&&(identical(other.name, name) || other.name == name)&&(identical(other.doorDelivery, doorDelivery) || other.doorDelivery == doorDelivery)&&const DeepCollectionEquality().equals(other.transitDays, _transitDays)&&(identical(other.fromKobo, fromKobo) || other.fromKobo == fromKobo)&&(identical(other.carrier, carrier) || other.carrier == carrier)&&const DeepCollectionEquality().equals(other.collectionHubs, _collectionHubs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,city,name,doorDelivery,const DeepCollectionEquality().hash(_transitDays),fromKobo,carrier,const DeepCollectionEquality().hash(_collectionHubs));
}

@override
String toString() {
    return 'WaybillDestination(city: $city, name: $name, doorDelivery: $doorDelivery, transitDays: $transitDays, fromKobo: $fromKobo, carrier: $carrier, collectionHubs: $collectionHubs)';
}


}

/// @nodoc
abstract mixin class _$WaybillDestinationCopyWith<$Res> implements $WaybillDestinationCopyWith<$Res> {
  factory _$WaybillDestinationCopyWith(_WaybillDestination value, $Res Function(_WaybillDestination) _then) = __$WaybillDestinationCopyWithImpl;
@override @useResult
$Res call({
 String city, String name, bool doorDelivery, List<int> transitDays, int fromKobo, String carrier, List<WaybillHub> collectionHubs
});




}
/// @nodoc
class __$WaybillDestinationCopyWithImpl<$Res>
    implements _$WaybillDestinationCopyWith<$Res> {
  __$WaybillDestinationCopyWithImpl(this._self, this._then);

  final _WaybillDestination _self;
  final $Res Function(_WaybillDestination) _then;

/// Create a copy of WaybillDestination
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? city = null,Object? name = null,Object? doorDelivery = null,Object? transitDays = null,Object? fromKobo = null,Object? carrier = null,Object? collectionHubs = null,}) {
  return _then(_WaybillDestination(
city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,doorDelivery: null == doorDelivery ? _self.doorDelivery : doorDelivery // ignore: cast_nullable_to_non_nullable
as bool,transitDays: null == transitDays ? _self._transitDays : transitDays // ignore: cast_nullable_to_non_nullable
as List<int>,fromKobo: null == fromKobo ? _self.fromKobo : fromKobo // ignore: cast_nullable_to_non_nullable
as int,carrier: null == carrier ? _self.carrier : carrier // ignore: cast_nullable_to_non_nullable
as String,collectionHubs: null == collectionHubs ? _self._collectionHubs : collectionHubs // ignore: cast_nullable_to_non_nullable
as List<WaybillHub>,
  ));
}


}


/// @nodoc
mixin _$WaybillDestinations {

 List<WaybillHub> get dropoffHubs; List<WaybillDestination> get destinations;
/// Create a copy of WaybillDestinations
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaybillDestinationsCopyWith<WaybillDestinations> get copyWith => _$WaybillDestinationsCopyWithImpl<WaybillDestinations>(this as WaybillDestinations, _$identity);

  /// Serializes this WaybillDestinations to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WaybillDestinations;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaybillDestinations&&const DeepCollectionEquality().equals(other.dropoffHubs, _this.dropoffHubs)&&const DeepCollectionEquality().equals(other.destinations, _this.destinations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WaybillDestinations;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.dropoffHubs),const DeepCollectionEquality().hash(_this.destinations));
}

@override
String toString() {
  final _this = this as WaybillDestinations;
  return 'WaybillDestinations(dropoffHubs: ${_this.dropoffHubs}, destinations: ${_this.destinations})';
}


}

/// @nodoc
abstract mixin class $WaybillDestinationsCopyWith<$Res>  {
  factory $WaybillDestinationsCopyWith(WaybillDestinations value, $Res Function(WaybillDestinations) _then) = _$WaybillDestinationsCopyWithImpl;
@useResult
$Res call({
 List<WaybillHub> dropoffHubs, List<WaybillDestination> destinations
});




}
/// @nodoc
class _$WaybillDestinationsCopyWithImpl<$Res>
    implements $WaybillDestinationsCopyWith<$Res> {
  _$WaybillDestinationsCopyWithImpl(this._self, this._then);

  final WaybillDestinations _self;
  final $Res Function(WaybillDestinations) _then;

/// Create a copy of WaybillDestinations
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dropoffHubs = null,Object? destinations = null,}) {
  return _then(WaybillDestinations(
dropoffHubs: null == dropoffHubs ? _self.dropoffHubs : dropoffHubs // ignore: cast_nullable_to_non_nullable
as List<WaybillHub>,destinations: null == destinations ? _self.destinations : destinations // ignore: cast_nullable_to_non_nullable
as List<WaybillDestination>,
  ));
}

}


/// Adds pattern-matching-related methods to [WaybillDestinations].
extension WaybillDestinationsPatterns on WaybillDestinations {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaybillDestinations value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaybillDestinations() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaybillDestinations value)  $default,){
final _that = this;
switch (_that) {
case _WaybillDestinations():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaybillDestinations value)?  $default,){
final _that = this;
switch (_that) {
case _WaybillDestinations() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<WaybillHub> dropoffHubs,  List<WaybillDestination> destinations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaybillDestinations() when $default != null:
return $default(_that.dropoffHubs,_that.destinations);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<WaybillHub> dropoffHubs,  List<WaybillDestination> destinations)  $default,) {final _that = this;
switch (_that) {
case _WaybillDestinations():
return $default(_that.dropoffHubs,_that.destinations);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<WaybillHub> dropoffHubs,  List<WaybillDestination> destinations)?  $default,) {final _that = this;
switch (_that) {
case _WaybillDestinations() when $default != null:
return $default(_that.dropoffHubs,_that.destinations);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaybillDestinations implements WaybillDestinations {
  const _WaybillDestinations({ List<WaybillHub> dropoffHubs = const <WaybillHub>[],  List<WaybillDestination> destinations = const <WaybillDestination>[]}): _dropoffHubs = dropoffHubs,_destinations = destinations;
  factory _WaybillDestinations.fromJson(Map<String, dynamic> json) => _$WaybillDestinationsFromJson(json);

 final  List<WaybillHub> _dropoffHubs;
@override@JsonKey() List<WaybillHub> get dropoffHubs {
  if (_dropoffHubs is EqualUnmodifiableListView) return _dropoffHubs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dropoffHubs);
}

 final  List<WaybillDestination> _destinations;
@override@JsonKey() List<WaybillDestination> get destinations {
  if (_destinations is EqualUnmodifiableListView) return _destinations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_destinations);
}


/// Create a copy of WaybillDestinations
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaybillDestinationsCopyWith<_WaybillDestinations> get copyWith => __$WaybillDestinationsCopyWithImpl<_WaybillDestinations>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaybillDestinationsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaybillDestinations&&const DeepCollectionEquality().equals(other.dropoffHubs, _dropoffHubs)&&const DeepCollectionEquality().equals(other.destinations, _destinations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_dropoffHubs),const DeepCollectionEquality().hash(_destinations));
}

@override
String toString() {
    return 'WaybillDestinations(dropoffHubs: $dropoffHubs, destinations: $destinations)';
}


}

/// @nodoc
abstract mixin class _$WaybillDestinationsCopyWith<$Res> implements $WaybillDestinationsCopyWith<$Res> {
  factory _$WaybillDestinationsCopyWith(_WaybillDestinations value, $Res Function(_WaybillDestinations) _then) = __$WaybillDestinationsCopyWithImpl;
@override @useResult
$Res call({
 List<WaybillHub> dropoffHubs, List<WaybillDestination> destinations
});




}
/// @nodoc
class __$WaybillDestinationsCopyWithImpl<$Res>
    implements _$WaybillDestinationsCopyWith<$Res> {
  __$WaybillDestinationsCopyWithImpl(this._self, this._then);

  final _WaybillDestinations _self;
  final $Res Function(_WaybillDestinations) _then;

/// Create a copy of WaybillDestinations
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dropoffHubs = null,Object? destinations = null,}) {
  return _then(_WaybillDestinations(
dropoffHubs: null == dropoffHubs ? _self._dropoffHubs : dropoffHubs // ignore: cast_nullable_to_non_nullable
as List<WaybillHub>,destinations: null == destinations ? _self._destinations : destinations // ignore: cast_nullable_to_non_nullable
as List<WaybillDestination>,
  ));
}


}


/// @nodoc
mixin _$WaybillScan {

 String get stage; String get label; DateTime get at; String? get place;
/// Create a copy of WaybillScan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaybillScanCopyWith<WaybillScan> get copyWith => _$WaybillScanCopyWithImpl<WaybillScan>(this as WaybillScan, _$identity);

  /// Serializes this WaybillScan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WaybillScan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaybillScan&&(identical(other.stage, _this.stage) || other.stage == _this.stage)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.place, _this.place) || other.place == _this.place));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WaybillScan;
  return Object.hash(runtimeType,_this.stage,_this.label,_this.at,_this.place);
}

@override
String toString() {
  final _this = this as WaybillScan;
  return 'WaybillScan(stage: ${_this.stage}, label: ${_this.label}, at: ${_this.at}, place: ${_this.place})';
}


}

/// @nodoc
abstract mixin class $WaybillScanCopyWith<$Res>  {
  factory $WaybillScanCopyWith(WaybillScan value, $Res Function(WaybillScan) _then) = _$WaybillScanCopyWithImpl;
@useResult
$Res call({
 String stage, String label, DateTime at, String? place
});




}
/// @nodoc
class _$WaybillScanCopyWithImpl<$Res>
    implements $WaybillScanCopyWith<$Res> {
  _$WaybillScanCopyWithImpl(this._self, this._then);

  final WaybillScan _self;
  final $Res Function(WaybillScan) _then;

/// Create a copy of WaybillScan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stage = null,Object? label = null,Object? at = null,Object? place = freezed,}) {
  return _then(WaybillScan(
stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,place: freezed == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WaybillScan].
extension WaybillScanPatterns on WaybillScan {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaybillScan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaybillScan() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaybillScan value)  $default,){
final _that = this;
switch (_that) {
case _WaybillScan():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaybillScan value)?  $default,){
final _that = this;
switch (_that) {
case _WaybillScan() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String stage,  String label,  DateTime at,  String? place)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaybillScan() when $default != null:
return $default(_that.stage,_that.label,_that.at,_that.place);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String stage,  String label,  DateTime at,  String? place)  $default,) {final _that = this;
switch (_that) {
case _WaybillScan():
return $default(_that.stage,_that.label,_that.at,_that.place);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String stage,  String label,  DateTime at,  String? place)?  $default,) {final _that = this;
switch (_that) {
case _WaybillScan() when $default != null:
return $default(_that.stage,_that.label,_that.at,_that.place);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaybillScan implements WaybillScan {
  const _WaybillScan({required this.stage, required this.label, required this.at, this.place});
  factory _WaybillScan.fromJson(Map<String, dynamic> json) => _$WaybillScanFromJson(json);

@override final  String stage;
@override final  String label;
@override final  DateTime at;
@override final  String? place;

/// Create a copy of WaybillScan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaybillScanCopyWith<_WaybillScan> get copyWith => __$WaybillScanCopyWithImpl<_WaybillScan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaybillScanToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaybillScan&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.label, label) || other.label == label)&&(identical(other.at, at) || other.at == at)&&(identical(other.place, place) || other.place == place));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,stage,label,at,place);
}

@override
String toString() {
    return 'WaybillScan(stage: $stage, label: $label, at: $at, place: $place)';
}


}

/// @nodoc
abstract mixin class _$WaybillScanCopyWith<$Res> implements $WaybillScanCopyWith<$Res> {
  factory _$WaybillScanCopyWith(_WaybillScan value, $Res Function(_WaybillScan) _then) = __$WaybillScanCopyWithImpl;
@override @useResult
$Res call({
 String stage, String label, DateTime at, String? place
});




}
/// @nodoc
class __$WaybillScanCopyWithImpl<$Res>
    implements _$WaybillScanCopyWith<$Res> {
  __$WaybillScanCopyWithImpl(this._self, this._then);

  final _WaybillScan _self;
  final $Res Function(_WaybillScan) _then;

/// Create a copy of WaybillScan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stage = null,Object? label = null,Object? at = null,Object? place = freezed,}) {
  return _then(_WaybillScan(
stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,place: freezed == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$WaybillTracking {

 String get trackingCode; String get origin; String get destination; String get label; int get step; List<String> get steps; String get etaText; String get lastMile; List<WaybillScan> get milestones; bool get delivered;
/// Create a copy of WaybillTracking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaybillTrackingCopyWith<WaybillTracking> get copyWith => _$WaybillTrackingCopyWithImpl<WaybillTracking>(this as WaybillTracking, _$identity);

  /// Serializes this WaybillTracking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WaybillTracking;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaybillTracking&&(identical(other.trackingCode, _this.trackingCode) || other.trackingCode == _this.trackingCode)&&(identical(other.origin, _this.origin) || other.origin == _this.origin)&&(identical(other.destination, _this.destination) || other.destination == _this.destination)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.step, _this.step) || other.step == _this.step)&&const DeepCollectionEquality().equals(other.steps, _this.steps)&&(identical(other.etaText, _this.etaText) || other.etaText == _this.etaText)&&(identical(other.lastMile, _this.lastMile) || other.lastMile == _this.lastMile)&&const DeepCollectionEquality().equals(other.milestones, _this.milestones)&&(identical(other.delivered, _this.delivered) || other.delivered == _this.delivered));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WaybillTracking;
  return Object.hash(runtimeType,_this.trackingCode,_this.origin,_this.destination,_this.label,_this.step,const DeepCollectionEquality().hash(_this.steps),_this.etaText,_this.lastMile,const DeepCollectionEquality().hash(_this.milestones),_this.delivered);
}

@override
String toString() {
  final _this = this as WaybillTracking;
  return 'WaybillTracking(trackingCode: ${_this.trackingCode}, origin: ${_this.origin}, destination: ${_this.destination}, label: ${_this.label}, step: ${_this.step}, steps: ${_this.steps}, etaText: ${_this.etaText}, lastMile: ${_this.lastMile}, milestones: ${_this.milestones}, delivered: ${_this.delivered})';
}


}

/// @nodoc
abstract mixin class $WaybillTrackingCopyWith<$Res>  {
  factory $WaybillTrackingCopyWith(WaybillTracking value, $Res Function(WaybillTracking) _then) = _$WaybillTrackingCopyWithImpl;
@useResult
$Res call({
 String trackingCode, String origin, String destination, String label, int step, List<String> steps, String etaText, String lastMile, List<WaybillScan> milestones, bool delivered
});




}
/// @nodoc
class _$WaybillTrackingCopyWithImpl<$Res>
    implements $WaybillTrackingCopyWith<$Res> {
  _$WaybillTrackingCopyWithImpl(this._self, this._then);

  final WaybillTracking _self;
  final $Res Function(WaybillTracking) _then;

/// Create a copy of WaybillTracking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trackingCode = null,Object? origin = null,Object? destination = null,Object? label = null,Object? step = null,Object? steps = null,Object? etaText = null,Object? lastMile = null,Object? milestones = null,Object? delivered = null,}) {
  return _then(WaybillTracking(
trackingCode: null == trackingCode ? _self.trackingCode : trackingCode // ignore: cast_nullable_to_non_nullable
as String,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<String>,etaText: null == etaText ? _self.etaText : etaText // ignore: cast_nullable_to_non_nullable
as String,lastMile: null == lastMile ? _self.lastMile : lastMile // ignore: cast_nullable_to_non_nullable
as String,milestones: null == milestones ? _self.milestones : milestones // ignore: cast_nullable_to_non_nullable
as List<WaybillScan>,delivered: null == delivered ? _self.delivered : delivered // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WaybillTracking].
extension WaybillTrackingPatterns on WaybillTracking {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaybillTracking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaybillTracking() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaybillTracking value)  $default,){
final _that = this;
switch (_that) {
case _WaybillTracking():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaybillTracking value)?  $default,){
final _that = this;
switch (_that) {
case _WaybillTracking() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String trackingCode,  String origin,  String destination,  String label,  int step,  List<String> steps,  String etaText,  String lastMile,  List<WaybillScan> milestones,  bool delivered)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaybillTracking() when $default != null:
return $default(_that.trackingCode,_that.origin,_that.destination,_that.label,_that.step,_that.steps,_that.etaText,_that.lastMile,_that.milestones,_that.delivered);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String trackingCode,  String origin,  String destination,  String label,  int step,  List<String> steps,  String etaText,  String lastMile,  List<WaybillScan> milestones,  bool delivered)  $default,) {final _that = this;
switch (_that) {
case _WaybillTracking():
return $default(_that.trackingCode,_that.origin,_that.destination,_that.label,_that.step,_that.steps,_that.etaText,_that.lastMile,_that.milestones,_that.delivered);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String trackingCode,  String origin,  String destination,  String label,  int step,  List<String> steps,  String etaText,  String lastMile,  List<WaybillScan> milestones,  bool delivered)?  $default,) {final _that = this;
switch (_that) {
case _WaybillTracking() when $default != null:
return $default(_that.trackingCode,_that.origin,_that.destination,_that.label,_that.step,_that.steps,_that.etaText,_that.lastMile,_that.milestones,_that.delivered);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaybillTracking implements WaybillTracking {
  const _WaybillTracking({required this.trackingCode, this.origin = '', this.destination = '', this.label = '', this.step = 0,  List<String> steps = const <String>[], this.etaText = '', this.lastMile = 'door',  List<WaybillScan> milestones = const <WaybillScan>[], this.delivered = false}): _steps = steps,_milestones = milestones;
  factory _WaybillTracking.fromJson(Map<String, dynamic> json) => _$WaybillTrackingFromJson(json);

@override final  String trackingCode;
@override@JsonKey() final  String origin;
@override@JsonKey() final  String destination;
@override@JsonKey() final  String label;
@override@JsonKey() final  int step;
 final  List<String> _steps;
@override@JsonKey() List<String> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

@override@JsonKey() final  String etaText;
@override@JsonKey() final  String lastMile;
 final  List<WaybillScan> _milestones;
@override@JsonKey() List<WaybillScan> get milestones {
  if (_milestones is EqualUnmodifiableListView) return _milestones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_milestones);
}

@override@JsonKey() final  bool delivered;

/// Create a copy of WaybillTracking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaybillTrackingCopyWith<_WaybillTracking> get copyWith => __$WaybillTrackingCopyWithImpl<_WaybillTracking>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaybillTrackingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaybillTracking&&(identical(other.trackingCode, trackingCode) || other.trackingCode == trackingCode)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.label, label) || other.label == label)&&(identical(other.step, step) || other.step == step)&&const DeepCollectionEquality().equals(other.steps, _steps)&&(identical(other.etaText, etaText) || other.etaText == etaText)&&(identical(other.lastMile, lastMile) || other.lastMile == lastMile)&&const DeepCollectionEquality().equals(other.milestones, _milestones)&&(identical(other.delivered, delivered) || other.delivered == delivered));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,trackingCode,origin,destination,label,step,const DeepCollectionEquality().hash(_steps),etaText,lastMile,const DeepCollectionEquality().hash(_milestones),delivered);
}

@override
String toString() {
    return 'WaybillTracking(trackingCode: $trackingCode, origin: $origin, destination: $destination, label: $label, step: $step, steps: $steps, etaText: $etaText, lastMile: $lastMile, milestones: $milestones, delivered: $delivered)';
}


}

/// @nodoc
abstract mixin class _$WaybillTrackingCopyWith<$Res> implements $WaybillTrackingCopyWith<$Res> {
  factory _$WaybillTrackingCopyWith(_WaybillTracking value, $Res Function(_WaybillTracking) _then) = __$WaybillTrackingCopyWithImpl;
@override @useResult
$Res call({
 String trackingCode, String origin, String destination, String label, int step, List<String> steps, String etaText, String lastMile, List<WaybillScan> milestones, bool delivered
});




}
/// @nodoc
class __$WaybillTrackingCopyWithImpl<$Res>
    implements _$WaybillTrackingCopyWith<$Res> {
  __$WaybillTrackingCopyWithImpl(this._self, this._then);

  final _WaybillTracking _self;
  final $Res Function(_WaybillTracking) _then;

/// Create a copy of WaybillTracking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trackingCode = null,Object? origin = null,Object? destination = null,Object? label = null,Object? step = null,Object? steps = null,Object? etaText = null,Object? lastMile = null,Object? milestones = null,Object? delivered = null,}) {
  return _then(_WaybillTracking(
trackingCode: null == trackingCode ? _self.trackingCode : trackingCode // ignore: cast_nullable_to_non_nullable
as String,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as String,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<String>,etaText: null == etaText ? _self.etaText : etaText // ignore: cast_nullable_to_non_nullable
as String,lastMile: null == lastMile ? _self.lastMile : lastMile // ignore: cast_nullable_to_non_nullable
as String,milestones: null == milestones ? _self._milestones : milestones // ignore: cast_nullable_to_non_nullable
as List<WaybillScan>,delivered: null == delivered ? _self.delivered : delivered // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$PlusPlan {

 bool get enabled; int get priceKobo; int get vatKobo; int get periodDays; int get freeDeliveryMinSubtotalKobo; int get serviceFeeDiscountBps; int get pointsMultiplier; List<String> get benefits;
/// Create a copy of PlusPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlusPlanCopyWith<PlusPlan> get copyWith => _$PlusPlanCopyWithImpl<PlusPlan>(this as PlusPlan, _$identity);

  /// Serializes this PlusPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlusPlan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlusPlan&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.priceKobo, _this.priceKobo) || other.priceKobo == _this.priceKobo)&&(identical(other.vatKobo, _this.vatKobo) || other.vatKobo == _this.vatKobo)&&(identical(other.periodDays, _this.periodDays) || other.periodDays == _this.periodDays)&&(identical(other.freeDeliveryMinSubtotalKobo, _this.freeDeliveryMinSubtotalKobo) || other.freeDeliveryMinSubtotalKobo == _this.freeDeliveryMinSubtotalKobo)&&(identical(other.serviceFeeDiscountBps, _this.serviceFeeDiscountBps) || other.serviceFeeDiscountBps == _this.serviceFeeDiscountBps)&&(identical(other.pointsMultiplier, _this.pointsMultiplier) || other.pointsMultiplier == _this.pointsMultiplier)&&const DeepCollectionEquality().equals(other.benefits, _this.benefits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlusPlan;
  return Object.hash(runtimeType,_this.enabled,_this.priceKobo,_this.vatKobo,_this.periodDays,_this.freeDeliveryMinSubtotalKobo,_this.serviceFeeDiscountBps,_this.pointsMultiplier,const DeepCollectionEquality().hash(_this.benefits));
}

@override
String toString() {
  final _this = this as PlusPlan;
  return 'PlusPlan(enabled: ${_this.enabled}, priceKobo: ${_this.priceKobo}, vatKobo: ${_this.vatKobo}, periodDays: ${_this.periodDays}, freeDeliveryMinSubtotalKobo: ${_this.freeDeliveryMinSubtotalKobo}, serviceFeeDiscountBps: ${_this.serviceFeeDiscountBps}, pointsMultiplier: ${_this.pointsMultiplier}, benefits: ${_this.benefits})';
}


}

/// @nodoc
abstract mixin class $PlusPlanCopyWith<$Res>  {
  factory $PlusPlanCopyWith(PlusPlan value, $Res Function(PlusPlan) _then) = _$PlusPlanCopyWithImpl;
@useResult
$Res call({
 bool enabled, int priceKobo, int vatKobo, int periodDays, int freeDeliveryMinSubtotalKobo, int serviceFeeDiscountBps, int pointsMultiplier, List<String> benefits
});




}
/// @nodoc
class _$PlusPlanCopyWithImpl<$Res>
    implements $PlusPlanCopyWith<$Res> {
  _$PlusPlanCopyWithImpl(this._self, this._then);

  final PlusPlan _self;
  final $Res Function(PlusPlan) _then;

/// Create a copy of PlusPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? priceKobo = null,Object? vatKobo = null,Object? periodDays = null,Object? freeDeliveryMinSubtotalKobo = null,Object? serviceFeeDiscountBps = null,Object? pointsMultiplier = null,Object? benefits = null,}) {
  return _then(PlusPlan(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,priceKobo: null == priceKobo ? _self.priceKobo : priceKobo // ignore: cast_nullable_to_non_nullable
as int,vatKobo: null == vatKobo ? _self.vatKobo : vatKobo // ignore: cast_nullable_to_non_nullable
as int,periodDays: null == periodDays ? _self.periodDays : periodDays // ignore: cast_nullable_to_non_nullable
as int,freeDeliveryMinSubtotalKobo: null == freeDeliveryMinSubtotalKobo ? _self.freeDeliveryMinSubtotalKobo : freeDeliveryMinSubtotalKobo // ignore: cast_nullable_to_non_nullable
as int,serviceFeeDiscountBps: null == serviceFeeDiscountBps ? _self.serviceFeeDiscountBps : serviceFeeDiscountBps // ignore: cast_nullable_to_non_nullable
as int,pointsMultiplier: null == pointsMultiplier ? _self.pointsMultiplier : pointsMultiplier // ignore: cast_nullable_to_non_nullable
as int,benefits: null == benefits ? _self.benefits : benefits // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlusPlan].
extension PlusPlanPatterns on PlusPlan {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlusPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlusPlan() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlusPlan value)  $default,){
final _that = this;
switch (_that) {
case _PlusPlan():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlusPlan value)?  $default,){
final _that = this;
switch (_that) {
case _PlusPlan() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  int priceKobo,  int vatKobo,  int periodDays,  int freeDeliveryMinSubtotalKobo,  int serviceFeeDiscountBps,  int pointsMultiplier,  List<String> benefits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlusPlan() when $default != null:
return $default(_that.enabled,_that.priceKobo,_that.vatKobo,_that.periodDays,_that.freeDeliveryMinSubtotalKobo,_that.serviceFeeDiscountBps,_that.pointsMultiplier,_that.benefits);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  int priceKobo,  int vatKobo,  int periodDays,  int freeDeliveryMinSubtotalKobo,  int serviceFeeDiscountBps,  int pointsMultiplier,  List<String> benefits)  $default,) {final _that = this;
switch (_that) {
case _PlusPlan():
return $default(_that.enabled,_that.priceKobo,_that.vatKobo,_that.periodDays,_that.freeDeliveryMinSubtotalKobo,_that.serviceFeeDiscountBps,_that.pointsMultiplier,_that.benefits);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  int priceKobo,  int vatKobo,  int periodDays,  int freeDeliveryMinSubtotalKobo,  int serviceFeeDiscountBps,  int pointsMultiplier,  List<String> benefits)?  $default,) {final _that = this;
switch (_that) {
case _PlusPlan() when $default != null:
return $default(_that.enabled,_that.priceKobo,_that.vatKobo,_that.periodDays,_that.freeDeliveryMinSubtotalKobo,_that.serviceFeeDiscountBps,_that.pointsMultiplier,_that.benefits);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlusPlan implements PlusPlan {
  const _PlusPlan({this.enabled = true, required this.priceKobo, this.vatKobo = 0, this.periodDays = 30, this.freeDeliveryMinSubtotalKobo = 0, this.serviceFeeDiscountBps = 0, this.pointsMultiplier = 1,  List<String> benefits = const <String>[]}): _benefits = benefits;
  factory _PlusPlan.fromJson(Map<String, dynamic> json) => _$PlusPlanFromJson(json);

@override@JsonKey() final  bool enabled;
@override final  int priceKobo;
@override@JsonKey() final  int vatKobo;
@override@JsonKey() final  int periodDays;
@override@JsonKey() final  int freeDeliveryMinSubtotalKobo;
@override@JsonKey() final  int serviceFeeDiscountBps;
@override@JsonKey() final  int pointsMultiplier;
 final  List<String> _benefits;
@override@JsonKey() List<String> get benefits {
  if (_benefits is EqualUnmodifiableListView) return _benefits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_benefits);
}


/// Create a copy of PlusPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlusPlanCopyWith<_PlusPlan> get copyWith => __$PlusPlanCopyWithImpl<_PlusPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlusPlanToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlusPlan&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.priceKobo, priceKobo) || other.priceKobo == priceKobo)&&(identical(other.vatKobo, vatKobo) || other.vatKobo == vatKobo)&&(identical(other.periodDays, periodDays) || other.periodDays == periodDays)&&(identical(other.freeDeliveryMinSubtotalKobo, freeDeliveryMinSubtotalKobo) || other.freeDeliveryMinSubtotalKobo == freeDeliveryMinSubtotalKobo)&&(identical(other.serviceFeeDiscountBps, serviceFeeDiscountBps) || other.serviceFeeDiscountBps == serviceFeeDiscountBps)&&(identical(other.pointsMultiplier, pointsMultiplier) || other.pointsMultiplier == pointsMultiplier)&&const DeepCollectionEquality().equals(other.benefits, _benefits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,enabled,priceKobo,vatKobo,periodDays,freeDeliveryMinSubtotalKobo,serviceFeeDiscountBps,pointsMultiplier,const DeepCollectionEquality().hash(_benefits));
}

@override
String toString() {
    return 'PlusPlan(enabled: $enabled, priceKobo: $priceKobo, vatKobo: $vatKobo, periodDays: $periodDays, freeDeliveryMinSubtotalKobo: $freeDeliveryMinSubtotalKobo, serviceFeeDiscountBps: $serviceFeeDiscountBps, pointsMultiplier: $pointsMultiplier, benefits: $benefits)';
}


}

/// @nodoc
abstract mixin class _$PlusPlanCopyWith<$Res> implements $PlusPlanCopyWith<$Res> {
  factory _$PlusPlanCopyWith(_PlusPlan value, $Res Function(_PlusPlan) _then) = __$PlusPlanCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, int priceKobo, int vatKobo, int periodDays, int freeDeliveryMinSubtotalKobo, int serviceFeeDiscountBps, int pointsMultiplier, List<String> benefits
});




}
/// @nodoc
class __$PlusPlanCopyWithImpl<$Res>
    implements _$PlusPlanCopyWith<$Res> {
  __$PlusPlanCopyWithImpl(this._self, this._then);

  final _PlusPlan _self;
  final $Res Function(_PlusPlan) _then;

/// Create a copy of PlusPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? priceKobo = null,Object? vatKobo = null,Object? periodDays = null,Object? freeDeliveryMinSubtotalKobo = null,Object? serviceFeeDiscountBps = null,Object? pointsMultiplier = null,Object? benefits = null,}) {
  return _then(_PlusPlan(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,priceKobo: null == priceKobo ? _self.priceKobo : priceKobo // ignore: cast_nullable_to_non_nullable
as int,vatKobo: null == vatKobo ? _self.vatKobo : vatKobo // ignore: cast_nullable_to_non_nullable
as int,periodDays: null == periodDays ? _self.periodDays : periodDays // ignore: cast_nullable_to_non_nullable
as int,freeDeliveryMinSubtotalKobo: null == freeDeliveryMinSubtotalKobo ? _self.freeDeliveryMinSubtotalKobo : freeDeliveryMinSubtotalKobo // ignore: cast_nullable_to_non_nullable
as int,serviceFeeDiscountBps: null == serviceFeeDiscountBps ? _self.serviceFeeDiscountBps : serviceFeeDiscountBps // ignore: cast_nullable_to_non_nullable
as int,pointsMultiplier: null == pointsMultiplier ? _self.pointsMultiplier : pointsMultiplier // ignore: cast_nullable_to_non_nullable
as int,benefits: null == benefits ? _self._benefits : benefits // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$PlusMembership {

 String get status; DateTime get paidThrough; String get paidThroughText; int get daysLeft; bool get autoRenew; bool get canRenew; int get periods; int get savingsKobo;
/// Create a copy of PlusMembership
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlusMembershipCopyWith<PlusMembership> get copyWith => _$PlusMembershipCopyWithImpl<PlusMembership>(this as PlusMembership, _$identity);

  /// Serializes this PlusMembership to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlusMembership;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlusMembership&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.paidThrough, _this.paidThrough) || other.paidThrough == _this.paidThrough)&&(identical(other.paidThroughText, _this.paidThroughText) || other.paidThroughText == _this.paidThroughText)&&(identical(other.daysLeft, _this.daysLeft) || other.daysLeft == _this.daysLeft)&&(identical(other.autoRenew, _this.autoRenew) || other.autoRenew == _this.autoRenew)&&(identical(other.canRenew, _this.canRenew) || other.canRenew == _this.canRenew)&&(identical(other.periods, _this.periods) || other.periods == _this.periods)&&(identical(other.savingsKobo, _this.savingsKobo) || other.savingsKobo == _this.savingsKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlusMembership;
  return Object.hash(runtimeType,_this.status,_this.paidThrough,_this.paidThroughText,_this.daysLeft,_this.autoRenew,_this.canRenew,_this.periods,_this.savingsKobo);
}

@override
String toString() {
  final _this = this as PlusMembership;
  return 'PlusMembership(status: ${_this.status}, paidThrough: ${_this.paidThrough}, paidThroughText: ${_this.paidThroughText}, daysLeft: ${_this.daysLeft}, autoRenew: ${_this.autoRenew}, canRenew: ${_this.canRenew}, periods: ${_this.periods}, savingsKobo: ${_this.savingsKobo})';
}


}

/// @nodoc
abstract mixin class $PlusMembershipCopyWith<$Res>  {
  factory $PlusMembershipCopyWith(PlusMembership value, $Res Function(PlusMembership) _then) = _$PlusMembershipCopyWithImpl;
@useResult
$Res call({
 String status, DateTime paidThrough, String paidThroughText, int daysLeft, bool autoRenew, bool canRenew, int periods, int savingsKobo
});




}
/// @nodoc
class _$PlusMembershipCopyWithImpl<$Res>
    implements $PlusMembershipCopyWith<$Res> {
  _$PlusMembershipCopyWithImpl(this._self, this._then);

  final PlusMembership _self;
  final $Res Function(PlusMembership) _then;

/// Create a copy of PlusMembership
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? paidThrough = null,Object? paidThroughText = null,Object? daysLeft = null,Object? autoRenew = null,Object? canRenew = null,Object? periods = null,Object? savingsKobo = null,}) {
  return _then(PlusMembership(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paidThrough: null == paidThrough ? _self.paidThrough : paidThrough // ignore: cast_nullable_to_non_nullable
as DateTime,paidThroughText: null == paidThroughText ? _self.paidThroughText : paidThroughText // ignore: cast_nullable_to_non_nullable
as String,daysLeft: null == daysLeft ? _self.daysLeft : daysLeft // ignore: cast_nullable_to_non_nullable
as int,autoRenew: null == autoRenew ? _self.autoRenew : autoRenew // ignore: cast_nullable_to_non_nullable
as bool,canRenew: null == canRenew ? _self.canRenew : canRenew // ignore: cast_nullable_to_non_nullable
as bool,periods: null == periods ? _self.periods : periods // ignore: cast_nullable_to_non_nullable
as int,savingsKobo: null == savingsKobo ? _self.savingsKobo : savingsKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlusMembership].
extension PlusMembershipPatterns on PlusMembership {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlusMembership value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlusMembership() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlusMembership value)  $default,){
final _that = this;
switch (_that) {
case _PlusMembership():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlusMembership value)?  $default,){
final _that = this;
switch (_that) {
case _PlusMembership() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  DateTime paidThrough,  String paidThroughText,  int daysLeft,  bool autoRenew,  bool canRenew,  int periods,  int savingsKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlusMembership() when $default != null:
return $default(_that.status,_that.paidThrough,_that.paidThroughText,_that.daysLeft,_that.autoRenew,_that.canRenew,_that.periods,_that.savingsKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  DateTime paidThrough,  String paidThroughText,  int daysLeft,  bool autoRenew,  bool canRenew,  int periods,  int savingsKobo)  $default,) {final _that = this;
switch (_that) {
case _PlusMembership():
return $default(_that.status,_that.paidThrough,_that.paidThroughText,_that.daysLeft,_that.autoRenew,_that.canRenew,_that.periods,_that.savingsKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  DateTime paidThrough,  String paidThroughText,  int daysLeft,  bool autoRenew,  bool canRenew,  int periods,  int savingsKobo)?  $default,) {final _that = this;
switch (_that) {
case _PlusMembership() when $default != null:
return $default(_that.status,_that.paidThrough,_that.paidThroughText,_that.daysLeft,_that.autoRenew,_that.canRenew,_that.periods,_that.savingsKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlusMembership implements PlusMembership {
  const _PlusMembership({this.status = 'active', required this.paidThrough, this.paidThroughText = '', this.daysLeft = 0, this.autoRenew = true, this.canRenew = false, this.periods = 0, this.savingsKobo = 0});
  factory _PlusMembership.fromJson(Map<String, dynamic> json) => _$PlusMembershipFromJson(json);

@override@JsonKey() final  String status;
@override final  DateTime paidThrough;
@override@JsonKey() final  String paidThroughText;
@override@JsonKey() final  int daysLeft;
@override@JsonKey() final  bool autoRenew;
@override@JsonKey() final  bool canRenew;
@override@JsonKey() final  int periods;
@override@JsonKey() final  int savingsKobo;

/// Create a copy of PlusMembership
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlusMembershipCopyWith<_PlusMembership> get copyWith => __$PlusMembershipCopyWithImpl<_PlusMembership>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlusMembershipToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlusMembership&&(identical(other.status, status) || other.status == status)&&(identical(other.paidThrough, paidThrough) || other.paidThrough == paidThrough)&&(identical(other.paidThroughText, paidThroughText) || other.paidThroughText == paidThroughText)&&(identical(other.daysLeft, daysLeft) || other.daysLeft == daysLeft)&&(identical(other.autoRenew, autoRenew) || other.autoRenew == autoRenew)&&(identical(other.canRenew, canRenew) || other.canRenew == canRenew)&&(identical(other.periods, periods) || other.periods == periods)&&(identical(other.savingsKobo, savingsKobo) || other.savingsKobo == savingsKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,status,paidThrough,paidThroughText,daysLeft,autoRenew,canRenew,periods,savingsKobo);
}

@override
String toString() {
    return 'PlusMembership(status: $status, paidThrough: $paidThrough, paidThroughText: $paidThroughText, daysLeft: $daysLeft, autoRenew: $autoRenew, canRenew: $canRenew, periods: $periods, savingsKobo: $savingsKobo)';
}


}

/// @nodoc
abstract mixin class _$PlusMembershipCopyWith<$Res> implements $PlusMembershipCopyWith<$Res> {
  factory _$PlusMembershipCopyWith(_PlusMembership value, $Res Function(_PlusMembership) _then) = __$PlusMembershipCopyWithImpl;
@override @useResult
$Res call({
 String status, DateTime paidThrough, String paidThroughText, int daysLeft, bool autoRenew, bool canRenew, int periods, int savingsKobo
});




}
/// @nodoc
class __$PlusMembershipCopyWithImpl<$Res>
    implements _$PlusMembershipCopyWith<$Res> {
  __$PlusMembershipCopyWithImpl(this._self, this._then);

  final _PlusMembership _self;
  final $Res Function(_PlusMembership) _then;

/// Create a copy of PlusMembership
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? paidThrough = null,Object? paidThroughText = null,Object? daysLeft = null,Object? autoRenew = null,Object? canRenew = null,Object? periods = null,Object? savingsKobo = null,}) {
  return _then(_PlusMembership(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paidThrough: null == paidThrough ? _self.paidThrough : paidThrough // ignore: cast_nullable_to_non_nullable
as DateTime,paidThroughText: null == paidThroughText ? _self.paidThroughText : paidThroughText // ignore: cast_nullable_to_non_nullable
as String,daysLeft: null == daysLeft ? _self.daysLeft : daysLeft // ignore: cast_nullable_to_non_nullable
as int,autoRenew: null == autoRenew ? _self.autoRenew : autoRenew // ignore: cast_nullable_to_non_nullable
as bool,canRenew: null == canRenew ? _self.canRenew : canRenew // ignore: cast_nullable_to_non_nullable
as bool,periods: null == periods ? _self.periods : periods // ignore: cast_nullable_to_non_nullable
as int,savingsKobo: null == savingsKobo ? _self.savingsKobo : savingsKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PlusOverview {

 PlusPlan get plan; bool get member; PlusMembership? get membership;
/// Create a copy of PlusOverview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlusOverviewCopyWith<PlusOverview> get copyWith => _$PlusOverviewCopyWithImpl<PlusOverview>(this as PlusOverview, _$identity);

  /// Serializes this PlusOverview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlusOverview;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlusOverview&&(identical(other.plan, _this.plan) || other.plan == _this.plan)&&(identical(other.member, _this.member) || other.member == _this.member)&&(identical(other.membership, _this.membership) || other.membership == _this.membership));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlusOverview;
  return Object.hash(runtimeType,_this.plan,_this.member,_this.membership);
}

@override
String toString() {
  final _this = this as PlusOverview;
  return 'PlusOverview(plan: ${_this.plan}, member: ${_this.member}, membership: ${_this.membership})';
}


}

/// @nodoc
abstract mixin class $PlusOverviewCopyWith<$Res>  {
  factory $PlusOverviewCopyWith(PlusOverview value, $Res Function(PlusOverview) _then) = _$PlusOverviewCopyWithImpl;
@useResult
$Res call({
 PlusPlan plan, bool member, PlusMembership? membership
});


$PlusPlanCopyWith<$Res> get plan;$PlusMembershipCopyWith<$Res>? get membership;

}
/// @nodoc
class _$PlusOverviewCopyWithImpl<$Res>
    implements $PlusOverviewCopyWith<$Res> {
  _$PlusOverviewCopyWithImpl(this._self, this._then);

  final PlusOverview _self;
  final $Res Function(PlusOverview) _then;

/// Create a copy of PlusOverview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plan = null,Object? member = null,Object? membership = freezed,}) {
  return _then(PlusOverview(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PlusPlan,member: null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as bool,membership: freezed == membership ? _self.membership : membership // ignore: cast_nullable_to_non_nullable
as PlusMembership?,
  ));
}
/// Create a copy of PlusOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlusPlanCopyWith<$Res> get plan {
  
  return $PlusPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}/// Create a copy of PlusOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlusMembershipCopyWith<$Res>? get membership {
    if (_self.membership == null) {
    return null;
  }

  return $PlusMembershipCopyWith<$Res>(_self.membership!, (value) {
    return _then(_self.copyWith(membership: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlusOverview].
extension PlusOverviewPatterns on PlusOverview {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlusOverview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlusOverview() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlusOverview value)  $default,){
final _that = this;
switch (_that) {
case _PlusOverview():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlusOverview value)?  $default,){
final _that = this;
switch (_that) {
case _PlusOverview() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlusPlan plan,  bool member,  PlusMembership? membership)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlusOverview() when $default != null:
return $default(_that.plan,_that.member,_that.membership);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlusPlan plan,  bool member,  PlusMembership? membership)  $default,) {final _that = this;
switch (_that) {
case _PlusOverview():
return $default(_that.plan,_that.member,_that.membership);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlusPlan plan,  bool member,  PlusMembership? membership)?  $default,) {final _that = this;
switch (_that) {
case _PlusOverview() when $default != null:
return $default(_that.plan,_that.member,_that.membership);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlusOverview implements PlusOverview {
  const _PlusOverview({required this.plan, this.member = false, this.membership});
  factory _PlusOverview.fromJson(Map<String, dynamic> json) => _$PlusOverviewFromJson(json);

@override final  PlusPlan plan;
@override@JsonKey() final  bool member;
@override final  PlusMembership? membership;

/// Create a copy of PlusOverview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlusOverviewCopyWith<_PlusOverview> get copyWith => __$PlusOverviewCopyWithImpl<_PlusOverview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlusOverviewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlusOverview&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.member, member) || other.member == member)&&(identical(other.membership, membership) || other.membership == membership));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,plan,member,membership);
}

@override
String toString() {
    return 'PlusOverview(plan: $plan, member: $member, membership: $membership)';
}


}

/// @nodoc
abstract mixin class _$PlusOverviewCopyWith<$Res> implements $PlusOverviewCopyWith<$Res> {
  factory _$PlusOverviewCopyWith(_PlusOverview value, $Res Function(_PlusOverview) _then) = __$PlusOverviewCopyWithImpl;
@override @useResult
$Res call({
 PlusPlan plan, bool member, PlusMembership? membership
});


@override $PlusPlanCopyWith<$Res> get plan;@override $PlusMembershipCopyWith<$Res>? get membership;

}
/// @nodoc
class __$PlusOverviewCopyWithImpl<$Res>
    implements _$PlusOverviewCopyWith<$Res> {
  __$PlusOverviewCopyWithImpl(this._self, this._then);

  final _PlusOverview _self;
  final $Res Function(_PlusOverview) _then;

/// Create a copy of PlusOverview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plan = null,Object? member = null,Object? membership = freezed,}) {
  return _then(_PlusOverview(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PlusPlan,member: null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as bool,membership: freezed == membership ? _self.membership : membership // ignore: cast_nullable_to_non_nullable
as PlusMembership?,
  ));
}

/// Create a copy of PlusOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlusPlanCopyWith<$Res> get plan {
  
  return $PlusPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}/// Create a copy of PlusOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlusMembershipCopyWith<$Res>? get membership {
    if (_self.membership == null) {
    return null;
  }

  return $PlusMembershipCopyWith<$Res>(_self.membership!, (value) {
    return _then(_self.copyWith(membership: value));
  });
}
}


/// @nodoc
mixin _$RewardVoucher {

 String get code; String get description; int get valueKobo; int get minSubtotalKobo; DateTime? get endsAt; String get source;
/// Create a copy of RewardVoucher
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardVoucherCopyWith<RewardVoucher> get copyWith => _$RewardVoucherCopyWithImpl<RewardVoucher>(this as RewardVoucher, _$identity);

  /// Serializes this RewardVoucher to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RewardVoucher;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardVoucher&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.valueKobo, _this.valueKobo) || other.valueKobo == _this.valueKobo)&&(identical(other.minSubtotalKobo, _this.minSubtotalKobo) || other.minSubtotalKobo == _this.minSubtotalKobo)&&(identical(other.endsAt, _this.endsAt) || other.endsAt == _this.endsAt)&&(identical(other.source, _this.source) || other.source == _this.source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RewardVoucher;
  return Object.hash(runtimeType,_this.code,_this.description,_this.valueKobo,_this.minSubtotalKobo,_this.endsAt,_this.source);
}

@override
String toString() {
  final _this = this as RewardVoucher;
  return 'RewardVoucher(code: ${_this.code}, description: ${_this.description}, valueKobo: ${_this.valueKobo}, minSubtotalKobo: ${_this.minSubtotalKobo}, endsAt: ${_this.endsAt}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $RewardVoucherCopyWith<$Res>  {
  factory $RewardVoucherCopyWith(RewardVoucher value, $Res Function(RewardVoucher) _then) = _$RewardVoucherCopyWithImpl;
@useResult
$Res call({
 String code, String description, int valueKobo, int minSubtotalKobo, DateTime? endsAt, String source
});




}
/// @nodoc
class _$RewardVoucherCopyWithImpl<$Res>
    implements $RewardVoucherCopyWith<$Res> {
  _$RewardVoucherCopyWithImpl(this._self, this._then);

  final RewardVoucher _self;
  final $Res Function(RewardVoucher) _then;

/// Create a copy of RewardVoucher
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? description = null,Object? valueKobo = null,Object? minSubtotalKobo = null,Object? endsAt = freezed,Object? source = null,}) {
  return _then(RewardVoucher(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,valueKobo: null == valueKobo ? _self.valueKobo : valueKobo // ignore: cast_nullable_to_non_nullable
as int,minSubtotalKobo: null == minSubtotalKobo ? _self.minSubtotalKobo : minSubtotalKobo // ignore: cast_nullable_to_non_nullable
as int,endsAt: freezed == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RewardVoucher].
extension RewardVoucherPatterns on RewardVoucher {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RewardVoucher value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RewardVoucher() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RewardVoucher value)  $default,){
final _that = this;
switch (_that) {
case _RewardVoucher():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RewardVoucher value)?  $default,){
final _that = this;
switch (_that) {
case _RewardVoucher() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String description,  int valueKobo,  int minSubtotalKobo,  DateTime? endsAt,  String source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RewardVoucher() when $default != null:
return $default(_that.code,_that.description,_that.valueKobo,_that.minSubtotalKobo,_that.endsAt,_that.source);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String description,  int valueKobo,  int minSubtotalKobo,  DateTime? endsAt,  String source)  $default,) {final _that = this;
switch (_that) {
case _RewardVoucher():
return $default(_that.code,_that.description,_that.valueKobo,_that.minSubtotalKobo,_that.endsAt,_that.source);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String description,  int valueKobo,  int minSubtotalKobo,  DateTime? endsAt,  String source)?  $default,) {final _that = this;
switch (_that) {
case _RewardVoucher() when $default != null:
return $default(_that.code,_that.description,_that.valueKobo,_that.minSubtotalKobo,_that.endsAt,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RewardVoucher implements RewardVoucher {
  const _RewardVoucher({required this.code, this.description = '', required this.valueKobo, this.minSubtotalKobo = 0, this.endsAt, this.source = 'points'});
  factory _RewardVoucher.fromJson(Map<String, dynamic> json) => _$RewardVoucherFromJson(json);

@override final  String code;
@override@JsonKey() final  String description;
@override final  int valueKobo;
@override@JsonKey() final  int minSubtotalKobo;
@override final  DateTime? endsAt;
@override@JsonKey() final  String source;

/// Create a copy of RewardVoucher
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RewardVoucherCopyWith<_RewardVoucher> get copyWith => __$RewardVoucherCopyWithImpl<_RewardVoucher>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RewardVoucherToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RewardVoucher&&(identical(other.code, code) || other.code == code)&&(identical(other.description, description) || other.description == description)&&(identical(other.valueKobo, valueKobo) || other.valueKobo == valueKobo)&&(identical(other.minSubtotalKobo, minSubtotalKobo) || other.minSubtotalKobo == minSubtotalKobo)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,code,description,valueKobo,minSubtotalKobo,endsAt,source);
}

@override
String toString() {
    return 'RewardVoucher(code: $code, description: $description, valueKobo: $valueKobo, minSubtotalKobo: $minSubtotalKobo, endsAt: $endsAt, source: $source)';
}


}

/// @nodoc
abstract mixin class _$RewardVoucherCopyWith<$Res> implements $RewardVoucherCopyWith<$Res> {
  factory _$RewardVoucherCopyWith(_RewardVoucher value, $Res Function(_RewardVoucher) _then) = __$RewardVoucherCopyWithImpl;
@override @useResult
$Res call({
 String code, String description, int valueKobo, int minSubtotalKobo, DateTime? endsAt, String source
});




}
/// @nodoc
class __$RewardVoucherCopyWithImpl<$Res>
    implements _$RewardVoucherCopyWith<$Res> {
  __$RewardVoucherCopyWithImpl(this._self, this._then);

  final _RewardVoucher _self;
  final $Res Function(_RewardVoucher) _then;

/// Create a copy of RewardVoucher
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? description = null,Object? valueKobo = null,Object? minSubtotalKobo = null,Object? endsAt = freezed,Object? source = null,}) {
  return _then(_RewardVoucher(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,valueKobo: null == valueKobo ? _self.valueKobo : valueKobo // ignore: cast_nullable_to_non_nullable
as int,minSubtotalKobo: null == minSubtotalKobo ? _self.minSubtotalKobo : minSubtotalKobo // ignore: cast_nullable_to_non_nullable
as int,endsAt: freezed == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PointsEntry {

 String get id; String get kind; int get points; String? get orderId; String? get voucherCode; String get note; DateTime get at;
/// Create a copy of PointsEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PointsEntryCopyWith<PointsEntry> get copyWith => _$PointsEntryCopyWithImpl<PointsEntry>(this as PointsEntry, _$identity);

  /// Serializes this PointsEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PointsEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PointsEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.points, _this.points) || other.points == _this.points)&&(identical(other.orderId, _this.orderId) || other.orderId == _this.orderId)&&(identical(other.voucherCode, _this.voucherCode) || other.voucherCode == _this.voucherCode)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.at, _this.at) || other.at == _this.at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PointsEntry;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.points,_this.orderId,_this.voucherCode,_this.note,_this.at);
}

@override
String toString() {
  final _this = this as PointsEntry;
  return 'PointsEntry(id: ${_this.id}, kind: ${_this.kind}, points: ${_this.points}, orderId: ${_this.orderId}, voucherCode: ${_this.voucherCode}, note: ${_this.note}, at: ${_this.at})';
}


}

/// @nodoc
abstract mixin class $PointsEntryCopyWith<$Res>  {
  factory $PointsEntryCopyWith(PointsEntry value, $Res Function(PointsEntry) _then) = _$PointsEntryCopyWithImpl;
@useResult
$Res call({
 String id, String kind, int points, String? orderId, String? voucherCode, String note, DateTime at
});




}
/// @nodoc
class _$PointsEntryCopyWithImpl<$Res>
    implements $PointsEntryCopyWith<$Res> {
  _$PointsEntryCopyWithImpl(this._self, this._then);

  final PointsEntry _self;
  final $Res Function(PointsEntry) _then;

/// Create a copy of PointsEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? points = null,Object? orderId = freezed,Object? voucherCode = freezed,Object? note = null,Object? at = null,}) {
  return _then(PointsEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,voucherCode: freezed == voucherCode ? _self.voucherCode : voucherCode // ignore: cast_nullable_to_non_nullable
as String?,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PointsEntry].
extension PointsEntryPatterns on PointsEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PointsEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PointsEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PointsEntry value)  $default,){
final _that = this;
switch (_that) {
case _PointsEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PointsEntry value)?  $default,){
final _that = this;
switch (_that) {
case _PointsEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  int points,  String? orderId,  String? voucherCode,  String note,  DateTime at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PointsEntry() when $default != null:
return $default(_that.id,_that.kind,_that.points,_that.orderId,_that.voucherCode,_that.note,_that.at);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  int points,  String? orderId,  String? voucherCode,  String note,  DateTime at)  $default,) {final _that = this;
switch (_that) {
case _PointsEntry():
return $default(_that.id,_that.kind,_that.points,_that.orderId,_that.voucherCode,_that.note,_that.at);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  int points,  String? orderId,  String? voucherCode,  String note,  DateTime at)?  $default,) {final _that = this;
switch (_that) {
case _PointsEntry() when $default != null:
return $default(_that.id,_that.kind,_that.points,_that.orderId,_that.voucherCode,_that.note,_that.at);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PointsEntry implements PointsEntry {
  const _PointsEntry({required this.id, required this.kind, required this.points, this.orderId, this.voucherCode, this.note = '', required this.at});
  factory _PointsEntry.fromJson(Map<String, dynamic> json) => _$PointsEntryFromJson(json);

@override final  String id;
@override final  String kind;
@override final  int points;
@override final  String? orderId;
@override final  String? voucherCode;
@override@JsonKey() final  String note;
@override final  DateTime at;

/// Create a copy of PointsEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PointsEntryCopyWith<_PointsEntry> get copyWith => __$PointsEntryCopyWithImpl<_PointsEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PointsEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PointsEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.points, points) || other.points == points)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.voucherCode, voucherCode) || other.voucherCode == voucherCode)&&(identical(other.note, note) || other.note == note)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,points,orderId,voucherCode,note,at);
}

@override
String toString() {
    return 'PointsEntry(id: $id, kind: $kind, points: $points, orderId: $orderId, voucherCode: $voucherCode, note: $note, at: $at)';
}


}

/// @nodoc
abstract mixin class _$PointsEntryCopyWith<$Res> implements $PointsEntryCopyWith<$Res> {
  factory _$PointsEntryCopyWith(_PointsEntry value, $Res Function(_PointsEntry) _then) = __$PointsEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, int points, String? orderId, String? voucherCode, String note, DateTime at
});




}
/// @nodoc
class __$PointsEntryCopyWithImpl<$Res>
    implements _$PointsEntryCopyWith<$Res> {
  __$PointsEntryCopyWithImpl(this._self, this._then);

  final _PointsEntry _self;
  final $Res Function(_PointsEntry) _then;

/// Create a copy of PointsEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? points = null,Object? orderId = freezed,Object? voucherCode = freezed,Object? note = null,Object? at = null,}) {
  return _then(_PointsEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,voucherCode: freezed == voucherCode ? _self.voucherCode : voucherCode // ignore: cast_nullable_to_non_nullable
as String?,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$RewardsRedeem {

 bool get enabled; int get stepPoints; int get stepValueKobo; int get redeemablePoints; int get pointsToNext; int get minSubtotalKobo; int get validDays;
/// Create a copy of RewardsRedeem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardsRedeemCopyWith<RewardsRedeem> get copyWith => _$RewardsRedeemCopyWithImpl<RewardsRedeem>(this as RewardsRedeem, _$identity);

  /// Serializes this RewardsRedeem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RewardsRedeem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardsRedeem&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.stepPoints, _this.stepPoints) || other.stepPoints == _this.stepPoints)&&(identical(other.stepValueKobo, _this.stepValueKobo) || other.stepValueKobo == _this.stepValueKobo)&&(identical(other.redeemablePoints, _this.redeemablePoints) || other.redeemablePoints == _this.redeemablePoints)&&(identical(other.pointsToNext, _this.pointsToNext) || other.pointsToNext == _this.pointsToNext)&&(identical(other.minSubtotalKobo, _this.minSubtotalKobo) || other.minSubtotalKobo == _this.minSubtotalKobo)&&(identical(other.validDays, _this.validDays) || other.validDays == _this.validDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RewardsRedeem;
  return Object.hash(runtimeType,_this.enabled,_this.stepPoints,_this.stepValueKobo,_this.redeemablePoints,_this.pointsToNext,_this.minSubtotalKobo,_this.validDays);
}

@override
String toString() {
  final _this = this as RewardsRedeem;
  return 'RewardsRedeem(enabled: ${_this.enabled}, stepPoints: ${_this.stepPoints}, stepValueKobo: ${_this.stepValueKobo}, redeemablePoints: ${_this.redeemablePoints}, pointsToNext: ${_this.pointsToNext}, minSubtotalKobo: ${_this.minSubtotalKobo}, validDays: ${_this.validDays})';
}


}

/// @nodoc
abstract mixin class $RewardsRedeemCopyWith<$Res>  {
  factory $RewardsRedeemCopyWith(RewardsRedeem value, $Res Function(RewardsRedeem) _then) = _$RewardsRedeemCopyWithImpl;
@useResult
$Res call({
 bool enabled, int stepPoints, int stepValueKobo, int redeemablePoints, int pointsToNext, int minSubtotalKobo, int validDays
});




}
/// @nodoc
class _$RewardsRedeemCopyWithImpl<$Res>
    implements $RewardsRedeemCopyWith<$Res> {
  _$RewardsRedeemCopyWithImpl(this._self, this._then);

  final RewardsRedeem _self;
  final $Res Function(RewardsRedeem) _then;

/// Create a copy of RewardsRedeem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? stepPoints = null,Object? stepValueKobo = null,Object? redeemablePoints = null,Object? pointsToNext = null,Object? minSubtotalKobo = null,Object? validDays = null,}) {
  return _then(RewardsRedeem(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,stepPoints: null == stepPoints ? _self.stepPoints : stepPoints // ignore: cast_nullable_to_non_nullable
as int,stepValueKobo: null == stepValueKobo ? _self.stepValueKobo : stepValueKobo // ignore: cast_nullable_to_non_nullable
as int,redeemablePoints: null == redeemablePoints ? _self.redeemablePoints : redeemablePoints // ignore: cast_nullable_to_non_nullable
as int,pointsToNext: null == pointsToNext ? _self.pointsToNext : pointsToNext // ignore: cast_nullable_to_non_nullable
as int,minSubtotalKobo: null == minSubtotalKobo ? _self.minSubtotalKobo : minSubtotalKobo // ignore: cast_nullable_to_non_nullable
as int,validDays: null == validDays ? _self.validDays : validDays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RewardsRedeem].
extension RewardsRedeemPatterns on RewardsRedeem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RewardsRedeem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RewardsRedeem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RewardsRedeem value)  $default,){
final _that = this;
switch (_that) {
case _RewardsRedeem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RewardsRedeem value)?  $default,){
final _that = this;
switch (_that) {
case _RewardsRedeem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  int stepPoints,  int stepValueKobo,  int redeemablePoints,  int pointsToNext,  int minSubtotalKobo,  int validDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RewardsRedeem() when $default != null:
return $default(_that.enabled,_that.stepPoints,_that.stepValueKobo,_that.redeemablePoints,_that.pointsToNext,_that.minSubtotalKobo,_that.validDays);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  int stepPoints,  int stepValueKobo,  int redeemablePoints,  int pointsToNext,  int minSubtotalKobo,  int validDays)  $default,) {final _that = this;
switch (_that) {
case _RewardsRedeem():
return $default(_that.enabled,_that.stepPoints,_that.stepValueKobo,_that.redeemablePoints,_that.pointsToNext,_that.minSubtotalKobo,_that.validDays);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  int stepPoints,  int stepValueKobo,  int redeemablePoints,  int pointsToNext,  int minSubtotalKobo,  int validDays)?  $default,) {final _that = this;
switch (_that) {
case _RewardsRedeem() when $default != null:
return $default(_that.enabled,_that.stepPoints,_that.stepValueKobo,_that.redeemablePoints,_that.pointsToNext,_that.minSubtotalKobo,_that.validDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RewardsRedeem implements RewardsRedeem {
  const _RewardsRedeem({this.enabled = true, this.stepPoints = 500, this.stepValueKobo = 50000, this.redeemablePoints = 0, this.pointsToNext = 0, this.minSubtotalKobo = 0, this.validDays = 90});
  factory _RewardsRedeem.fromJson(Map<String, dynamic> json) => _$RewardsRedeemFromJson(json);

@override@JsonKey() final  bool enabled;
@override@JsonKey() final  int stepPoints;
@override@JsonKey() final  int stepValueKobo;
@override@JsonKey() final  int redeemablePoints;
@override@JsonKey() final  int pointsToNext;
@override@JsonKey() final  int minSubtotalKobo;
@override@JsonKey() final  int validDays;

/// Create a copy of RewardsRedeem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RewardsRedeemCopyWith<_RewardsRedeem> get copyWith => __$RewardsRedeemCopyWithImpl<_RewardsRedeem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RewardsRedeemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RewardsRedeem&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.stepPoints, stepPoints) || other.stepPoints == stepPoints)&&(identical(other.stepValueKobo, stepValueKobo) || other.stepValueKobo == stepValueKobo)&&(identical(other.redeemablePoints, redeemablePoints) || other.redeemablePoints == redeemablePoints)&&(identical(other.pointsToNext, pointsToNext) || other.pointsToNext == pointsToNext)&&(identical(other.minSubtotalKobo, minSubtotalKobo) || other.minSubtotalKobo == minSubtotalKobo)&&(identical(other.validDays, validDays) || other.validDays == validDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,enabled,stepPoints,stepValueKobo,redeemablePoints,pointsToNext,minSubtotalKobo,validDays);
}

@override
String toString() {
    return 'RewardsRedeem(enabled: $enabled, stepPoints: $stepPoints, stepValueKobo: $stepValueKobo, redeemablePoints: $redeemablePoints, pointsToNext: $pointsToNext, minSubtotalKobo: $minSubtotalKobo, validDays: $validDays)';
}


}

/// @nodoc
abstract mixin class _$RewardsRedeemCopyWith<$Res> implements $RewardsRedeemCopyWith<$Res> {
  factory _$RewardsRedeemCopyWith(_RewardsRedeem value, $Res Function(_RewardsRedeem) _then) = __$RewardsRedeemCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, int stepPoints, int stepValueKobo, int redeemablePoints, int pointsToNext, int minSubtotalKobo, int validDays
});




}
/// @nodoc
class __$RewardsRedeemCopyWithImpl<$Res>
    implements _$RewardsRedeemCopyWith<$Res> {
  __$RewardsRedeemCopyWithImpl(this._self, this._then);

  final _RewardsRedeem _self;
  final $Res Function(_RewardsRedeem) _then;

/// Create a copy of RewardsRedeem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? stepPoints = null,Object? stepValueKobo = null,Object? redeemablePoints = null,Object? pointsToNext = null,Object? minSubtotalKobo = null,Object? validDays = null,}) {
  return _then(_RewardsRedeem(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,stepPoints: null == stepPoints ? _self.stepPoints : stepPoints // ignore: cast_nullable_to_non_nullable
as int,stepValueKobo: null == stepValueKobo ? _self.stepValueKobo : stepValueKobo // ignore: cast_nullable_to_non_nullable
as int,redeemablePoints: null == redeemablePoints ? _self.redeemablePoints : redeemablePoints // ignore: cast_nullable_to_non_nullable
as int,pointsToNext: null == pointsToNext ? _self.pointsToNext : pointsToNext // ignore: cast_nullable_to_non_nullable
as int,minSubtotalKobo: null == minSubtotalKobo ? _self.minSubtotalKobo : minSubtotalKobo // ignore: cast_nullable_to_non_nullable
as int,validDays: null == validDays ? _self.validDays : validDays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$RewardsReferral {

 bool get enabled; String get code; int get friendGetsKobo; int get youGetKobo; int get minSubtotalKobo; int get friendsRewarded; bool get applied; bool get canApply; String get shareText;
/// Create a copy of RewardsReferral
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardsReferralCopyWith<RewardsReferral> get copyWith => _$RewardsReferralCopyWithImpl<RewardsReferral>(this as RewardsReferral, _$identity);

  /// Serializes this RewardsReferral to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RewardsReferral;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardsReferral&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.friendGetsKobo, _this.friendGetsKobo) || other.friendGetsKobo == _this.friendGetsKobo)&&(identical(other.youGetKobo, _this.youGetKobo) || other.youGetKobo == _this.youGetKobo)&&(identical(other.minSubtotalKobo, _this.minSubtotalKobo) || other.minSubtotalKobo == _this.minSubtotalKobo)&&(identical(other.friendsRewarded, _this.friendsRewarded) || other.friendsRewarded == _this.friendsRewarded)&&(identical(other.applied, _this.applied) || other.applied == _this.applied)&&(identical(other.canApply, _this.canApply) || other.canApply == _this.canApply)&&(identical(other.shareText, _this.shareText) || other.shareText == _this.shareText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RewardsReferral;
  return Object.hash(runtimeType,_this.enabled,_this.code,_this.friendGetsKobo,_this.youGetKobo,_this.minSubtotalKobo,_this.friendsRewarded,_this.applied,_this.canApply,_this.shareText);
}

@override
String toString() {
  final _this = this as RewardsReferral;
  return 'RewardsReferral(enabled: ${_this.enabled}, code: ${_this.code}, friendGetsKobo: ${_this.friendGetsKobo}, youGetKobo: ${_this.youGetKobo}, minSubtotalKobo: ${_this.minSubtotalKobo}, friendsRewarded: ${_this.friendsRewarded}, applied: ${_this.applied}, canApply: ${_this.canApply}, shareText: ${_this.shareText})';
}


}

/// @nodoc
abstract mixin class $RewardsReferralCopyWith<$Res>  {
  factory $RewardsReferralCopyWith(RewardsReferral value, $Res Function(RewardsReferral) _then) = _$RewardsReferralCopyWithImpl;
@useResult
$Res call({
 bool enabled, String code, int friendGetsKobo, int youGetKobo, int minSubtotalKobo, int friendsRewarded, bool applied, bool canApply, String shareText
});




}
/// @nodoc
class _$RewardsReferralCopyWithImpl<$Res>
    implements $RewardsReferralCopyWith<$Res> {
  _$RewardsReferralCopyWithImpl(this._self, this._then);

  final RewardsReferral _self;
  final $Res Function(RewardsReferral) _then;

/// Create a copy of RewardsReferral
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? code = null,Object? friendGetsKobo = null,Object? youGetKobo = null,Object? minSubtotalKobo = null,Object? friendsRewarded = null,Object? applied = null,Object? canApply = null,Object? shareText = null,}) {
  return _then(RewardsReferral(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,friendGetsKobo: null == friendGetsKobo ? _self.friendGetsKobo : friendGetsKobo // ignore: cast_nullable_to_non_nullable
as int,youGetKobo: null == youGetKobo ? _self.youGetKobo : youGetKobo // ignore: cast_nullable_to_non_nullable
as int,minSubtotalKobo: null == minSubtotalKobo ? _self.minSubtotalKobo : minSubtotalKobo // ignore: cast_nullable_to_non_nullable
as int,friendsRewarded: null == friendsRewarded ? _self.friendsRewarded : friendsRewarded // ignore: cast_nullable_to_non_nullable
as int,applied: null == applied ? _self.applied : applied // ignore: cast_nullable_to_non_nullable
as bool,canApply: null == canApply ? _self.canApply : canApply // ignore: cast_nullable_to_non_nullable
as bool,shareText: null == shareText ? _self.shareText : shareText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RewardsReferral].
extension RewardsReferralPatterns on RewardsReferral {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RewardsReferral value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RewardsReferral() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RewardsReferral value)  $default,){
final _that = this;
switch (_that) {
case _RewardsReferral():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RewardsReferral value)?  $default,){
final _that = this;
switch (_that) {
case _RewardsReferral() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  String code,  int friendGetsKobo,  int youGetKobo,  int minSubtotalKobo,  int friendsRewarded,  bool applied,  bool canApply,  String shareText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RewardsReferral() when $default != null:
return $default(_that.enabled,_that.code,_that.friendGetsKobo,_that.youGetKobo,_that.minSubtotalKobo,_that.friendsRewarded,_that.applied,_that.canApply,_that.shareText);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  String code,  int friendGetsKobo,  int youGetKobo,  int minSubtotalKobo,  int friendsRewarded,  bool applied,  bool canApply,  String shareText)  $default,) {final _that = this;
switch (_that) {
case _RewardsReferral():
return $default(_that.enabled,_that.code,_that.friendGetsKobo,_that.youGetKobo,_that.minSubtotalKobo,_that.friendsRewarded,_that.applied,_that.canApply,_that.shareText);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  String code,  int friendGetsKobo,  int youGetKobo,  int minSubtotalKobo,  int friendsRewarded,  bool applied,  bool canApply,  String shareText)?  $default,) {final _that = this;
switch (_that) {
case _RewardsReferral() when $default != null:
return $default(_that.enabled,_that.code,_that.friendGetsKobo,_that.youGetKobo,_that.minSubtotalKobo,_that.friendsRewarded,_that.applied,_that.canApply,_that.shareText);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RewardsReferral implements RewardsReferral {
  const _RewardsReferral({this.enabled = true, this.code = '', this.friendGetsKobo = 0, this.youGetKobo = 0, this.minSubtotalKobo = 0, this.friendsRewarded = 0, this.applied = false, this.canApply = false, this.shareText = ''});
  factory _RewardsReferral.fromJson(Map<String, dynamic> json) => _$RewardsReferralFromJson(json);

@override@JsonKey() final  bool enabled;
@override@JsonKey() final  String code;
@override@JsonKey() final  int friendGetsKobo;
@override@JsonKey() final  int youGetKobo;
@override@JsonKey() final  int minSubtotalKobo;
@override@JsonKey() final  int friendsRewarded;
@override@JsonKey() final  bool applied;
@override@JsonKey() final  bool canApply;
@override@JsonKey() final  String shareText;

/// Create a copy of RewardsReferral
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RewardsReferralCopyWith<_RewardsReferral> get copyWith => __$RewardsReferralCopyWithImpl<_RewardsReferral>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RewardsReferralToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RewardsReferral&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.code, code) || other.code == code)&&(identical(other.friendGetsKobo, friendGetsKobo) || other.friendGetsKobo == friendGetsKobo)&&(identical(other.youGetKobo, youGetKobo) || other.youGetKobo == youGetKobo)&&(identical(other.minSubtotalKobo, minSubtotalKobo) || other.minSubtotalKobo == minSubtotalKobo)&&(identical(other.friendsRewarded, friendsRewarded) || other.friendsRewarded == friendsRewarded)&&(identical(other.applied, applied) || other.applied == applied)&&(identical(other.canApply, canApply) || other.canApply == canApply)&&(identical(other.shareText, shareText) || other.shareText == shareText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,enabled,code,friendGetsKobo,youGetKobo,minSubtotalKobo,friendsRewarded,applied,canApply,shareText);
}

@override
String toString() {
    return 'RewardsReferral(enabled: $enabled, code: $code, friendGetsKobo: $friendGetsKobo, youGetKobo: $youGetKobo, minSubtotalKobo: $minSubtotalKobo, friendsRewarded: $friendsRewarded, applied: $applied, canApply: $canApply, shareText: $shareText)';
}


}

/// @nodoc
abstract mixin class _$RewardsReferralCopyWith<$Res> implements $RewardsReferralCopyWith<$Res> {
  factory _$RewardsReferralCopyWith(_RewardsReferral value, $Res Function(_RewardsReferral) _then) = __$RewardsReferralCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, String code, int friendGetsKobo, int youGetKobo, int minSubtotalKobo, int friendsRewarded, bool applied, bool canApply, String shareText
});




}
/// @nodoc
class __$RewardsReferralCopyWithImpl<$Res>
    implements _$RewardsReferralCopyWith<$Res> {
  __$RewardsReferralCopyWithImpl(this._self, this._then);

  final _RewardsReferral _self;
  final $Res Function(_RewardsReferral) _then;

/// Create a copy of RewardsReferral
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? code = null,Object? friendGetsKobo = null,Object? youGetKobo = null,Object? minSubtotalKobo = null,Object? friendsRewarded = null,Object? applied = null,Object? canApply = null,Object? shareText = null,}) {
  return _then(_RewardsReferral(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,friendGetsKobo: null == friendGetsKobo ? _self.friendGetsKobo : friendGetsKobo // ignore: cast_nullable_to_non_nullable
as int,youGetKobo: null == youGetKobo ? _self.youGetKobo : youGetKobo // ignore: cast_nullable_to_non_nullable
as int,minSubtotalKobo: null == minSubtotalKobo ? _self.minSubtotalKobo : minSubtotalKobo // ignore: cast_nullable_to_non_nullable
as int,friendsRewarded: null == friendsRewarded ? _self.friendsRewarded : friendsRewarded // ignore: cast_nullable_to_non_nullable
as int,applied: null == applied ? _self.applied : applied // ignore: cast_nullable_to_non_nullable
as bool,canApply: null == canApply ? _self.canApply : canApply // ignore: cast_nullable_to_non_nullable
as bool,shareText: null == shareText ? _self.shareText : shareText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RewardsOverview {

 int get points; int get lifetimePoints; int get pointsValueKobo; RewardsRedeem get redeem; RewardsReferral get referral; List<RewardVoucher> get vouchers; List<PointsEntry> get history;
/// Create a copy of RewardsOverview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardsOverviewCopyWith<RewardsOverview> get copyWith => _$RewardsOverviewCopyWithImpl<RewardsOverview>(this as RewardsOverview, _$identity);

  /// Serializes this RewardsOverview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RewardsOverview;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardsOverview&&(identical(other.points, _this.points) || other.points == _this.points)&&(identical(other.lifetimePoints, _this.lifetimePoints) || other.lifetimePoints == _this.lifetimePoints)&&(identical(other.pointsValueKobo, _this.pointsValueKobo) || other.pointsValueKobo == _this.pointsValueKobo)&&(identical(other.redeem, _this.redeem) || other.redeem == _this.redeem)&&(identical(other.referral, _this.referral) || other.referral == _this.referral)&&const DeepCollectionEquality().equals(other.vouchers, _this.vouchers)&&const DeepCollectionEquality().equals(other.history, _this.history));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RewardsOverview;
  return Object.hash(runtimeType,_this.points,_this.lifetimePoints,_this.pointsValueKobo,_this.redeem,_this.referral,const DeepCollectionEquality().hash(_this.vouchers),const DeepCollectionEquality().hash(_this.history));
}

@override
String toString() {
  final _this = this as RewardsOverview;
  return 'RewardsOverview(points: ${_this.points}, lifetimePoints: ${_this.lifetimePoints}, pointsValueKobo: ${_this.pointsValueKobo}, redeem: ${_this.redeem}, referral: ${_this.referral}, vouchers: ${_this.vouchers}, history: ${_this.history})';
}


}

/// @nodoc
abstract mixin class $RewardsOverviewCopyWith<$Res>  {
  factory $RewardsOverviewCopyWith(RewardsOverview value, $Res Function(RewardsOverview) _then) = _$RewardsOverviewCopyWithImpl;
@useResult
$Res call({
 int points, int lifetimePoints, int pointsValueKobo, RewardsRedeem redeem, RewardsReferral referral, List<RewardVoucher> vouchers, List<PointsEntry> history
});


$RewardsRedeemCopyWith<$Res> get redeem;$RewardsReferralCopyWith<$Res> get referral;

}
/// @nodoc
class _$RewardsOverviewCopyWithImpl<$Res>
    implements $RewardsOverviewCopyWith<$Res> {
  _$RewardsOverviewCopyWithImpl(this._self, this._then);

  final RewardsOverview _self;
  final $Res Function(RewardsOverview) _then;

/// Create a copy of RewardsOverview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? points = null,Object? lifetimePoints = null,Object? pointsValueKobo = null,Object? redeem = null,Object? referral = null,Object? vouchers = null,Object? history = null,}) {
  return _then(RewardsOverview(
points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,lifetimePoints: null == lifetimePoints ? _self.lifetimePoints : lifetimePoints // ignore: cast_nullable_to_non_nullable
as int,pointsValueKobo: null == pointsValueKobo ? _self.pointsValueKobo : pointsValueKobo // ignore: cast_nullable_to_non_nullable
as int,redeem: null == redeem ? _self.redeem : redeem // ignore: cast_nullable_to_non_nullable
as RewardsRedeem,referral: null == referral ? _self.referral : referral // ignore: cast_nullable_to_non_nullable
as RewardsReferral,vouchers: null == vouchers ? _self.vouchers : vouchers // ignore: cast_nullable_to_non_nullable
as List<RewardVoucher>,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as List<PointsEntry>,
  ));
}
/// Create a copy of RewardsOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RewardsRedeemCopyWith<$Res> get redeem {
  
  return $RewardsRedeemCopyWith<$Res>(_self.redeem, (value) {
    return _then(_self.copyWith(redeem: value));
  });
}/// Create a copy of RewardsOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RewardsReferralCopyWith<$Res> get referral {
  
  return $RewardsReferralCopyWith<$Res>(_self.referral, (value) {
    return _then(_self.copyWith(referral: value));
  });
}
}


/// Adds pattern-matching-related methods to [RewardsOverview].
extension RewardsOverviewPatterns on RewardsOverview {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RewardsOverview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RewardsOverview() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RewardsOverview value)  $default,){
final _that = this;
switch (_that) {
case _RewardsOverview():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RewardsOverview value)?  $default,){
final _that = this;
switch (_that) {
case _RewardsOverview() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int points,  int lifetimePoints,  int pointsValueKobo,  RewardsRedeem redeem,  RewardsReferral referral,  List<RewardVoucher> vouchers,  List<PointsEntry> history)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RewardsOverview() when $default != null:
return $default(_that.points,_that.lifetimePoints,_that.pointsValueKobo,_that.redeem,_that.referral,_that.vouchers,_that.history);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int points,  int lifetimePoints,  int pointsValueKobo,  RewardsRedeem redeem,  RewardsReferral referral,  List<RewardVoucher> vouchers,  List<PointsEntry> history)  $default,) {final _that = this;
switch (_that) {
case _RewardsOverview():
return $default(_that.points,_that.lifetimePoints,_that.pointsValueKobo,_that.redeem,_that.referral,_that.vouchers,_that.history);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int points,  int lifetimePoints,  int pointsValueKobo,  RewardsRedeem redeem,  RewardsReferral referral,  List<RewardVoucher> vouchers,  List<PointsEntry> history)?  $default,) {final _that = this;
switch (_that) {
case _RewardsOverview() when $default != null:
return $default(_that.points,_that.lifetimePoints,_that.pointsValueKobo,_that.redeem,_that.referral,_that.vouchers,_that.history);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RewardsOverview implements RewardsOverview {
  const _RewardsOverview({this.points = 0, this.lifetimePoints = 0, this.pointsValueKobo = 0, required this.redeem, required this.referral,  List<RewardVoucher> vouchers = const <RewardVoucher>[],  List<PointsEntry> history = const <PointsEntry>[]}): _vouchers = vouchers,_history = history;
  factory _RewardsOverview.fromJson(Map<String, dynamic> json) => _$RewardsOverviewFromJson(json);

@override@JsonKey() final  int points;
@override@JsonKey() final  int lifetimePoints;
@override@JsonKey() final  int pointsValueKobo;
@override final  RewardsRedeem redeem;
@override final  RewardsReferral referral;
 final  List<RewardVoucher> _vouchers;
@override@JsonKey() List<RewardVoucher> get vouchers {
  if (_vouchers is EqualUnmodifiableListView) return _vouchers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_vouchers);
}

 final  List<PointsEntry> _history;
@override@JsonKey() List<PointsEntry> get history {
  if (_history is EqualUnmodifiableListView) return _history;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_history);
}


/// Create a copy of RewardsOverview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RewardsOverviewCopyWith<_RewardsOverview> get copyWith => __$RewardsOverviewCopyWithImpl<_RewardsOverview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RewardsOverviewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RewardsOverview&&(identical(other.points, points) || other.points == points)&&(identical(other.lifetimePoints, lifetimePoints) || other.lifetimePoints == lifetimePoints)&&(identical(other.pointsValueKobo, pointsValueKobo) || other.pointsValueKobo == pointsValueKobo)&&(identical(other.redeem, redeem) || other.redeem == redeem)&&(identical(other.referral, referral) || other.referral == referral)&&const DeepCollectionEquality().equals(other.vouchers, _vouchers)&&const DeepCollectionEquality().equals(other.history, _history));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,points,lifetimePoints,pointsValueKobo,redeem,referral,const DeepCollectionEquality().hash(_vouchers),const DeepCollectionEquality().hash(_history));
}

@override
String toString() {
    return 'RewardsOverview(points: $points, lifetimePoints: $lifetimePoints, pointsValueKobo: $pointsValueKobo, redeem: $redeem, referral: $referral, vouchers: $vouchers, history: $history)';
}


}

/// @nodoc
abstract mixin class _$RewardsOverviewCopyWith<$Res> implements $RewardsOverviewCopyWith<$Res> {
  factory _$RewardsOverviewCopyWith(_RewardsOverview value, $Res Function(_RewardsOverview) _then) = __$RewardsOverviewCopyWithImpl;
@override @useResult
$Res call({
 int points, int lifetimePoints, int pointsValueKobo, RewardsRedeem redeem, RewardsReferral referral, List<RewardVoucher> vouchers, List<PointsEntry> history
});


@override $RewardsRedeemCopyWith<$Res> get redeem;@override $RewardsReferralCopyWith<$Res> get referral;

}
/// @nodoc
class __$RewardsOverviewCopyWithImpl<$Res>
    implements _$RewardsOverviewCopyWith<$Res> {
  __$RewardsOverviewCopyWithImpl(this._self, this._then);

  final _RewardsOverview _self;
  final $Res Function(_RewardsOverview) _then;

/// Create a copy of RewardsOverview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? points = null,Object? lifetimePoints = null,Object? pointsValueKobo = null,Object? redeem = null,Object? referral = null,Object? vouchers = null,Object? history = null,}) {
  return _then(_RewardsOverview(
points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,lifetimePoints: null == lifetimePoints ? _self.lifetimePoints : lifetimePoints // ignore: cast_nullable_to_non_nullable
as int,pointsValueKobo: null == pointsValueKobo ? _self.pointsValueKobo : pointsValueKobo // ignore: cast_nullable_to_non_nullable
as int,redeem: null == redeem ? _self.redeem : redeem // ignore: cast_nullable_to_non_nullable
as RewardsRedeem,referral: null == referral ? _self.referral : referral // ignore: cast_nullable_to_non_nullable
as RewardsReferral,vouchers: null == vouchers ? _self._vouchers : vouchers // ignore: cast_nullable_to_non_nullable
as List<RewardVoucher>,history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<PointsEntry>,
  ));
}

/// Create a copy of RewardsOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RewardsRedeemCopyWith<$Res> get redeem {
  
  return $RewardsRedeemCopyWith<$Res>(_self.redeem, (value) {
    return _then(_self.copyWith(redeem: value));
  });
}/// Create a copy of RewardsOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RewardsReferralCopyWith<$Res> get referral {
  
  return $RewardsReferralCopyWith<$Res>(_self.referral, (value) {
    return _then(_self.copyWith(referral: value));
  });
}
}


/// @nodoc
mixin _$GroupMemberView {

 String get uid; String get name; bool get isHost; bool get me; bool get ready; int get items; int get itemsKobo;
/// Create a copy of GroupMemberView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupMemberViewCopyWith<GroupMemberView> get copyWith => _$GroupMemberViewCopyWithImpl<GroupMemberView>(this as GroupMemberView, _$identity);

  /// Serializes this GroupMemberView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GroupMemberView;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupMemberView&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.isHost, _this.isHost) || other.isHost == _this.isHost)&&(identical(other.me, _this.me) || other.me == _this.me)&&(identical(other.ready, _this.ready) || other.ready == _this.ready)&&(identical(other.items, _this.items) || other.items == _this.items)&&(identical(other.itemsKobo, _this.itemsKobo) || other.itemsKobo == _this.itemsKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroupMemberView;
  return Object.hash(runtimeType,_this.uid,_this.name,_this.isHost,_this.me,_this.ready,_this.items,_this.itemsKobo);
}

@override
String toString() {
  final _this = this as GroupMemberView;
  return 'GroupMemberView(uid: ${_this.uid}, name: ${_this.name}, isHost: ${_this.isHost}, me: ${_this.me}, ready: ${_this.ready}, items: ${_this.items}, itemsKobo: ${_this.itemsKobo})';
}


}

/// @nodoc
abstract mixin class $GroupMemberViewCopyWith<$Res>  {
  factory $GroupMemberViewCopyWith(GroupMemberView value, $Res Function(GroupMemberView) _then) = _$GroupMemberViewCopyWithImpl;
@useResult
$Res call({
 String uid, String name, bool isHost, bool me, bool ready, int items, int itemsKobo
});




}
/// @nodoc
class _$GroupMemberViewCopyWithImpl<$Res>
    implements $GroupMemberViewCopyWith<$Res> {
  _$GroupMemberViewCopyWithImpl(this._self, this._then);

  final GroupMemberView _self;
  final $Res Function(GroupMemberView) _then;

/// Create a copy of GroupMemberView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? name = null,Object? isHost = null,Object? me = null,Object? ready = null,Object? items = null,Object? itemsKobo = null,}) {
  return _then(GroupMemberView(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,me: null == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as bool,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as int,itemsKobo: null == itemsKobo ? _self.itemsKobo : itemsKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupMemberView].
extension GroupMemberViewPatterns on GroupMemberView {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupMemberView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupMemberView() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupMemberView value)  $default,){
final _that = this;
switch (_that) {
case _GroupMemberView():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupMemberView value)?  $default,){
final _that = this;
switch (_that) {
case _GroupMemberView() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String name,  bool isHost,  bool me,  bool ready,  int items,  int itemsKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupMemberView() when $default != null:
return $default(_that.uid,_that.name,_that.isHost,_that.me,_that.ready,_that.items,_that.itemsKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String name,  bool isHost,  bool me,  bool ready,  int items,  int itemsKobo)  $default,) {final _that = this;
switch (_that) {
case _GroupMemberView():
return $default(_that.uid,_that.name,_that.isHost,_that.me,_that.ready,_that.items,_that.itemsKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String name,  bool isHost,  bool me,  bool ready,  int items,  int itemsKobo)?  $default,) {final _that = this;
switch (_that) {
case _GroupMemberView() when $default != null:
return $default(_that.uid,_that.name,_that.isHost,_that.me,_that.ready,_that.items,_that.itemsKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupMemberView implements GroupMemberView {
  const _GroupMemberView({required this.uid, required this.name, this.isHost = false, this.me = false, this.ready = false, this.items = 0, this.itemsKobo = 0});
  factory _GroupMemberView.fromJson(Map<String, dynamic> json) => _$GroupMemberViewFromJson(json);

@override final  String uid;
@override final  String name;
@override@JsonKey() final  bool isHost;
@override@JsonKey() final  bool me;
@override@JsonKey() final  bool ready;
@override@JsonKey() final  int items;
@override@JsonKey() final  int itemsKobo;

/// Create a copy of GroupMemberView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupMemberViewCopyWith<_GroupMemberView> get copyWith => __$GroupMemberViewCopyWithImpl<_GroupMemberView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupMemberViewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupMemberView&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.name, name) || other.name == name)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&(identical(other.me, me) || other.me == me)&&(identical(other.ready, ready) || other.ready == ready)&&(identical(other.items, items) || other.items == items)&&(identical(other.itemsKobo, itemsKobo) || other.itemsKobo == itemsKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,uid,name,isHost,me,ready,items,itemsKobo);
}

@override
String toString() {
    return 'GroupMemberView(uid: $uid, name: $name, isHost: $isHost, me: $me, ready: $ready, items: $items, itemsKobo: $itemsKobo)';
}


}

/// @nodoc
abstract mixin class _$GroupMemberViewCopyWith<$Res> implements $GroupMemberViewCopyWith<$Res> {
  factory _$GroupMemberViewCopyWith(_GroupMemberView value, $Res Function(_GroupMemberView) _then) = __$GroupMemberViewCopyWithImpl;
@override @useResult
$Res call({
 String uid, String name, bool isHost, bool me, bool ready, int items, int itemsKobo
});




}
/// @nodoc
class __$GroupMemberViewCopyWithImpl<$Res>
    implements _$GroupMemberViewCopyWith<$Res> {
  __$GroupMemberViewCopyWithImpl(this._self, this._then);

  final _GroupMemberView _self;
  final $Res Function(_GroupMemberView) _then;

/// Create a copy of GroupMemberView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? name = null,Object? isHost = null,Object? me = null,Object? ready = null,Object? items = null,Object? itemsKobo = null,}) {
  return _then(_GroupMemberView(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,me: null == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as bool,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as int,itemsKobo: null == itemsKobo ? _self.itemsKobo : itemsKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$GroupLineView {

 String get id; String get memberUid; String get member; String get itemId; String get name; int get quantity; List<OptionSelection> get selections; List<String> get options; String? get notes; int get lineTotalKobo; String? get problem;
/// Create a copy of GroupLineView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupLineViewCopyWith<GroupLineView> get copyWith => _$GroupLineViewCopyWithImpl<GroupLineView>(this as GroupLineView, _$identity);

  /// Serializes this GroupLineView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GroupLineView;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupLineView&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.memberUid, _this.memberUid) || other.memberUid == _this.memberUid)&&(identical(other.member, _this.member) || other.member == _this.member)&&(identical(other.itemId, _this.itemId) || other.itemId == _this.itemId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&const DeepCollectionEquality().equals(other.selections, _this.selections)&&const DeepCollectionEquality().equals(other.options, _this.options)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.lineTotalKobo, _this.lineTotalKobo) || other.lineTotalKobo == _this.lineTotalKobo)&&(identical(other.problem, _this.problem) || other.problem == _this.problem));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroupLineView;
  return Object.hash(runtimeType,_this.id,_this.memberUid,_this.member,_this.itemId,_this.name,_this.quantity,const DeepCollectionEquality().hash(_this.selections),const DeepCollectionEquality().hash(_this.options),_this.notes,_this.lineTotalKobo,_this.problem);
}

@override
String toString() {
  final _this = this as GroupLineView;
  return 'GroupLineView(id: ${_this.id}, memberUid: ${_this.memberUid}, member: ${_this.member}, itemId: ${_this.itemId}, name: ${_this.name}, quantity: ${_this.quantity}, selections: ${_this.selections}, options: ${_this.options}, notes: ${_this.notes}, lineTotalKobo: ${_this.lineTotalKobo}, problem: ${_this.problem})';
}


}

/// @nodoc
abstract mixin class $GroupLineViewCopyWith<$Res>  {
  factory $GroupLineViewCopyWith(GroupLineView value, $Res Function(GroupLineView) _then) = _$GroupLineViewCopyWithImpl;
@useResult
$Res call({
 String id, String memberUid, String member, String itemId, String name, int quantity, List<OptionSelection> selections, List<String> options, String? notes, int lineTotalKobo, String? problem
});




}
/// @nodoc
class _$GroupLineViewCopyWithImpl<$Res>
    implements $GroupLineViewCopyWith<$Res> {
  _$GroupLineViewCopyWithImpl(this._self, this._then);

  final GroupLineView _self;
  final $Res Function(GroupLineView) _then;

/// Create a copy of GroupLineView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? memberUid = null,Object? member = null,Object? itemId = null,Object? name = null,Object? quantity = null,Object? selections = null,Object? options = null,Object? notes = freezed,Object? lineTotalKobo = null,Object? problem = freezed,}) {
  return _then(GroupLineView(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,memberUid: null == memberUid ? _self.memberUid : memberUid // ignore: cast_nullable_to_non_nullable
as String,member: null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,selections: null == selections ? _self.selections : selections // ignore: cast_nullable_to_non_nullable
as List<OptionSelection>,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<String>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,lineTotalKobo: null == lineTotalKobo ? _self.lineTotalKobo : lineTotalKobo // ignore: cast_nullable_to_non_nullable
as int,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupLineView].
extension GroupLineViewPatterns on GroupLineView {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupLineView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupLineView() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupLineView value)  $default,){
final _that = this;
switch (_that) {
case _GroupLineView():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupLineView value)?  $default,){
final _that = this;
switch (_that) {
case _GroupLineView() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String memberUid,  String member,  String itemId,  String name,  int quantity,  List<OptionSelection> selections,  List<String> options,  String? notes,  int lineTotalKobo,  String? problem)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupLineView() when $default != null:
return $default(_that.id,_that.memberUid,_that.member,_that.itemId,_that.name,_that.quantity,_that.selections,_that.options,_that.notes,_that.lineTotalKobo,_that.problem);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String memberUid,  String member,  String itemId,  String name,  int quantity,  List<OptionSelection> selections,  List<String> options,  String? notes,  int lineTotalKobo,  String? problem)  $default,) {final _that = this;
switch (_that) {
case _GroupLineView():
return $default(_that.id,_that.memberUid,_that.member,_that.itemId,_that.name,_that.quantity,_that.selections,_that.options,_that.notes,_that.lineTotalKobo,_that.problem);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String memberUid,  String member,  String itemId,  String name,  int quantity,  List<OptionSelection> selections,  List<String> options,  String? notes,  int lineTotalKobo,  String? problem)?  $default,) {final _that = this;
switch (_that) {
case _GroupLineView() when $default != null:
return $default(_that.id,_that.memberUid,_that.member,_that.itemId,_that.name,_that.quantity,_that.selections,_that.options,_that.notes,_that.lineTotalKobo,_that.problem);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupLineView implements GroupLineView {
  const _GroupLineView({required this.id, required this.memberUid, this.member = '', required this.itemId, required this.name, required this.quantity,  List<OptionSelection> selections = const <OptionSelection>[],  List<String> options = const <String>[], this.notes, this.lineTotalKobo = 0, this.problem}): _selections = selections,_options = options;
  factory _GroupLineView.fromJson(Map<String, dynamic> json) => _$GroupLineViewFromJson(json);

@override final  String id;
@override final  String memberUid;
@override@JsonKey() final  String member;
@override final  String itemId;
@override final  String name;
@override final  int quantity;
 final  List<OptionSelection> _selections;
@override@JsonKey() List<OptionSelection> get selections {
  if (_selections is EqualUnmodifiableListView) return _selections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selections);
}

 final  List<String> _options;
@override@JsonKey() List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

@override final  String? notes;
@override@JsonKey() final  int lineTotalKobo;
@override final  String? problem;

/// Create a copy of GroupLineView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupLineViewCopyWith<_GroupLineView> get copyWith => __$GroupLineViewCopyWithImpl<_GroupLineView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupLineViewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupLineView&&(identical(other.id, id) || other.id == id)&&(identical(other.memberUid, memberUid) || other.memberUid == memberUid)&&(identical(other.member, member) || other.member == member)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&const DeepCollectionEquality().equals(other.selections, _selections)&&const DeepCollectionEquality().equals(other.options, _options)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.lineTotalKobo, lineTotalKobo) || other.lineTotalKobo == lineTotalKobo)&&(identical(other.problem, problem) || other.problem == problem));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,memberUid,member,itemId,name,quantity,const DeepCollectionEquality().hash(_selections),const DeepCollectionEquality().hash(_options),notes,lineTotalKobo,problem);
}

@override
String toString() {
    return 'GroupLineView(id: $id, memberUid: $memberUid, member: $member, itemId: $itemId, name: $name, quantity: $quantity, selections: $selections, options: $options, notes: $notes, lineTotalKobo: $lineTotalKobo, problem: $problem)';
}


}

/// @nodoc
abstract mixin class _$GroupLineViewCopyWith<$Res> implements $GroupLineViewCopyWith<$Res> {
  factory _$GroupLineViewCopyWith(_GroupLineView value, $Res Function(_GroupLineView) _then) = __$GroupLineViewCopyWithImpl;
@override @useResult
$Res call({
 String id, String memberUid, String member, String itemId, String name, int quantity, List<OptionSelection> selections, List<String> options, String? notes, int lineTotalKobo, String? problem
});




}
/// @nodoc
class __$GroupLineViewCopyWithImpl<$Res>
    implements _$GroupLineViewCopyWith<$Res> {
  __$GroupLineViewCopyWithImpl(this._self, this._then);

  final _GroupLineView _self;
  final $Res Function(_GroupLineView) _then;

/// Create a copy of GroupLineView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? memberUid = null,Object? member = null,Object? itemId = null,Object? name = null,Object? quantity = null,Object? selections = null,Object? options = null,Object? notes = freezed,Object? lineTotalKobo = null,Object? problem = freezed,}) {
  return _then(_GroupLineView(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,memberUid: null == memberUid ? _self.memberUid : memberUid // ignore: cast_nullable_to_non_nullable
as String,member: null == member ? _self.member : member // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,selections: null == selections ? _self._selections : selections // ignore: cast_nullable_to_non_nullable
as List<OptionSelection>,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,lineTotalKobo: null == lineTotalKobo ? _self.lineTotalKobo : lineTotalKobo // ignore: cast_nullable_to_non_nullable
as int,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$GroupShareView {

 String get uid; String get name; bool get me; int get itemsKobo; int get amountKobo; String get status; bool get paidByHost;
/// Create a copy of GroupShareView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupShareViewCopyWith<GroupShareView> get copyWith => _$GroupShareViewCopyWithImpl<GroupShareView>(this as GroupShareView, _$identity);

  /// Serializes this GroupShareView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GroupShareView;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupShareView&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.me, _this.me) || other.me == _this.me)&&(identical(other.itemsKobo, _this.itemsKobo) || other.itemsKobo == _this.itemsKobo)&&(identical(other.amountKobo, _this.amountKobo) || other.amountKobo == _this.amountKobo)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.paidByHost, _this.paidByHost) || other.paidByHost == _this.paidByHost));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroupShareView;
  return Object.hash(runtimeType,_this.uid,_this.name,_this.me,_this.itemsKobo,_this.amountKobo,_this.status,_this.paidByHost);
}

@override
String toString() {
  final _this = this as GroupShareView;
  return 'GroupShareView(uid: ${_this.uid}, name: ${_this.name}, me: ${_this.me}, itemsKobo: ${_this.itemsKobo}, amountKobo: ${_this.amountKobo}, status: ${_this.status}, paidByHost: ${_this.paidByHost})';
}


}

/// @nodoc
abstract mixin class $GroupShareViewCopyWith<$Res>  {
  factory $GroupShareViewCopyWith(GroupShareView value, $Res Function(GroupShareView) _then) = _$GroupShareViewCopyWithImpl;
@useResult
$Res call({
 String uid, String name, bool me, int itemsKobo, int amountKobo, String status, bool paidByHost
});




}
/// @nodoc
class _$GroupShareViewCopyWithImpl<$Res>
    implements $GroupShareViewCopyWith<$Res> {
  _$GroupShareViewCopyWithImpl(this._self, this._then);

  final GroupShareView _self;
  final $Res Function(GroupShareView) _then;

/// Create a copy of GroupShareView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? name = null,Object? me = null,Object? itemsKobo = null,Object? amountKobo = null,Object? status = null,Object? paidByHost = null,}) {
  return _then(GroupShareView(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,me: null == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as bool,itemsKobo: null == itemsKobo ? _self.itemsKobo : itemsKobo // ignore: cast_nullable_to_non_nullable
as int,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paidByHost: null == paidByHost ? _self.paidByHost : paidByHost // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupShareView].
extension GroupShareViewPatterns on GroupShareView {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupShareView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupShareView() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupShareView value)  $default,){
final _that = this;
switch (_that) {
case _GroupShareView():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupShareView value)?  $default,){
final _that = this;
switch (_that) {
case _GroupShareView() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String name,  bool me,  int itemsKobo,  int amountKobo,  String status,  bool paidByHost)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupShareView() when $default != null:
return $default(_that.uid,_that.name,_that.me,_that.itemsKobo,_that.amountKobo,_that.status,_that.paidByHost);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String name,  bool me,  int itemsKobo,  int amountKobo,  String status,  bool paidByHost)  $default,) {final _that = this;
switch (_that) {
case _GroupShareView():
return $default(_that.uid,_that.name,_that.me,_that.itemsKobo,_that.amountKobo,_that.status,_that.paidByHost);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String name,  bool me,  int itemsKobo,  int amountKobo,  String status,  bool paidByHost)?  $default,) {final _that = this;
switch (_that) {
case _GroupShareView() when $default != null:
return $default(_that.uid,_that.name,_that.me,_that.itemsKobo,_that.amountKobo,_that.status,_that.paidByHost);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupShareView implements GroupShareView {
  const _GroupShareView({required this.uid, required this.name, this.me = false, this.itemsKobo = 0, required this.amountKobo, this.status = 'unpaid', this.paidByHost = false});
  factory _GroupShareView.fromJson(Map<String, dynamic> json) => _$GroupShareViewFromJson(json);

@override final  String uid;
@override final  String name;
@override@JsonKey() final  bool me;
@override@JsonKey() final  int itemsKobo;
@override final  int amountKobo;
@override@JsonKey() final  String status;
@override@JsonKey() final  bool paidByHost;

/// Create a copy of GroupShareView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupShareViewCopyWith<_GroupShareView> get copyWith => __$GroupShareViewCopyWithImpl<_GroupShareView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupShareViewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupShareView&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.name, name) || other.name == name)&&(identical(other.me, me) || other.me == me)&&(identical(other.itemsKobo, itemsKobo) || other.itemsKobo == itemsKobo)&&(identical(other.amountKobo, amountKobo) || other.amountKobo == amountKobo)&&(identical(other.status, status) || other.status == status)&&(identical(other.paidByHost, paidByHost) || other.paidByHost == paidByHost));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,uid,name,me,itemsKobo,amountKobo,status,paidByHost);
}

@override
String toString() {
    return 'GroupShareView(uid: $uid, name: $name, me: $me, itemsKobo: $itemsKobo, amountKobo: $amountKobo, status: $status, paidByHost: $paidByHost)';
}


}

/// @nodoc
abstract mixin class _$GroupShareViewCopyWith<$Res> implements $GroupShareViewCopyWith<$Res> {
  factory _$GroupShareViewCopyWith(_GroupShareView value, $Res Function(_GroupShareView) _then) = __$GroupShareViewCopyWithImpl;
@override @useResult
$Res call({
 String uid, String name, bool me, int itemsKobo, int amountKobo, String status, bool paidByHost
});




}
/// @nodoc
class __$GroupShareViewCopyWithImpl<$Res>
    implements _$GroupShareViewCopyWith<$Res> {
  __$GroupShareViewCopyWithImpl(this._self, this._then);

  final _GroupShareView _self;
  final $Res Function(_GroupShareView) _then;

/// Create a copy of GroupShareView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? name = null,Object? me = null,Object? itemsKobo = null,Object? amountKobo = null,Object? status = null,Object? paidByHost = null,}) {
  return _then(_GroupShareView(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,me: null == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as bool,itemsKobo: null == itemsKobo ? _self.itemsKobo : itemsKobo // ignore: cast_nullable_to_non_nullable
as int,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paidByHost: null == paidByHost ? _self.paidByHost : paidByHost // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$GroupOrderRef {

 String get id; String get shortCode; String get status; int get totalKobo;
/// Create a copy of GroupOrderRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupOrderRefCopyWith<GroupOrderRef> get copyWith => _$GroupOrderRefCopyWithImpl<GroupOrderRef>(this as GroupOrderRef, _$identity);

  /// Serializes this GroupOrderRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GroupOrderRef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupOrderRef&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.shortCode, _this.shortCode) || other.shortCode == _this.shortCode)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.totalKobo, _this.totalKobo) || other.totalKobo == _this.totalKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroupOrderRef;
  return Object.hash(runtimeType,_this.id,_this.shortCode,_this.status,_this.totalKobo);
}

@override
String toString() {
  final _this = this as GroupOrderRef;
  return 'GroupOrderRef(id: ${_this.id}, shortCode: ${_this.shortCode}, status: ${_this.status}, totalKobo: ${_this.totalKobo})';
}


}

/// @nodoc
abstract mixin class $GroupOrderRefCopyWith<$Res>  {
  factory $GroupOrderRefCopyWith(GroupOrderRef value, $Res Function(GroupOrderRef) _then) = _$GroupOrderRefCopyWithImpl;
@useResult
$Res call({
 String id, String shortCode, String status, int totalKobo
});




}
/// @nodoc
class _$GroupOrderRefCopyWithImpl<$Res>
    implements $GroupOrderRefCopyWith<$Res> {
  _$GroupOrderRefCopyWithImpl(this._self, this._then);

  final GroupOrderRef _self;
  final $Res Function(GroupOrderRef) _then;

/// Create a copy of GroupOrderRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? shortCode = null,Object? status = null,Object? totalKobo = null,}) {
  return _then(GroupOrderRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shortCode: null == shortCode ? _self.shortCode : shortCode // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,totalKobo: null == totalKobo ? _self.totalKobo : totalKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupOrderRef].
extension GroupOrderRefPatterns on GroupOrderRef {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupOrderRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupOrderRef() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupOrderRef value)  $default,){
final _that = this;
switch (_that) {
case _GroupOrderRef():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupOrderRef value)?  $default,){
final _that = this;
switch (_that) {
case _GroupOrderRef() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String shortCode,  String status,  int totalKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupOrderRef() when $default != null:
return $default(_that.id,_that.shortCode,_that.status,_that.totalKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String shortCode,  String status,  int totalKobo)  $default,) {final _that = this;
switch (_that) {
case _GroupOrderRef():
return $default(_that.id,_that.shortCode,_that.status,_that.totalKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String shortCode,  String status,  int totalKobo)?  $default,) {final _that = this;
switch (_that) {
case _GroupOrderRef() when $default != null:
return $default(_that.id,_that.shortCode,_that.status,_that.totalKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupOrderRef implements GroupOrderRef {
  const _GroupOrderRef({required this.id, this.shortCode = '', required this.status, this.totalKobo = 0});
  factory _GroupOrderRef.fromJson(Map<String, dynamic> json) => _$GroupOrderRefFromJson(json);

@override final  String id;
@override@JsonKey() final  String shortCode;
@override final  String status;
@override@JsonKey() final  int totalKobo;

/// Create a copy of GroupOrderRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupOrderRefCopyWith<_GroupOrderRef> get copyWith => __$GroupOrderRefCopyWithImpl<_GroupOrderRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupOrderRefToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupOrderRef&&(identical(other.id, id) || other.id == id)&&(identical(other.shortCode, shortCode) || other.shortCode == shortCode)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalKobo, totalKobo) || other.totalKobo == totalKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,shortCode,status,totalKobo);
}

@override
String toString() {
    return 'GroupOrderRef(id: $id, shortCode: $shortCode, status: $status, totalKobo: $totalKobo)';
}


}

/// @nodoc
abstract mixin class _$GroupOrderRefCopyWith<$Res> implements $GroupOrderRefCopyWith<$Res> {
  factory _$GroupOrderRefCopyWith(_GroupOrderRef value, $Res Function(_GroupOrderRef) _then) = __$GroupOrderRefCopyWithImpl;
@override @useResult
$Res call({
 String id, String shortCode, String status, int totalKobo
});




}
/// @nodoc
class __$GroupOrderRefCopyWithImpl<$Res>
    implements _$GroupOrderRefCopyWith<$Res> {
  __$GroupOrderRefCopyWithImpl(this._self, this._then);

  final _GroupOrderRef _self;
  final $Res Function(_GroupOrderRef) _then;

/// Create a copy of GroupOrderRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? shortCode = null,Object? status = null,Object? totalKobo = null,}) {
  return _then(_GroupOrderRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,shortCode: null == shortCode ? _self.shortCode : shortCode // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,totalKobo: null == totalKobo ? _self.totalKobo : totalKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$GroupMyShare {

 int get amountKobo; int get itemsKobo; String get status;
/// Create a copy of GroupMyShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupMyShareCopyWith<GroupMyShare> get copyWith => _$GroupMyShareCopyWithImpl<GroupMyShare>(this as GroupMyShare, _$identity);

  /// Serializes this GroupMyShare to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GroupMyShare;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupMyShare&&(identical(other.amountKobo, _this.amountKobo) || other.amountKobo == _this.amountKobo)&&(identical(other.itemsKobo, _this.itemsKobo) || other.itemsKobo == _this.itemsKobo)&&(identical(other.status, _this.status) || other.status == _this.status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroupMyShare;
  return Object.hash(runtimeType,_this.amountKobo,_this.itemsKobo,_this.status);
}

@override
String toString() {
  final _this = this as GroupMyShare;
  return 'GroupMyShare(amountKobo: ${_this.amountKobo}, itemsKobo: ${_this.itemsKobo}, status: ${_this.status})';
}


}

/// @nodoc
abstract mixin class $GroupMyShareCopyWith<$Res>  {
  factory $GroupMyShareCopyWith(GroupMyShare value, $Res Function(GroupMyShare) _then) = _$GroupMyShareCopyWithImpl;
@useResult
$Res call({
 int amountKobo, int itemsKobo, String status
});




}
/// @nodoc
class _$GroupMyShareCopyWithImpl<$Res>
    implements $GroupMyShareCopyWith<$Res> {
  _$GroupMyShareCopyWithImpl(this._self, this._then);

  final GroupMyShare _self;
  final $Res Function(GroupMyShare) _then;

/// Create a copy of GroupMyShare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amountKobo = null,Object? itemsKobo = null,Object? status = null,}) {
  return _then(GroupMyShare(
amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,itemsKobo: null == itemsKobo ? _self.itemsKobo : itemsKobo // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupMyShare].
extension GroupMySharePatterns on GroupMyShare {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupMyShare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupMyShare() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupMyShare value)  $default,){
final _that = this;
switch (_that) {
case _GroupMyShare():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupMyShare value)?  $default,){
final _that = this;
switch (_that) {
case _GroupMyShare() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int amountKobo,  int itemsKobo,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupMyShare() when $default != null:
return $default(_that.amountKobo,_that.itemsKobo,_that.status);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int amountKobo,  int itemsKobo,  String status)  $default,) {final _that = this;
switch (_that) {
case _GroupMyShare():
return $default(_that.amountKobo,_that.itemsKobo,_that.status);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int amountKobo,  int itemsKobo,  String status)?  $default,) {final _that = this;
switch (_that) {
case _GroupMyShare() when $default != null:
return $default(_that.amountKobo,_that.itemsKobo,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupMyShare implements GroupMyShare {
  const _GroupMyShare({required this.amountKobo, this.itemsKobo = 0, this.status = 'unpaid'});
  factory _GroupMyShare.fromJson(Map<String, dynamic> json) => _$GroupMyShareFromJson(json);

@override final  int amountKobo;
@override@JsonKey() final  int itemsKobo;
@override@JsonKey() final  String status;

/// Create a copy of GroupMyShare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupMyShareCopyWith<_GroupMyShare> get copyWith => __$GroupMyShareCopyWithImpl<_GroupMyShare>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupMyShareToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupMyShare&&(identical(other.amountKobo, amountKobo) || other.amountKobo == amountKobo)&&(identical(other.itemsKobo, itemsKobo) || other.itemsKobo == itemsKobo)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,amountKobo,itemsKobo,status);
}

@override
String toString() {
    return 'GroupMyShare(amountKobo: $amountKobo, itemsKobo: $itemsKobo, status: $status)';
}


}

/// @nodoc
abstract mixin class _$GroupMyShareCopyWith<$Res> implements $GroupMyShareCopyWith<$Res> {
  factory _$GroupMyShareCopyWith(_GroupMyShare value, $Res Function(_GroupMyShare) _then) = __$GroupMyShareCopyWithImpl;
@override @useResult
$Res call({
 int amountKobo, int itemsKobo, String status
});




}
/// @nodoc
class __$GroupMyShareCopyWithImpl<$Res>
    implements _$GroupMyShareCopyWith<$Res> {
  __$GroupMyShareCopyWithImpl(this._self, this._then);

  final _GroupMyShare _self;
  final $Res Function(_GroupMyShare) _then;

/// Create a copy of GroupMyShare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amountKobo = null,Object? itemsKobo = null,Object? status = null,}) {
  return _then(_GroupMyShare(
amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,itemsKobo: null == itemsKobo ? _self.itemsKobo : itemsKobo // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GroupRestaurant {

 String get id; String get name;
/// Create a copy of GroupRestaurant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupRestaurantCopyWith<GroupRestaurant> get copyWith => _$GroupRestaurantCopyWithImpl<GroupRestaurant>(this as GroupRestaurant, _$identity);

  /// Serializes this GroupRestaurant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GroupRestaurant;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupRestaurant&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroupRestaurant;
  return Object.hash(runtimeType,_this.id,_this.name);
}

@override
String toString() {
  final _this = this as GroupRestaurant;
  return 'GroupRestaurant(id: ${_this.id}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $GroupRestaurantCopyWith<$Res>  {
  factory $GroupRestaurantCopyWith(GroupRestaurant value, $Res Function(GroupRestaurant) _then) = _$GroupRestaurantCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$GroupRestaurantCopyWithImpl<$Res>
    implements $GroupRestaurantCopyWith<$Res> {
  _$GroupRestaurantCopyWithImpl(this._self, this._then);

  final GroupRestaurant _self;
  final $Res Function(GroupRestaurant) _then;

/// Create a copy of GroupRestaurant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(GroupRestaurant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupRestaurant].
extension GroupRestaurantPatterns on GroupRestaurant {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupRestaurant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupRestaurant() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupRestaurant value)  $default,){
final _that = this;
switch (_that) {
case _GroupRestaurant():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupRestaurant value)?  $default,){
final _that = this;
switch (_that) {
case _GroupRestaurant() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupRestaurant() when $default != null:
return $default(_that.id,_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _GroupRestaurant():
return $default(_that.id,_that.name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _GroupRestaurant() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupRestaurant implements GroupRestaurant {
  const _GroupRestaurant({required this.id, required this.name});
  factory _GroupRestaurant.fromJson(Map<String, dynamic> json) => _$GroupRestaurantFromJson(json);

@override final  String id;
@override final  String name;

/// Create a copy of GroupRestaurant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupRestaurantCopyWith<_GroupRestaurant> get copyWith => __$GroupRestaurantCopyWithImpl<_GroupRestaurant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupRestaurantToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupRestaurant&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name);
}

@override
String toString() {
    return 'GroupRestaurant(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$GroupRestaurantCopyWith<$Res> implements $GroupRestaurantCopyWith<$Res> {
  factory _$GroupRestaurantCopyWith(_GroupRestaurant value, $Res Function(_GroupRestaurant) _then) = __$GroupRestaurantCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$GroupRestaurantCopyWithImpl<$Res>
    implements _$GroupRestaurantCopyWith<$Res> {
  __$GroupRestaurantCopyWithImpl(this._self, this._then);

  final _GroupRestaurant _self;
  final $Res Function(_GroupRestaurant) _then;

/// Create a copy of GroupRestaurant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_GroupRestaurant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GroupOrder {

 String get id; String get code; String get status; String get splitMode; bool get isHost; String get hostName; GroupRestaurant get restaurant; String get fulfillment; String? get deliveryArea; List<GroupMemberView> get members; int get maxMembers; List<GroupLineView> get lines; int get estimatedItemsKobo; DateTime? get expiresAt; GroupOrderRef? get order; int get totalKobo; List<GroupShareView> get shares; GroupMyShare? get myShare; int get paidKobo; int get remainingKobo; DateTime? get payBy; bool get canPay; bool get canCoverRest; String? get cancelReason;
/// Create a copy of GroupOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupOrderCopyWith<GroupOrder> get copyWith => _$GroupOrderCopyWithImpl<GroupOrder>(this as GroupOrder, _$identity);

  /// Serializes this GroupOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GroupOrder;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupOrder&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.splitMode, _this.splitMode) || other.splitMode == _this.splitMode)&&(identical(other.isHost, _this.isHost) || other.isHost == _this.isHost)&&(identical(other.hostName, _this.hostName) || other.hostName == _this.hostName)&&(identical(other.restaurant, _this.restaurant) || other.restaurant == _this.restaurant)&&(identical(other.fulfillment, _this.fulfillment) || other.fulfillment == _this.fulfillment)&&(identical(other.deliveryArea, _this.deliveryArea) || other.deliveryArea == _this.deliveryArea)&&const DeepCollectionEquality().equals(other.members, _this.members)&&(identical(other.maxMembers, _this.maxMembers) || other.maxMembers == _this.maxMembers)&&const DeepCollectionEquality().equals(other.lines, _this.lines)&&(identical(other.estimatedItemsKobo, _this.estimatedItemsKobo) || other.estimatedItemsKobo == _this.estimatedItemsKobo)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.order, _this.order) || other.order == _this.order)&&(identical(other.totalKobo, _this.totalKobo) || other.totalKobo == _this.totalKobo)&&const DeepCollectionEquality().equals(other.shares, _this.shares)&&(identical(other.myShare, _this.myShare) || other.myShare == _this.myShare)&&(identical(other.paidKobo, _this.paidKobo) || other.paidKobo == _this.paidKobo)&&(identical(other.remainingKobo, _this.remainingKobo) || other.remainingKobo == _this.remainingKobo)&&(identical(other.payBy, _this.payBy) || other.payBy == _this.payBy)&&(identical(other.canPay, _this.canPay) || other.canPay == _this.canPay)&&(identical(other.canCoverRest, _this.canCoverRest) || other.canCoverRest == _this.canCoverRest)&&(identical(other.cancelReason, _this.cancelReason) || other.cancelReason == _this.cancelReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroupOrder;
  return Object.hashAll([runtimeType,_this.id,_this.code,_this.status,_this.splitMode,_this.isHost,_this.hostName,_this.restaurant,_this.fulfillment,_this.deliveryArea,const DeepCollectionEquality().hash(_this.members),_this.maxMembers,const DeepCollectionEquality().hash(_this.lines),_this.estimatedItemsKobo,_this.expiresAt,_this.order,_this.totalKobo,const DeepCollectionEquality().hash(_this.shares),_this.myShare,_this.paidKobo,_this.remainingKobo,_this.payBy,_this.canPay,_this.canCoverRest,_this.cancelReason]);
}

@override
String toString() {
  final _this = this as GroupOrder;
  return 'GroupOrder(id: ${_this.id}, code: ${_this.code}, status: ${_this.status}, splitMode: ${_this.splitMode}, isHost: ${_this.isHost}, hostName: ${_this.hostName}, restaurant: ${_this.restaurant}, fulfillment: ${_this.fulfillment}, deliveryArea: ${_this.deliveryArea}, members: ${_this.members}, maxMembers: ${_this.maxMembers}, lines: ${_this.lines}, estimatedItemsKobo: ${_this.estimatedItemsKobo}, expiresAt: ${_this.expiresAt}, order: ${_this.order}, totalKobo: ${_this.totalKobo}, shares: ${_this.shares}, myShare: ${_this.myShare}, paidKobo: ${_this.paidKobo}, remainingKobo: ${_this.remainingKobo}, payBy: ${_this.payBy}, canPay: ${_this.canPay}, canCoverRest: ${_this.canCoverRest}, cancelReason: ${_this.cancelReason})';
}


}

/// @nodoc
abstract mixin class $GroupOrderCopyWith<$Res>  {
  factory $GroupOrderCopyWith(GroupOrder value, $Res Function(GroupOrder) _then) = _$GroupOrderCopyWithImpl;
@useResult
$Res call({
 String id, String code, String status, String splitMode, bool isHost, String hostName, GroupRestaurant restaurant, String fulfillment, String? deliveryArea, List<GroupMemberView> members, int maxMembers, List<GroupLineView> lines, int estimatedItemsKobo, DateTime? expiresAt, GroupOrderRef? order, int totalKobo, List<GroupShareView> shares, GroupMyShare? myShare, int paidKobo, int remainingKobo, DateTime? payBy, bool canPay, bool canCoverRest, String? cancelReason
});


$GroupRestaurantCopyWith<$Res> get restaurant;$GroupOrderRefCopyWith<$Res>? get order;$GroupMyShareCopyWith<$Res>? get myShare;

}
/// @nodoc
class _$GroupOrderCopyWithImpl<$Res>
    implements $GroupOrderCopyWith<$Res> {
  _$GroupOrderCopyWithImpl(this._self, this._then);

  final GroupOrder _self;
  final $Res Function(GroupOrder) _then;

/// Create a copy of GroupOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? status = null,Object? splitMode = null,Object? isHost = null,Object? hostName = null,Object? restaurant = null,Object? fulfillment = null,Object? deliveryArea = freezed,Object? members = null,Object? maxMembers = null,Object? lines = null,Object? estimatedItemsKobo = null,Object? expiresAt = freezed,Object? order = freezed,Object? totalKobo = null,Object? shares = null,Object? myShare = freezed,Object? paidKobo = null,Object? remainingKobo = null,Object? payBy = freezed,Object? canPay = null,Object? canCoverRest = null,Object? cancelReason = freezed,}) {
  return _then(GroupOrder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,splitMode: null == splitMode ? _self.splitMode : splitMode // ignore: cast_nullable_to_non_nullable
as String,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,hostName: null == hostName ? _self.hostName : hostName // ignore: cast_nullable_to_non_nullable
as String,restaurant: null == restaurant ? _self.restaurant : restaurant // ignore: cast_nullable_to_non_nullable
as GroupRestaurant,fulfillment: null == fulfillment ? _self.fulfillment : fulfillment // ignore: cast_nullable_to_non_nullable
as String,deliveryArea: freezed == deliveryArea ? _self.deliveryArea : deliveryArea // ignore: cast_nullable_to_non_nullable
as String?,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<GroupMemberView>,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<GroupLineView>,estimatedItemsKobo: null == estimatedItemsKobo ? _self.estimatedItemsKobo : estimatedItemsKobo // ignore: cast_nullable_to_non_nullable
as int,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as GroupOrderRef?,totalKobo: null == totalKobo ? _self.totalKobo : totalKobo // ignore: cast_nullable_to_non_nullable
as int,shares: null == shares ? _self.shares : shares // ignore: cast_nullable_to_non_nullable
as List<GroupShareView>,myShare: freezed == myShare ? _self.myShare : myShare // ignore: cast_nullable_to_non_nullable
as GroupMyShare?,paidKobo: null == paidKobo ? _self.paidKobo : paidKobo // ignore: cast_nullable_to_non_nullable
as int,remainingKobo: null == remainingKobo ? _self.remainingKobo : remainingKobo // ignore: cast_nullable_to_non_nullable
as int,payBy: freezed == payBy ? _self.payBy : payBy // ignore: cast_nullable_to_non_nullable
as DateTime?,canPay: null == canPay ? _self.canPay : canPay // ignore: cast_nullable_to_non_nullable
as bool,canCoverRest: null == canCoverRest ? _self.canCoverRest : canCoverRest // ignore: cast_nullable_to_non_nullable
as bool,cancelReason: freezed == cancelReason ? _self.cancelReason : cancelReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of GroupOrder
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupRestaurantCopyWith<$Res> get restaurant {
  
  return $GroupRestaurantCopyWith<$Res>(_self.restaurant, (value) {
    return _then(_self.copyWith(restaurant: value));
  });
}/// Create a copy of GroupOrder
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupOrderRefCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $GroupOrderRefCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}/// Create a copy of GroupOrder
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupMyShareCopyWith<$Res>? get myShare {
    if (_self.myShare == null) {
    return null;
  }

  return $GroupMyShareCopyWith<$Res>(_self.myShare!, (value) {
    return _then(_self.copyWith(myShare: value));
  });
}
}


/// Adds pattern-matching-related methods to [GroupOrder].
extension GroupOrderPatterns on GroupOrder {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupOrder() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupOrder value)  $default,){
final _that = this;
switch (_that) {
case _GroupOrder():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupOrder value)?  $default,){
final _that = this;
switch (_that) {
case _GroupOrder() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code,  String status,  String splitMode,  bool isHost,  String hostName,  GroupRestaurant restaurant,  String fulfillment,  String? deliveryArea,  List<GroupMemberView> members,  int maxMembers,  List<GroupLineView> lines,  int estimatedItemsKobo,  DateTime? expiresAt,  GroupOrderRef? order,  int totalKobo,  List<GroupShareView> shares,  GroupMyShare? myShare,  int paidKobo,  int remainingKobo,  DateTime? payBy,  bool canPay,  bool canCoverRest,  String? cancelReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupOrder() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.splitMode,_that.isHost,_that.hostName,_that.restaurant,_that.fulfillment,_that.deliveryArea,_that.members,_that.maxMembers,_that.lines,_that.estimatedItemsKobo,_that.expiresAt,_that.order,_that.totalKobo,_that.shares,_that.myShare,_that.paidKobo,_that.remainingKobo,_that.payBy,_that.canPay,_that.canCoverRest,_that.cancelReason);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code,  String status,  String splitMode,  bool isHost,  String hostName,  GroupRestaurant restaurant,  String fulfillment,  String? deliveryArea,  List<GroupMemberView> members,  int maxMembers,  List<GroupLineView> lines,  int estimatedItemsKobo,  DateTime? expiresAt,  GroupOrderRef? order,  int totalKobo,  List<GroupShareView> shares,  GroupMyShare? myShare,  int paidKobo,  int remainingKobo,  DateTime? payBy,  bool canPay,  bool canCoverRest,  String? cancelReason)  $default,) {final _that = this;
switch (_that) {
case _GroupOrder():
return $default(_that.id,_that.code,_that.status,_that.splitMode,_that.isHost,_that.hostName,_that.restaurant,_that.fulfillment,_that.deliveryArea,_that.members,_that.maxMembers,_that.lines,_that.estimatedItemsKobo,_that.expiresAt,_that.order,_that.totalKobo,_that.shares,_that.myShare,_that.paidKobo,_that.remainingKobo,_that.payBy,_that.canPay,_that.canCoverRest,_that.cancelReason);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code,  String status,  String splitMode,  bool isHost,  String hostName,  GroupRestaurant restaurant,  String fulfillment,  String? deliveryArea,  List<GroupMemberView> members,  int maxMembers,  List<GroupLineView> lines,  int estimatedItemsKobo,  DateTime? expiresAt,  GroupOrderRef? order,  int totalKobo,  List<GroupShareView> shares,  GroupMyShare? myShare,  int paidKobo,  int remainingKobo,  DateTime? payBy,  bool canPay,  bool canCoverRest,  String? cancelReason)?  $default,) {final _that = this;
switch (_that) {
case _GroupOrder() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.splitMode,_that.isHost,_that.hostName,_that.restaurant,_that.fulfillment,_that.deliveryArea,_that.members,_that.maxMembers,_that.lines,_that.estimatedItemsKobo,_that.expiresAt,_that.order,_that.totalKobo,_that.shares,_that.myShare,_that.paidKobo,_that.remainingKobo,_that.payBy,_that.canPay,_that.canCoverRest,_that.cancelReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupOrder implements GroupOrder {
  const _GroupOrder({required this.id, required this.code, required this.status, this.splitMode = 'each', this.isHost = false, this.hostName = '', required this.restaurant, this.fulfillment = 'delivery', this.deliveryArea,  List<GroupMemberView> members = const <GroupMemberView>[], this.maxMembers = 10,  List<GroupLineView> lines = const <GroupLineView>[], this.estimatedItemsKobo = 0, this.expiresAt, this.order, this.totalKobo = 0,  List<GroupShareView> shares = const <GroupShareView>[], this.myShare, this.paidKobo = 0, this.remainingKobo = 0, this.payBy, this.canPay = false, this.canCoverRest = false, this.cancelReason}): _members = members,_lines = lines,_shares = shares;
  factory _GroupOrder.fromJson(Map<String, dynamic> json) => _$GroupOrderFromJson(json);

@override final  String id;
@override final  String code;
@override final  String status;
@override@JsonKey() final  String splitMode;
@override@JsonKey() final  bool isHost;
@override@JsonKey() final  String hostName;
@override final  GroupRestaurant restaurant;
@override@JsonKey() final  String fulfillment;
@override final  String? deliveryArea;
 final  List<GroupMemberView> _members;
@override@JsonKey() List<GroupMemberView> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

@override@JsonKey() final  int maxMembers;
 final  List<GroupLineView> _lines;
@override@JsonKey() List<GroupLineView> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

@override@JsonKey() final  int estimatedItemsKobo;
@override final  DateTime? expiresAt;
@override final  GroupOrderRef? order;
@override@JsonKey() final  int totalKobo;
 final  List<GroupShareView> _shares;
@override@JsonKey() List<GroupShareView> get shares {
  if (_shares is EqualUnmodifiableListView) return _shares;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shares);
}

@override final  GroupMyShare? myShare;
@override@JsonKey() final  int paidKobo;
@override@JsonKey() final  int remainingKobo;
@override final  DateTime? payBy;
@override@JsonKey() final  bool canPay;
@override@JsonKey() final  bool canCoverRest;
@override final  String? cancelReason;

/// Create a copy of GroupOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupOrderCopyWith<_GroupOrder> get copyWith => __$GroupOrderCopyWithImpl<_GroupOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupOrderToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.splitMode, splitMode) || other.splitMode == splitMode)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&(identical(other.hostName, hostName) || other.hostName == hostName)&&(identical(other.restaurant, restaurant) || other.restaurant == restaurant)&&(identical(other.fulfillment, fulfillment) || other.fulfillment == fulfillment)&&(identical(other.deliveryArea, deliveryArea) || other.deliveryArea == deliveryArea)&&const DeepCollectionEquality().equals(other.members, _members)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&const DeepCollectionEquality().equals(other.lines, _lines)&&(identical(other.estimatedItemsKobo, estimatedItemsKobo) || other.estimatedItemsKobo == estimatedItemsKobo)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.order, order) || other.order == order)&&(identical(other.totalKobo, totalKobo) || other.totalKobo == totalKobo)&&const DeepCollectionEquality().equals(other.shares, _shares)&&(identical(other.myShare, myShare) || other.myShare == myShare)&&(identical(other.paidKobo, paidKobo) || other.paidKobo == paidKobo)&&(identical(other.remainingKobo, remainingKobo) || other.remainingKobo == remainingKobo)&&(identical(other.payBy, payBy) || other.payBy == payBy)&&(identical(other.canPay, canPay) || other.canPay == canPay)&&(identical(other.canCoverRest, canCoverRest) || other.canCoverRest == canCoverRest)&&(identical(other.cancelReason, cancelReason) || other.cancelReason == cancelReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,code,status,splitMode,isHost,hostName,restaurant,fulfillment,deliveryArea,const DeepCollectionEquality().hash(_members),maxMembers,const DeepCollectionEquality().hash(_lines),estimatedItemsKobo,expiresAt,order,totalKobo,const DeepCollectionEquality().hash(_shares),myShare,paidKobo,remainingKobo,payBy,canPay,canCoverRest,cancelReason]);
}

@override
String toString() {
    return 'GroupOrder(id: $id, code: $code, status: $status, splitMode: $splitMode, isHost: $isHost, hostName: $hostName, restaurant: $restaurant, fulfillment: $fulfillment, deliveryArea: $deliveryArea, members: $members, maxMembers: $maxMembers, lines: $lines, estimatedItemsKobo: $estimatedItemsKobo, expiresAt: $expiresAt, order: $order, totalKobo: $totalKobo, shares: $shares, myShare: $myShare, paidKobo: $paidKobo, remainingKobo: $remainingKobo, payBy: $payBy, canPay: $canPay, canCoverRest: $canCoverRest, cancelReason: $cancelReason)';
}


}

/// @nodoc
abstract mixin class _$GroupOrderCopyWith<$Res> implements $GroupOrderCopyWith<$Res> {
  factory _$GroupOrderCopyWith(_GroupOrder value, $Res Function(_GroupOrder) _then) = __$GroupOrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, String status, String splitMode, bool isHost, String hostName, GroupRestaurant restaurant, String fulfillment, String? deliveryArea, List<GroupMemberView> members, int maxMembers, List<GroupLineView> lines, int estimatedItemsKobo, DateTime? expiresAt, GroupOrderRef? order, int totalKobo, List<GroupShareView> shares, GroupMyShare? myShare, int paidKobo, int remainingKobo, DateTime? payBy, bool canPay, bool canCoverRest, String? cancelReason
});


@override $GroupRestaurantCopyWith<$Res> get restaurant;@override $GroupOrderRefCopyWith<$Res>? get order;@override $GroupMyShareCopyWith<$Res>? get myShare;

}
/// @nodoc
class __$GroupOrderCopyWithImpl<$Res>
    implements _$GroupOrderCopyWith<$Res> {
  __$GroupOrderCopyWithImpl(this._self, this._then);

  final _GroupOrder _self;
  final $Res Function(_GroupOrder) _then;

/// Create a copy of GroupOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? status = null,Object? splitMode = null,Object? isHost = null,Object? hostName = null,Object? restaurant = null,Object? fulfillment = null,Object? deliveryArea = freezed,Object? members = null,Object? maxMembers = null,Object? lines = null,Object? estimatedItemsKobo = null,Object? expiresAt = freezed,Object? order = freezed,Object? totalKobo = null,Object? shares = null,Object? myShare = freezed,Object? paidKobo = null,Object? remainingKobo = null,Object? payBy = freezed,Object? canPay = null,Object? canCoverRest = null,Object? cancelReason = freezed,}) {
  return _then(_GroupOrder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,splitMode: null == splitMode ? _self.splitMode : splitMode // ignore: cast_nullable_to_non_nullable
as String,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,hostName: null == hostName ? _self.hostName : hostName // ignore: cast_nullable_to_non_nullable
as String,restaurant: null == restaurant ? _self.restaurant : restaurant // ignore: cast_nullable_to_non_nullable
as GroupRestaurant,fulfillment: null == fulfillment ? _self.fulfillment : fulfillment // ignore: cast_nullable_to_non_nullable
as String,deliveryArea: freezed == deliveryArea ? _self.deliveryArea : deliveryArea // ignore: cast_nullable_to_non_nullable
as String?,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<GroupMemberView>,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<GroupLineView>,estimatedItemsKobo: null == estimatedItemsKobo ? _self.estimatedItemsKobo : estimatedItemsKobo // ignore: cast_nullable_to_non_nullable
as int,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as GroupOrderRef?,totalKobo: null == totalKobo ? _self.totalKobo : totalKobo // ignore: cast_nullable_to_non_nullable
as int,shares: null == shares ? _self._shares : shares // ignore: cast_nullable_to_non_nullable
as List<GroupShareView>,myShare: freezed == myShare ? _self.myShare : myShare // ignore: cast_nullable_to_non_nullable
as GroupMyShare?,paidKobo: null == paidKobo ? _self.paidKobo : paidKobo // ignore: cast_nullable_to_non_nullable
as int,remainingKobo: null == remainingKobo ? _self.remainingKobo : remainingKobo // ignore: cast_nullable_to_non_nullable
as int,payBy: freezed == payBy ? _self.payBy : payBy // ignore: cast_nullable_to_non_nullable
as DateTime?,canPay: null == canPay ? _self.canPay : canPay // ignore: cast_nullable_to_non_nullable
as bool,canCoverRest: null == canCoverRest ? _self.canCoverRest : canCoverRest // ignore: cast_nullable_to_non_nullable
as bool,cancelReason: freezed == cancelReason ? _self.cancelReason : cancelReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of GroupOrder
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupRestaurantCopyWith<$Res> get restaurant {
  
  return $GroupRestaurantCopyWith<$Res>(_self.restaurant, (value) {
    return _then(_self.copyWith(restaurant: value));
  });
}/// Create a copy of GroupOrder
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupOrderRefCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $GroupOrderRefCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}/// Create a copy of GroupOrder
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupMyShareCopyWith<$Res>? get myShare {
    if (_self.myShare == null) {
    return null;
  }

  return $GroupMyShareCopyWith<$Res>(_self.myShare!, (value) {
    return _then(_self.copyWith(myShare: value));
  });
}
}


/// @nodoc
mixin _$WhatsAppStatus {

 bool get enabled; bool get linked; String? get number; DateTime? get linkedAt; String get businessNumber; String? get chatLink;
/// Create a copy of WhatsAppStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WhatsAppStatusCopyWith<WhatsAppStatus> get copyWith => _$WhatsAppStatusCopyWithImpl<WhatsAppStatus>(this as WhatsAppStatus, _$identity);

  /// Serializes this WhatsAppStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WhatsAppStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WhatsAppStatus&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.linked, _this.linked) || other.linked == _this.linked)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.linkedAt, _this.linkedAt) || other.linkedAt == _this.linkedAt)&&(identical(other.businessNumber, _this.businessNumber) || other.businessNumber == _this.businessNumber)&&(identical(other.chatLink, _this.chatLink) || other.chatLink == _this.chatLink));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WhatsAppStatus;
  return Object.hash(runtimeType,_this.enabled,_this.linked,_this.number,_this.linkedAt,_this.businessNumber,_this.chatLink);
}

@override
String toString() {
  final _this = this as WhatsAppStatus;
  return 'WhatsAppStatus(enabled: ${_this.enabled}, linked: ${_this.linked}, number: ${_this.number}, linkedAt: ${_this.linkedAt}, businessNumber: ${_this.businessNumber}, chatLink: ${_this.chatLink})';
}


}

/// @nodoc
abstract mixin class $WhatsAppStatusCopyWith<$Res>  {
  factory $WhatsAppStatusCopyWith(WhatsAppStatus value, $Res Function(WhatsAppStatus) _then) = _$WhatsAppStatusCopyWithImpl;
@useResult
$Res call({
 bool enabled, bool linked, String? number, DateTime? linkedAt, String businessNumber, String? chatLink
});




}
/// @nodoc
class _$WhatsAppStatusCopyWithImpl<$Res>
    implements $WhatsAppStatusCopyWith<$Res> {
  _$WhatsAppStatusCopyWithImpl(this._self, this._then);

  final WhatsAppStatus _self;
  final $Res Function(WhatsAppStatus) _then;

/// Create a copy of WhatsAppStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? linked = null,Object? number = freezed,Object? linkedAt = freezed,Object? businessNumber = null,Object? chatLink = freezed,}) {
  return _then(WhatsAppStatus(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,linked: null == linked ? _self.linked : linked // ignore: cast_nullable_to_non_nullable
as bool,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String?,linkedAt: freezed == linkedAt ? _self.linkedAt : linkedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,businessNumber: null == businessNumber ? _self.businessNumber : businessNumber // ignore: cast_nullable_to_non_nullable
as String,chatLink: freezed == chatLink ? _self.chatLink : chatLink // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WhatsAppStatus].
extension WhatsAppStatusPatterns on WhatsAppStatus {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WhatsAppStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WhatsAppStatus() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WhatsAppStatus value)  $default,){
final _that = this;
switch (_that) {
case _WhatsAppStatus():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WhatsAppStatus value)?  $default,){
final _that = this;
switch (_that) {
case _WhatsAppStatus() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  bool linked,  String? number,  DateTime? linkedAt,  String businessNumber,  String? chatLink)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WhatsAppStatus() when $default != null:
return $default(_that.enabled,_that.linked,_that.number,_that.linkedAt,_that.businessNumber,_that.chatLink);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  bool linked,  String? number,  DateTime? linkedAt,  String businessNumber,  String? chatLink)  $default,) {final _that = this;
switch (_that) {
case _WhatsAppStatus():
return $default(_that.enabled,_that.linked,_that.number,_that.linkedAt,_that.businessNumber,_that.chatLink);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  bool linked,  String? number,  DateTime? linkedAt,  String businessNumber,  String? chatLink)?  $default,) {final _that = this;
switch (_that) {
case _WhatsAppStatus() when $default != null:
return $default(_that.enabled,_that.linked,_that.number,_that.linkedAt,_that.businessNumber,_that.chatLink);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WhatsAppStatus implements WhatsAppStatus {
  const _WhatsAppStatus({this.enabled = false, this.linked = false, this.number, this.linkedAt, this.businessNumber = '', this.chatLink});
  factory _WhatsAppStatus.fromJson(Map<String, dynamic> json) => _$WhatsAppStatusFromJson(json);

@override@JsonKey() final  bool enabled;
@override@JsonKey() final  bool linked;
@override final  String? number;
@override final  DateTime? linkedAt;
@override@JsonKey() final  String businessNumber;
@override final  String? chatLink;

/// Create a copy of WhatsAppStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WhatsAppStatusCopyWith<_WhatsAppStatus> get copyWith => __$WhatsAppStatusCopyWithImpl<_WhatsAppStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WhatsAppStatusToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WhatsAppStatus&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.linked, linked) || other.linked == linked)&&(identical(other.number, number) || other.number == number)&&(identical(other.linkedAt, linkedAt) || other.linkedAt == linkedAt)&&(identical(other.businessNumber, businessNumber) || other.businessNumber == businessNumber)&&(identical(other.chatLink, chatLink) || other.chatLink == chatLink));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,enabled,linked,number,linkedAt,businessNumber,chatLink);
}

@override
String toString() {
    return 'WhatsAppStatus(enabled: $enabled, linked: $linked, number: $number, linkedAt: $linkedAt, businessNumber: $businessNumber, chatLink: $chatLink)';
}


}

/// @nodoc
abstract mixin class _$WhatsAppStatusCopyWith<$Res> implements $WhatsAppStatusCopyWith<$Res> {
  factory _$WhatsAppStatusCopyWith(_WhatsAppStatus value, $Res Function(_WhatsAppStatus) _then) = __$WhatsAppStatusCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, bool linked, String? number, DateTime? linkedAt, String businessNumber, String? chatLink
});




}
/// @nodoc
class __$WhatsAppStatusCopyWithImpl<$Res>
    implements _$WhatsAppStatusCopyWith<$Res> {
  __$WhatsAppStatusCopyWithImpl(this._self, this._then);

  final _WhatsAppStatus _self;
  final $Res Function(_WhatsAppStatus) _then;

/// Create a copy of WhatsAppStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? linked = null,Object? number = freezed,Object? linkedAt = freezed,Object? businessNumber = null,Object? chatLink = freezed,}) {
  return _then(_WhatsAppStatus(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,linked: null == linked ? _self.linked : linked // ignore: cast_nullable_to_non_nullable
as bool,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String?,linkedAt: freezed == linkedAt ? _self.linkedAt : linkedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,businessNumber: null == businessNumber ? _self.businessNumber : businessNumber // ignore: cast_nullable_to_non_nullable
as String,chatLink: freezed == chatLink ? _self.chatLink : chatLink // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$WhatsAppLinkCode {

 String get code; DateTime get expiresAt; String get businessNumber; String get waLink;
/// Create a copy of WhatsAppLinkCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WhatsAppLinkCodeCopyWith<WhatsAppLinkCode> get copyWith => _$WhatsAppLinkCodeCopyWithImpl<WhatsAppLinkCode>(this as WhatsAppLinkCode, _$identity);

  /// Serializes this WhatsAppLinkCode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WhatsAppLinkCode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WhatsAppLinkCode&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.businessNumber, _this.businessNumber) || other.businessNumber == _this.businessNumber)&&(identical(other.waLink, _this.waLink) || other.waLink == _this.waLink));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WhatsAppLinkCode;
  return Object.hash(runtimeType,_this.code,_this.expiresAt,_this.businessNumber,_this.waLink);
}

@override
String toString() {
  final _this = this as WhatsAppLinkCode;
  return 'WhatsAppLinkCode(code: ${_this.code}, expiresAt: ${_this.expiresAt}, businessNumber: ${_this.businessNumber}, waLink: ${_this.waLink})';
}


}

/// @nodoc
abstract mixin class $WhatsAppLinkCodeCopyWith<$Res>  {
  factory $WhatsAppLinkCodeCopyWith(WhatsAppLinkCode value, $Res Function(WhatsAppLinkCode) _then) = _$WhatsAppLinkCodeCopyWithImpl;
@useResult
$Res call({
 String code, DateTime expiresAt, String businessNumber, String waLink
});




}
/// @nodoc
class _$WhatsAppLinkCodeCopyWithImpl<$Res>
    implements $WhatsAppLinkCodeCopyWith<$Res> {
  _$WhatsAppLinkCodeCopyWithImpl(this._self, this._then);

  final WhatsAppLinkCode _self;
  final $Res Function(WhatsAppLinkCode) _then;

/// Create a copy of WhatsAppLinkCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? expiresAt = null,Object? businessNumber = null,Object? waLink = null,}) {
  return _then(WhatsAppLinkCode(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,businessNumber: null == businessNumber ? _self.businessNumber : businessNumber // ignore: cast_nullable_to_non_nullable
as String,waLink: null == waLink ? _self.waLink : waLink // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WhatsAppLinkCode].
extension WhatsAppLinkCodePatterns on WhatsAppLinkCode {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WhatsAppLinkCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WhatsAppLinkCode() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WhatsAppLinkCode value)  $default,){
final _that = this;
switch (_that) {
case _WhatsAppLinkCode():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WhatsAppLinkCode value)?  $default,){
final _that = this;
switch (_that) {
case _WhatsAppLinkCode() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  DateTime expiresAt,  String businessNumber,  String waLink)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WhatsAppLinkCode() when $default != null:
return $default(_that.code,_that.expiresAt,_that.businessNumber,_that.waLink);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  DateTime expiresAt,  String businessNumber,  String waLink)  $default,) {final _that = this;
switch (_that) {
case _WhatsAppLinkCode():
return $default(_that.code,_that.expiresAt,_that.businessNumber,_that.waLink);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  DateTime expiresAt,  String businessNumber,  String waLink)?  $default,) {final _that = this;
switch (_that) {
case _WhatsAppLinkCode() when $default != null:
return $default(_that.code,_that.expiresAt,_that.businessNumber,_that.waLink);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WhatsAppLinkCode implements WhatsAppLinkCode {
  const _WhatsAppLinkCode({required this.code, required this.expiresAt, this.businessNumber = '', required this.waLink});
  factory _WhatsAppLinkCode.fromJson(Map<String, dynamic> json) => _$WhatsAppLinkCodeFromJson(json);

@override final  String code;
@override final  DateTime expiresAt;
@override@JsonKey() final  String businessNumber;
@override final  String waLink;

/// Create a copy of WhatsAppLinkCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WhatsAppLinkCodeCopyWith<_WhatsAppLinkCode> get copyWith => __$WhatsAppLinkCodeCopyWithImpl<_WhatsAppLinkCode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WhatsAppLinkCodeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WhatsAppLinkCode&&(identical(other.code, code) || other.code == code)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.businessNumber, businessNumber) || other.businessNumber == businessNumber)&&(identical(other.waLink, waLink) || other.waLink == waLink));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,code,expiresAt,businessNumber,waLink);
}

@override
String toString() {
    return 'WhatsAppLinkCode(code: $code, expiresAt: $expiresAt, businessNumber: $businessNumber, waLink: $waLink)';
}


}

/// @nodoc
abstract mixin class _$WhatsAppLinkCodeCopyWith<$Res> implements $WhatsAppLinkCodeCopyWith<$Res> {
  factory _$WhatsAppLinkCodeCopyWith(_WhatsAppLinkCode value, $Res Function(_WhatsAppLinkCode) _then) = __$WhatsAppLinkCodeCopyWithImpl;
@override @useResult
$Res call({
 String code, DateTime expiresAt, String businessNumber, String waLink
});




}
/// @nodoc
class __$WhatsAppLinkCodeCopyWithImpl<$Res>
    implements _$WhatsAppLinkCodeCopyWith<$Res> {
  __$WhatsAppLinkCodeCopyWithImpl(this._self, this._then);

  final _WhatsAppLinkCode _self;
  final $Res Function(_WhatsAppLinkCode) _then;

/// Create a copy of WhatsAppLinkCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? expiresAt = null,Object? businessNumber = null,Object? waLink = null,}) {
  return _then(_WhatsAppLinkCode(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,businessNumber: null == businessNumber ? _self.businessNumber : businessNumber // ignore: cast_nullable_to_non_nullable
as String,waLink: null == waLink ? _self.waLink : waLink // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TopUpResult {

 String get reference; String get provider; String? get authorizationUrl; int get amountKobo;
/// Create a copy of TopUpResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopUpResultCopyWith<TopUpResult> get copyWith => _$TopUpResultCopyWithImpl<TopUpResult>(this as TopUpResult, _$identity);

  /// Serializes this TopUpResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TopUpResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopUpResult&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.authorizationUrl, _this.authorizationUrl) || other.authorizationUrl == _this.authorizationUrl)&&(identical(other.amountKobo, _this.amountKobo) || other.amountKobo == _this.amountKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TopUpResult;
  return Object.hash(runtimeType,_this.reference,_this.provider,_this.authorizationUrl,_this.amountKobo);
}

@override
String toString() {
  final _this = this as TopUpResult;
  return 'TopUpResult(reference: ${_this.reference}, provider: ${_this.provider}, authorizationUrl: ${_this.authorizationUrl}, amountKobo: ${_this.amountKobo})';
}


}

/// @nodoc
abstract mixin class $TopUpResultCopyWith<$Res>  {
  factory $TopUpResultCopyWith(TopUpResult value, $Res Function(TopUpResult) _then) = _$TopUpResultCopyWithImpl;
@useResult
$Res call({
 String reference, String provider, String? authorizationUrl, int amountKobo
});




}
/// @nodoc
class _$TopUpResultCopyWithImpl<$Res>
    implements $TopUpResultCopyWith<$Res> {
  _$TopUpResultCopyWithImpl(this._self, this._then);

  final TopUpResult _self;
  final $Res Function(TopUpResult) _then;

/// Create a copy of TopUpResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reference = null,Object? provider = null,Object? authorizationUrl = freezed,Object? amountKobo = null,}) {
  return _then(TopUpResult(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,authorizationUrl: freezed == authorizationUrl ? _self.authorizationUrl : authorizationUrl // ignore: cast_nullable_to_non_nullable
as String?,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TopUpResult].
extension TopUpResultPatterns on TopUpResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopUpResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopUpResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopUpResult value)  $default,){
final _that = this;
switch (_that) {
case _TopUpResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopUpResult value)?  $default,){
final _that = this;
switch (_that) {
case _TopUpResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String reference,  String provider,  String? authorizationUrl,  int amountKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopUpResult() when $default != null:
return $default(_that.reference,_that.provider,_that.authorizationUrl,_that.amountKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String reference,  String provider,  String? authorizationUrl,  int amountKobo)  $default,) {final _that = this;
switch (_that) {
case _TopUpResult():
return $default(_that.reference,_that.provider,_that.authorizationUrl,_that.amountKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String reference,  String provider,  String? authorizationUrl,  int amountKobo)?  $default,) {final _that = this;
switch (_that) {
case _TopUpResult() when $default != null:
return $default(_that.reference,_that.provider,_that.authorizationUrl,_that.amountKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TopUpResult implements TopUpResult {
  const _TopUpResult({required this.reference, required this.provider, this.authorizationUrl, required this.amountKobo});
  factory _TopUpResult.fromJson(Map<String, dynamic> json) => _$TopUpResultFromJson(json);

@override final  String reference;
@override final  String provider;
@override final  String? authorizationUrl;
@override final  int amountKobo;

/// Create a copy of TopUpResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopUpResultCopyWith<_TopUpResult> get copyWith => __$TopUpResultCopyWithImpl<_TopUpResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TopUpResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopUpResult&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.authorizationUrl, authorizationUrl) || other.authorizationUrl == authorizationUrl)&&(identical(other.amountKobo, amountKobo) || other.amountKobo == amountKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,reference,provider,authorizationUrl,amountKobo);
}

@override
String toString() {
    return 'TopUpResult(reference: $reference, provider: $provider, authorizationUrl: $authorizationUrl, amountKobo: $amountKobo)';
}


}

/// @nodoc
abstract mixin class _$TopUpResultCopyWith<$Res> implements $TopUpResultCopyWith<$Res> {
  factory _$TopUpResultCopyWith(_TopUpResult value, $Res Function(_TopUpResult) _then) = __$TopUpResultCopyWithImpl;
@override @useResult
$Res call({
 String reference, String provider, String? authorizationUrl, int amountKobo
});




}
/// @nodoc
class __$TopUpResultCopyWithImpl<$Res>
    implements _$TopUpResultCopyWith<$Res> {
  __$TopUpResultCopyWithImpl(this._self, this._then);

  final _TopUpResult _self;
  final $Res Function(_TopUpResult) _then;

/// Create a copy of TopUpResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reference = null,Object? provider = null,Object? authorizationUrl = freezed,Object? amountKobo = null,}) {
  return _then(_TopUpResult(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,authorizationUrl: freezed == authorizationUrl ? _self.authorizationUrl : authorizationUrl // ignore: cast_nullable_to_non_nullable
as String?,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Tracking {

 String get status; String? get riderName; GeoPoint? get riderLocation; int? get etaMinutes; DateTime? get estimatedDeliveryAt;
/// Create a copy of Tracking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackingCopyWith<Tracking> get copyWith => _$TrackingCopyWithImpl<Tracking>(this as Tracking, _$identity);

  /// Serializes this Tracking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Tracking;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Tracking&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.riderName, _this.riderName) || other.riderName == _this.riderName)&&(identical(other.riderLocation, _this.riderLocation) || other.riderLocation == _this.riderLocation)&&(identical(other.etaMinutes, _this.etaMinutes) || other.etaMinutes == _this.etaMinutes)&&(identical(other.estimatedDeliveryAt, _this.estimatedDeliveryAt) || other.estimatedDeliveryAt == _this.estimatedDeliveryAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Tracking;
  return Object.hash(runtimeType,_this.status,_this.riderName,_this.riderLocation,_this.etaMinutes,_this.estimatedDeliveryAt);
}

@override
String toString() {
  final _this = this as Tracking;
  return 'Tracking(status: ${_this.status}, riderName: ${_this.riderName}, riderLocation: ${_this.riderLocation}, etaMinutes: ${_this.etaMinutes}, estimatedDeliveryAt: ${_this.estimatedDeliveryAt})';
}


}

/// @nodoc
abstract mixin class $TrackingCopyWith<$Res>  {
  factory $TrackingCopyWith(Tracking value, $Res Function(Tracking) _then) = _$TrackingCopyWithImpl;
@useResult
$Res call({
 String status, String? riderName, GeoPoint? riderLocation, int? etaMinutes, DateTime? estimatedDeliveryAt
});


$GeoPointCopyWith<$Res>? get riderLocation;

}
/// @nodoc
class _$TrackingCopyWithImpl<$Res>
    implements $TrackingCopyWith<$Res> {
  _$TrackingCopyWithImpl(this._self, this._then);

  final Tracking _self;
  final $Res Function(Tracking) _then;

/// Create a copy of Tracking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? riderName = freezed,Object? riderLocation = freezed,Object? etaMinutes = freezed,Object? estimatedDeliveryAt = freezed,}) {
  return _then(Tracking(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,riderName: freezed == riderName ? _self.riderName : riderName // ignore: cast_nullable_to_non_nullable
as String?,riderLocation: freezed == riderLocation ? _self.riderLocation : riderLocation // ignore: cast_nullable_to_non_nullable
as GeoPoint?,etaMinutes: freezed == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as int?,estimatedDeliveryAt: freezed == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Tracking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get riderLocation {
    if (_self.riderLocation == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.riderLocation!, (value) {
    return _then(_self.copyWith(riderLocation: value));
  });
}
}


/// Adds pattern-matching-related methods to [Tracking].
extension TrackingPatterns on Tracking {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Tracking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Tracking() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Tracking value)  $default,){
final _that = this;
switch (_that) {
case _Tracking():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Tracking value)?  $default,){
final _that = this;
switch (_that) {
case _Tracking() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String? riderName,  GeoPoint? riderLocation,  int? etaMinutes,  DateTime? estimatedDeliveryAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Tracking() when $default != null:
return $default(_that.status,_that.riderName,_that.riderLocation,_that.etaMinutes,_that.estimatedDeliveryAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String? riderName,  GeoPoint? riderLocation,  int? etaMinutes,  DateTime? estimatedDeliveryAt)  $default,) {final _that = this;
switch (_that) {
case _Tracking():
return $default(_that.status,_that.riderName,_that.riderLocation,_that.etaMinutes,_that.estimatedDeliveryAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String? riderName,  GeoPoint? riderLocation,  int? etaMinutes,  DateTime? estimatedDeliveryAt)?  $default,) {final _that = this;
switch (_that) {
case _Tracking() when $default != null:
return $default(_that.status,_that.riderName,_that.riderLocation,_that.etaMinutes,_that.estimatedDeliveryAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Tracking implements Tracking {
  const _Tracking({required this.status, this.riderName, this.riderLocation, this.etaMinutes, this.estimatedDeliveryAt});
  factory _Tracking.fromJson(Map<String, dynamic> json) => _$TrackingFromJson(json);

@override final  String status;
@override final  String? riderName;
@override final  GeoPoint? riderLocation;
@override final  int? etaMinutes;
@override final  DateTime? estimatedDeliveryAt;

/// Create a copy of Tracking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackingCopyWith<_Tracking> get copyWith => __$TrackingCopyWithImpl<_Tracking>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Tracking&&(identical(other.status, status) || other.status == status)&&(identical(other.riderName, riderName) || other.riderName == riderName)&&(identical(other.riderLocation, riderLocation) || other.riderLocation == riderLocation)&&(identical(other.etaMinutes, etaMinutes) || other.etaMinutes == etaMinutes)&&(identical(other.estimatedDeliveryAt, estimatedDeliveryAt) || other.estimatedDeliveryAt == estimatedDeliveryAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,status,riderName,riderLocation,etaMinutes,estimatedDeliveryAt);
}

@override
String toString() {
    return 'Tracking(status: $status, riderName: $riderName, riderLocation: $riderLocation, etaMinutes: $etaMinutes, estimatedDeliveryAt: $estimatedDeliveryAt)';
}


}

/// @nodoc
abstract mixin class _$TrackingCopyWith<$Res> implements $TrackingCopyWith<$Res> {
  factory _$TrackingCopyWith(_Tracking value, $Res Function(_Tracking) _then) = __$TrackingCopyWithImpl;
@override @useResult
$Res call({
 String status, String? riderName, GeoPoint? riderLocation, int? etaMinutes, DateTime? estimatedDeliveryAt
});


@override $GeoPointCopyWith<$Res>? get riderLocation;

}
/// @nodoc
class __$TrackingCopyWithImpl<$Res>
    implements _$TrackingCopyWith<$Res> {
  __$TrackingCopyWithImpl(this._self, this._then);

  final _Tracking _self;
  final $Res Function(_Tracking) _then;

/// Create a copy of Tracking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? riderName = freezed,Object? riderLocation = freezed,Object? etaMinutes = freezed,Object? estimatedDeliveryAt = freezed,}) {
  return _then(_Tracking(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,riderName: freezed == riderName ? _self.riderName : riderName // ignore: cast_nullable_to_non_nullable
as String?,riderLocation: freezed == riderLocation ? _self.riderLocation : riderLocation // ignore: cast_nullable_to_non_nullable
as GeoPoint?,etaMinutes: freezed == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as int?,estimatedDeliveryAt: freezed == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Tracking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get riderLocation {
    if (_self.riderLocation == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.riderLocation!, (value) {
    return _then(_self.copyWith(riderLocation: value));
  });
}
}


/// @nodoc
mixin _$DeliveryOffer {

 String get id; String get orderId; String get restaurantName; double get distanceToRestaurantKm; int get payoutKobo; DateTime get expiresAt; GeoPoint get pickup; GeoPoint? get dropoff; String? get dropoffArea;/// Every order this offer covers: one for a normal job, several for a mixed cart (one trip, one rider).
 List<String> get tripOrderIds;/// The places to collect from (one per order of the trip).
 List<OfferPickup> get pickups;/// Seconds left when the API answered, by the server's clock (apps count down from it; null on older servers).
 int? get expiresInSeconds;
/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryOfferCopyWith<DeliveryOffer> get copyWith => _$DeliveryOfferCopyWithImpl<DeliveryOffer>(this as DeliveryOffer, _$identity);

  /// Serializes this DeliveryOffer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DeliveryOffer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryOffer&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.orderId, _this.orderId) || other.orderId == _this.orderId)&&(identical(other.restaurantName, _this.restaurantName) || other.restaurantName == _this.restaurantName)&&(identical(other.distanceToRestaurantKm, _this.distanceToRestaurantKm) || other.distanceToRestaurantKm == _this.distanceToRestaurantKm)&&(identical(other.payoutKobo, _this.payoutKobo) || other.payoutKobo == _this.payoutKobo)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.pickup, _this.pickup) || other.pickup == _this.pickup)&&(identical(other.dropoff, _this.dropoff) || other.dropoff == _this.dropoff)&&(identical(other.dropoffArea, _this.dropoffArea) || other.dropoffArea == _this.dropoffArea)&&const DeepCollectionEquality().equals(other.tripOrderIds, _this.tripOrderIds)&&const DeepCollectionEquality().equals(other.pickups, _this.pickups)&&(identical(other.expiresInSeconds, _this.expiresInSeconds) || other.expiresInSeconds == _this.expiresInSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DeliveryOffer;
  return Object.hash(runtimeType,_this.id,_this.orderId,_this.restaurantName,_this.distanceToRestaurantKm,_this.payoutKobo,_this.expiresAt,_this.pickup,_this.dropoff,_this.dropoffArea,const DeepCollectionEquality().hash(_this.tripOrderIds),const DeepCollectionEquality().hash(_this.pickups),_this.expiresInSeconds);
}

@override
String toString() {
  final _this = this as DeliveryOffer;
  return 'DeliveryOffer(id: ${_this.id}, orderId: ${_this.orderId}, restaurantName: ${_this.restaurantName}, distanceToRestaurantKm: ${_this.distanceToRestaurantKm}, payoutKobo: ${_this.payoutKobo}, expiresAt: ${_this.expiresAt}, pickup: ${_this.pickup}, dropoff: ${_this.dropoff}, dropoffArea: ${_this.dropoffArea}, tripOrderIds: ${_this.tripOrderIds}, pickups: ${_this.pickups}, expiresInSeconds: ${_this.expiresInSeconds})';
}


}

/// @nodoc
abstract mixin class $DeliveryOfferCopyWith<$Res>  {
  factory $DeliveryOfferCopyWith(DeliveryOffer value, $Res Function(DeliveryOffer) _then) = _$DeliveryOfferCopyWithImpl;
@useResult
$Res call({
 String id, String orderId, String restaurantName, double distanceToRestaurantKm, int payoutKobo, DateTime expiresAt, GeoPoint pickup, GeoPoint? dropoff, String? dropoffArea, List<String> tripOrderIds, List<OfferPickup> pickups, int? expiresInSeconds
});


$GeoPointCopyWith<$Res> get pickup;$GeoPointCopyWith<$Res>? get dropoff;

}
/// @nodoc
class _$DeliveryOfferCopyWithImpl<$Res>
    implements $DeliveryOfferCopyWith<$Res> {
  _$DeliveryOfferCopyWithImpl(this._self, this._then);

  final DeliveryOffer _self;
  final $Res Function(DeliveryOffer) _then;

/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = null,Object? restaurantName = null,Object? distanceToRestaurantKm = null,Object? payoutKobo = null,Object? expiresAt = null,Object? pickup = null,Object? dropoff = freezed,Object? dropoffArea = freezed,Object? tripOrderIds = null,Object? pickups = null,Object? expiresInSeconds = freezed,}) {
  return _then(DeliveryOffer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,restaurantName: null == restaurantName ? _self.restaurantName : restaurantName // ignore: cast_nullable_to_non_nullable
as String,distanceToRestaurantKm: null == distanceToRestaurantKm ? _self.distanceToRestaurantKm : distanceToRestaurantKm // ignore: cast_nullable_to_non_nullable
as double,payoutKobo: null == payoutKobo ? _self.payoutKobo : payoutKobo // ignore: cast_nullable_to_non_nullable
as int,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as GeoPoint,dropoff: freezed == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as GeoPoint?,dropoffArea: freezed == dropoffArea ? _self.dropoffArea : dropoffArea // ignore: cast_nullable_to_non_nullable
as String?,tripOrderIds: null == tripOrderIds ? _self.tripOrderIds : tripOrderIds // ignore: cast_nullable_to_non_nullable
as List<String>,pickups: null == pickups ? _self.pickups : pickups // ignore: cast_nullable_to_non_nullable
as List<OfferPickup>,expiresInSeconds: freezed == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get pickup {
  
  return $GeoPointCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get dropoff {
    if (_self.dropoff == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.dropoff!, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}
}


/// Adds pattern-matching-related methods to [DeliveryOffer].
extension DeliveryOfferPatterns on DeliveryOffer {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryOffer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryOffer() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryOffer value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryOffer():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryOffer value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryOffer() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String orderId,  String restaurantName,  double distanceToRestaurantKm,  int payoutKobo,  DateTime expiresAt,  GeoPoint pickup,  GeoPoint? dropoff,  String? dropoffArea,  List<String> tripOrderIds,  List<OfferPickup> pickups,  int? expiresInSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryOffer() when $default != null:
return $default(_that.id,_that.orderId,_that.restaurantName,_that.distanceToRestaurantKm,_that.payoutKobo,_that.expiresAt,_that.pickup,_that.dropoff,_that.dropoffArea,_that.tripOrderIds,_that.pickups,_that.expiresInSeconds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String orderId,  String restaurantName,  double distanceToRestaurantKm,  int payoutKobo,  DateTime expiresAt,  GeoPoint pickup,  GeoPoint? dropoff,  String? dropoffArea,  List<String> tripOrderIds,  List<OfferPickup> pickups,  int? expiresInSeconds)  $default,) {final _that = this;
switch (_that) {
case _DeliveryOffer():
return $default(_that.id,_that.orderId,_that.restaurantName,_that.distanceToRestaurantKm,_that.payoutKobo,_that.expiresAt,_that.pickup,_that.dropoff,_that.dropoffArea,_that.tripOrderIds,_that.pickups,_that.expiresInSeconds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String orderId,  String restaurantName,  double distanceToRestaurantKm,  int payoutKobo,  DateTime expiresAt,  GeoPoint pickup,  GeoPoint? dropoff,  String? dropoffArea,  List<String> tripOrderIds,  List<OfferPickup> pickups,  int? expiresInSeconds)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryOffer() when $default != null:
return $default(_that.id,_that.orderId,_that.restaurantName,_that.distanceToRestaurantKm,_that.payoutKobo,_that.expiresAt,_that.pickup,_that.dropoff,_that.dropoffArea,_that.tripOrderIds,_that.pickups,_that.expiresInSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeliveryOffer implements DeliveryOffer {
  const _DeliveryOffer({required this.id, required this.orderId, required this.restaurantName, required this.distanceToRestaurantKm, required this.payoutKobo, required this.expiresAt, required this.pickup, this.dropoff, this.dropoffArea,  List<String> tripOrderIds = const <String>[],  List<OfferPickup> pickups = const <OfferPickup>[], this.expiresInSeconds}): _tripOrderIds = tripOrderIds,_pickups = pickups;
  factory _DeliveryOffer.fromJson(Map<String, dynamic> json) => _$DeliveryOfferFromJson(json);

@override final  String id;
@override final  String orderId;
@override final  String restaurantName;
@override final  double distanceToRestaurantKm;
@override final  int payoutKobo;
@override final  DateTime expiresAt;
@override final  GeoPoint pickup;
@override final  GeoPoint? dropoff;
@override final  String? dropoffArea;
/// Every order this offer covers: one for a normal job, several for a mixed cart (one trip, one rider).
 final  List<String> _tripOrderIds;
/// Every order this offer covers: one for a normal job, several for a mixed cart (one trip, one rider).
@override@JsonKey() List<String> get tripOrderIds {
  if (_tripOrderIds is EqualUnmodifiableListView) return _tripOrderIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tripOrderIds);
}

/// The places to collect from (one per order of the trip).
 final  List<OfferPickup> _pickups;
/// The places to collect from (one per order of the trip).
@override@JsonKey() List<OfferPickup> get pickups {
  if (_pickups is EqualUnmodifiableListView) return _pickups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pickups);
}

/// Seconds left when the API answered, by the server's clock (apps count down from it; null on older servers).
@override final  int? expiresInSeconds;

/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryOfferCopyWith<_DeliveryOffer> get copyWith => __$DeliveryOfferCopyWithImpl<_DeliveryOffer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeliveryOfferToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryOffer&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.restaurantName, restaurantName) || other.restaurantName == restaurantName)&&(identical(other.distanceToRestaurantKm, distanceToRestaurantKm) || other.distanceToRestaurantKm == distanceToRestaurantKm)&&(identical(other.payoutKobo, payoutKobo) || other.payoutKobo == payoutKobo)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff)&&(identical(other.dropoffArea, dropoffArea) || other.dropoffArea == dropoffArea)&&const DeepCollectionEquality().equals(other.tripOrderIds, _tripOrderIds)&&const DeepCollectionEquality().equals(other.pickups, _pickups)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,orderId,restaurantName,distanceToRestaurantKm,payoutKobo,expiresAt,pickup,dropoff,dropoffArea,const DeepCollectionEquality().hash(_tripOrderIds),const DeepCollectionEquality().hash(_pickups),expiresInSeconds);
}

@override
String toString() {
    return 'DeliveryOffer(id: $id, orderId: $orderId, restaurantName: $restaurantName, distanceToRestaurantKm: $distanceToRestaurantKm, payoutKobo: $payoutKobo, expiresAt: $expiresAt, pickup: $pickup, dropoff: $dropoff, dropoffArea: $dropoffArea, tripOrderIds: $tripOrderIds, pickups: $pickups, expiresInSeconds: $expiresInSeconds)';
}


}

/// @nodoc
abstract mixin class _$DeliveryOfferCopyWith<$Res> implements $DeliveryOfferCopyWith<$Res> {
  factory _$DeliveryOfferCopyWith(_DeliveryOffer value, $Res Function(_DeliveryOffer) _then) = __$DeliveryOfferCopyWithImpl;
@override @useResult
$Res call({
 String id, String orderId, String restaurantName, double distanceToRestaurantKm, int payoutKobo, DateTime expiresAt, GeoPoint pickup, GeoPoint? dropoff, String? dropoffArea, List<String> tripOrderIds, List<OfferPickup> pickups, int? expiresInSeconds
});


@override $GeoPointCopyWith<$Res> get pickup;@override $GeoPointCopyWith<$Res>? get dropoff;

}
/// @nodoc
class __$DeliveryOfferCopyWithImpl<$Res>
    implements _$DeliveryOfferCopyWith<$Res> {
  __$DeliveryOfferCopyWithImpl(this._self, this._then);

  final _DeliveryOffer _self;
  final $Res Function(_DeliveryOffer) _then;

/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = null,Object? restaurantName = null,Object? distanceToRestaurantKm = null,Object? payoutKobo = null,Object? expiresAt = null,Object? pickup = null,Object? dropoff = freezed,Object? dropoffArea = freezed,Object? tripOrderIds = null,Object? pickups = null,Object? expiresInSeconds = freezed,}) {
  return _then(_DeliveryOffer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,restaurantName: null == restaurantName ? _self.restaurantName : restaurantName // ignore: cast_nullable_to_non_nullable
as String,distanceToRestaurantKm: null == distanceToRestaurantKm ? _self.distanceToRestaurantKm : distanceToRestaurantKm // ignore: cast_nullable_to_non_nullable
as double,payoutKobo: null == payoutKobo ? _self.payoutKobo : payoutKobo // ignore: cast_nullable_to_non_nullable
as int,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as GeoPoint,dropoff: freezed == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as GeoPoint?,dropoffArea: freezed == dropoffArea ? _self.dropoffArea : dropoffArea // ignore: cast_nullable_to_non_nullable
as String?,tripOrderIds: null == tripOrderIds ? _self._tripOrderIds : tripOrderIds // ignore: cast_nullable_to_non_nullable
as List<String>,pickups: null == pickups ? _self._pickups : pickups // ignore: cast_nullable_to_non_nullable
as List<OfferPickup>,expiresInSeconds: freezed == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get pickup {
  
  return $GeoPointCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of DeliveryOffer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get dropoff {
    if (_self.dropoff == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.dropoff!, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}
}


/// @nodoc
mixin _$OfferPickup {

 String get orderId; String get name; String? get address; GeoPoint? get location;
/// Create a copy of OfferPickup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfferPickupCopyWith<OfferPickup> get copyWith => _$OfferPickupCopyWithImpl<OfferPickup>(this as OfferPickup, _$identity);

  /// Serializes this OfferPickup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OfferPickup;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OfferPickup&&(identical(other.orderId, _this.orderId) || other.orderId == _this.orderId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.location, _this.location) || other.location == _this.location));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OfferPickup;
  return Object.hash(runtimeType,_this.orderId,_this.name,_this.address,_this.location);
}

@override
String toString() {
  final _this = this as OfferPickup;
  return 'OfferPickup(orderId: ${_this.orderId}, name: ${_this.name}, address: ${_this.address}, location: ${_this.location})';
}


}

/// @nodoc
abstract mixin class $OfferPickupCopyWith<$Res>  {
  factory $OfferPickupCopyWith(OfferPickup value, $Res Function(OfferPickup) _then) = _$OfferPickupCopyWithImpl;
@useResult
$Res call({
 String orderId, String name, String? address, GeoPoint? location
});


$GeoPointCopyWith<$Res>? get location;

}
/// @nodoc
class _$OfferPickupCopyWithImpl<$Res>
    implements $OfferPickupCopyWith<$Res> {
  _$OfferPickupCopyWithImpl(this._self, this._then);

  final OfferPickup _self;
  final $Res Function(OfferPickup) _then;

/// Create a copy of OfferPickup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? name = null,Object? address = freezed,Object? location = freezed,}) {
  return _then(OfferPickup(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint?,
  ));
}
/// Create a copy of OfferPickup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [OfferPickup].
extension OfferPickupPatterns on OfferPickup {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OfferPickup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OfferPickup() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OfferPickup value)  $default,){
final _that = this;
switch (_that) {
case _OfferPickup():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OfferPickup value)?  $default,){
final _that = this;
switch (_that) {
case _OfferPickup() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String orderId,  String name,  String? address,  GeoPoint? location)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OfferPickup() when $default != null:
return $default(_that.orderId,_that.name,_that.address,_that.location);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String orderId,  String name,  String? address,  GeoPoint? location)  $default,) {final _that = this;
switch (_that) {
case _OfferPickup():
return $default(_that.orderId,_that.name,_that.address,_that.location);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String orderId,  String name,  String? address,  GeoPoint? location)?  $default,) {final _that = this;
switch (_that) {
case _OfferPickup() when $default != null:
return $default(_that.orderId,_that.name,_that.address,_that.location);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OfferPickup implements OfferPickup {
  const _OfferPickup({required this.orderId, this.name = '', this.address, this.location});
  factory _OfferPickup.fromJson(Map<String, dynamic> json) => _$OfferPickupFromJson(json);

@override final  String orderId;
@override@JsonKey() final  String name;
@override final  String? address;
@override final  GeoPoint? location;

/// Create a copy of OfferPickup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OfferPickupCopyWith<_OfferPickup> get copyWith => __$OfferPickupCopyWithImpl<_OfferPickup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OfferPickupToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OfferPickup&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.location, location) || other.location == location));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,orderId,name,address,location);
}

@override
String toString() {
    return 'OfferPickup(orderId: $orderId, name: $name, address: $address, location: $location)';
}


}

/// @nodoc
abstract mixin class _$OfferPickupCopyWith<$Res> implements $OfferPickupCopyWith<$Res> {
  factory _$OfferPickupCopyWith(_OfferPickup value, $Res Function(_OfferPickup) _then) = __$OfferPickupCopyWithImpl;
@override @useResult
$Res call({
 String orderId, String name, String? address, GeoPoint? location
});


@override $GeoPointCopyWith<$Res>? get location;

}
/// @nodoc
class __$OfferPickupCopyWithImpl<$Res>
    implements _$OfferPickupCopyWith<$Res> {
  __$OfferPickupCopyWithImpl(this._self, this._then);

  final _OfferPickup _self;
  final $Res Function(_OfferPickup) _then;

/// Create a copy of OfferPickup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? name = null,Object? address = freezed,Object? location = freezed,}) {
  return _then(_OfferPickup(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint?,
  ));
}

/// Create a copy of OfferPickup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// @nodoc
mixin _$TripItem {

 String get name; int get quantity; List<String> get options;
/// Create a copy of TripItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripItemCopyWith<TripItem> get copyWith => _$TripItemCopyWithImpl<TripItem>(this as TripItem, _$identity);

  /// Serializes this TripItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TripItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripItem&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&const DeepCollectionEquality().equals(other.options, _this.options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TripItem;
  return Object.hash(runtimeType,_this.name,_this.quantity,const DeepCollectionEquality().hash(_this.options));
}

@override
String toString() {
  final _this = this as TripItem;
  return 'TripItem(name: ${_this.name}, quantity: ${_this.quantity}, options: ${_this.options})';
}


}

/// @nodoc
abstract mixin class $TripItemCopyWith<$Res>  {
  factory $TripItemCopyWith(TripItem value, $Res Function(TripItem) _then) = _$TripItemCopyWithImpl;
@useResult
$Res call({
 String name, int quantity, List<String> options
});




}
/// @nodoc
class _$TripItemCopyWithImpl<$Res>
    implements $TripItemCopyWith<$Res> {
  _$TripItemCopyWithImpl(this._self, this._then);

  final TripItem _self;
  final $Res Function(TripItem) _then;

/// Create a copy of TripItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? quantity = null,Object? options = null,}) {
  return _then(TripItem(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [TripItem].
extension TripItemPatterns on TripItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripItem value)  $default,){
final _that = this;
switch (_that) {
case _TripItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripItem value)?  $default,){
final _that = this;
switch (_that) {
case _TripItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int quantity,  List<String> options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripItem() when $default != null:
return $default(_that.name,_that.quantity,_that.options);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int quantity,  List<String> options)  $default,) {final _that = this;
switch (_that) {
case _TripItem():
return $default(_that.name,_that.quantity,_that.options);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int quantity,  List<String> options)?  $default,) {final _that = this;
switch (_that) {
case _TripItem() when $default != null:
return $default(_that.name,_that.quantity,_that.options);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripItem implements TripItem {
  const _TripItem({required this.name, this.quantity = 1,  List<String> options = const <String>[]}): _options = options;
  factory _TripItem.fromJson(Map<String, dynamic> json) => _$TripItemFromJson(json);

@override final  String name;
@override@JsonKey() final  int quantity;
 final  List<String> _options;
@override@JsonKey() List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


/// Create a copy of TripItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripItemCopyWith<_TripItem> get copyWith => __$TripItemCopyWithImpl<_TripItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripItem&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&const DeepCollectionEquality().equals(other.options, _options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,quantity,const DeepCollectionEquality().hash(_options));
}

@override
String toString() {
    return 'TripItem(name: $name, quantity: $quantity, options: $options)';
}


}

/// @nodoc
abstract mixin class _$TripItemCopyWith<$Res> implements $TripItemCopyWith<$Res> {
  factory _$TripItemCopyWith(_TripItem value, $Res Function(_TripItem) _then) = __$TripItemCopyWithImpl;
@override @useResult
$Res call({
 String name, int quantity, List<String> options
});




}
/// @nodoc
class __$TripItemCopyWithImpl<$Res>
    implements _$TripItemCopyWith<$Res> {
  __$TripItemCopyWithImpl(this._self, this._then);

  final _TripItem _self;
  final $Res Function(_TripItem) _then;

/// Create a copy of TripItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? quantity = null,Object? options = null,}) {
  return _then(_TripItem(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$TripStop {

 String get kind; String? get orderId; List<String> get orderIds; String? get shortCode; String get name; String? get vertical; String? get address; GeoPoint? get location; String? get phone; List<TripItem> get items; String? get status; bool get ready; bool get done; String? get instructions; int get cashToCollectKobo; double? get legKm; int? get legMinutes;
/// Create a copy of TripStop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripStopCopyWith<TripStop> get copyWith => _$TripStopCopyWithImpl<TripStop>(this as TripStop, _$identity);

  /// Serializes this TripStop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TripStop;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripStop&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.orderId, _this.orderId) || other.orderId == _this.orderId)&&const DeepCollectionEquality().equals(other.orderIds, _this.orderIds)&&(identical(other.shortCode, _this.shortCode) || other.shortCode == _this.shortCode)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.vertical, _this.vertical) || other.vertical == _this.vertical)&&(identical(other.address, _this.address) || other.address == _this.address)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.ready, _this.ready) || other.ready == _this.ready)&&(identical(other.done, _this.done) || other.done == _this.done)&&(identical(other.instructions, _this.instructions) || other.instructions == _this.instructions)&&(identical(other.cashToCollectKobo, _this.cashToCollectKobo) || other.cashToCollectKobo == _this.cashToCollectKobo)&&(identical(other.legKm, _this.legKm) || other.legKm == _this.legKm)&&(identical(other.legMinutes, _this.legMinutes) || other.legMinutes == _this.legMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TripStop;
  return Object.hash(runtimeType,_this.kind,_this.orderId,const DeepCollectionEquality().hash(_this.orderIds),_this.shortCode,_this.name,_this.vertical,_this.address,_this.location,_this.phone,const DeepCollectionEquality().hash(_this.items),_this.status,_this.ready,_this.done,_this.instructions,_this.cashToCollectKobo,_this.legKm,_this.legMinutes);
}

@override
String toString() {
  final _this = this as TripStop;
  return 'TripStop(kind: ${_this.kind}, orderId: ${_this.orderId}, orderIds: ${_this.orderIds}, shortCode: ${_this.shortCode}, name: ${_this.name}, vertical: ${_this.vertical}, address: ${_this.address}, location: ${_this.location}, phone: ${_this.phone}, items: ${_this.items}, status: ${_this.status}, ready: ${_this.ready}, done: ${_this.done}, instructions: ${_this.instructions}, cashToCollectKobo: ${_this.cashToCollectKobo}, legKm: ${_this.legKm}, legMinutes: ${_this.legMinutes})';
}


}

/// @nodoc
abstract mixin class $TripStopCopyWith<$Res>  {
  factory $TripStopCopyWith(TripStop value, $Res Function(TripStop) _then) = _$TripStopCopyWithImpl;
@useResult
$Res call({
 String kind, String? orderId, List<String> orderIds, String? shortCode, String name, String? vertical, String? address, GeoPoint? location, String? phone, List<TripItem> items, String? status, bool ready, bool done, String? instructions, int cashToCollectKobo, double? legKm, int? legMinutes
});


$GeoPointCopyWith<$Res>? get location;

}
/// @nodoc
class _$TripStopCopyWithImpl<$Res>
    implements $TripStopCopyWith<$Res> {
  _$TripStopCopyWithImpl(this._self, this._then);

  final TripStop _self;
  final $Res Function(TripStop) _then;

/// Create a copy of TripStop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? orderId = freezed,Object? orderIds = null,Object? shortCode = freezed,Object? name = null,Object? vertical = freezed,Object? address = freezed,Object? location = freezed,Object? phone = freezed,Object? items = null,Object? status = freezed,Object? ready = null,Object? done = null,Object? instructions = freezed,Object? cashToCollectKobo = null,Object? legKm = freezed,Object? legMinutes = freezed,}) {
  return _then(TripStop(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,orderIds: null == orderIds ? _self.orderIds : orderIds // ignore: cast_nullable_to_non_nullable
as List<String>,shortCode: freezed == shortCode ? _self.shortCode : shortCode // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,vertical: freezed == vertical ? _self.vertical : vertical // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<TripItem>,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,cashToCollectKobo: null == cashToCollectKobo ? _self.cashToCollectKobo : cashToCollectKobo // ignore: cast_nullable_to_non_nullable
as int,legKm: freezed == legKm ? _self.legKm : legKm // ignore: cast_nullable_to_non_nullable
as double?,legMinutes: freezed == legMinutes ? _self.legMinutes : legMinutes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of TripStop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [TripStop].
extension TripStopPatterns on TripStop {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripStop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripStop() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripStop value)  $default,){
final _that = this;
switch (_that) {
case _TripStop():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripStop value)?  $default,){
final _that = this;
switch (_that) {
case _TripStop() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String? orderId,  List<String> orderIds,  String? shortCode,  String name,  String? vertical,  String? address,  GeoPoint? location,  String? phone,  List<TripItem> items,  String? status,  bool ready,  bool done,  String? instructions,  int cashToCollectKobo,  double? legKm,  int? legMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripStop() when $default != null:
return $default(_that.kind,_that.orderId,_that.orderIds,_that.shortCode,_that.name,_that.vertical,_that.address,_that.location,_that.phone,_that.items,_that.status,_that.ready,_that.done,_that.instructions,_that.cashToCollectKobo,_that.legKm,_that.legMinutes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String? orderId,  List<String> orderIds,  String? shortCode,  String name,  String? vertical,  String? address,  GeoPoint? location,  String? phone,  List<TripItem> items,  String? status,  bool ready,  bool done,  String? instructions,  int cashToCollectKobo,  double? legKm,  int? legMinutes)  $default,) {final _that = this;
switch (_that) {
case _TripStop():
return $default(_that.kind,_that.orderId,_that.orderIds,_that.shortCode,_that.name,_that.vertical,_that.address,_that.location,_that.phone,_that.items,_that.status,_that.ready,_that.done,_that.instructions,_that.cashToCollectKobo,_that.legKm,_that.legMinutes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String? orderId,  List<String> orderIds,  String? shortCode,  String name,  String? vertical,  String? address,  GeoPoint? location,  String? phone,  List<TripItem> items,  String? status,  bool ready,  bool done,  String? instructions,  int cashToCollectKobo,  double? legKm,  int? legMinutes)?  $default,) {final _that = this;
switch (_that) {
case _TripStop() when $default != null:
return $default(_that.kind,_that.orderId,_that.orderIds,_that.shortCode,_that.name,_that.vertical,_that.address,_that.location,_that.phone,_that.items,_that.status,_that.ready,_that.done,_that.instructions,_that.cashToCollectKobo,_that.legKm,_that.legMinutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripStop extends TripStop {
  const _TripStop({required this.kind, this.orderId,  List<String> orderIds = const <String>[], this.shortCode, this.name = '', this.vertical, this.address, this.location, this.phone,  List<TripItem> items = const <TripItem>[], this.status, this.ready = false, this.done = false, this.instructions, this.cashToCollectKobo = 0, this.legKm, this.legMinutes}): _orderIds = orderIds,_items = items,super._();
  factory _TripStop.fromJson(Map<String, dynamic> json) => _$TripStopFromJson(json);

@override final  String kind;
@override final  String? orderId;
 final  List<String> _orderIds;
@override@JsonKey() List<String> get orderIds {
  if (_orderIds is EqualUnmodifiableListView) return _orderIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orderIds);
}

@override final  String? shortCode;
@override@JsonKey() final  String name;
@override final  String? vertical;
@override final  String? address;
@override final  GeoPoint? location;
@override final  String? phone;
 final  List<TripItem> _items;
@override@JsonKey() List<TripItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? status;
@override@JsonKey() final  bool ready;
@override@JsonKey() final  bool done;
@override final  String? instructions;
@override@JsonKey() final  int cashToCollectKobo;
@override final  double? legKm;
@override final  int? legMinutes;

/// Create a copy of TripStop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripStopCopyWith<_TripStop> get copyWith => __$TripStopCopyWithImpl<_TripStop>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripStopToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripStop&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&const DeepCollectionEquality().equals(other.orderIds, _orderIds)&&(identical(other.shortCode, shortCode) || other.shortCode == shortCode)&&(identical(other.name, name) || other.name == name)&&(identical(other.vertical, vertical) || other.vertical == vertical)&&(identical(other.address, address) || other.address == address)&&(identical(other.location, location) || other.location == location)&&(identical(other.phone, phone) || other.phone == phone)&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.status, status) || other.status == status)&&(identical(other.ready, ready) || other.ready == ready)&&(identical(other.done, done) || other.done == done)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.cashToCollectKobo, cashToCollectKobo) || other.cashToCollectKobo == cashToCollectKobo)&&(identical(other.legKm, legKm) || other.legKm == legKm)&&(identical(other.legMinutes, legMinutes) || other.legMinutes == legMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,orderId,const DeepCollectionEquality().hash(_orderIds),shortCode,name,vertical,address,location,phone,const DeepCollectionEquality().hash(_items),status,ready,done,instructions,cashToCollectKobo,legKm,legMinutes);
}

@override
String toString() {
    return 'TripStop(kind: $kind, orderId: $orderId, orderIds: $orderIds, shortCode: $shortCode, name: $name, vertical: $vertical, address: $address, location: $location, phone: $phone, items: $items, status: $status, ready: $ready, done: $done, instructions: $instructions, cashToCollectKobo: $cashToCollectKobo, legKm: $legKm, legMinutes: $legMinutes)';
}


}

/// @nodoc
abstract mixin class _$TripStopCopyWith<$Res> implements $TripStopCopyWith<$Res> {
  factory _$TripStopCopyWith(_TripStop value, $Res Function(_TripStop) _then) = __$TripStopCopyWithImpl;
@override @useResult
$Res call({
 String kind, String? orderId, List<String> orderIds, String? shortCode, String name, String? vertical, String? address, GeoPoint? location, String? phone, List<TripItem> items, String? status, bool ready, bool done, String? instructions, int cashToCollectKobo, double? legKm, int? legMinutes
});


@override $GeoPointCopyWith<$Res>? get location;

}
/// @nodoc
class __$TripStopCopyWithImpl<$Res>
    implements _$TripStopCopyWith<$Res> {
  __$TripStopCopyWithImpl(this._self, this._then);

  final _TripStop _self;
  final $Res Function(_TripStop) _then;

/// Create a copy of TripStop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? orderId = freezed,Object? orderIds = null,Object? shortCode = freezed,Object? name = null,Object? vertical = freezed,Object? address = freezed,Object? location = freezed,Object? phone = freezed,Object? items = null,Object? status = freezed,Object? ready = null,Object? done = null,Object? instructions = freezed,Object? cashToCollectKobo = null,Object? legKm = freezed,Object? legMinutes = freezed,}) {
  return _then(_TripStop(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,orderIds: null == orderIds ? _self._orderIds : orderIds // ignore: cast_nullable_to_non_nullable
as List<String>,shortCode: freezed == shortCode ? _self.shortCode : shortCode // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,vertical: freezed == vertical ? _self.vertical : vertical // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<TripItem>,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,ready: null == ready ? _self.ready : ready // ignore: cast_nullable_to_non_nullable
as bool,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,cashToCollectKobo: null == cashToCollectKobo ? _self.cashToCollectKobo : cashToCollectKobo // ignore: cast_nullable_to_non_nullable
as int,legKm: freezed == legKm ? _self.legKm : legKm // ignore: cast_nullable_to_non_nullable
as double?,legMinutes: freezed == legMinutes ? _self.legMinutes : legMinutes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of TripStop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res>? get location {
    if (_self.location == null) {
    return null;
  }

  return $GeoPointCopyWith<$Res>(_self.location!, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// @nodoc
mixin _$RiderTrip {

 String get tripId; List<String> get orderIds; List<TripStop> get stops; int get nextStop; double? get totalKm; int? get totalMinutes; String? get routeSource; String? get navigationUrl; int? get payoutKobo;
/// Create a copy of RiderTrip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RiderTripCopyWith<RiderTrip> get copyWith => _$RiderTripCopyWithImpl<RiderTrip>(this as RiderTrip, _$identity);

  /// Serializes this RiderTrip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RiderTrip;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RiderTrip&&(identical(other.tripId, _this.tripId) || other.tripId == _this.tripId)&&const DeepCollectionEquality().equals(other.orderIds, _this.orderIds)&&const DeepCollectionEquality().equals(other.stops, _this.stops)&&(identical(other.nextStop, _this.nextStop) || other.nextStop == _this.nextStop)&&(identical(other.totalKm, _this.totalKm) || other.totalKm == _this.totalKm)&&(identical(other.totalMinutes, _this.totalMinutes) || other.totalMinutes == _this.totalMinutes)&&(identical(other.routeSource, _this.routeSource) || other.routeSource == _this.routeSource)&&(identical(other.navigationUrl, _this.navigationUrl) || other.navigationUrl == _this.navigationUrl)&&(identical(other.payoutKobo, _this.payoutKobo) || other.payoutKobo == _this.payoutKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RiderTrip;
  return Object.hash(runtimeType,_this.tripId,const DeepCollectionEquality().hash(_this.orderIds),const DeepCollectionEquality().hash(_this.stops),_this.nextStop,_this.totalKm,_this.totalMinutes,_this.routeSource,_this.navigationUrl,_this.payoutKobo);
}

@override
String toString() {
  final _this = this as RiderTrip;
  return 'RiderTrip(tripId: ${_this.tripId}, orderIds: ${_this.orderIds}, stops: ${_this.stops}, nextStop: ${_this.nextStop}, totalKm: ${_this.totalKm}, totalMinutes: ${_this.totalMinutes}, routeSource: ${_this.routeSource}, navigationUrl: ${_this.navigationUrl}, payoutKobo: ${_this.payoutKobo})';
}


}

/// @nodoc
abstract mixin class $RiderTripCopyWith<$Res>  {
  factory $RiderTripCopyWith(RiderTrip value, $Res Function(RiderTrip) _then) = _$RiderTripCopyWithImpl;
@useResult
$Res call({
 String tripId, List<String> orderIds, List<TripStop> stops, int nextStop, double? totalKm, int? totalMinutes, String? routeSource, String? navigationUrl, int? payoutKobo
});




}
/// @nodoc
class _$RiderTripCopyWithImpl<$Res>
    implements $RiderTripCopyWith<$Res> {
  _$RiderTripCopyWithImpl(this._self, this._then);

  final RiderTrip _self;
  final $Res Function(RiderTrip) _then;

/// Create a copy of RiderTrip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tripId = null,Object? orderIds = null,Object? stops = null,Object? nextStop = null,Object? totalKm = freezed,Object? totalMinutes = freezed,Object? routeSource = freezed,Object? navigationUrl = freezed,Object? payoutKobo = freezed,}) {
  return _then(RiderTrip(
tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,orderIds: null == orderIds ? _self.orderIds : orderIds // ignore: cast_nullable_to_non_nullable
as List<String>,stops: null == stops ? _self.stops : stops // ignore: cast_nullable_to_non_nullable
as List<TripStop>,nextStop: null == nextStop ? _self.nextStop : nextStop // ignore: cast_nullable_to_non_nullable
as int,totalKm: freezed == totalKm ? _self.totalKm : totalKm // ignore: cast_nullable_to_non_nullable
as double?,totalMinutes: freezed == totalMinutes ? _self.totalMinutes : totalMinutes // ignore: cast_nullable_to_non_nullable
as int?,routeSource: freezed == routeSource ? _self.routeSource : routeSource // ignore: cast_nullable_to_non_nullable
as String?,navigationUrl: freezed == navigationUrl ? _self.navigationUrl : navigationUrl // ignore: cast_nullable_to_non_nullable
as String?,payoutKobo: freezed == payoutKobo ? _self.payoutKobo : payoutKobo // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [RiderTrip].
extension RiderTripPatterns on RiderTrip {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RiderTrip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RiderTrip() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RiderTrip value)  $default,){
final _that = this;
switch (_that) {
case _RiderTrip():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RiderTrip value)?  $default,){
final _that = this;
switch (_that) {
case _RiderTrip() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tripId,  List<String> orderIds,  List<TripStop> stops,  int nextStop,  double? totalKm,  int? totalMinutes,  String? routeSource,  String? navigationUrl,  int? payoutKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RiderTrip() when $default != null:
return $default(_that.tripId,_that.orderIds,_that.stops,_that.nextStop,_that.totalKm,_that.totalMinutes,_that.routeSource,_that.navigationUrl,_that.payoutKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tripId,  List<String> orderIds,  List<TripStop> stops,  int nextStop,  double? totalKm,  int? totalMinutes,  String? routeSource,  String? navigationUrl,  int? payoutKobo)  $default,) {final _that = this;
switch (_that) {
case _RiderTrip():
return $default(_that.tripId,_that.orderIds,_that.stops,_that.nextStop,_that.totalKm,_that.totalMinutes,_that.routeSource,_that.navigationUrl,_that.payoutKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tripId,  List<String> orderIds,  List<TripStop> stops,  int nextStop,  double? totalKm,  int? totalMinutes,  String? routeSource,  String? navigationUrl,  int? payoutKobo)?  $default,) {final _that = this;
switch (_that) {
case _RiderTrip() when $default != null:
return $default(_that.tripId,_that.orderIds,_that.stops,_that.nextStop,_that.totalKm,_that.totalMinutes,_that.routeSource,_that.navigationUrl,_that.payoutKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RiderTrip implements RiderTrip {
  const _RiderTrip({required this.tripId,  List<String> orderIds = const <String>[],  List<TripStop> stops = const <TripStop>[], this.nextStop = 0, this.totalKm, this.totalMinutes, this.routeSource, this.navigationUrl, this.payoutKobo}): _orderIds = orderIds,_stops = stops;
  factory _RiderTrip.fromJson(Map<String, dynamic> json) => _$RiderTripFromJson(json);

@override final  String tripId;
 final  List<String> _orderIds;
@override@JsonKey() List<String> get orderIds {
  if (_orderIds is EqualUnmodifiableListView) return _orderIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orderIds);
}

 final  List<TripStop> _stops;
@override@JsonKey() List<TripStop> get stops {
  if (_stops is EqualUnmodifiableListView) return _stops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stops);
}

@override@JsonKey() final  int nextStop;
@override final  double? totalKm;
@override final  int? totalMinutes;
@override final  String? routeSource;
@override final  String? navigationUrl;
@override final  int? payoutKobo;

/// Create a copy of RiderTrip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RiderTripCopyWith<_RiderTrip> get copyWith => __$RiderTripCopyWithImpl<_RiderTrip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RiderTripToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RiderTrip&&(identical(other.tripId, tripId) || other.tripId == tripId)&&const DeepCollectionEquality().equals(other.orderIds, _orderIds)&&const DeepCollectionEquality().equals(other.stops, _stops)&&(identical(other.nextStop, nextStop) || other.nextStop == nextStop)&&(identical(other.totalKm, totalKm) || other.totalKm == totalKm)&&(identical(other.totalMinutes, totalMinutes) || other.totalMinutes == totalMinutes)&&(identical(other.routeSource, routeSource) || other.routeSource == routeSource)&&(identical(other.navigationUrl, navigationUrl) || other.navigationUrl == navigationUrl)&&(identical(other.payoutKobo, payoutKobo) || other.payoutKobo == payoutKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,tripId,const DeepCollectionEquality().hash(_orderIds),const DeepCollectionEquality().hash(_stops),nextStop,totalKm,totalMinutes,routeSource,navigationUrl,payoutKobo);
}

@override
String toString() {
    return 'RiderTrip(tripId: $tripId, orderIds: $orderIds, stops: $stops, nextStop: $nextStop, totalKm: $totalKm, totalMinutes: $totalMinutes, routeSource: $routeSource, navigationUrl: $navigationUrl, payoutKobo: $payoutKobo)';
}


}

/// @nodoc
abstract mixin class _$RiderTripCopyWith<$Res> implements $RiderTripCopyWith<$Res> {
  factory _$RiderTripCopyWith(_RiderTrip value, $Res Function(_RiderTrip) _then) = __$RiderTripCopyWithImpl;
@override @useResult
$Res call({
 String tripId, List<String> orderIds, List<TripStop> stops, int nextStop, double? totalKm, int? totalMinutes, String? routeSource, String? navigationUrl, int? payoutKobo
});




}
/// @nodoc
class __$RiderTripCopyWithImpl<$Res>
    implements _$RiderTripCopyWith<$Res> {
  __$RiderTripCopyWithImpl(this._self, this._then);

  final _RiderTrip _self;
  final $Res Function(_RiderTrip) _then;

/// Create a copy of RiderTrip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tripId = null,Object? orderIds = null,Object? stops = null,Object? nextStop = null,Object? totalKm = freezed,Object? totalMinutes = freezed,Object? routeSource = freezed,Object? navigationUrl = freezed,Object? payoutKobo = freezed,}) {
  return _then(_RiderTrip(
tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,orderIds: null == orderIds ? _self._orderIds : orderIds // ignore: cast_nullable_to_non_nullable
as List<String>,stops: null == stops ? _self._stops : stops // ignore: cast_nullable_to_non_nullable
as List<TripStop>,nextStop: null == nextStop ? _self.nextStop : nextStop // ignore: cast_nullable_to_non_nullable
as int,totalKm: freezed == totalKm ? _self.totalKm : totalKm // ignore: cast_nullable_to_non_nullable
as double?,totalMinutes: freezed == totalMinutes ? _self.totalMinutes : totalMinutes // ignore: cast_nullable_to_non_nullable
as int?,routeSource: freezed == routeSource ? _self.routeSource : routeSource // ignore: cast_nullable_to_non_nullable
as String?,navigationUrl: freezed == navigationUrl ? _self.navigationUrl : navigationUrl // ignore: cast_nullable_to_non_nullable
as String?,payoutKobo: freezed == payoutKobo ? _self.payoutKobo : payoutKobo // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$RiderProfile {

 String get uid; String get name; String get vehicle; String get status; bool get isOnline; double get rating; List<String> get activeOrderIds; int get completedDeliveries;
/// Create a copy of RiderProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RiderProfileCopyWith<RiderProfile> get copyWith => _$RiderProfileCopyWithImpl<RiderProfile>(this as RiderProfile, _$identity);

  /// Serializes this RiderProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RiderProfile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RiderProfile&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.vehicle, _this.vehicle) || other.vehicle == _this.vehicle)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.isOnline, _this.isOnline) || other.isOnline == _this.isOnline)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&const DeepCollectionEquality().equals(other.activeOrderIds, _this.activeOrderIds)&&(identical(other.completedDeliveries, _this.completedDeliveries) || other.completedDeliveries == _this.completedDeliveries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RiderProfile;
  return Object.hash(runtimeType,_this.uid,_this.name,_this.vehicle,_this.status,_this.isOnline,_this.rating,const DeepCollectionEquality().hash(_this.activeOrderIds),_this.completedDeliveries);
}

@override
String toString() {
  final _this = this as RiderProfile;
  return 'RiderProfile(uid: ${_this.uid}, name: ${_this.name}, vehicle: ${_this.vehicle}, status: ${_this.status}, isOnline: ${_this.isOnline}, rating: ${_this.rating}, activeOrderIds: ${_this.activeOrderIds}, completedDeliveries: ${_this.completedDeliveries})';
}


}

/// @nodoc
abstract mixin class $RiderProfileCopyWith<$Res>  {
  factory $RiderProfileCopyWith(RiderProfile value, $Res Function(RiderProfile) _then) = _$RiderProfileCopyWithImpl;
@useResult
$Res call({
 String uid, String name, String vehicle, String status, bool isOnline, double rating, List<String> activeOrderIds, int completedDeliveries
});




}
/// @nodoc
class _$RiderProfileCopyWithImpl<$Res>
    implements $RiderProfileCopyWith<$Res> {
  _$RiderProfileCopyWithImpl(this._self, this._then);

  final RiderProfile _self;
  final $Res Function(RiderProfile) _then;

/// Create a copy of RiderProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? name = null,Object? vehicle = null,Object? status = null,Object? isOnline = null,Object? rating = null,Object? activeOrderIds = null,Object? completedDeliveries = null,}) {
  return _then(RiderProfile(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,vehicle: null == vehicle ? _self.vehicle : vehicle // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,activeOrderIds: null == activeOrderIds ? _self.activeOrderIds : activeOrderIds // ignore: cast_nullable_to_non_nullable
as List<String>,completedDeliveries: null == completedDeliveries ? _self.completedDeliveries : completedDeliveries // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RiderProfile].
extension RiderProfilePatterns on RiderProfile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RiderProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RiderProfile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RiderProfile value)  $default,){
final _that = this;
switch (_that) {
case _RiderProfile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RiderProfile value)?  $default,){
final _that = this;
switch (_that) {
case _RiderProfile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String name,  String vehicle,  String status,  bool isOnline,  double rating,  List<String> activeOrderIds,  int completedDeliveries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RiderProfile() when $default != null:
return $default(_that.uid,_that.name,_that.vehicle,_that.status,_that.isOnline,_that.rating,_that.activeOrderIds,_that.completedDeliveries);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String name,  String vehicle,  String status,  bool isOnline,  double rating,  List<String> activeOrderIds,  int completedDeliveries)  $default,) {final _that = this;
switch (_that) {
case _RiderProfile():
return $default(_that.uid,_that.name,_that.vehicle,_that.status,_that.isOnline,_that.rating,_that.activeOrderIds,_that.completedDeliveries);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String name,  String vehicle,  String status,  bool isOnline,  double rating,  List<String> activeOrderIds,  int completedDeliveries)?  $default,) {final _that = this;
switch (_that) {
case _RiderProfile() when $default != null:
return $default(_that.uid,_that.name,_that.vehicle,_that.status,_that.isOnline,_that.rating,_that.activeOrderIds,_that.completedDeliveries);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RiderProfile implements RiderProfile {
  const _RiderProfile({required this.uid, required this.name, this.vehicle = 'motorcycle', this.status = 'pending', this.isOnline = false, this.rating = 5,  List<String> activeOrderIds = const <String>[], this.completedDeliveries = 0}): _activeOrderIds = activeOrderIds;
  factory _RiderProfile.fromJson(Map<String, dynamic> json) => _$RiderProfileFromJson(json);

@override final  String uid;
@override final  String name;
@override@JsonKey() final  String vehicle;
@override@JsonKey() final  String status;
@override@JsonKey() final  bool isOnline;
@override@JsonKey() final  double rating;
 final  List<String> _activeOrderIds;
@override@JsonKey() List<String> get activeOrderIds {
  if (_activeOrderIds is EqualUnmodifiableListView) return _activeOrderIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeOrderIds);
}

@override@JsonKey() final  int completedDeliveries;

/// Create a copy of RiderProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RiderProfileCopyWith<_RiderProfile> get copyWith => __$RiderProfileCopyWithImpl<_RiderProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RiderProfileToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RiderProfile&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.name, name) || other.name == name)&&(identical(other.vehicle, vehicle) || other.vehicle == vehicle)&&(identical(other.status, status) || other.status == status)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.activeOrderIds, _activeOrderIds)&&(identical(other.completedDeliveries, completedDeliveries) || other.completedDeliveries == completedDeliveries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,uid,name,vehicle,status,isOnline,rating,const DeepCollectionEquality().hash(_activeOrderIds),completedDeliveries);
}

@override
String toString() {
    return 'RiderProfile(uid: $uid, name: $name, vehicle: $vehicle, status: $status, isOnline: $isOnline, rating: $rating, activeOrderIds: $activeOrderIds, completedDeliveries: $completedDeliveries)';
}


}

/// @nodoc
abstract mixin class _$RiderProfileCopyWith<$Res> implements $RiderProfileCopyWith<$Res> {
  factory _$RiderProfileCopyWith(_RiderProfile value, $Res Function(_RiderProfile) _then) = __$RiderProfileCopyWithImpl;
@override @useResult
$Res call({
 String uid, String name, String vehicle, String status, bool isOnline, double rating, List<String> activeOrderIds, int completedDeliveries
});




}
/// @nodoc
class __$RiderProfileCopyWithImpl<$Res>
    implements _$RiderProfileCopyWith<$Res> {
  __$RiderProfileCopyWithImpl(this._self, this._then);

  final _RiderProfile _self;
  final $Res Function(_RiderProfile) _then;

/// Create a copy of RiderProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? name = null,Object? vehicle = null,Object? status = null,Object? isOnline = null,Object? rating = null,Object? activeOrderIds = null,Object? completedDeliveries = null,}) {
  return _then(_RiderProfile(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,vehicle: null == vehicle ? _self.vehicle : vehicle // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,activeOrderIds: null == activeOrderIds ? _self._activeOrderIds : activeOrderIds // ignore: cast_nullable_to_non_nullable
as List<String>,completedDeliveries: null == completedDeliveries ? _self.completedDeliveries : completedDeliveries // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Earnings {

 int get balanceKobo; int get pendingPayoutsKobo; int get availableKobo; int get deliveriesCompleted;@JsonKey(name: 'earned_last_7_days_kobo') int get earnedLast7DaysKobo;/// Cash collected at the door that the rider still has to hand in (netted off before withdrawals).
 int get cashHeldKobo;
/// Create a copy of Earnings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EarningsCopyWith<Earnings> get copyWith => _$EarningsCopyWithImpl<Earnings>(this as Earnings, _$identity);

  /// Serializes this Earnings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Earnings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Earnings&&(identical(other.balanceKobo, _this.balanceKobo) || other.balanceKobo == _this.balanceKobo)&&(identical(other.pendingPayoutsKobo, _this.pendingPayoutsKobo) || other.pendingPayoutsKobo == _this.pendingPayoutsKobo)&&(identical(other.availableKobo, _this.availableKobo) || other.availableKobo == _this.availableKobo)&&(identical(other.deliveriesCompleted, _this.deliveriesCompleted) || other.deliveriesCompleted == _this.deliveriesCompleted)&&(identical(other.earnedLast7DaysKobo, _this.earnedLast7DaysKobo) || other.earnedLast7DaysKobo == _this.earnedLast7DaysKobo)&&(identical(other.cashHeldKobo, _this.cashHeldKobo) || other.cashHeldKobo == _this.cashHeldKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Earnings;
  return Object.hash(runtimeType,_this.balanceKobo,_this.pendingPayoutsKobo,_this.availableKobo,_this.deliveriesCompleted,_this.earnedLast7DaysKobo,_this.cashHeldKobo);
}

@override
String toString() {
  final _this = this as Earnings;
  return 'Earnings(balanceKobo: ${_this.balanceKobo}, pendingPayoutsKobo: ${_this.pendingPayoutsKobo}, availableKobo: ${_this.availableKobo}, deliveriesCompleted: ${_this.deliveriesCompleted}, earnedLast7DaysKobo: ${_this.earnedLast7DaysKobo}, cashHeldKobo: ${_this.cashHeldKobo})';
}


}

/// @nodoc
abstract mixin class $EarningsCopyWith<$Res>  {
  factory $EarningsCopyWith(Earnings value, $Res Function(Earnings) _then) = _$EarningsCopyWithImpl;
@useResult
$Res call({
 int balanceKobo, int pendingPayoutsKobo, int availableKobo, int deliveriesCompleted,@JsonKey(name: 'earned_last_7_days_kobo') int earnedLast7DaysKobo, int cashHeldKobo
});




}
/// @nodoc
class _$EarningsCopyWithImpl<$Res>
    implements $EarningsCopyWith<$Res> {
  _$EarningsCopyWithImpl(this._self, this._then);

  final Earnings _self;
  final $Res Function(Earnings) _then;

/// Create a copy of Earnings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? balanceKobo = null,Object? pendingPayoutsKobo = null,Object? availableKobo = null,Object? deliveriesCompleted = null,Object? earnedLast7DaysKobo = null,Object? cashHeldKobo = null,}) {
  return _then(Earnings(
balanceKobo: null == balanceKobo ? _self.balanceKobo : balanceKobo // ignore: cast_nullable_to_non_nullable
as int,pendingPayoutsKobo: null == pendingPayoutsKobo ? _self.pendingPayoutsKobo : pendingPayoutsKobo // ignore: cast_nullable_to_non_nullable
as int,availableKobo: null == availableKobo ? _self.availableKobo : availableKobo // ignore: cast_nullable_to_non_nullable
as int,deliveriesCompleted: null == deliveriesCompleted ? _self.deliveriesCompleted : deliveriesCompleted // ignore: cast_nullable_to_non_nullable
as int,earnedLast7DaysKobo: null == earnedLast7DaysKobo ? _self.earnedLast7DaysKobo : earnedLast7DaysKobo // ignore: cast_nullable_to_non_nullable
as int,cashHeldKobo: null == cashHeldKobo ? _self.cashHeldKobo : cashHeldKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Earnings].
extension EarningsPatterns on Earnings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Earnings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Earnings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Earnings value)  $default,){
final _that = this;
switch (_that) {
case _Earnings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Earnings value)?  $default,){
final _that = this;
switch (_that) {
case _Earnings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int balanceKobo,  int pendingPayoutsKobo,  int availableKobo,  int deliveriesCompleted, @JsonKey(name: 'earned_last_7_days_kobo')  int earnedLast7DaysKobo,  int cashHeldKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Earnings() when $default != null:
return $default(_that.balanceKobo,_that.pendingPayoutsKobo,_that.availableKobo,_that.deliveriesCompleted,_that.earnedLast7DaysKobo,_that.cashHeldKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int balanceKobo,  int pendingPayoutsKobo,  int availableKobo,  int deliveriesCompleted, @JsonKey(name: 'earned_last_7_days_kobo')  int earnedLast7DaysKobo,  int cashHeldKobo)  $default,) {final _that = this;
switch (_that) {
case _Earnings():
return $default(_that.balanceKobo,_that.pendingPayoutsKobo,_that.availableKobo,_that.deliveriesCompleted,_that.earnedLast7DaysKobo,_that.cashHeldKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int balanceKobo,  int pendingPayoutsKobo,  int availableKobo,  int deliveriesCompleted, @JsonKey(name: 'earned_last_7_days_kobo')  int earnedLast7DaysKobo,  int cashHeldKobo)?  $default,) {final _that = this;
switch (_that) {
case _Earnings() when $default != null:
return $default(_that.balanceKobo,_that.pendingPayoutsKobo,_that.availableKobo,_that.deliveriesCompleted,_that.earnedLast7DaysKobo,_that.cashHeldKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Earnings implements Earnings {
  const _Earnings({required this.balanceKobo, required this.pendingPayoutsKobo, required this.availableKobo, required this.deliveriesCompleted, @JsonKey(name: 'earned_last_7_days_kobo') required this.earnedLast7DaysKobo, this.cashHeldKobo = 0});
  factory _Earnings.fromJson(Map<String, dynamic> json) => _$EarningsFromJson(json);

@override final  int balanceKobo;
@override final  int pendingPayoutsKobo;
@override final  int availableKobo;
@override final  int deliveriesCompleted;
@override@JsonKey(name: 'earned_last_7_days_kobo') final  int earnedLast7DaysKobo;
/// Cash collected at the door that the rider still has to hand in (netted off before withdrawals).
@override@JsonKey() final  int cashHeldKobo;

/// Create a copy of Earnings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EarningsCopyWith<_Earnings> get copyWith => __$EarningsCopyWithImpl<_Earnings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EarningsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Earnings&&(identical(other.balanceKobo, balanceKobo) || other.balanceKobo == balanceKobo)&&(identical(other.pendingPayoutsKobo, pendingPayoutsKobo) || other.pendingPayoutsKobo == pendingPayoutsKobo)&&(identical(other.availableKobo, availableKobo) || other.availableKobo == availableKobo)&&(identical(other.deliveriesCompleted, deliveriesCompleted) || other.deliveriesCompleted == deliveriesCompleted)&&(identical(other.earnedLast7DaysKobo, earnedLast7DaysKobo) || other.earnedLast7DaysKobo == earnedLast7DaysKobo)&&(identical(other.cashHeldKobo, cashHeldKobo) || other.cashHeldKobo == cashHeldKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,balanceKobo,pendingPayoutsKobo,availableKobo,deliveriesCompleted,earnedLast7DaysKobo,cashHeldKobo);
}

@override
String toString() {
    return 'Earnings(balanceKobo: $balanceKobo, pendingPayoutsKobo: $pendingPayoutsKobo, availableKobo: $availableKobo, deliveriesCompleted: $deliveriesCompleted, earnedLast7DaysKobo: $earnedLast7DaysKobo, cashHeldKobo: $cashHeldKobo)';
}


}

/// @nodoc
abstract mixin class _$EarningsCopyWith<$Res> implements $EarningsCopyWith<$Res> {
  factory _$EarningsCopyWith(_Earnings value, $Res Function(_Earnings) _then) = __$EarningsCopyWithImpl;
@override @useResult
$Res call({
 int balanceKobo, int pendingPayoutsKobo, int availableKobo, int deliveriesCompleted,@JsonKey(name: 'earned_last_7_days_kobo') int earnedLast7DaysKobo, int cashHeldKobo
});




}
/// @nodoc
class __$EarningsCopyWithImpl<$Res>
    implements _$EarningsCopyWith<$Res> {
  __$EarningsCopyWithImpl(this._self, this._then);

  final _Earnings _self;
  final $Res Function(_Earnings) _then;

/// Create a copy of Earnings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? balanceKobo = null,Object? pendingPayoutsKobo = null,Object? availableKobo = null,Object? deliveriesCompleted = null,Object? earnedLast7DaysKobo = null,Object? cashHeldKobo = null,}) {
  return _then(_Earnings(
balanceKobo: null == balanceKobo ? _self.balanceKobo : balanceKobo // ignore: cast_nullable_to_non_nullable
as int,pendingPayoutsKobo: null == pendingPayoutsKobo ? _self.pendingPayoutsKobo : pendingPayoutsKobo // ignore: cast_nullable_to_non_nullable
as int,availableKobo: null == availableKobo ? _self.availableKobo : availableKobo // ignore: cast_nullable_to_non_nullable
as int,deliveriesCompleted: null == deliveriesCompleted ? _self.deliveriesCompleted : deliveriesCompleted // ignore: cast_nullable_to_non_nullable
as int,earnedLast7DaysKobo: null == earnedLast7DaysKobo ? _self.earnedLast7DaysKobo : earnedLast7DaysKobo // ignore: cast_nullable_to_non_nullable
as int,cashHeldKobo: null == cashHeldKobo ? _self.cashHeldKobo : cashHeldKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ChatApproval {

 String get tool; String get toolCallId; Map<String, dynamic> get preview;
/// Create a copy of ChatApproval
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatApprovalCopyWith<ChatApproval> get copyWith => _$ChatApprovalCopyWithImpl<ChatApproval>(this as ChatApproval, _$identity);

  /// Serializes this ChatApproval to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatApproval;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatApproval&&(identical(other.tool, _this.tool) || other.tool == _this.tool)&&(identical(other.toolCallId, _this.toolCallId) || other.toolCallId == _this.toolCallId)&&const DeepCollectionEquality().equals(other.preview, _this.preview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatApproval;
  return Object.hash(runtimeType,_this.tool,_this.toolCallId,const DeepCollectionEquality().hash(_this.preview));
}

@override
String toString() {
  final _this = this as ChatApproval;
  return 'ChatApproval(tool: ${_this.tool}, toolCallId: ${_this.toolCallId}, preview: ${_this.preview})';
}


}

/// @nodoc
abstract mixin class $ChatApprovalCopyWith<$Res>  {
  factory $ChatApprovalCopyWith(ChatApproval value, $Res Function(ChatApproval) _then) = _$ChatApprovalCopyWithImpl;
@useResult
$Res call({
 String tool, String toolCallId, Map<String, dynamic> preview
});




}
/// @nodoc
class _$ChatApprovalCopyWithImpl<$Res>
    implements $ChatApprovalCopyWith<$Res> {
  _$ChatApprovalCopyWithImpl(this._self, this._then);

  final ChatApproval _self;
  final $Res Function(ChatApproval) _then;

/// Create a copy of ChatApproval
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tool = null,Object? toolCallId = null,Object? preview = null,}) {
  return _then(ChatApproval(
tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as String,toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatApproval].
extension ChatApprovalPatterns on ChatApproval {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatApproval value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatApproval() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatApproval value)  $default,){
final _that = this;
switch (_that) {
case _ChatApproval():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatApproval value)?  $default,){
final _that = this;
switch (_that) {
case _ChatApproval() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tool,  String toolCallId,  Map<String, dynamic> preview)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatApproval() when $default != null:
return $default(_that.tool,_that.toolCallId,_that.preview);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tool,  String toolCallId,  Map<String, dynamic> preview)  $default,) {final _that = this;
switch (_that) {
case _ChatApproval():
return $default(_that.tool,_that.toolCallId,_that.preview);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tool,  String toolCallId,  Map<String, dynamic> preview)?  $default,) {final _that = this;
switch (_that) {
case _ChatApproval() when $default != null:
return $default(_that.tool,_that.toolCallId,_that.preview);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatApproval implements ChatApproval {
  const _ChatApproval({required this.tool, required this.toolCallId,  Map<String, dynamic> preview = const <String, dynamic>{}}): _preview = preview;
  factory _ChatApproval.fromJson(Map<String, dynamic> json) => _$ChatApprovalFromJson(json);

@override final  String tool;
@override final  String toolCallId;
 final  Map<String, dynamic> _preview;
@override@JsonKey() Map<String, dynamic> get preview {
  if (_preview is EqualUnmodifiableMapView) return _preview;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_preview);
}


/// Create a copy of ChatApproval
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatApprovalCopyWith<_ChatApproval> get copyWith => __$ChatApprovalCopyWithImpl<_ChatApproval>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatApprovalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatApproval&&(identical(other.tool, tool) || other.tool == tool)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&const DeepCollectionEquality().equals(other.preview, _preview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,tool,toolCallId,const DeepCollectionEquality().hash(_preview));
}

@override
String toString() {
    return 'ChatApproval(tool: $tool, toolCallId: $toolCallId, preview: $preview)';
}


}

/// @nodoc
abstract mixin class _$ChatApprovalCopyWith<$Res> implements $ChatApprovalCopyWith<$Res> {
  factory _$ChatApprovalCopyWith(_ChatApproval value, $Res Function(_ChatApproval) _then) = __$ChatApprovalCopyWithImpl;
@override @useResult
$Res call({
 String tool, String toolCallId, Map<String, dynamic> preview
});




}
/// @nodoc
class __$ChatApprovalCopyWithImpl<$Res>
    implements _$ChatApprovalCopyWith<$Res> {
  __$ChatApprovalCopyWithImpl(this._self, this._then);

  final _ChatApproval _self;
  final $Res Function(_ChatApproval) _then;

/// Create a copy of ChatApproval
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tool = null,Object? toolCallId = null,Object? preview = null,}) {
  return _then(_ChatApproval(
tool: null == tool ? _self.tool : tool // ignore: cast_nullable_to_non_nullable
as String,toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,preview: null == preview ? _self._preview : preview // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$ChatResponse {

 String get threadId; String get status; String? get reply; String? get agent; List<Map<String, dynamic>> get cards; ChatApproval? get approval;
/// Create a copy of ChatResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatResponseCopyWith<ChatResponse> get copyWith => _$ChatResponseCopyWithImpl<ChatResponse>(this as ChatResponse, _$identity);

  /// Serializes this ChatResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatResponse&&(identical(other.threadId, _this.threadId) || other.threadId == _this.threadId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reply, _this.reply) || other.reply == _this.reply)&&(identical(other.agent, _this.agent) || other.agent == _this.agent)&&const DeepCollectionEquality().equals(other.cards, _this.cards)&&(identical(other.approval, _this.approval) || other.approval == _this.approval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatResponse;
  return Object.hash(runtimeType,_this.threadId,_this.status,_this.reply,_this.agent,const DeepCollectionEquality().hash(_this.cards),_this.approval);
}

@override
String toString() {
  final _this = this as ChatResponse;
  return 'ChatResponse(threadId: ${_this.threadId}, status: ${_this.status}, reply: ${_this.reply}, agent: ${_this.agent}, cards: ${_this.cards}, approval: ${_this.approval})';
}


}

/// @nodoc
abstract mixin class $ChatResponseCopyWith<$Res>  {
  factory $ChatResponseCopyWith(ChatResponse value, $Res Function(ChatResponse) _then) = _$ChatResponseCopyWithImpl;
@useResult
$Res call({
 String threadId, String status, String? reply, String? agent, List<Map<String, dynamic>> cards, ChatApproval? approval
});


$ChatApprovalCopyWith<$Res>? get approval;

}
/// @nodoc
class _$ChatResponseCopyWithImpl<$Res>
    implements $ChatResponseCopyWith<$Res> {
  _$ChatResponseCopyWithImpl(this._self, this._then);

  final ChatResponse _self;
  final $Res Function(ChatResponse) _then;

/// Create a copy of ChatResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? threadId = null,Object? status = null,Object? reply = freezed,Object? agent = freezed,Object? cards = null,Object? approval = freezed,}) {
  return _then(ChatResponse(
threadId: null == threadId ? _self.threadId : threadId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reply: freezed == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String?,agent: freezed == agent ? _self.agent : agent // ignore: cast_nullable_to_non_nullable
as String?,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,approval: freezed == approval ? _self.approval : approval // ignore: cast_nullable_to_non_nullable
as ChatApproval?,
  ));
}
/// Create a copy of ChatResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatApprovalCopyWith<$Res>? get approval {
    if (_self.approval == null) {
    return null;
  }

  return $ChatApprovalCopyWith<$Res>(_self.approval!, (value) {
    return _then(_self.copyWith(approval: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatResponse].
extension ChatResponsePatterns on ChatResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatResponse value)  $default,){
final _that = this;
switch (_that) {
case _ChatResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ChatResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String threadId,  String status,  String? reply,  String? agent,  List<Map<String, dynamic>> cards,  ChatApproval? approval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatResponse() when $default != null:
return $default(_that.threadId,_that.status,_that.reply,_that.agent,_that.cards,_that.approval);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String threadId,  String status,  String? reply,  String? agent,  List<Map<String, dynamic>> cards,  ChatApproval? approval)  $default,) {final _that = this;
switch (_that) {
case _ChatResponse():
return $default(_that.threadId,_that.status,_that.reply,_that.agent,_that.cards,_that.approval);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String threadId,  String status,  String? reply,  String? agent,  List<Map<String, dynamic>> cards,  ChatApproval? approval)?  $default,) {final _that = this;
switch (_that) {
case _ChatResponse() when $default != null:
return $default(_that.threadId,_that.status,_that.reply,_that.agent,_that.cards,_that.approval);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatResponse implements ChatResponse {
  const _ChatResponse({required this.threadId, required this.status, this.reply, this.agent,  List<Map<String, dynamic>> cards = const <Map<String, dynamic>>[], this.approval}): _cards = cards;
  factory _ChatResponse.fromJson(Map<String, dynamic> json) => _$ChatResponseFromJson(json);

@override final  String threadId;
@override final  String status;
@override final  String? reply;
@override final  String? agent;
 final  List<Map<String, dynamic>> _cards;
@override@JsonKey() List<Map<String, dynamic>> get cards {
  if (_cards is EqualUnmodifiableListView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cards);
}

@override final  ChatApproval? approval;

/// Create a copy of ChatResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatResponseCopyWith<_ChatResponse> get copyWith => __$ChatResponseCopyWithImpl<_ChatResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatResponse&&(identical(other.threadId, threadId) || other.threadId == threadId)&&(identical(other.status, status) || other.status == status)&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.agent, agent) || other.agent == agent)&&const DeepCollectionEquality().equals(other.cards, _cards)&&(identical(other.approval, approval) || other.approval == approval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,threadId,status,reply,agent,const DeepCollectionEquality().hash(_cards),approval);
}

@override
String toString() {
    return 'ChatResponse(threadId: $threadId, status: $status, reply: $reply, agent: $agent, cards: $cards, approval: $approval)';
}


}

/// @nodoc
abstract mixin class _$ChatResponseCopyWith<$Res> implements $ChatResponseCopyWith<$Res> {
  factory _$ChatResponseCopyWith(_ChatResponse value, $Res Function(_ChatResponse) _then) = __$ChatResponseCopyWithImpl;
@override @useResult
$Res call({
 String threadId, String status, String? reply, String? agent, List<Map<String, dynamic>> cards, ChatApproval? approval
});


@override $ChatApprovalCopyWith<$Res>? get approval;

}
/// @nodoc
class __$ChatResponseCopyWithImpl<$Res>
    implements _$ChatResponseCopyWith<$Res> {
  __$ChatResponseCopyWithImpl(this._self, this._then);

  final _ChatResponse _self;
  final $Res Function(_ChatResponse) _then;

/// Create a copy of ChatResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? threadId = null,Object? status = null,Object? reply = freezed,Object? agent = freezed,Object? cards = null,Object? approval = freezed,}) {
  return _then(_ChatResponse(
threadId: null == threadId ? _self.threadId : threadId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reply: freezed == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String?,agent: freezed == agent ? _self.agent : agent // ignore: cast_nullable_to_non_nullable
as String?,cards: null == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,approval: freezed == approval ? _self.approval : approval // ignore: cast_nullable_to_non_nullable
as ChatApproval?,
  ));
}

/// Create a copy of ChatResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatApprovalCopyWith<$Res>? get approval {
    if (_self.approval == null) {
    return null;
  }

  return $ChatApprovalCopyWith<$Res>(_self.approval!, (value) {
    return _then(_self.copyWith(approval: value));
  });
}
}


/// @nodoc
mixin _$PromoBadge {

 String get code; String get label;
/// Create a copy of PromoBadge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PromoBadgeCopyWith<PromoBadge> get copyWith => _$PromoBadgeCopyWithImpl<PromoBadge>(this as PromoBadge, _$identity);

  /// Serializes this PromoBadge to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PromoBadge;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PromoBadge&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.label, _this.label) || other.label == _this.label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PromoBadge;
  return Object.hash(runtimeType,_this.code,_this.label);
}

@override
String toString() {
  final _this = this as PromoBadge;
  return 'PromoBadge(code: ${_this.code}, label: ${_this.label})';
}


}

/// @nodoc
abstract mixin class $PromoBadgeCopyWith<$Res>  {
  factory $PromoBadgeCopyWith(PromoBadge value, $Res Function(PromoBadge) _then) = _$PromoBadgeCopyWithImpl;
@useResult
$Res call({
 String code, String label
});




}
/// @nodoc
class _$PromoBadgeCopyWithImpl<$Res>
    implements $PromoBadgeCopyWith<$Res> {
  _$PromoBadgeCopyWithImpl(this._self, this._then);

  final PromoBadge _self;
  final $Res Function(PromoBadge) _then;

/// Create a copy of PromoBadge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? label = null,}) {
  return _then(PromoBadge(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PromoBadge].
extension PromoBadgePatterns on PromoBadge {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PromoBadge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PromoBadge() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PromoBadge value)  $default,){
final _that = this;
switch (_that) {
case _PromoBadge():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PromoBadge value)?  $default,){
final _that = this;
switch (_that) {
case _PromoBadge() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PromoBadge() when $default != null:
return $default(_that.code,_that.label);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String label)  $default,) {final _that = this;
switch (_that) {
case _PromoBadge():
return $default(_that.code,_that.label);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String label)?  $default,) {final _that = this;
switch (_that) {
case _PromoBadge() when $default != null:
return $default(_that.code,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PromoBadge implements PromoBadge {
  const _PromoBadge({required this.code, required this.label});
  factory _PromoBadge.fromJson(Map<String, dynamic> json) => _$PromoBadgeFromJson(json);

@override final  String code;
@override final  String label;

/// Create a copy of PromoBadge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PromoBadgeCopyWith<_PromoBadge> get copyWith => __$PromoBadgeCopyWithImpl<_PromoBadge>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PromoBadgeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PromoBadge&&(identical(other.code, code) || other.code == code)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,code,label);
}

@override
String toString() {
    return 'PromoBadge(code: $code, label: $label)';
}


}

/// @nodoc
abstract mixin class _$PromoBadgeCopyWith<$Res> implements $PromoBadgeCopyWith<$Res> {
  factory _$PromoBadgeCopyWith(_PromoBadge value, $Res Function(_PromoBadge) _then) = __$PromoBadgeCopyWithImpl;
@override @useResult
$Res call({
 String code, String label
});




}
/// @nodoc
class __$PromoBadgeCopyWithImpl<$Res>
    implements _$PromoBadgeCopyWith<$Res> {
  __$PromoBadgeCopyWithImpl(this._self, this._then);

  final _PromoBadge _self;
  final $Res Function(_PromoBadge) _then;

/// Create a copy of PromoBadge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? label = null,}) {
  return _then(_PromoBadge(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ServiceInfo {

 String get id; String get name; String get tagline; bool get available; int? get merchants; List<String> get options; List<String> get comingSoon; List<String> get cities;
/// Create a copy of ServiceInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceInfoCopyWith<ServiceInfo> get copyWith => _$ServiceInfoCopyWithImpl<ServiceInfo>(this as ServiceInfo, _$identity);

  /// Serializes this ServiceInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ServiceInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceInfo&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.tagline, _this.tagline) || other.tagline == _this.tagline)&&(identical(other.available, _this.available) || other.available == _this.available)&&(identical(other.merchants, _this.merchants) || other.merchants == _this.merchants)&&const DeepCollectionEquality().equals(other.options, _this.options)&&const DeepCollectionEquality().equals(other.comingSoon, _this.comingSoon)&&const DeepCollectionEquality().equals(other.cities, _this.cities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ServiceInfo;
  return Object.hash(runtimeType,_this.id,_this.name,_this.tagline,_this.available,_this.merchants,const DeepCollectionEquality().hash(_this.options),const DeepCollectionEquality().hash(_this.comingSoon),const DeepCollectionEquality().hash(_this.cities));
}

@override
String toString() {
  final _this = this as ServiceInfo;
  return 'ServiceInfo(id: ${_this.id}, name: ${_this.name}, tagline: ${_this.tagline}, available: ${_this.available}, merchants: ${_this.merchants}, options: ${_this.options}, comingSoon: ${_this.comingSoon}, cities: ${_this.cities})';
}


}

/// @nodoc
abstract mixin class $ServiceInfoCopyWith<$Res>  {
  factory $ServiceInfoCopyWith(ServiceInfo value, $Res Function(ServiceInfo) _then) = _$ServiceInfoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String tagline, bool available, int? merchants, List<String> options, List<String> comingSoon, List<String> cities
});




}
/// @nodoc
class _$ServiceInfoCopyWithImpl<$Res>
    implements $ServiceInfoCopyWith<$Res> {
  _$ServiceInfoCopyWithImpl(this._self, this._then);

  final ServiceInfo _self;
  final $Res Function(ServiceInfo) _then;

/// Create a copy of ServiceInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? tagline = null,Object? available = null,Object? merchants = freezed,Object? options = null,Object? comingSoon = null,Object? cities = null,}) {
  return _then(ServiceInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,merchants: freezed == merchants ? _self.merchants : merchants // ignore: cast_nullable_to_non_nullable
as int?,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<String>,comingSoon: null == comingSoon ? _self.comingSoon : comingSoon // ignore: cast_nullable_to_non_nullable
as List<String>,cities: null == cities ? _self.cities : cities // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceInfo].
extension ServiceInfoPatterns on ServiceInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceInfo value)  $default,){
final _that = this;
switch (_that) {
case _ServiceInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String tagline,  bool available,  int? merchants,  List<String> options,  List<String> comingSoon,  List<String> cities)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceInfo() when $default != null:
return $default(_that.id,_that.name,_that.tagline,_that.available,_that.merchants,_that.options,_that.comingSoon,_that.cities);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String tagline,  bool available,  int? merchants,  List<String> options,  List<String> comingSoon,  List<String> cities)  $default,) {final _that = this;
switch (_that) {
case _ServiceInfo():
return $default(_that.id,_that.name,_that.tagline,_that.available,_that.merchants,_that.options,_that.comingSoon,_that.cities);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String tagline,  bool available,  int? merchants,  List<String> options,  List<String> comingSoon,  List<String> cities)?  $default,) {final _that = this;
switch (_that) {
case _ServiceInfo() when $default != null:
return $default(_that.id,_that.name,_that.tagline,_that.available,_that.merchants,_that.options,_that.comingSoon,_that.cities);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceInfo implements ServiceInfo {
  const _ServiceInfo({required this.id, required this.name, this.tagline = '', this.available = true, this.merchants,  List<String> options = const <String>[],  List<String> comingSoon = const <String>[],  List<String> cities = const <String>[]}): _options = options,_comingSoon = comingSoon,_cities = cities;
  factory _ServiceInfo.fromJson(Map<String, dynamic> json) => _$ServiceInfoFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String tagline;
@override@JsonKey() final  bool available;
@override final  int? merchants;
 final  List<String> _options;
@override@JsonKey() List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

 final  List<String> _comingSoon;
@override@JsonKey() List<String> get comingSoon {
  if (_comingSoon is EqualUnmodifiableListView) return _comingSoon;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_comingSoon);
}

 final  List<String> _cities;
@override@JsonKey() List<String> get cities {
  if (_cities is EqualUnmodifiableListView) return _cities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cities);
}


/// Create a copy of ServiceInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceInfoCopyWith<_ServiceInfo> get copyWith => __$ServiceInfoCopyWithImpl<_ServiceInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.available, available) || other.available == available)&&(identical(other.merchants, merchants) || other.merchants == merchants)&&const DeepCollectionEquality().equals(other.options, _options)&&const DeepCollectionEquality().equals(other.comingSoon, _comingSoon)&&const DeepCollectionEquality().equals(other.cities, _cities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,tagline,available,merchants,const DeepCollectionEquality().hash(_options),const DeepCollectionEquality().hash(_comingSoon),const DeepCollectionEquality().hash(_cities));
}

@override
String toString() {
    return 'ServiceInfo(id: $id, name: $name, tagline: $tagline, available: $available, merchants: $merchants, options: $options, comingSoon: $comingSoon, cities: $cities)';
}


}

/// @nodoc
abstract mixin class _$ServiceInfoCopyWith<$Res> implements $ServiceInfoCopyWith<$Res> {
  factory _$ServiceInfoCopyWith(_ServiceInfo value, $Res Function(_ServiceInfo) _then) = __$ServiceInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String tagline, bool available, int? merchants, List<String> options, List<String> comingSoon, List<String> cities
});




}
/// @nodoc
class __$ServiceInfoCopyWithImpl<$Res>
    implements _$ServiceInfoCopyWith<$Res> {
  __$ServiceInfoCopyWithImpl(this._self, this._then);

  final _ServiceInfo _self;
  final $Res Function(_ServiceInfo) _then;

/// Create a copy of ServiceInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? tagline = null,Object? available = null,Object? merchants = freezed,Object? options = null,Object? comingSoon = null,Object? cities = null,}) {
  return _then(_ServiceInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,merchants: freezed == merchants ? _self.merchants : merchants // ignore: cast_nullable_to_non_nullable
as int?,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,comingSoon: null == comingSoon ? _self._comingSoon : comingSoon // ignore: cast_nullable_to_non_nullable
as List<String>,cities: null == cities ? _self._cities : cities // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$BrowseCategory {

 String get id; String get name; String get emoji; int get merchants;
/// Create a copy of BrowseCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BrowseCategoryCopyWith<BrowseCategory> get copyWith => _$BrowseCategoryCopyWithImpl<BrowseCategory>(this as BrowseCategory, _$identity);

  /// Serializes this BrowseCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BrowseCategory;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BrowseCategory&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.emoji, _this.emoji) || other.emoji == _this.emoji)&&(identical(other.merchants, _this.merchants) || other.merchants == _this.merchants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BrowseCategory;
  return Object.hash(runtimeType,_this.id,_this.name,_this.emoji,_this.merchants);
}

@override
String toString() {
  final _this = this as BrowseCategory;
  return 'BrowseCategory(id: ${_this.id}, name: ${_this.name}, emoji: ${_this.emoji}, merchants: ${_this.merchants})';
}


}

/// @nodoc
abstract mixin class $BrowseCategoryCopyWith<$Res>  {
  factory $BrowseCategoryCopyWith(BrowseCategory value, $Res Function(BrowseCategory) _then) = _$BrowseCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String emoji, int merchants
});




}
/// @nodoc
class _$BrowseCategoryCopyWithImpl<$Res>
    implements $BrowseCategoryCopyWith<$Res> {
  _$BrowseCategoryCopyWithImpl(this._self, this._then);

  final BrowseCategory _self;
  final $Res Function(BrowseCategory) _then;

/// Create a copy of BrowseCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? emoji = null,Object? merchants = null,}) {
  return _then(BrowseCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,merchants: null == merchants ? _self.merchants : merchants // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BrowseCategory].
extension BrowseCategoryPatterns on BrowseCategory {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BrowseCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BrowseCategory() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BrowseCategory value)  $default,){
final _that = this;
switch (_that) {
case _BrowseCategory():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BrowseCategory value)?  $default,){
final _that = this;
switch (_that) {
case _BrowseCategory() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String emoji,  int merchants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BrowseCategory() when $default != null:
return $default(_that.id,_that.name,_that.emoji,_that.merchants);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String emoji,  int merchants)  $default,) {final _that = this;
switch (_that) {
case _BrowseCategory():
return $default(_that.id,_that.name,_that.emoji,_that.merchants);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String emoji,  int merchants)?  $default,) {final _that = this;
switch (_that) {
case _BrowseCategory() when $default != null:
return $default(_that.id,_that.name,_that.emoji,_that.merchants);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BrowseCategory implements BrowseCategory {
  const _BrowseCategory({required this.id, required this.name, this.emoji = '', this.merchants = 0});
  factory _BrowseCategory.fromJson(Map<String, dynamic> json) => _$BrowseCategoryFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String emoji;
@override@JsonKey() final  int merchants;

/// Create a copy of BrowseCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BrowseCategoryCopyWith<_BrowseCategory> get copyWith => __$BrowseCategoryCopyWithImpl<_BrowseCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BrowseCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BrowseCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.merchants, merchants) || other.merchants == merchants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,emoji,merchants);
}

@override
String toString() {
    return 'BrowseCategory(id: $id, name: $name, emoji: $emoji, merchants: $merchants)';
}


}

/// @nodoc
abstract mixin class _$BrowseCategoryCopyWith<$Res> implements $BrowseCategoryCopyWith<$Res> {
  factory _$BrowseCategoryCopyWith(_BrowseCategory value, $Res Function(_BrowseCategory) _then) = __$BrowseCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String emoji, int merchants
});




}
/// @nodoc
class __$BrowseCategoryCopyWithImpl<$Res>
    implements _$BrowseCategoryCopyWith<$Res> {
  __$BrowseCategoryCopyWithImpl(this._self, this._then);

  final _BrowseCategory _self;
  final $Res Function(_BrowseCategory) _then;

/// Create a copy of BrowseCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? emoji = null,Object? merchants = null,}) {
  return _then(_BrowseCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,merchants: null == merchants ? _self.merchants : merchants // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PlaceArea {

 String get name; String get city; double get lat; double get lng;
/// Create a copy of PlaceArea
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceAreaCopyWith<PlaceArea> get copyWith => _$PlaceAreaCopyWithImpl<PlaceArea>(this as PlaceArea, _$identity);

  /// Serializes this PlaceArea to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlaceArea;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceArea&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.lng, _this.lng) || other.lng == _this.lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlaceArea;
  return Object.hash(runtimeType,_this.name,_this.city,_this.lat,_this.lng);
}

@override
String toString() {
  final _this = this as PlaceArea;
  return 'PlaceArea(name: ${_this.name}, city: ${_this.city}, lat: ${_this.lat}, lng: ${_this.lng})';
}


}

/// @nodoc
abstract mixin class $PlaceAreaCopyWith<$Res>  {
  factory $PlaceAreaCopyWith(PlaceArea value, $Res Function(PlaceArea) _then) = _$PlaceAreaCopyWithImpl;
@useResult
$Res call({
 String name, String city, double lat, double lng
});




}
/// @nodoc
class _$PlaceAreaCopyWithImpl<$Res>
    implements $PlaceAreaCopyWith<$Res> {
  _$PlaceAreaCopyWithImpl(this._self, this._then);

  final PlaceArea _self;
  final $Res Function(PlaceArea) _then;

/// Create a copy of PlaceArea
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? city = null,Object? lat = null,Object? lng = null,}) {
  return _then(PlaceArea(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaceArea].
extension PlaceAreaPatterns on PlaceArea {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaceArea value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaceArea() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaceArea value)  $default,){
final _that = this;
switch (_that) {
case _PlaceArea():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaceArea value)?  $default,){
final _that = this;
switch (_that) {
case _PlaceArea() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String city,  double lat,  double lng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaceArea() when $default != null:
return $default(_that.name,_that.city,_that.lat,_that.lng);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String city,  double lat,  double lng)  $default,) {final _that = this;
switch (_that) {
case _PlaceArea():
return $default(_that.name,_that.city,_that.lat,_that.lng);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String city,  double lat,  double lng)?  $default,) {final _that = this;
switch (_that) {
case _PlaceArea() when $default != null:
return $default(_that.name,_that.city,_that.lat,_that.lng);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaceArea implements PlaceArea {
  const _PlaceArea({required this.name, required this.city, required this.lat, required this.lng});
  factory _PlaceArea.fromJson(Map<String, dynamic> json) => _$PlaceAreaFromJson(json);

@override final  String name;
@override final  String city;
@override final  double lat;
@override final  double lng;

/// Create a copy of PlaceArea
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaceAreaCopyWith<_PlaceArea> get copyWith => __$PlaceAreaCopyWithImpl<_PlaceArea>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaceAreaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaceArea&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,city,lat,lng);
}

@override
String toString() {
    return 'PlaceArea(name: $name, city: $city, lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class _$PlaceAreaCopyWith<$Res> implements $PlaceAreaCopyWith<$Res> {
  factory _$PlaceAreaCopyWith(_PlaceArea value, $Res Function(_PlaceArea) _then) = __$PlaceAreaCopyWithImpl;
@override @useResult
$Res call({
 String name, String city, double lat, double lng
});




}
/// @nodoc
class __$PlaceAreaCopyWithImpl<$Res>
    implements _$PlaceAreaCopyWith<$Res> {
  __$PlaceAreaCopyWithImpl(this._self, this._then);

  final _PlaceArea _self;
  final $Res Function(_PlaceArea) _then;

/// Create a copy of PlaceArea
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? city = null,Object? lat = null,Object? lng = null,}) {
  return _then(_PlaceArea(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ParcelStop {

 String get name; String get phone; String get line1; String? get area; String get city; GeoPoint get location; String? get instructions;
/// Create a copy of ParcelStop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParcelStopCopyWith<ParcelStop> get copyWith => _$ParcelStopCopyWithImpl<ParcelStop>(this as ParcelStop, _$identity);

  /// Serializes this ParcelStop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ParcelStop;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParcelStop&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.line1, _this.line1) || other.line1 == _this.line1)&&(identical(other.area, _this.area) || other.area == _this.area)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.instructions, _this.instructions) || other.instructions == _this.instructions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ParcelStop;
  return Object.hash(runtimeType,_this.name,_this.phone,_this.line1,_this.area,_this.city,_this.location,_this.instructions);
}

@override
String toString() {
  final _this = this as ParcelStop;
  return 'ParcelStop(name: ${_this.name}, phone: ${_this.phone}, line1: ${_this.line1}, area: ${_this.area}, city: ${_this.city}, location: ${_this.location}, instructions: ${_this.instructions})';
}


}

/// @nodoc
abstract mixin class $ParcelStopCopyWith<$Res>  {
  factory $ParcelStopCopyWith(ParcelStop value, $Res Function(ParcelStop) _then) = _$ParcelStopCopyWithImpl;
@useResult
$Res call({
 String name, String phone, String line1, String? area, String city, GeoPoint location, String? instructions
});


$GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class _$ParcelStopCopyWithImpl<$Res>
    implements $ParcelStopCopyWith<$Res> {
  _$ParcelStopCopyWithImpl(this._self, this._then);

  final ParcelStop _self;
  final $Res Function(ParcelStop) _then;

/// Create a copy of ParcelStop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? phone = null,Object? line1 = null,Object? area = freezed,Object? city = null,Object? location = null,Object? instructions = freezed,}) {
  return _then(ParcelStop(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,line1: null == line1 ? _self.line1 : line1 // ignore: cast_nullable_to_non_nullable
as String,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ParcelStop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// Adds pattern-matching-related methods to [ParcelStop].
extension ParcelStopPatterns on ParcelStop {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParcelStop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParcelStop() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParcelStop value)  $default,){
final _that = this;
switch (_that) {
case _ParcelStop():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParcelStop value)?  $default,){
final _that = this;
switch (_that) {
case _ParcelStop() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String phone,  String line1,  String? area,  String city,  GeoPoint location,  String? instructions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParcelStop() when $default != null:
return $default(_that.name,_that.phone,_that.line1,_that.area,_that.city,_that.location,_that.instructions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String phone,  String line1,  String? area,  String city,  GeoPoint location,  String? instructions)  $default,) {final _that = this;
switch (_that) {
case _ParcelStop():
return $default(_that.name,_that.phone,_that.line1,_that.area,_that.city,_that.location,_that.instructions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String phone,  String line1,  String? area,  String city,  GeoPoint location,  String? instructions)?  $default,) {final _that = this;
switch (_that) {
case _ParcelStop() when $default != null:
return $default(_that.name,_that.phone,_that.line1,_that.area,_that.city,_that.location,_that.instructions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParcelStop implements ParcelStop {
  const _ParcelStop({required this.name, required this.phone, required this.line1, this.area, this.city = 'Lagos', required this.location, this.instructions});
  factory _ParcelStop.fromJson(Map<String, dynamic> json) => _$ParcelStopFromJson(json);

@override final  String name;
@override final  String phone;
@override final  String line1;
@override final  String? area;
@override@JsonKey() final  String city;
@override final  GeoPoint location;
@override final  String? instructions;

/// Create a copy of ParcelStop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParcelStopCopyWith<_ParcelStop> get copyWith => __$ParcelStopCopyWithImpl<_ParcelStop>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParcelStopToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParcelStop&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.line1, line1) || other.line1 == line1)&&(identical(other.area, area) || other.area == area)&&(identical(other.city, city) || other.city == city)&&(identical(other.location, location) || other.location == location)&&(identical(other.instructions, instructions) || other.instructions == instructions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,phone,line1,area,city,location,instructions);
}

@override
String toString() {
    return 'ParcelStop(name: $name, phone: $phone, line1: $line1, area: $area, city: $city, location: $location, instructions: $instructions)';
}


}

/// @nodoc
abstract mixin class _$ParcelStopCopyWith<$Res> implements $ParcelStopCopyWith<$Res> {
  factory _$ParcelStopCopyWith(_ParcelStop value, $Res Function(_ParcelStop) _then) = __$ParcelStopCopyWithImpl;
@override @useResult
$Res call({
 String name, String phone, String line1, String? area, String city, GeoPoint location, String? instructions
});


@override $GeoPointCopyWith<$Res> get location;

}
/// @nodoc
class __$ParcelStopCopyWithImpl<$Res>
    implements _$ParcelStopCopyWith<$Res> {
  __$ParcelStopCopyWithImpl(this._self, this._then);

  final _ParcelStop _self;
  final $Res Function(_ParcelStop) _then;

/// Create a copy of ParcelStop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? phone = null,Object? line1 = null,Object? area = freezed,Object? city = null,Object? location = null,Object? instructions = freezed,}) {
  return _then(_ParcelStop(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,line1: null == line1 ? _self.line1 : line1 // ignore: cast_nullable_to_non_nullable
as String,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ParcelStop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get location {
  
  return $GeoPointCopyWith<$Res>(_self.location, (value) {
    return _then(_self.copyWith(location: value));
  });
}
}


/// @nodoc
mixin _$ParcelDetails {

 ParcelStop get pickup; ParcelStop get dropoff; String get size; String get category; String get description; String get city;/// Cash the rider collects from the recipient for the sender (vendor cash on delivery).
 int? get codAmountKobo;
/// Create a copy of ParcelDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParcelDetailsCopyWith<ParcelDetails> get copyWith => _$ParcelDetailsCopyWithImpl<ParcelDetails>(this as ParcelDetails, _$identity);

  /// Serializes this ParcelDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ParcelDetails;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParcelDetails&&(identical(other.pickup, _this.pickup) || other.pickup == _this.pickup)&&(identical(other.dropoff, _this.dropoff) || other.dropoff == _this.dropoff)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.codAmountKobo, _this.codAmountKobo) || other.codAmountKobo == _this.codAmountKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ParcelDetails;
  return Object.hash(runtimeType,_this.pickup,_this.dropoff,_this.size,_this.category,_this.description,_this.city,_this.codAmountKobo);
}

@override
String toString() {
  final _this = this as ParcelDetails;
  return 'ParcelDetails(pickup: ${_this.pickup}, dropoff: ${_this.dropoff}, size: ${_this.size}, category: ${_this.category}, description: ${_this.description}, city: ${_this.city}, codAmountKobo: ${_this.codAmountKobo})';
}


}

/// @nodoc
abstract mixin class $ParcelDetailsCopyWith<$Res>  {
  factory $ParcelDetailsCopyWith(ParcelDetails value, $Res Function(ParcelDetails) _then) = _$ParcelDetailsCopyWithImpl;
@useResult
$Res call({
 ParcelStop pickup, ParcelStop dropoff, String size, String category, String description, String city, int? codAmountKobo
});


$ParcelStopCopyWith<$Res> get pickup;$ParcelStopCopyWith<$Res> get dropoff;

}
/// @nodoc
class _$ParcelDetailsCopyWithImpl<$Res>
    implements $ParcelDetailsCopyWith<$Res> {
  _$ParcelDetailsCopyWithImpl(this._self, this._then);

  final ParcelDetails _self;
  final $Res Function(ParcelDetails) _then;

/// Create a copy of ParcelDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pickup = null,Object? dropoff = null,Object? size = null,Object? category = null,Object? description = null,Object? city = null,Object? codAmountKobo = freezed,}) {
  return _then(ParcelDetails(
pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as ParcelStop,dropoff: null == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as ParcelStop,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,codAmountKobo: freezed == codAmountKobo ? _self.codAmountKobo : codAmountKobo // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of ParcelDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParcelStopCopyWith<$Res> get pickup {
  
  return $ParcelStopCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of ParcelDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParcelStopCopyWith<$Res> get dropoff {
  
  return $ParcelStopCopyWith<$Res>(_self.dropoff, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}
}


/// Adds pattern-matching-related methods to [ParcelDetails].
extension ParcelDetailsPatterns on ParcelDetails {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParcelDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParcelDetails() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParcelDetails value)  $default,){
final _that = this;
switch (_that) {
case _ParcelDetails():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParcelDetails value)?  $default,){
final _that = this;
switch (_that) {
case _ParcelDetails() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ParcelStop pickup,  ParcelStop dropoff,  String size,  String category,  String description,  String city,  int? codAmountKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParcelDetails() when $default != null:
return $default(_that.pickup,_that.dropoff,_that.size,_that.category,_that.description,_that.city,_that.codAmountKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ParcelStop pickup,  ParcelStop dropoff,  String size,  String category,  String description,  String city,  int? codAmountKobo)  $default,) {final _that = this;
switch (_that) {
case _ParcelDetails():
return $default(_that.pickup,_that.dropoff,_that.size,_that.category,_that.description,_that.city,_that.codAmountKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ParcelStop pickup,  ParcelStop dropoff,  String size,  String category,  String description,  String city,  int? codAmountKobo)?  $default,) {final _that = this;
switch (_that) {
case _ParcelDetails() when $default != null:
return $default(_that.pickup,_that.dropoff,_that.size,_that.category,_that.description,_that.city,_that.codAmountKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParcelDetails implements ParcelDetails {
  const _ParcelDetails({required this.pickup, required this.dropoff, this.size = 'small', this.category = 'other', this.description = '', this.city = 'lagos', this.codAmountKobo});
  factory _ParcelDetails.fromJson(Map<String, dynamic> json) => _$ParcelDetailsFromJson(json);

@override final  ParcelStop pickup;
@override final  ParcelStop dropoff;
@override@JsonKey() final  String size;
@override@JsonKey() final  String category;
@override@JsonKey() final  String description;
@override@JsonKey() final  String city;
/// Cash the rider collects from the recipient for the sender (vendor cash on delivery).
@override final  int? codAmountKobo;

/// Create a copy of ParcelDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParcelDetailsCopyWith<_ParcelDetails> get copyWith => __$ParcelDetailsCopyWithImpl<_ParcelDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParcelDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParcelDetails&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff)&&(identical(other.size, size) || other.size == size)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.city, city) || other.city == city)&&(identical(other.codAmountKobo, codAmountKobo) || other.codAmountKobo == codAmountKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,pickup,dropoff,size,category,description,city,codAmountKobo);
}

@override
String toString() {
    return 'ParcelDetails(pickup: $pickup, dropoff: $dropoff, size: $size, category: $category, description: $description, city: $city, codAmountKobo: $codAmountKobo)';
}


}

/// @nodoc
abstract mixin class _$ParcelDetailsCopyWith<$Res> implements $ParcelDetailsCopyWith<$Res> {
  factory _$ParcelDetailsCopyWith(_ParcelDetails value, $Res Function(_ParcelDetails) _then) = __$ParcelDetailsCopyWithImpl;
@override @useResult
$Res call({
 ParcelStop pickup, ParcelStop dropoff, String size, String category, String description, String city, int? codAmountKobo
});


@override $ParcelStopCopyWith<$Res> get pickup;@override $ParcelStopCopyWith<$Res> get dropoff;

}
/// @nodoc
class __$ParcelDetailsCopyWithImpl<$Res>
    implements _$ParcelDetailsCopyWith<$Res> {
  __$ParcelDetailsCopyWithImpl(this._self, this._then);

  final _ParcelDetails _self;
  final $Res Function(_ParcelDetails) _then;

/// Create a copy of ParcelDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pickup = null,Object? dropoff = null,Object? size = null,Object? category = null,Object? description = null,Object? city = null,Object? codAmountKobo = freezed,}) {
  return _then(_ParcelDetails(
pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as ParcelStop,dropoff: null == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as ParcelStop,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,codAmountKobo: freezed == codAmountKobo ? _self.codAmountKobo : codAmountKobo // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of ParcelDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParcelStopCopyWith<$Res> get pickup {
  
  return $ParcelStopCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of ParcelDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParcelStopCopyWith<$Res> get dropoff {
  
  return $ParcelStopCopyWith<$Res>(_self.dropoff, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}
}


/// @nodoc
mixin _$ParcelQuote {

 String get id; ParcelDetails get details; PriceBreakdown get breakdown; double get distanceKm; int get etaMinutes; DateTime get estimatedDeliveryAt; DateTime? get scheduledFor; DateTime get expiresAt;
/// Create a copy of ParcelQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParcelQuoteCopyWith<ParcelQuote> get copyWith => _$ParcelQuoteCopyWithImpl<ParcelQuote>(this as ParcelQuote, _$identity);

  /// Serializes this ParcelQuote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ParcelQuote;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParcelQuote&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.details, _this.details) || other.details == _this.details)&&(identical(other.breakdown, _this.breakdown) || other.breakdown == _this.breakdown)&&(identical(other.distanceKm, _this.distanceKm) || other.distanceKm == _this.distanceKm)&&(identical(other.etaMinutes, _this.etaMinutes) || other.etaMinutes == _this.etaMinutes)&&(identical(other.estimatedDeliveryAt, _this.estimatedDeliveryAt) || other.estimatedDeliveryAt == _this.estimatedDeliveryAt)&&(identical(other.scheduledFor, _this.scheduledFor) || other.scheduledFor == _this.scheduledFor)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ParcelQuote;
  return Object.hash(runtimeType,_this.id,_this.details,_this.breakdown,_this.distanceKm,_this.etaMinutes,_this.estimatedDeliveryAt,_this.scheduledFor,_this.expiresAt);
}

@override
String toString() {
  final _this = this as ParcelQuote;
  return 'ParcelQuote(id: ${_this.id}, details: ${_this.details}, breakdown: ${_this.breakdown}, distanceKm: ${_this.distanceKm}, etaMinutes: ${_this.etaMinutes}, estimatedDeliveryAt: ${_this.estimatedDeliveryAt}, scheduledFor: ${_this.scheduledFor}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $ParcelQuoteCopyWith<$Res>  {
  factory $ParcelQuoteCopyWith(ParcelQuote value, $Res Function(ParcelQuote) _then) = _$ParcelQuoteCopyWithImpl;
@useResult
$Res call({
 String id, ParcelDetails details, PriceBreakdown breakdown, double distanceKm, int etaMinutes, DateTime estimatedDeliveryAt, DateTime? scheduledFor, DateTime expiresAt
});


$ParcelDetailsCopyWith<$Res> get details;$PriceBreakdownCopyWith<$Res> get breakdown;

}
/// @nodoc
class _$ParcelQuoteCopyWithImpl<$Res>
    implements $ParcelQuoteCopyWith<$Res> {
  _$ParcelQuoteCopyWithImpl(this._self, this._then);

  final ParcelQuote _self;
  final $Res Function(ParcelQuote) _then;

/// Create a copy of ParcelQuote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? details = null,Object? breakdown = null,Object? distanceKm = null,Object? etaMinutes = null,Object? estimatedDeliveryAt = null,Object? scheduledFor = freezed,Object? expiresAt = null,}) {
  return _then(ParcelQuote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as ParcelDetails,breakdown: null == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as PriceBreakdown,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,etaMinutes: null == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as int,estimatedDeliveryAt: null == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime,scheduledFor: freezed == scheduledFor ? _self.scheduledFor : scheduledFor // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of ParcelQuote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParcelDetailsCopyWith<$Res> get details {
  
  return $ParcelDetailsCopyWith<$Res>(_self.details, (value) {
    return _then(_self.copyWith(details: value));
  });
}/// Create a copy of ParcelQuote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceBreakdownCopyWith<$Res> get breakdown {
  
  return $PriceBreakdownCopyWith<$Res>(_self.breakdown, (value) {
    return _then(_self.copyWith(breakdown: value));
  });
}
}


/// Adds pattern-matching-related methods to [ParcelQuote].
extension ParcelQuotePatterns on ParcelQuote {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParcelQuote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParcelQuote() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParcelQuote value)  $default,){
final _that = this;
switch (_that) {
case _ParcelQuote():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParcelQuote value)?  $default,){
final _that = this;
switch (_that) {
case _ParcelQuote() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ParcelDetails details,  PriceBreakdown breakdown,  double distanceKm,  int etaMinutes,  DateTime estimatedDeliveryAt,  DateTime? scheduledFor,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParcelQuote() when $default != null:
return $default(_that.id,_that.details,_that.breakdown,_that.distanceKm,_that.etaMinutes,_that.estimatedDeliveryAt,_that.scheduledFor,_that.expiresAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ParcelDetails details,  PriceBreakdown breakdown,  double distanceKm,  int etaMinutes,  DateTime estimatedDeliveryAt,  DateTime? scheduledFor,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _ParcelQuote():
return $default(_that.id,_that.details,_that.breakdown,_that.distanceKm,_that.etaMinutes,_that.estimatedDeliveryAt,_that.scheduledFor,_that.expiresAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ParcelDetails details,  PriceBreakdown breakdown,  double distanceKm,  int etaMinutes,  DateTime estimatedDeliveryAt,  DateTime? scheduledFor,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _ParcelQuote() when $default != null:
return $default(_that.id,_that.details,_that.breakdown,_that.distanceKm,_that.etaMinutes,_that.estimatedDeliveryAt,_that.scheduledFor,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParcelQuote implements ParcelQuote {
  const _ParcelQuote({required this.id, required this.details, required this.breakdown, required this.distanceKm, required this.etaMinutes, required this.estimatedDeliveryAt, this.scheduledFor, required this.expiresAt});
  factory _ParcelQuote.fromJson(Map<String, dynamic> json) => _$ParcelQuoteFromJson(json);

@override final  String id;
@override final  ParcelDetails details;
@override final  PriceBreakdown breakdown;
@override final  double distanceKm;
@override final  int etaMinutes;
@override final  DateTime estimatedDeliveryAt;
@override final  DateTime? scheduledFor;
@override final  DateTime expiresAt;

/// Create a copy of ParcelQuote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParcelQuoteCopyWith<_ParcelQuote> get copyWith => __$ParcelQuoteCopyWithImpl<_ParcelQuote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParcelQuoteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParcelQuote&&(identical(other.id, id) || other.id == id)&&(identical(other.details, details) || other.details == details)&&(identical(other.breakdown, breakdown) || other.breakdown == breakdown)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.etaMinutes, etaMinutes) || other.etaMinutes == etaMinutes)&&(identical(other.estimatedDeliveryAt, estimatedDeliveryAt) || other.estimatedDeliveryAt == estimatedDeliveryAt)&&(identical(other.scheduledFor, scheduledFor) || other.scheduledFor == scheduledFor)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,details,breakdown,distanceKm,etaMinutes,estimatedDeliveryAt,scheduledFor,expiresAt);
}

@override
String toString() {
    return 'ParcelQuote(id: $id, details: $details, breakdown: $breakdown, distanceKm: $distanceKm, etaMinutes: $etaMinutes, estimatedDeliveryAt: $estimatedDeliveryAt, scheduledFor: $scheduledFor, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$ParcelQuoteCopyWith<$Res> implements $ParcelQuoteCopyWith<$Res> {
  factory _$ParcelQuoteCopyWith(_ParcelQuote value, $Res Function(_ParcelQuote) _then) = __$ParcelQuoteCopyWithImpl;
@override @useResult
$Res call({
 String id, ParcelDetails details, PriceBreakdown breakdown, double distanceKm, int etaMinutes, DateTime estimatedDeliveryAt, DateTime? scheduledFor, DateTime expiresAt
});


@override $ParcelDetailsCopyWith<$Res> get details;@override $PriceBreakdownCopyWith<$Res> get breakdown;

}
/// @nodoc
class __$ParcelQuoteCopyWithImpl<$Res>
    implements _$ParcelQuoteCopyWith<$Res> {
  __$ParcelQuoteCopyWithImpl(this._self, this._then);

  final _ParcelQuote _self;
  final $Res Function(_ParcelQuote) _then;

/// Create a copy of ParcelQuote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? details = null,Object? breakdown = null,Object? distanceKm = null,Object? etaMinutes = null,Object? estimatedDeliveryAt = null,Object? scheduledFor = freezed,Object? expiresAt = null,}) {
  return _then(_ParcelQuote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as ParcelDetails,breakdown: null == breakdown ? _self.breakdown : breakdown // ignore: cast_nullable_to_non_nullable
as PriceBreakdown,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,etaMinutes: null == etaMinutes ? _self.etaMinutes : etaMinutes // ignore: cast_nullable_to_non_nullable
as int,estimatedDeliveryAt: null == estimatedDeliveryAt ? _self.estimatedDeliveryAt : estimatedDeliveryAt // ignore: cast_nullable_to_non_nullable
as DateTime,scheduledFor: freezed == scheduledFor ? _self.scheduledFor : scheduledFor // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of ParcelQuote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParcelDetailsCopyWith<$Res> get details {
  
  return $ParcelDetailsCopyWith<$Res>(_self.details, (value) {
    return _then(_self.copyWith(details: value));
  });
}/// Create a copy of ParcelQuote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceBreakdownCopyWith<$Res> get breakdown {
  
  return $PriceBreakdownCopyWith<$Res>(_self.breakdown, (value) {
    return _then(_self.copyWith(breakdown: value));
  });
}
}


/// @nodoc
mixin _$VerticalSpend {

 int get orders; int get spentKobo;
/// Create a copy of VerticalSpend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerticalSpendCopyWith<VerticalSpend> get copyWith => _$VerticalSpendCopyWithImpl<VerticalSpend>(this as VerticalSpend, _$identity);

  /// Serializes this VerticalSpend to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as VerticalSpend;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerticalSpend&&(identical(other.orders, _this.orders) || other.orders == _this.orders)&&(identical(other.spentKobo, _this.spentKobo) || other.spentKobo == _this.spentKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as VerticalSpend;
  return Object.hash(runtimeType,_this.orders,_this.spentKobo);
}

@override
String toString() {
  final _this = this as VerticalSpend;
  return 'VerticalSpend(orders: ${_this.orders}, spentKobo: ${_this.spentKobo})';
}


}

/// @nodoc
abstract mixin class $VerticalSpendCopyWith<$Res>  {
  factory $VerticalSpendCopyWith(VerticalSpend value, $Res Function(VerticalSpend) _then) = _$VerticalSpendCopyWithImpl;
@useResult
$Res call({
 int orders, int spentKobo
});




}
/// @nodoc
class _$VerticalSpendCopyWithImpl<$Res>
    implements $VerticalSpendCopyWith<$Res> {
  _$VerticalSpendCopyWithImpl(this._self, this._then);

  final VerticalSpend _self;
  final $Res Function(VerticalSpend) _then;

/// Create a copy of VerticalSpend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orders = null,Object? spentKobo = null,}) {
  return _then(VerticalSpend(
orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as int,spentKobo: null == spentKobo ? _self.spentKobo : spentKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VerticalSpend].
extension VerticalSpendPatterns on VerticalSpend {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerticalSpend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerticalSpend() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerticalSpend value)  $default,){
final _that = this;
switch (_that) {
case _VerticalSpend():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerticalSpend value)?  $default,){
final _that = this;
switch (_that) {
case _VerticalSpend() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int orders,  int spentKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerticalSpend() when $default != null:
return $default(_that.orders,_that.spentKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int orders,  int spentKobo)  $default,) {final _that = this;
switch (_that) {
case _VerticalSpend():
return $default(_that.orders,_that.spentKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int orders,  int spentKobo)?  $default,) {final _that = this;
switch (_that) {
case _VerticalSpend() when $default != null:
return $default(_that.orders,_that.spentKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerticalSpend implements VerticalSpend {
  const _VerticalSpend({this.orders = 0, this.spentKobo = 0});
  factory _VerticalSpend.fromJson(Map<String, dynamic> json) => _$VerticalSpendFromJson(json);

@override@JsonKey() final  int orders;
@override@JsonKey() final  int spentKobo;

/// Create a copy of VerticalSpend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerticalSpendCopyWith<_VerticalSpend> get copyWith => __$VerticalSpendCopyWithImpl<_VerticalSpend>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerticalSpendToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerticalSpend&&(identical(other.orders, orders) || other.orders == orders)&&(identical(other.spentKobo, spentKobo) || other.spentKobo == spentKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,orders,spentKobo);
}

@override
String toString() {
    return 'VerticalSpend(orders: $orders, spentKobo: $spentKobo)';
}


}

/// @nodoc
abstract mixin class _$VerticalSpendCopyWith<$Res> implements $VerticalSpendCopyWith<$Res> {
  factory _$VerticalSpendCopyWith(_VerticalSpend value, $Res Function(_VerticalSpend) _then) = __$VerticalSpendCopyWithImpl;
@override @useResult
$Res call({
 int orders, int spentKobo
});




}
/// @nodoc
class __$VerticalSpendCopyWithImpl<$Res>
    implements _$VerticalSpendCopyWith<$Res> {
  __$VerticalSpendCopyWithImpl(this._self, this._then);

  final _VerticalSpend _self;
  final $Res Function(_VerticalSpend) _then;

/// Create a copy of VerticalSpend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orders = null,Object? spentKobo = null,}) {
  return _then(_VerticalSpend(
orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as int,spentKobo: null == spentKobo ? _self.spentKobo : spentKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$FavouriteMerchant {

 String get id; String get name; int get orders;
/// Create a copy of FavouriteMerchant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavouriteMerchantCopyWith<FavouriteMerchant> get copyWith => _$FavouriteMerchantCopyWithImpl<FavouriteMerchant>(this as FavouriteMerchant, _$identity);

  /// Serializes this FavouriteMerchant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FavouriteMerchant;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavouriteMerchant&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.orders, _this.orders) || other.orders == _this.orders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FavouriteMerchant;
  return Object.hash(runtimeType,_this.id,_this.name,_this.orders);
}

@override
String toString() {
  final _this = this as FavouriteMerchant;
  return 'FavouriteMerchant(id: ${_this.id}, name: ${_this.name}, orders: ${_this.orders})';
}


}

/// @nodoc
abstract mixin class $FavouriteMerchantCopyWith<$Res>  {
  factory $FavouriteMerchantCopyWith(FavouriteMerchant value, $Res Function(FavouriteMerchant) _then) = _$FavouriteMerchantCopyWithImpl;
@useResult
$Res call({
 String id, String name, int orders
});




}
/// @nodoc
class _$FavouriteMerchantCopyWithImpl<$Res>
    implements $FavouriteMerchantCopyWith<$Res> {
  _$FavouriteMerchantCopyWithImpl(this._self, this._then);

  final FavouriteMerchant _self;
  final $Res Function(FavouriteMerchant) _then;

/// Create a copy of FavouriteMerchant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? orders = null,}) {
  return _then(FavouriteMerchant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FavouriteMerchant].
extension FavouriteMerchantPatterns on FavouriteMerchant {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FavouriteMerchant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FavouriteMerchant() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FavouriteMerchant value)  $default,){
final _that = this;
switch (_that) {
case _FavouriteMerchant():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FavouriteMerchant value)?  $default,){
final _that = this;
switch (_that) {
case _FavouriteMerchant() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int orders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FavouriteMerchant() when $default != null:
return $default(_that.id,_that.name,_that.orders);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int orders)  $default,) {final _that = this;
switch (_that) {
case _FavouriteMerchant():
return $default(_that.id,_that.name,_that.orders);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int orders)?  $default,) {final _that = this;
switch (_that) {
case _FavouriteMerchant() when $default != null:
return $default(_that.id,_that.name,_that.orders);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FavouriteMerchant implements FavouriteMerchant {
  const _FavouriteMerchant({required this.id, required this.name, this.orders = 0});
  factory _FavouriteMerchant.fromJson(Map<String, dynamic> json) => _$FavouriteMerchantFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  int orders;

/// Create a copy of FavouriteMerchant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavouriteMerchantCopyWith<_FavouriteMerchant> get copyWith => __$FavouriteMerchantCopyWithImpl<_FavouriteMerchant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FavouriteMerchantToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FavouriteMerchant&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.orders, orders) || other.orders == orders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,orders);
}

@override
String toString() {
    return 'FavouriteMerchant(id: $id, name: $name, orders: $orders)';
}


}

/// @nodoc
abstract mixin class _$FavouriteMerchantCopyWith<$Res> implements $FavouriteMerchantCopyWith<$Res> {
  factory _$FavouriteMerchantCopyWith(_FavouriteMerchant value, $Res Function(_FavouriteMerchant) _then) = __$FavouriteMerchantCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int orders
});




}
/// @nodoc
class __$FavouriteMerchantCopyWithImpl<$Res>
    implements _$FavouriteMerchantCopyWith<$Res> {
  __$FavouriteMerchantCopyWithImpl(this._self, this._then);

  final _FavouriteMerchant _self;
  final $Res Function(_FavouriteMerchant) _then;

/// Create a copy of FavouriteMerchant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? orders = null,}) {
  return _then(_FavouriteMerchant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$OrderSummary {

 int get ordersCount; int get completedCount; int get inProgressCount; int get totalSpentKobo; int get thisMonthSpentKobo; int get refundedKobo; Map<String, VerticalSpend> get byVertical; FavouriteMerchant? get favouriteMerchant;
/// Create a copy of OrderSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderSummaryCopyWith<OrderSummary> get copyWith => _$OrderSummaryCopyWithImpl<OrderSummary>(this as OrderSummary, _$identity);

  /// Serializes this OrderSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OrderSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderSummary&&(identical(other.ordersCount, _this.ordersCount) || other.ordersCount == _this.ordersCount)&&(identical(other.completedCount, _this.completedCount) || other.completedCount == _this.completedCount)&&(identical(other.inProgressCount, _this.inProgressCount) || other.inProgressCount == _this.inProgressCount)&&(identical(other.totalSpentKobo, _this.totalSpentKobo) || other.totalSpentKobo == _this.totalSpentKobo)&&(identical(other.thisMonthSpentKobo, _this.thisMonthSpentKobo) || other.thisMonthSpentKobo == _this.thisMonthSpentKobo)&&(identical(other.refundedKobo, _this.refundedKobo) || other.refundedKobo == _this.refundedKobo)&&const DeepCollectionEquality().equals(other.byVertical, _this.byVertical)&&(identical(other.favouriteMerchant, _this.favouriteMerchant) || other.favouriteMerchant == _this.favouriteMerchant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OrderSummary;
  return Object.hash(runtimeType,_this.ordersCount,_this.completedCount,_this.inProgressCount,_this.totalSpentKobo,_this.thisMonthSpentKobo,_this.refundedKobo,const DeepCollectionEquality().hash(_this.byVertical),_this.favouriteMerchant);
}

@override
String toString() {
  final _this = this as OrderSummary;
  return 'OrderSummary(ordersCount: ${_this.ordersCount}, completedCount: ${_this.completedCount}, inProgressCount: ${_this.inProgressCount}, totalSpentKobo: ${_this.totalSpentKobo}, thisMonthSpentKobo: ${_this.thisMonthSpentKobo}, refundedKobo: ${_this.refundedKobo}, byVertical: ${_this.byVertical}, favouriteMerchant: ${_this.favouriteMerchant})';
}


}

/// @nodoc
abstract mixin class $OrderSummaryCopyWith<$Res>  {
  factory $OrderSummaryCopyWith(OrderSummary value, $Res Function(OrderSummary) _then) = _$OrderSummaryCopyWithImpl;
@useResult
$Res call({
 int ordersCount, int completedCount, int inProgressCount, int totalSpentKobo, int thisMonthSpentKobo, int refundedKobo, Map<String, VerticalSpend> byVertical, FavouriteMerchant? favouriteMerchant
});


$FavouriteMerchantCopyWith<$Res>? get favouriteMerchant;

}
/// @nodoc
class _$OrderSummaryCopyWithImpl<$Res>
    implements $OrderSummaryCopyWith<$Res> {
  _$OrderSummaryCopyWithImpl(this._self, this._then);

  final OrderSummary _self;
  final $Res Function(OrderSummary) _then;

/// Create a copy of OrderSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ordersCount = null,Object? completedCount = null,Object? inProgressCount = null,Object? totalSpentKobo = null,Object? thisMonthSpentKobo = null,Object? refundedKobo = null,Object? byVertical = null,Object? favouriteMerchant = freezed,}) {
  return _then(OrderSummary(
ordersCount: null == ordersCount ? _self.ordersCount : ordersCount // ignore: cast_nullable_to_non_nullable
as int,completedCount: null == completedCount ? _self.completedCount : completedCount // ignore: cast_nullable_to_non_nullable
as int,inProgressCount: null == inProgressCount ? _self.inProgressCount : inProgressCount // ignore: cast_nullable_to_non_nullable
as int,totalSpentKobo: null == totalSpentKobo ? _self.totalSpentKobo : totalSpentKobo // ignore: cast_nullable_to_non_nullable
as int,thisMonthSpentKobo: null == thisMonthSpentKobo ? _self.thisMonthSpentKobo : thisMonthSpentKobo // ignore: cast_nullable_to_non_nullable
as int,refundedKobo: null == refundedKobo ? _self.refundedKobo : refundedKobo // ignore: cast_nullable_to_non_nullable
as int,byVertical: null == byVertical ? _self.byVertical : byVertical // ignore: cast_nullable_to_non_nullable
as Map<String, VerticalSpend>,favouriteMerchant: freezed == favouriteMerchant ? _self.favouriteMerchant : favouriteMerchant // ignore: cast_nullable_to_non_nullable
as FavouriteMerchant?,
  ));
}
/// Create a copy of OrderSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FavouriteMerchantCopyWith<$Res>? get favouriteMerchant {
    if (_self.favouriteMerchant == null) {
    return null;
  }

  return $FavouriteMerchantCopyWith<$Res>(_self.favouriteMerchant!, (value) {
    return _then(_self.copyWith(favouriteMerchant: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrderSummary].
extension OrderSummaryPatterns on OrderSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderSummary value)  $default,){
final _that = this;
switch (_that) {
case _OrderSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderSummary value)?  $default,){
final _that = this;
switch (_that) {
case _OrderSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int ordersCount,  int completedCount,  int inProgressCount,  int totalSpentKobo,  int thisMonthSpentKobo,  int refundedKobo,  Map<String, VerticalSpend> byVertical,  FavouriteMerchant? favouriteMerchant)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderSummary() when $default != null:
return $default(_that.ordersCount,_that.completedCount,_that.inProgressCount,_that.totalSpentKobo,_that.thisMonthSpentKobo,_that.refundedKobo,_that.byVertical,_that.favouriteMerchant);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int ordersCount,  int completedCount,  int inProgressCount,  int totalSpentKobo,  int thisMonthSpentKobo,  int refundedKobo,  Map<String, VerticalSpend> byVertical,  FavouriteMerchant? favouriteMerchant)  $default,) {final _that = this;
switch (_that) {
case _OrderSummary():
return $default(_that.ordersCount,_that.completedCount,_that.inProgressCount,_that.totalSpentKobo,_that.thisMonthSpentKobo,_that.refundedKobo,_that.byVertical,_that.favouriteMerchant);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int ordersCount,  int completedCount,  int inProgressCount,  int totalSpentKobo,  int thisMonthSpentKobo,  int refundedKobo,  Map<String, VerticalSpend> byVertical,  FavouriteMerchant? favouriteMerchant)?  $default,) {final _that = this;
switch (_that) {
case _OrderSummary() when $default != null:
return $default(_that.ordersCount,_that.completedCount,_that.inProgressCount,_that.totalSpentKobo,_that.thisMonthSpentKobo,_that.refundedKobo,_that.byVertical,_that.favouriteMerchant);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderSummary implements OrderSummary {
  const _OrderSummary({this.ordersCount = 0, this.completedCount = 0, this.inProgressCount = 0, this.totalSpentKobo = 0, this.thisMonthSpentKobo = 0, this.refundedKobo = 0,  Map<String, VerticalSpend> byVertical = const <String, VerticalSpend>{}, this.favouriteMerchant}): _byVertical = byVertical;
  factory _OrderSummary.fromJson(Map<String, dynamic> json) => _$OrderSummaryFromJson(json);

@override@JsonKey() final  int ordersCount;
@override@JsonKey() final  int completedCount;
@override@JsonKey() final  int inProgressCount;
@override@JsonKey() final  int totalSpentKobo;
@override@JsonKey() final  int thisMonthSpentKobo;
@override@JsonKey() final  int refundedKobo;
 final  Map<String, VerticalSpend> _byVertical;
@override@JsonKey() Map<String, VerticalSpend> get byVertical {
  if (_byVertical is EqualUnmodifiableMapView) return _byVertical;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_byVertical);
}

@override final  FavouriteMerchant? favouriteMerchant;

/// Create a copy of OrderSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderSummaryCopyWith<_OrderSummary> get copyWith => __$OrderSummaryCopyWithImpl<_OrderSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderSummary&&(identical(other.ordersCount, ordersCount) || other.ordersCount == ordersCount)&&(identical(other.completedCount, completedCount) || other.completedCount == completedCount)&&(identical(other.inProgressCount, inProgressCount) || other.inProgressCount == inProgressCount)&&(identical(other.totalSpentKobo, totalSpentKobo) || other.totalSpentKobo == totalSpentKobo)&&(identical(other.thisMonthSpentKobo, thisMonthSpentKobo) || other.thisMonthSpentKobo == thisMonthSpentKobo)&&(identical(other.refundedKobo, refundedKobo) || other.refundedKobo == refundedKobo)&&const DeepCollectionEquality().equals(other.byVertical, _byVertical)&&(identical(other.favouriteMerchant, favouriteMerchant) || other.favouriteMerchant == favouriteMerchant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,ordersCount,completedCount,inProgressCount,totalSpentKobo,thisMonthSpentKobo,refundedKobo,const DeepCollectionEquality().hash(_byVertical),favouriteMerchant);
}

@override
String toString() {
    return 'OrderSummary(ordersCount: $ordersCount, completedCount: $completedCount, inProgressCount: $inProgressCount, totalSpentKobo: $totalSpentKobo, thisMonthSpentKobo: $thisMonthSpentKobo, refundedKobo: $refundedKobo, byVertical: $byVertical, favouriteMerchant: $favouriteMerchant)';
}


}

/// @nodoc
abstract mixin class _$OrderSummaryCopyWith<$Res> implements $OrderSummaryCopyWith<$Res> {
  factory _$OrderSummaryCopyWith(_OrderSummary value, $Res Function(_OrderSummary) _then) = __$OrderSummaryCopyWithImpl;
@override @useResult
$Res call({
 int ordersCount, int completedCount, int inProgressCount, int totalSpentKobo, int thisMonthSpentKobo, int refundedKobo, Map<String, VerticalSpend> byVertical, FavouriteMerchant? favouriteMerchant
});


@override $FavouriteMerchantCopyWith<$Res>? get favouriteMerchant;

}
/// @nodoc
class __$OrderSummaryCopyWithImpl<$Res>
    implements _$OrderSummaryCopyWith<$Res> {
  __$OrderSummaryCopyWithImpl(this._self, this._then);

  final _OrderSummary _self;
  final $Res Function(_OrderSummary) _then;

/// Create a copy of OrderSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ordersCount = null,Object? completedCount = null,Object? inProgressCount = null,Object? totalSpentKobo = null,Object? thisMonthSpentKobo = null,Object? refundedKobo = null,Object? byVertical = null,Object? favouriteMerchant = freezed,}) {
  return _then(_OrderSummary(
ordersCount: null == ordersCount ? _self.ordersCount : ordersCount // ignore: cast_nullable_to_non_nullable
as int,completedCount: null == completedCount ? _self.completedCount : completedCount // ignore: cast_nullable_to_non_nullable
as int,inProgressCount: null == inProgressCount ? _self.inProgressCount : inProgressCount // ignore: cast_nullable_to_non_nullable
as int,totalSpentKobo: null == totalSpentKobo ? _self.totalSpentKobo : totalSpentKobo // ignore: cast_nullable_to_non_nullable
as int,thisMonthSpentKobo: null == thisMonthSpentKobo ? _self.thisMonthSpentKobo : thisMonthSpentKobo // ignore: cast_nullable_to_non_nullable
as int,refundedKobo: null == refundedKobo ? _self.refundedKobo : refundedKobo // ignore: cast_nullable_to_non_nullable
as int,byVertical: null == byVertical ? _self._byVertical : byVertical // ignore: cast_nullable_to_non_nullable
as Map<String, VerticalSpend>,favouriteMerchant: freezed == favouriteMerchant ? _self.favouriteMerchant : favouriteMerchant // ignore: cast_nullable_to_non_nullable
as FavouriteMerchant?,
  ));
}

/// Create a copy of OrderSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FavouriteMerchantCopyWith<$Res>? get favouriteMerchant {
    if (_self.favouriteMerchant == null) {
    return null;
  }

  return $FavouriteMerchantCopyWith<$Res>(_self.favouriteMerchant!, (value) {
    return _then(_self.copyWith(favouriteMerchant: value));
  });
}
}


/// @nodoc
mixin _$SupportContacts {

 String get whatsapp; String get phone; String get email; String get hours; bool get placeholders;
/// Create a copy of SupportContacts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportContactsCopyWith<SupportContacts> get copyWith => _$SupportContactsCopyWithImpl<SupportContacts>(this as SupportContacts, _$identity);

  /// Serializes this SupportContacts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SupportContacts;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportContacts&&(identical(other.whatsapp, _this.whatsapp) || other.whatsapp == _this.whatsapp)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.hours, _this.hours) || other.hours == _this.hours)&&(identical(other.placeholders, _this.placeholders) || other.placeholders == _this.placeholders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SupportContacts;
  return Object.hash(runtimeType,_this.whatsapp,_this.phone,_this.email,_this.hours,_this.placeholders);
}

@override
String toString() {
  final _this = this as SupportContacts;
  return 'SupportContacts(whatsapp: ${_this.whatsapp}, phone: ${_this.phone}, email: ${_this.email}, hours: ${_this.hours}, placeholders: ${_this.placeholders})';
}


}

/// @nodoc
abstract mixin class $SupportContactsCopyWith<$Res>  {
  factory $SupportContactsCopyWith(SupportContacts value, $Res Function(SupportContacts) _then) = _$SupportContactsCopyWithImpl;
@useResult
$Res call({
 String whatsapp, String phone, String email, String hours, bool placeholders
});




}
/// @nodoc
class _$SupportContactsCopyWithImpl<$Res>
    implements $SupportContactsCopyWith<$Res> {
  _$SupportContactsCopyWithImpl(this._self, this._then);

  final SupportContacts _self;
  final $Res Function(SupportContacts) _then;

/// Create a copy of SupportContacts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? whatsapp = null,Object? phone = null,Object? email = null,Object? hours = null,Object? placeholders = null,}) {
  return _then(SupportContacts(
whatsapp: null == whatsapp ? _self.whatsapp : whatsapp // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as String,placeholders: null == placeholders ? _self.placeholders : placeholders // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportContacts].
extension SupportContactsPatterns on SupportContacts {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportContacts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportContacts() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportContacts value)  $default,){
final _that = this;
switch (_that) {
case _SupportContacts():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportContacts value)?  $default,){
final _that = this;
switch (_that) {
case _SupportContacts() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String whatsapp,  String phone,  String email,  String hours,  bool placeholders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportContacts() when $default != null:
return $default(_that.whatsapp,_that.phone,_that.email,_that.hours,_that.placeholders);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String whatsapp,  String phone,  String email,  String hours,  bool placeholders)  $default,) {final _that = this;
switch (_that) {
case _SupportContacts():
return $default(_that.whatsapp,_that.phone,_that.email,_that.hours,_that.placeholders);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String whatsapp,  String phone,  String email,  String hours,  bool placeholders)?  $default,) {final _that = this;
switch (_that) {
case _SupportContacts() when $default != null:
return $default(_that.whatsapp,_that.phone,_that.email,_that.hours,_that.placeholders);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportContacts implements SupportContacts {
  const _SupportContacts({this.whatsapp = '', this.phone = '', this.email = '', this.hours = '', this.placeholders = true});
  factory _SupportContacts.fromJson(Map<String, dynamic> json) => _$SupportContactsFromJson(json);

@override@JsonKey() final  String whatsapp;
@override@JsonKey() final  String phone;
@override@JsonKey() final  String email;
@override@JsonKey() final  String hours;
@override@JsonKey() final  bool placeholders;

/// Create a copy of SupportContacts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportContactsCopyWith<_SupportContacts> get copyWith => __$SupportContactsCopyWithImpl<_SupportContacts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportContactsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportContacts&&(identical(other.whatsapp, whatsapp) || other.whatsapp == whatsapp)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.placeholders, placeholders) || other.placeholders == placeholders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,whatsapp,phone,email,hours,placeholders);
}

@override
String toString() {
    return 'SupportContacts(whatsapp: $whatsapp, phone: $phone, email: $email, hours: $hours, placeholders: $placeholders)';
}


}

/// @nodoc
abstract mixin class _$SupportContactsCopyWith<$Res> implements $SupportContactsCopyWith<$Res> {
  factory _$SupportContactsCopyWith(_SupportContacts value, $Res Function(_SupportContacts) _then) = __$SupportContactsCopyWithImpl;
@override @useResult
$Res call({
 String whatsapp, String phone, String email, String hours, bool placeholders
});




}
/// @nodoc
class __$SupportContactsCopyWithImpl<$Res>
    implements _$SupportContactsCopyWith<$Res> {
  __$SupportContactsCopyWithImpl(this._self, this._then);

  final _SupportContacts _self;
  final $Res Function(_SupportContacts) _then;

/// Create a copy of SupportContacts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? whatsapp = null,Object? phone = null,Object? email = null,Object? hours = null,Object? placeholders = null,}) {
  return _then(_SupportContacts(
whatsapp: null == whatsapp ? _self.whatsapp : whatsapp // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as String,placeholders: null == placeholders ? _self.placeholders : placeholders // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ReceiptLine {

 String get name; int get quantity; int get amountKobo; List<String> get details;
/// Create a copy of ReceiptLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptLineCopyWith<ReceiptLine> get copyWith => _$ReceiptLineCopyWithImpl<ReceiptLine>(this as ReceiptLine, _$identity);

  /// Serializes this ReceiptLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReceiptLine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptLine&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.amountKobo, _this.amountKobo) || other.amountKobo == _this.amountKobo)&&const DeepCollectionEquality().equals(other.details, _this.details));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReceiptLine;
  return Object.hash(runtimeType,_this.name,_this.quantity,_this.amountKobo,const DeepCollectionEquality().hash(_this.details));
}

@override
String toString() {
  final _this = this as ReceiptLine;
  return 'ReceiptLine(name: ${_this.name}, quantity: ${_this.quantity}, amountKobo: ${_this.amountKobo}, details: ${_this.details})';
}


}

/// @nodoc
abstract mixin class $ReceiptLineCopyWith<$Res>  {
  factory $ReceiptLineCopyWith(ReceiptLine value, $Res Function(ReceiptLine) _then) = _$ReceiptLineCopyWithImpl;
@useResult
$Res call({
 String name, int quantity, int amountKobo, List<String> details
});




}
/// @nodoc
class _$ReceiptLineCopyWithImpl<$Res>
    implements $ReceiptLineCopyWith<$Res> {
  _$ReceiptLineCopyWithImpl(this._self, this._then);

  final ReceiptLine _self;
  final $Res Function(ReceiptLine) _then;

/// Create a copy of ReceiptLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? quantity = null,Object? amountKobo = null,Object? details = null,}) {
  return _then(ReceiptLine(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceiptLine].
extension ReceiptLinePatterns on ReceiptLine {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceiptLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceiptLine() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceiptLine value)  $default,){
final _that = this;
switch (_that) {
case _ReceiptLine():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceiptLine value)?  $default,){
final _that = this;
switch (_that) {
case _ReceiptLine() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int quantity,  int amountKobo,  List<String> details)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceiptLine() when $default != null:
return $default(_that.name,_that.quantity,_that.amountKobo,_that.details);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int quantity,  int amountKobo,  List<String> details)  $default,) {final _that = this;
switch (_that) {
case _ReceiptLine():
return $default(_that.name,_that.quantity,_that.amountKobo,_that.details);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int quantity,  int amountKobo,  List<String> details)?  $default,) {final _that = this;
switch (_that) {
case _ReceiptLine() when $default != null:
return $default(_that.name,_that.quantity,_that.amountKobo,_that.details);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReceiptLine implements ReceiptLine {
  const _ReceiptLine({required this.name, this.quantity = 1, this.amountKobo = 0,  List<String> details = const []}): _details = details;
  factory _ReceiptLine.fromJson(Map<String, dynamic> json) => _$ReceiptLineFromJson(json);

@override final  String name;
@override@JsonKey() final  int quantity;
@override@JsonKey() final  int amountKobo;
 final  List<String> _details;
@override@JsonKey() List<String> get details {
  if (_details is EqualUnmodifiableListView) return _details;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_details);
}


/// Create a copy of ReceiptLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptLineCopyWith<_ReceiptLine> get copyWith => __$ReceiptLineCopyWithImpl<_ReceiptLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceiptLineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptLine&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.amountKobo, amountKobo) || other.amountKobo == amountKobo)&&const DeepCollectionEquality().equals(other.details, _details));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,quantity,amountKobo,const DeepCollectionEquality().hash(_details));
}

@override
String toString() {
    return 'ReceiptLine(name: $name, quantity: $quantity, amountKobo: $amountKobo, details: $details)';
}


}

/// @nodoc
abstract mixin class _$ReceiptLineCopyWith<$Res> implements $ReceiptLineCopyWith<$Res> {
  factory _$ReceiptLineCopyWith(_ReceiptLine value, $Res Function(_ReceiptLine) _then) = __$ReceiptLineCopyWithImpl;
@override @useResult
$Res call({
 String name, int quantity, int amountKobo, List<String> details
});




}
/// @nodoc
class __$ReceiptLineCopyWithImpl<$Res>
    implements _$ReceiptLineCopyWith<$Res> {
  __$ReceiptLineCopyWithImpl(this._self, this._then);

  final _ReceiptLine _self;
  final $Res Function(_ReceiptLine) _then;

/// Create a copy of ReceiptLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? quantity = null,Object? amountKobo = null,Object? details = null,}) {
  return _then(_ReceiptLine(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,details: null == details ? _self._details : details // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$ReceiptCharge {

 String get label; int get amountKobo;
/// Create a copy of ReceiptCharge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptChargeCopyWith<ReceiptCharge> get copyWith => _$ReceiptChargeCopyWithImpl<ReceiptCharge>(this as ReceiptCharge, _$identity);

  /// Serializes this ReceiptCharge to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReceiptCharge;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptCharge&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.amountKobo, _this.amountKobo) || other.amountKobo == _this.amountKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReceiptCharge;
  return Object.hash(runtimeType,_this.label,_this.amountKobo);
}

@override
String toString() {
  final _this = this as ReceiptCharge;
  return 'ReceiptCharge(label: ${_this.label}, amountKobo: ${_this.amountKobo})';
}


}

/// @nodoc
abstract mixin class $ReceiptChargeCopyWith<$Res>  {
  factory $ReceiptChargeCopyWith(ReceiptCharge value, $Res Function(ReceiptCharge) _then) = _$ReceiptChargeCopyWithImpl;
@useResult
$Res call({
 String label, int amountKobo
});




}
/// @nodoc
class _$ReceiptChargeCopyWithImpl<$Res>
    implements $ReceiptChargeCopyWith<$Res> {
  _$ReceiptChargeCopyWithImpl(this._self, this._then);

  final ReceiptCharge _self;
  final $Res Function(ReceiptCharge) _then;

/// Create a copy of ReceiptCharge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? amountKobo = null,}) {
  return _then(ReceiptCharge(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceiptCharge].
extension ReceiptChargePatterns on ReceiptCharge {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceiptCharge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceiptCharge() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceiptCharge value)  $default,){
final _that = this;
switch (_that) {
case _ReceiptCharge():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceiptCharge value)?  $default,){
final _that = this;
switch (_that) {
case _ReceiptCharge() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  int amountKobo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceiptCharge() when $default != null:
return $default(_that.label,_that.amountKobo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  int amountKobo)  $default,) {final _that = this;
switch (_that) {
case _ReceiptCharge():
return $default(_that.label,_that.amountKobo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  int amountKobo)?  $default,) {final _that = this;
switch (_that) {
case _ReceiptCharge() when $default != null:
return $default(_that.label,_that.amountKobo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReceiptCharge implements ReceiptCharge {
  const _ReceiptCharge({required this.label, this.amountKobo = 0});
  factory _ReceiptCharge.fromJson(Map<String, dynamic> json) => _$ReceiptChargeFromJson(json);

@override final  String label;
@override@JsonKey() final  int amountKobo;

/// Create a copy of ReceiptCharge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptChargeCopyWith<_ReceiptCharge> get copyWith => __$ReceiptChargeCopyWithImpl<_ReceiptCharge>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceiptChargeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptCharge&&(identical(other.label, label) || other.label == label)&&(identical(other.amountKobo, amountKobo) || other.amountKobo == amountKobo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,label,amountKobo);
}

@override
String toString() {
    return 'ReceiptCharge(label: $label, amountKobo: $amountKobo)';
}


}

/// @nodoc
abstract mixin class _$ReceiptChargeCopyWith<$Res> implements $ReceiptChargeCopyWith<$Res> {
  factory _$ReceiptChargeCopyWith(_ReceiptCharge value, $Res Function(_ReceiptCharge) _then) = __$ReceiptChargeCopyWithImpl;
@override @useResult
$Res call({
 String label, int amountKobo
});




}
/// @nodoc
class __$ReceiptChargeCopyWithImpl<$Res>
    implements _$ReceiptChargeCopyWith<$Res> {
  __$ReceiptChargeCopyWithImpl(this._self, this._then);

  final _ReceiptCharge _self;
  final $Res Function(_ReceiptCharge) _then;

/// Create a copy of ReceiptCharge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? amountKobo = null,}) {
  return _then(_ReceiptCharge(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,amountKobo: null == amountKobo ? _self.amountKobo : amountKobo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Receipt {

 String get id; String get number; String get orderId; String get orderCode; String? get customerName; String get service; String get serviceName; String get seller; String get sellerAddress; List<String> get summary; List<ReceiptLine> get lines; List<ReceiptCharge> get charges; int get totalKobo; int get savingsKobo; int get refundedKobo; String get paidWith; String? get paymentReference; DateTime? get paidAt; DateTime? get orderedAt; DateTime? get issuedAt; DateTime? get printedAt; int get printCount; bool get saved;
/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptCopyWith<Receipt> get copyWith => _$ReceiptCopyWithImpl<Receipt>(this as Receipt, _$identity);

  /// Serializes this Receipt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Receipt;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Receipt&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.orderId, _this.orderId) || other.orderId == _this.orderId)&&(identical(other.orderCode, _this.orderCode) || other.orderCode == _this.orderCode)&&(identical(other.customerName, _this.customerName) || other.customerName == _this.customerName)&&(identical(other.service, _this.service) || other.service == _this.service)&&(identical(other.serviceName, _this.serviceName) || other.serviceName == _this.serviceName)&&(identical(other.seller, _this.seller) || other.seller == _this.seller)&&(identical(other.sellerAddress, _this.sellerAddress) || other.sellerAddress == _this.sellerAddress)&&const DeepCollectionEquality().equals(other.summary, _this.summary)&&const DeepCollectionEquality().equals(other.lines, _this.lines)&&const DeepCollectionEquality().equals(other.charges, _this.charges)&&(identical(other.totalKobo, _this.totalKobo) || other.totalKobo == _this.totalKobo)&&(identical(other.savingsKobo, _this.savingsKobo) || other.savingsKobo == _this.savingsKobo)&&(identical(other.refundedKobo, _this.refundedKobo) || other.refundedKobo == _this.refundedKobo)&&(identical(other.paidWith, _this.paidWith) || other.paidWith == _this.paidWith)&&(identical(other.paymentReference, _this.paymentReference) || other.paymentReference == _this.paymentReference)&&(identical(other.paidAt, _this.paidAt) || other.paidAt == _this.paidAt)&&(identical(other.orderedAt, _this.orderedAt) || other.orderedAt == _this.orderedAt)&&(identical(other.issuedAt, _this.issuedAt) || other.issuedAt == _this.issuedAt)&&(identical(other.printedAt, _this.printedAt) || other.printedAt == _this.printedAt)&&(identical(other.printCount, _this.printCount) || other.printCount == _this.printCount)&&(identical(other.saved, _this.saved) || other.saved == _this.saved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Receipt;
  return Object.hashAll([runtimeType,_this.id,_this.number,_this.orderId,_this.orderCode,_this.customerName,_this.service,_this.serviceName,_this.seller,_this.sellerAddress,const DeepCollectionEquality().hash(_this.summary),const DeepCollectionEquality().hash(_this.lines),const DeepCollectionEquality().hash(_this.charges),_this.totalKobo,_this.savingsKobo,_this.refundedKobo,_this.paidWith,_this.paymentReference,_this.paidAt,_this.orderedAt,_this.issuedAt,_this.printedAt,_this.printCount,_this.saved]);
}

@override
String toString() {
  final _this = this as Receipt;
  return 'Receipt(id: ${_this.id}, number: ${_this.number}, orderId: ${_this.orderId}, orderCode: ${_this.orderCode}, customerName: ${_this.customerName}, service: ${_this.service}, serviceName: ${_this.serviceName}, seller: ${_this.seller}, sellerAddress: ${_this.sellerAddress}, summary: ${_this.summary}, lines: ${_this.lines}, charges: ${_this.charges}, totalKobo: ${_this.totalKobo}, savingsKobo: ${_this.savingsKobo}, refundedKobo: ${_this.refundedKobo}, paidWith: ${_this.paidWith}, paymentReference: ${_this.paymentReference}, paidAt: ${_this.paidAt}, orderedAt: ${_this.orderedAt}, issuedAt: ${_this.issuedAt}, printedAt: ${_this.printedAt}, printCount: ${_this.printCount}, saved: ${_this.saved})';
}


}

/// @nodoc
abstract mixin class $ReceiptCopyWith<$Res>  {
  factory $ReceiptCopyWith(Receipt value, $Res Function(Receipt) _then) = _$ReceiptCopyWithImpl;
@useResult
$Res call({
 String id, String number, String orderId, String orderCode, String? customerName, String service, String serviceName, String seller, String sellerAddress, List<String> summary, List<ReceiptLine> lines, List<ReceiptCharge> charges, int totalKobo, int savingsKobo, int refundedKobo, String paidWith, String? paymentReference, DateTime? paidAt, DateTime? orderedAt, DateTime? issuedAt, DateTime? printedAt, int printCount, bool saved
});




}
/// @nodoc
class _$ReceiptCopyWithImpl<$Res>
    implements $ReceiptCopyWith<$Res> {
  _$ReceiptCopyWithImpl(this._self, this._then);

  final Receipt _self;
  final $Res Function(Receipt) _then;

/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? orderId = null,Object? orderCode = null,Object? customerName = freezed,Object? service = null,Object? serviceName = null,Object? seller = null,Object? sellerAddress = null,Object? summary = null,Object? lines = null,Object? charges = null,Object? totalKobo = null,Object? savingsKobo = null,Object? refundedKobo = null,Object? paidWith = null,Object? paymentReference = freezed,Object? paidAt = freezed,Object? orderedAt = freezed,Object? issuedAt = freezed,Object? printedAt = freezed,Object? printCount = null,Object? saved = null,}) {
  return _then(Receipt(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,orderCode: null == orderCode ? _self.orderCode : orderCode // ignore: cast_nullable_to_non_nullable
as String,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as String,serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,seller: null == seller ? _self.seller : seller // ignore: cast_nullable_to_non_nullable
as String,sellerAddress: null == sellerAddress ? _self.sellerAddress : sellerAddress // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as List<String>,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<ReceiptLine>,charges: null == charges ? _self.charges : charges // ignore: cast_nullable_to_non_nullable
as List<ReceiptCharge>,totalKobo: null == totalKobo ? _self.totalKobo : totalKobo // ignore: cast_nullable_to_non_nullable
as int,savingsKobo: null == savingsKobo ? _self.savingsKobo : savingsKobo // ignore: cast_nullable_to_non_nullable
as int,refundedKobo: null == refundedKobo ? _self.refundedKobo : refundedKobo // ignore: cast_nullable_to_non_nullable
as int,paidWith: null == paidWith ? _self.paidWith : paidWith // ignore: cast_nullable_to_non_nullable
as String,paymentReference: freezed == paymentReference ? _self.paymentReference : paymentReference // ignore: cast_nullable_to_non_nullable
as String?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,orderedAt: freezed == orderedAt ? _self.orderedAt : orderedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,printedAt: freezed == printedAt ? _self.printedAt : printedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,printCount: null == printCount ? _self.printCount : printCount // ignore: cast_nullable_to_non_nullable
as int,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Receipt].
extension ReceiptPatterns on Receipt {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Receipt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Receipt() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Receipt value)  $default,){
final _that = this;
switch (_that) {
case _Receipt():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Receipt value)?  $default,){
final _that = this;
switch (_that) {
case _Receipt() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String number,  String orderId,  String orderCode,  String? customerName,  String service,  String serviceName,  String seller,  String sellerAddress,  List<String> summary,  List<ReceiptLine> lines,  List<ReceiptCharge> charges,  int totalKobo,  int savingsKobo,  int refundedKobo,  String paidWith,  String? paymentReference,  DateTime? paidAt,  DateTime? orderedAt,  DateTime? issuedAt,  DateTime? printedAt,  int printCount,  bool saved)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Receipt() when $default != null:
return $default(_that.id,_that.number,_that.orderId,_that.orderCode,_that.customerName,_that.service,_that.serviceName,_that.seller,_that.sellerAddress,_that.summary,_that.lines,_that.charges,_that.totalKobo,_that.savingsKobo,_that.refundedKobo,_that.paidWith,_that.paymentReference,_that.paidAt,_that.orderedAt,_that.issuedAt,_that.printedAt,_that.printCount,_that.saved);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String number,  String orderId,  String orderCode,  String? customerName,  String service,  String serviceName,  String seller,  String sellerAddress,  List<String> summary,  List<ReceiptLine> lines,  List<ReceiptCharge> charges,  int totalKobo,  int savingsKobo,  int refundedKobo,  String paidWith,  String? paymentReference,  DateTime? paidAt,  DateTime? orderedAt,  DateTime? issuedAt,  DateTime? printedAt,  int printCount,  bool saved)  $default,) {final _that = this;
switch (_that) {
case _Receipt():
return $default(_that.id,_that.number,_that.orderId,_that.orderCode,_that.customerName,_that.service,_that.serviceName,_that.seller,_that.sellerAddress,_that.summary,_that.lines,_that.charges,_that.totalKobo,_that.savingsKobo,_that.refundedKobo,_that.paidWith,_that.paymentReference,_that.paidAt,_that.orderedAt,_that.issuedAt,_that.printedAt,_that.printCount,_that.saved);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String number,  String orderId,  String orderCode,  String? customerName,  String service,  String serviceName,  String seller,  String sellerAddress,  List<String> summary,  List<ReceiptLine> lines,  List<ReceiptCharge> charges,  int totalKobo,  int savingsKobo,  int refundedKobo,  String paidWith,  String? paymentReference,  DateTime? paidAt,  DateTime? orderedAt,  DateTime? issuedAt,  DateTime? printedAt,  int printCount,  bool saved)?  $default,) {final _that = this;
switch (_that) {
case _Receipt() when $default != null:
return $default(_that.id,_that.number,_that.orderId,_that.orderCode,_that.customerName,_that.service,_that.serviceName,_that.seller,_that.sellerAddress,_that.summary,_that.lines,_that.charges,_that.totalKobo,_that.savingsKobo,_that.refundedKobo,_that.paidWith,_that.paymentReference,_that.paidAt,_that.orderedAt,_that.issuedAt,_that.printedAt,_that.printCount,_that.saved);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Receipt implements Receipt {
  const _Receipt({required this.id, required this.number, required this.orderId, this.orderCode = '', this.customerName, this.service = 'food', this.serviceName = '', this.seller = '', this.sellerAddress = '',  List<String> summary = const [],  List<ReceiptLine> lines = const [],  List<ReceiptCharge> charges = const [], this.totalKobo = 0, this.savingsKobo = 0, this.refundedKobo = 0, this.paidWith = '', this.paymentReference, this.paidAt, this.orderedAt, this.issuedAt, this.printedAt, this.printCount = 0, this.saved = false}): _summary = summary,_lines = lines,_charges = charges;
  factory _Receipt.fromJson(Map<String, dynamic> json) => _$ReceiptFromJson(json);

@override final  String id;
@override final  String number;
@override final  String orderId;
@override@JsonKey() final  String orderCode;
@override final  String? customerName;
@override@JsonKey() final  String service;
@override@JsonKey() final  String serviceName;
@override@JsonKey() final  String seller;
@override@JsonKey() final  String sellerAddress;
 final  List<String> _summary;
@override@JsonKey() List<String> get summary {
  if (_summary is EqualUnmodifiableListView) return _summary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_summary);
}

 final  List<ReceiptLine> _lines;
@override@JsonKey() List<ReceiptLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

 final  List<ReceiptCharge> _charges;
@override@JsonKey() List<ReceiptCharge> get charges {
  if (_charges is EqualUnmodifiableListView) return _charges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_charges);
}

@override@JsonKey() final  int totalKobo;
@override@JsonKey() final  int savingsKobo;
@override@JsonKey() final  int refundedKobo;
@override@JsonKey() final  String paidWith;
@override final  String? paymentReference;
@override final  DateTime? paidAt;
@override final  DateTime? orderedAt;
@override final  DateTime? issuedAt;
@override final  DateTime? printedAt;
@override@JsonKey() final  int printCount;
@override@JsonKey() final  bool saved;

/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptCopyWith<_Receipt> get copyWith => __$ReceiptCopyWithImpl<_Receipt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceiptToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Receipt&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.orderCode, orderCode) || other.orderCode == orderCode)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.service, service) || other.service == service)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.seller, seller) || other.seller == seller)&&(identical(other.sellerAddress, sellerAddress) || other.sellerAddress == sellerAddress)&&const DeepCollectionEquality().equals(other.summary, _summary)&&const DeepCollectionEquality().equals(other.lines, _lines)&&const DeepCollectionEquality().equals(other.charges, _charges)&&(identical(other.totalKobo, totalKobo) || other.totalKobo == totalKobo)&&(identical(other.savingsKobo, savingsKobo) || other.savingsKobo == savingsKobo)&&(identical(other.refundedKobo, refundedKobo) || other.refundedKobo == refundedKobo)&&(identical(other.paidWith, paidWith) || other.paidWith == paidWith)&&(identical(other.paymentReference, paymentReference) || other.paymentReference == paymentReference)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.orderedAt, orderedAt) || other.orderedAt == orderedAt)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.printedAt, printedAt) || other.printedAt == printedAt)&&(identical(other.printCount, printCount) || other.printCount == printCount)&&(identical(other.saved, saved) || other.saved == saved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,number,orderId,orderCode,customerName,service,serviceName,seller,sellerAddress,const DeepCollectionEquality().hash(_summary),const DeepCollectionEquality().hash(_lines),const DeepCollectionEquality().hash(_charges),totalKobo,savingsKobo,refundedKobo,paidWith,paymentReference,paidAt,orderedAt,issuedAt,printedAt,printCount,saved]);
}

@override
String toString() {
    return 'Receipt(id: $id, number: $number, orderId: $orderId, orderCode: $orderCode, customerName: $customerName, service: $service, serviceName: $serviceName, seller: $seller, sellerAddress: $sellerAddress, summary: $summary, lines: $lines, charges: $charges, totalKobo: $totalKobo, savingsKobo: $savingsKobo, refundedKobo: $refundedKobo, paidWith: $paidWith, paymentReference: $paymentReference, paidAt: $paidAt, orderedAt: $orderedAt, issuedAt: $issuedAt, printedAt: $printedAt, printCount: $printCount, saved: $saved)';
}


}

/// @nodoc
abstract mixin class _$ReceiptCopyWith<$Res> implements $ReceiptCopyWith<$Res> {
  factory _$ReceiptCopyWith(_Receipt value, $Res Function(_Receipt) _then) = __$ReceiptCopyWithImpl;
@override @useResult
$Res call({
 String id, String number, String orderId, String orderCode, String? customerName, String service, String serviceName, String seller, String sellerAddress, List<String> summary, List<ReceiptLine> lines, List<ReceiptCharge> charges, int totalKobo, int savingsKobo, int refundedKobo, String paidWith, String? paymentReference, DateTime? paidAt, DateTime? orderedAt, DateTime? issuedAt, DateTime? printedAt, int printCount, bool saved
});




}
/// @nodoc
class __$ReceiptCopyWithImpl<$Res>
    implements _$ReceiptCopyWith<$Res> {
  __$ReceiptCopyWithImpl(this._self, this._then);

  final _Receipt _self;
  final $Res Function(_Receipt) _then;

/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? orderId = null,Object? orderCode = null,Object? customerName = freezed,Object? service = null,Object? serviceName = null,Object? seller = null,Object? sellerAddress = null,Object? summary = null,Object? lines = null,Object? charges = null,Object? totalKobo = null,Object? savingsKobo = null,Object? refundedKobo = null,Object? paidWith = null,Object? paymentReference = freezed,Object? paidAt = freezed,Object? orderedAt = freezed,Object? issuedAt = freezed,Object? printedAt = freezed,Object? printCount = null,Object? saved = null,}) {
  return _then(_Receipt(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,orderCode: null == orderCode ? _self.orderCode : orderCode // ignore: cast_nullable_to_non_nullable
as String,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as String,serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,seller: null == seller ? _self.seller : seller // ignore: cast_nullable_to_non_nullable
as String,sellerAddress: null == sellerAddress ? _self.sellerAddress : sellerAddress // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self._summary : summary // ignore: cast_nullable_to_non_nullable
as List<String>,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<ReceiptLine>,charges: null == charges ? _self._charges : charges // ignore: cast_nullable_to_non_nullable
as List<ReceiptCharge>,totalKobo: null == totalKobo ? _self.totalKobo : totalKobo // ignore: cast_nullable_to_non_nullable
as int,savingsKobo: null == savingsKobo ? _self.savingsKobo : savingsKobo // ignore: cast_nullable_to_non_nullable
as int,refundedKobo: null == refundedKobo ? _self.refundedKobo : refundedKobo // ignore: cast_nullable_to_non_nullable
as int,paidWith: null == paidWith ? _self.paidWith : paidWith // ignore: cast_nullable_to_non_nullable
as String,paymentReference: freezed == paymentReference ? _self.paymentReference : paymentReference // ignore: cast_nullable_to_non_nullable
as String?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,orderedAt: freezed == orderedAt ? _self.orderedAt : orderedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,printedAt: freezed == printedAt ? _self.printedAt : printedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,printCount: null == printCount ? _self.printCount : printCount // ignore: cast_nullable_to_non_nullable
as int,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
