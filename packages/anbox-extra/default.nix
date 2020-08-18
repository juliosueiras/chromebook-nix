with import <nixpkgs> {};

# Modifed from https://raw.githubusercontent.com/geeks-r-us/anbox-playstore-installer/master/install-playstore.sh

let
  anboxXML = ./anbox.xml;

  opengapps = fetchurl {
    url = "https://sourceforge.net/projects/opengapps/files/x86_64/20200817/open_gapps-x86_64-7.1-pico-20200817.zip";
    sha256 = "1irrbg28kam8yjijp632kjsvjafd2bh3py0v7sqg79q9794cm5s6";
  };

  houdini_y = fetchurl {
    url = "http://dl.android-x86.org/houdini/7_y/houdini.sfs";
    sha256 = "0rdnc0y0zsi8wyf0a4gh76pz08li2c3rr0bid8w7h1c49320izan";
  };

  houdini_z = fetchurl {
    url = "http://dl.android-x86.org/houdini/7_z/houdini.sfs";
    sha256 = "1likkbkbdzd56milf3829q6w5k7g8690jsj03ahq9yz62lhc9vby";
  };

in stdenv.mkDerivation {
  name = "anbox-playstore-overlay";

  buildInputs = [
    lzip
    unzip
    squashfsTools
    wget
  ];

  src = null;


  APPDIR = "overlays/system/priv-app";
  OVERLAYDIR = "overlays";

  buildCommand = ''
    WORKDIR=$PWD
    mkdir -p houdini_{z,y} squashfs-root overlays/system/{lib/arm,lib64/arm64,priv-app,etc/permissions}

    unzip ${opengapps} -d opengapps
    unsquashfs -f -d houdini_y ${houdini_y}
    unsquashfs -f -d houdini_z ${houdini_z}
    unsquashfs -f -d squashfs-root ${anbox.image}
    cp ${anboxXML} overlays/system/etc/permissions/anbox.xml
    cp squashfs-root/system/build.prop $OVERLAYDIR/system/build.prop
    cp squashfs-root/default.prop $OVERLAYDIR/default.prop
    

    cp -r ./houdini_y/* overlays/system/lib/arm/
    mv overlays/system/lib/arm/libhoudini.so overlays/system/lib/
     
    cp -r ./houdini_z/* overlays/system/lib64/arm64/
    mv overlays/system/lib64/arm64/libhoudini.so overlays/system/lib64/

    cd opengapps/Core
    for filename in *.tar.lz
    do
      tar --lzip -xvf ./$filename
    done

    cd $WORKDIR
    cp -r ./$(find opengapps -type d -name "PrebuiltGmsCore") $APPDIR
    cp -r ./$(find opengapps -type d -name "Phonesky") $APPDIR
    cp -r ./$(find opengapps -type d -name "GoogleLoginService") $APPDIR
    cp -r ./$(find opengapps -type d -name "GoogleServicesFramework") $APPDIR


    sed -i "/^ro.product.cpu.abilist=x86_64,x86/ s/$/,armeabi-v7a,armeabi,arm64-v8a/" "$OVERLAYDIR/system/build.prop"
    sed -i "/^ro.product.cpu.abilist32=x86/ s/$/,armeabi-v7a,armeabi/" "$OVERLAYDIR/system/build.prop"
    sed -i "/^ro.product.cpu.abilist64=x86_64/ s/$/,arm64-v8a/" "$OVERLAYDIR/system/build.prop"

    echo "persist.sys.nativebridge=1" | tee -a "$OVERLAYDIR/system/build.prop"
    sed -i '/ro.zygote=zygote64_32/a\ro.dalvik.vm.native.bridge=libhoudini.so' "$OVERLAYDIR/default.prop"

    echo "ro.opengles.version=131072" | tee -a "$OVERLAYDIR/system/build.prop"
    mkdir -p $out
    cp -rf overlays $out/
  '';


  meta = with stdenv.lib; {
    license = licenses.unfree;
  };
}
