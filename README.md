# TWRP for Snapdragon 8 Gen 1 Engineering Device (QRD8450 DVT2.0_2nd)

## Features

* Works: ADB, Decryption of /data, Correct screenshot color, MTP, Flashing, Backup, Sdcard
* Partially working: USB OTG

## Fixed Issues

* Vibration fully fixed
* Health HAL fully fixed

---

## 8Gen1 TWRP Fix Process for Vibration & Health HAL

### 1. Symptoms

* Touch press responds instantly, but touch release causes serious UI lag.
* Logcat shows TWRP waiting for the vibrator HAL:

```text
Waiting for service 'android.hardware.vibrator.IVibrator/vibratorfeature'
```

* Kernel haptics node exists:

```text
/dev/input/event2
```

* `qcom-hv-haptics` is registered correctly by the kernel.
* The kernel driver was working, but the userspace HAL was missing from the recovery environment.

### 2. Fix Steps

#### 2.1 BoardConfig Macros

```makefile
TW_SUPPORT_INPUT_AIDL_HAPTICS := true
TW_SUPPORT_INPUT_AIDL_HAPTICS_FQNAME := "IVibrator/vibratorfeature"
TW_SUPPORT_INPUT_AIDL_HAPTICS_FIX_OFF := true
```

> Note: If your device registers the vibrator service as `IVibrator/default`, replace `IVibrator/vibratorfeature` with `IVibrator/default`.

#### 2.2 VINTF Declaration

Add the required HAL declarations to `manifest.xml`:

```xml
<hal format="aidl">
    <name>android.hardware.vibrator</name>
    <version>2</version>
    <fqname>IVibrator/vibratorfeature</fqname>
</hal>

<hal format="hidl">
    <name>android.hardware.health</name>
    <transport>hwbinder</transport>
    <fqname>@2.1::IHealth/default</fqname>
</hal>
```

#### 2.3 rc Service

Add the HAL services to `init.recovery.qcom.rc` or `recovery.rc`:

```rc
service vendor.qti.hardware.vibrator.service /vendor/bin/vendor.qti.hardware.vibrator.service
    class hal
    user root
    group root system input
    seclabel u:r:recovery:s0
    oneshot

service vendor.health-hal-2-1 /vendor/bin/hw/android.hardware.health@2.1-service
    class hal
    user root
    group root system
    capabilities WAKE_ALARM
    file /dev/kmsg w
    seclabel u:r:recovery:s0
    interface android.hardware.health@2.1::IHealth default
    oneshot

on boot
    start vendor.qti.hardware.vibrator.service
    start vendor.health-hal-2-1
```

#### 2.4 Add HAL Binaries and Dependencies

Copy the required HAL binaries from stock firmware:

```bash
cp /vendor/bin/vendor.qti.hardware.vibrator.service recovery/root/vendor/bin/
cp /vendor/bin/hw/android.hardware.health@2.1-service recovery/root/vendor/bin/hw/
```

Analyze dependencies:

```bash
readelf -d recovery/root/vendor/bin/vendor.qti.hardware.vibrator.service | grep NEEDED
readelf -d recovery/root/vendor/bin/hw/android.hardware.health@2.1-service | grep NEEDED
```

Then recursively copy all required `.so` files into the recovery ramdisk, usually under:

```text
recovery/root/vendor/lib64/
recovery/root/system/lib64/
```

Missing dependencies may cause the HAL service to abort or fail to register.

### 3. Verification

Boot into TWRP and run:

```bash
service list | grep -E "vibrator|health"
cat /proc/bus/input/devices | grep -A8 -i haptic
ls -l /dev/input/event2
```

Expected result:

* Vibrator HAL is registered.
* Health HAL is registered.
* Touch vibration responds instantly.
* TWRP UI no longer lags on touch release.

### Core Principle

**BoardConfig macro + VINTF declaration + rc service + HAL binaries/dependencies** are all required.

If any one of them is missing, the HAL may fail to start, fail to register, or cause TWRP to wait for the service and lag.

---

## Compile

First checkout minimal TWRP with OmniROM tree:

```bash
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp -b twrp-12.1
repo sync
```

Then add this project to `.repo/manifest.xml`:

```xml
<project path="device/qcom/qrd8450" name="your-username/twrp_device_qcom_qrd8450" remote="github" revision="android-12.1" />
```

Finally execute:

```bash
. build/envsetup.sh
lunch twrp_qrd8450-eng
mka recoveryimage
```

To test it:

```bash
fastboot flash recovery out/target/product/qrd8450/recovery.img
```

## Note

This TWRP is built for the Snapdragon 8 Gen 1 engineering device, QRD8450 DVT2.0_2nd.

## Thanks

* [@rtyutechstudio](https://github.com/rtyutechstudio/) for the TWRP base
