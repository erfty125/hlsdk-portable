
#1. install https://github.com/lzhiyong/termux-ndk( to compile libs ),
#  set path to this dir in NDKDIR variable
#2. get android.jar file, for example:
# wget https://raw.githubusercontent.com/Sable/android-platforms/master/android-23/android.jar
# and set path to this file in AJAR variable
#3. edit libname variable, for exammple LIBNAME=damnmod
#4. open in nano app/src/main/java/su/xash/hlsdk/MainActivity.java
#  and add .putExtra("argv", "-console -dll @fard") line in code, so launcher
#  will launch your library instead of default hl lib, also replace fard with
#  your LIBNAME variable, for example .putExtra("argv", "-console -dll @damnmod")
#5. create keystore file, to sign apk, example command:
#  keytool -genkeypair -v -keystore my-release-key.keystore -alias my-alias -keyalg RSA -keysize 2048 -validity 10000
#6. set path to keystore file in KEYSTORE variable
#   and set password of key in KEYPASS variable
#7. now you can read tips, close this file and
#  enter command to build launcher:
#      bash build.sh

# IMPORTANT: LAUNCH THIS SCRIPT ONLY FROM
# SCRIPT LOCATION, OR YOU WILL FAIL BUILD

# tips:
# dont shit in AndroidManifest.xml file
# I strongly recommend you to only edit variables in this file
# edit package name in AndroidManifest.xml and in MainActivity.java
#


#envars
##########
AJAR=~/android-platforms/android-23/android.jar
RT=~/../usr/lib/rt.jar
AN=Launcher
KEYSTORE=~/Launcher.keystore
KEYPASS=defaultpassword
LIBNAME=fard
NDKDIR=~/android-ndk-r29
##########


WPATH=app/src/main
#buildflags
##########
#java
JF="-Xlint:deprecation -source 1.8 -target 1.8\
	-bootclasspath ${RT}\
	-classpath ${AJAR} -d build/obj"
JTF=${WPATH}/java/su/xash/hlsdk/MainActivity.java
#java

#dx
DXF="--dex --output=build/apk/classes.dex build/obj/"

#aapt
AGRF=" -I ${AJAR} -f -m -J build/gen/ -M build/AndroidManifest.xml"
APF=" -I ${AJAR} -f -M build/AndroidManifest.xml \
	-F build/${AN}.apk build/apk/"
#aapt
##########



#COMMANDS
##########
set -e
rm -rf build/*
mkdir -p build/gen build/obj build/apk build/lib/arm64-v8a

if [ -d "../build/dlls" ]; then
    echo "cmake was configured(maybe)"
else
    echo "cmake was not configured, configuring..."
cd ..
cmake -DCMAKE_TOOLCHAIN_FILE=${NDKDIR}/build/cmake/android.toolchain.cmake \
      -DANDROID_ABI=arm64-v8a \
      -DANDROID_PLATFORM=android-21 \
      -DCMAKE_BUILD_TYPE=Release \
      -B build
cd android
fi

cp ${WPATH}/AndroidManifest.xml build
sed -i '/<manifest/apackage="su.xash.hlsdk"' build/AndroidManifest.xml
sed -i '/<\/queries>/a<uses-sdk android:minSdkVersion="3" android:targetSdkVersion="34"\/>' build/AndroidManifest.xml
#default manifest file not containing this lines, so we just copying into it

aapt package ${AGRF}
echo "aapt done"
javac ${JF} ${JTF}
echo "java done"
dx ${DXF}
echo "dx done"
aapt package ${APF}
echo "aapt done"

cd ..
cmake --build build
cp build/cl_dll/libclient_android_arm64.so android/build/lib/arm64-v8a
cp build/dlls/libhl_android_arm64.so android/build/lib/arm64-v8a/lib${LIBNAME}_android_arm64.so

cd android/build
aapt add ${AN}.apk lib/arm64-v8a/libclient_android_arm64.so
aapt add ${AN}.apk lib/arm64-v8a/lib${LIBNAME}_android_arm64.so
cd ..

echo "cmake build done"
echo ${KEYPASS} | apksigner sign --ks ~/launcher/Launcher.keystore build/Launcher.apk
#cp build/Launcher.apk /sdcard
echo "build done, if not opening installation prompt, try termux-open build/${AN}.apk"

termux-open build/${AN}.apk
##########
