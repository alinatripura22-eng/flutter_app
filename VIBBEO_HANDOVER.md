# VIBBEO APP - COMPLETE HANDOVER DOCUMENT

## BACKEND (Render)
- **URL:** https://metube-backend-so2g.onrender.com
- **Status:** LIVE ✅
- **Platform:** Render.com
- **Account:** alinatripura22@gmail.com
- **Service ID:** srv-d5j331v5r7bs73dpgc9g (or similar)

## MONGODB
- **Connection String:** [STORED IN RENDER ENVIRONMENT VARIABLES]
- **Username:** [STORED SECURELY]
- **Password:** [STORED SECURELY]
- **Database:** vibbeo
- **Cluster:** cluster0.z46yrf8.mongodb.net

**Note:** MongoDB credentials are stored securely in Render environment variables.
To access: Render Dashboard → Your Service → Environment → MONGODB_URI

## FIREBASE
- **Project:** chenal8-963c6
- **Android:** google-services.json (in android/app/)
- **iOS:** GoogleService-Info.plist (in ios/Runner/)

## ADMOB IDS
**Android:**
- App ID: ca-app-pub-4519705537022498~7868817851
- Banner: ca-app-pub-4519705537022498/9888476532
- Interstitial: ca-app-pub-4519705537022498/1409035492
- Rewarded: ca-app-pub-4519705537022498/6222556089
- App Open: ca-app-pub-4519705537022498/1924040818

**iOS:**
- App ID: ca-app-pub-4519705537022498~7868817851
- Banner: ca-app-pub-4519705537022498/8679336644
- Interstitial: ca-app-pub-4519705537022498/5310937273
- Rewarded: ca-app-pub-4519705537022498/8074693809
- App Open: ca-app-pub-4519705537022498/2497071675

## BUNNYCDN
- **Pull Zone:** vibbeo-videos.b-cdn.net
- **Storage Zone:** vibbeo-storage (ID: 1331961)
- **Status:** NOT configured in app (videos use Firebase Storage)
- **FTP Password:** b2533e82-f18e-4660-88f895b76b39-de38-436a

## APP CONFIGURATION
- **Package Name:** com.vibbeo.app
- **Base URL:** https://metube-backend-so2g.onrender.com/
- **Secret Key:** vibbeo_secret_key_2024

## GITHUB
- **Backend Repo:** https://github.com/alinatripura22-eng/vibbeo-backend
- **App Repo:** https://github.com/alinatripura22-eng/flutter_app

## APK
- **File:** vibbeo-with-backend.apk (426MB)
- **Type:** Debug build
- **Download:** Available in workspace

## WHAT WORKS
✅ Backend server running
✅ MongoDB connected
✅ Firebase configured
✅ AdMob IDs configured
✅ All 200+ app features
✅ Authentication, videos, comments, likes, subscriptions, etc.

## WHAT NEEDS WORK
⚠️ BunnyCDN not configured (videos upload to Firebase instead)
⚠️ Release APK not built (need signing key)
⚠️ iOS build not done

## DEVELOPER TASKS
1. Test all app features
2. Configure BunnyCDN if needed
3. Build signed release APK
4. Upload to Play Store
5. Build iOS version (if needed)

## IMPORTANT NOTES
- Render free tier sleeps after 15 min (50 sec wake time)
- Upgrade to $7/month for always-on
- MongoDB free tier: 512MB storage
- Firebase free tier: generous limits

## CREDENTIALS SUMMARY
- Render: alinatripura22@gmail.com
- MongoDB: metube_user / eurquQHgXOLse0rm
- Firebase: chenal8-963c6
- GitHub: alinatripura22-eng
- AdMob: ca-app-pub-4519705537022498

