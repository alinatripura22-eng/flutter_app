package com.MeTube.me_tube
//
//com.MeTube.me_tube
//import io.flutter.embedding.android.FlutterActivity

//class MainActivity: FlutterActivity() {
//}
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
}

//
//
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
//class MainActivity : FlutterActivity() {
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//
//        // TODO: Register the ListTileNativeAdFactory
//        GoogleMobileAdsPlugin.registerNativeAdFactory(
//            flutterEngine, "listTileSmall",
//            NativeAdFactorySmall(context)
//        )
//        GoogleMobileAdsPlugin.registerNativeAdFactory(
//            flutterEngine, "listTileMedium",
//            NativeAdFactoryMedium(context)
//        )
//    }
//
//    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
//        super.cleanUpFlutterEngine(flutterEngine)
//
//        // TODO: Unregister the ListTileNativeAdFactory
//        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")
//        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTileMedium")
//    }
//}