package com.rescueapp

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.net.Uri
import android.os.Bundle
import android.os.CountDownTimer
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.*
import java.net.URLEncoder
import kotlin.math.pow
import kotlin.math.sqrt

class MainActivity : AppCompatActivity(), SensorEventListener {

    // REPLACE WITH YOUR TEST EMERGENCY CONTACT (Country Code + Phone, no '+')
    private val emergencyPhoneNumber = "14155552671"

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var sensorManager: SensorManager
    private var lastLocation: Location? = null
    
    private lateinit var tvLocation: TextView
    private lateinit var btnSos: Button
    
    private var countdownDialog: AlertDialog? = null
    private var countDownTimer: CountDownTimer? = null
    private val impactThreshold = 38.0 // ~3.8G (m/s^2)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        tvLocation = findViewById(R.id.tvLocation)
        btnSos = findViewById(R.id.btnSos)

        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager

        val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_UI)

        checkPermissionsAndStartLocation()

        btnSos.setOnClickListener {
            startEmergencyCountdown()
        }
    }

    private fun checkPermissionsAndStartLocation() {
        val permissions = arrayOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, permissions, 1001)
            return
        }

        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 5000)
            .setMinUpdateDistanceMeters(5f)
            .build()

        fusedLocationClient.requestLocationUpdates(locationRequest, object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.lastLocation?.let { loc ->
                    lastLocation = loc
                    tvLocation.text = String.format("Lat: %.5f | Lon: %.5f", loc.latitude, loc.longitude)
                }
            }
        }, mainLooper)
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_ACCELEROMETER) {
            val x = event.values[0]
            val y = event.values[1]
            val z = event.values[2]
            val totalAcceleration = sqrt(x.toDouble().pow(2.0) + y.toDouble().pow(2.0) + z.toDouble().pow(2.0))

            if (totalAcceleration > impactThreshold) {
                startEmergencyCountdown()
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun startEmergencyCountdown() {
        if (countdownDialog?.isShowing == true) return

        var secondsRemaining = 10
        val builder = AlertDialog.Builder(this)
            .setTitle("🚨 CRASH DETECTED!")
            .setMessage("Sending live location via WhatsApp in $secondsRemaining seconds...")
            .setNegativeButton("I'M OK - CANCEL") { _, _ ->
                countDownTimer?.cancel()
            }
            .setCancelable(false)

        countdownDialog = builder.create()
        countdownDialog?.show()

        countDownTimer = object : CountDownTimer(10000, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                secondsRemaining = (millisUntilFinished / 1000).toInt()
                countdownDialog?.setMessage("Sending live location via WhatsApp in $secondsRemaining seconds...")
            }

            override fun onFinish() {
                countdownDialog?.dismiss()
                sendWhatsAppEmergencyAlert()
            }
        }.start()
    }

    private fun sendWhatsAppEmergencyAlert() {
        val lat = lastLocation?.latitude ?: 0.0
        val lon = lastLocation?.longitude ?: 0.0
        val mapsUrl = "https://maps.google.com/?q=$lat,$lon"

        val message = """
            🚨 EMERGENCY ALERT 🚨
            I have been involved in an accident. Here is my current GPS location:
            $mapsUrl
            
            Speed: ${((lastLocation?.speed ?: 0f) * 3.6).toInt()} km/h
            Please send emergency help immediately!
        """.trimIndent()

        try {
            val encodedMessage = URLEncoder.encode(message, "UTF-8")
            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("https://api.whatsapp.com/send?phone=$emergencyPhoneNumber&text=$encodedMessage")
                setPackage("com.whatsapp")
            }
            startActivity(intent)
        } catch (e: Exception) {
            val fallbackIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://api.whatsapp.com/send?phone=$emergencyPhoneNumber&text=${URLEncoder.encode(message, "UTF-8")}"))
            startActivity(fallbackIntent)
        }
    }
}
