package com.vfph.virtualfitnessph;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Create a notification channel
        //createNotificationChannel();

        // Fetch the FCM token
//        FirebaseMessaging.getInstance().getToken().addOnCompleteListener(task -> {
//            if (!task.isSuccessful()) {
//                Log.w("FCM Token", "Fetching FCM token failed", task.getException());
//                return;
//            }
//            String token = task.getResult();
//            // Log the token
//            Log.d("FCM Token", token);
//            // Optionally, you can send the token to your backend server here
//        });
    }

//    private void createNotificationChannel() {
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            CharSequence name = "VirtualFitness PH Notifications";
//            String description = "This channel is used for VirtualFitness PH notifications.";
//            int importance = NotificationManager.IMPORTANCE_HIGH;
//            NotificationChannel channel = new NotificationChannel("virtualfitnessph_channel", name, importance);
//            channel.setDescription(description);
//
//            // Register the channel with the system; you can't change the importance or other notification behaviors after this
//            NotificationManager notificationManager = getSystemService(NotificationManager.class);
//            notificationManager.createNotificationChannel(channel);
//        }
//    }
}