# Maintainer: karboncore
# Contributor: Jan Alexander Steffens (heftig) <heftig@archlinux.org>
# Contributor: Ionut Biru <ibiru@archlinux.org>
# Contributor: Jakub Schmidtke <sjakub@gmail.com>

pkgbase=firefox
pkgname=$pkgbase-appmenu
pkgver=120.0
pkgrel=1
pkgdesc="Standalone web browser from mozilla.org"
url="https://www.mozilla.org/firefox/"
arch=(x86_64)
license=(
  GPL
  LGPL
  MPL
)
depends=(
  dbus
  ffmpeg
  gtk3
  libpulse
  libxss
  libxt
  mime-types
  nss
  ttf-font
)
makedepends=(
  cbindgen
  clang
  diffutils
  dump_syms
  imake
  inetutils
  jack
  lld
  llvm
  mesa
  nasm
  nodejs
  python
  rust
  unzip
  wasi-compiler-rt
  wasi-libc
  wasi-libc++
  wasi-libc++abi
  xorg-server-xvfb
  yasm
  zip
)
optdepends=(
  'hunspell-en_US: Spell checking, American English'
  'libnotify: Notification integration'
  'networkmanager: Location detection via available WiFi networks'
  'pulseaudio: Audio support'
  'speech-dispatcher: Text-to-Speech'
  'xdg-desktop-portal: Screensharing with Wayland'
)
options=(
  !debug
  !emptydirs
  !lto
  !makeflags
  !strip
)
source=(
  https://archive.mozilla.org/pub/firefox/releases/$pkgver/source/firefox-$pkgver.source.tar.xz{,.asc}
  $pkgbase.desktop
  identity-icons-brand.svg
)
validpgpkeys=(
  # Mozilla Software Releases <release@mozilla.com>
  # https://blog.mozilla.org/security/2023/05/11/updated-gpg-key-for-signing-firefox-releases/
  14F26682D0916CDD81E37B6D61B7B526D98F0353
)
sha256sums=('e710058701074eda53ca9f5fd52c57254858a027984f735bdcd58d6906f6b574'
            'SKIP'
            '1f241fdc619f92a914c75aece7c7c717401d7467c9a306458e106b05f34e5044'
            'a9b8b4a0a1f4a7b4af77d5fc70c2686d624038909263c795ecc81e0aec7711e9')
b2sums=('06f11d9d6f705c13c3288f1757d68c7c910e258b3efa643f0f0168fba0d585f758082af3905c951e227894df0c092965663f52196ee1fc3477195748e0049767'
        'SKIP'
        'd07557840097dd48a60c51cc5111950781e1c6ce255557693bd11306c7a9258b2a82548329762148f117b2295145f9e66e0483a18e2fe09c5afcffed2e4b8628'
        '63a8dd9d8910f9efb353bed452d8b4b2a2da435857ccee083fc0c557f8c4c1339ca593b463db320f70387a1b63f1a79e709e9d12c69520993e26d85a3d742e34')

# Google API keys (see http://www.chromium.org/developers/how-tos/api-keys)
# Note: These are for Arch Linux use ONLY. For your own distribution, please
# get your own set of keys. Feel free to contact foutrelis@archlinux.org for
# more information.
_google_api_key=AIzaSyDwr302FpOSkGRpLlUpPThNTDPbXcIn_FM

# Mozilla API keys (see https://location.services.mozilla.com/api)
# Note: These are for Arch Linux use ONLY. For your own distribution, please
# get your own set of keys. Feel free to contact heftig@archlinux.org for
# more information.
_mozilla_api_key=e05d56db0a694edc8b5aaebda3f2db6a

prepare() {
  mkdir mozbuild
  cd firefox-$pkgver

  # Appmenu patches
  patch -Np1 -i ../unity-menubar.patch
  patch -Np1 -i ../fix_csd_window_buttons.patch
  patch -Np1 -i ../assert.patch

  echo -n "$_google_api_key" >google-api-key
  echo -n "$_mozilla_api_key" >mozilla-api-key

  cat >../mozconfig <<END
ac_add_options --enable-application=browser
mk_add_options MOZ_OBJDIR=${PWD@Q}/obj

ac_add_options --prefix=/usr
ac_add_options --enable-release
ac_add_options --enable-hardening
ac_add_options --enable-optimize
ac_add_options --enable-rust-simd
ac_add_options --enable-linker=lld
ac_add_options --disable-elf-hack
ac_add_options --disable-bootstrap
ac_add_options --with-wasi-sysroot=/usr/share/wasi-sysroot

# Branding
ac_add_options --enable-official-branding
ac_add_options --enable-update-channel=release
ac_add_options --with-distribution-id=org.archlinux
ac_add_options --with-unsigned-addon-scopes=app,system
ac_add_options --allow-addon-sideload
export MOZILLA_OFFICIAL=1
export MOZ_APP_REMOTINGNAME=${pkgbase//-/}

# Keys
ac_add_options --with-google-location-service-api-keyfile=${PWD@Q}/google-api-key
ac_add_options --with-google-safebrowsing-api-keyfile=${PWD@Q}/google-api-key
ac_add_options --with-mozilla-api-keyfile=${PWD@Q}/mozilla-api-key

# System libraries
ac_add_options --with-system-nspr
ac_add_options --with-system-nss

# Features
ac_add_options --enable-alsa
ac_add_options --enable-jack
ac_add_options --enable-crashreporter
ac_add_options --disable-updater
ac_add_options --disable-tests
END
}

build() {
  cd firefox-$pkgver

  export MOZ_NOSPAM=1
  export MOZBUILD_STATE_PATH="$srcdir/mozbuild"
  export MOZ_ENABLE_FULL_SYMBOLS=1
  export MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE=pip

  # malloc_usable_size is used in various parts of the codebase
  CFLAGS="${CFLAGS/_FORTIFY_SOURCE=3/_FORTIFY_SOURCE=2}"
  CXXFLAGS="${CXXFLAGS/_FORTIFY_SOURCE=3/_FORTIFY_SOURCE=2}"

  # LTO needs more open files
  ulimit -n 4096

  # Do 3-tier PGO
  echo "Building instrumented browser..."
  cat >.mozconfig ../mozconfig - <<END
ac_add_options --enable-profile-generate=cross
END
  ./mach build

  echo "Profiling instrumented browser..."
  ./mach package
  LLVM_PROFDATA=llvm-profdata \
    JARLOG_FILE="$PWD/jarlog" \
    xvfb-run -s "-screen 0 1920x1080x24 -nolisten local" \
    ./mach python build/pgo/profileserver.py

  stat -c "Profile data found (%s bytes)" merged.profdata
  test -s merged.profdata

  stat -c "Jar log found (%s bytes)" jarlog
  test -s jarlog

  echo "Removing instrumented browser..."
  ./mach clobber

  echo "Building optimized browser..."
  cat >.mozconfig ../mozconfig - <<END
ac_add_options --enable-lto=cross,full
ac_add_options --enable-profile-use=cross
ac_add_options --with-pgo-profile-path=${PWD@Q}/merged.profdata
ac_add_options --with-pgo-jarlog=${PWD@Q}/jarlog
END
  ./mach build

  echo "Building symbol archive..."
  ./mach buildsymbols
}

package() {
  cd firefox-$pkgver
  DESTDIR="$pkgdir" ./mach install

  local vendorjs="$pkgdir/usr/lib/$pkgbase/browser/defaults/preferences/vendor.js"
  install -Dvm644 /dev/stdin "$vendorjs" <<END
// Use LANG environment variable to choose locale
pref("intl.locale.requested", "");

// Use system-provided dictionaries
pref("spellchecker.dictionary_path", "/usr/share/hunspell");

// Disable default browser checking.
pref("browser.shell.checkDefaultBrowser", false);

// Don't disable extensions in the application directory
pref("extensions.autoDisableScopes", 11);

// Enable GNOME Shell search provider
pref("browser.gnome-search-provider.enabled", true);
END

  local distini="$pkgdir/usr/lib/$pkgbase/distribution/distribution.ini"
  install -Dvm644 /dev/stdin "$distini" <<END
[Global]
id=archlinux
version=1.0
about=Mozilla Firefox for Arch Linux

[Preferences]
app.distributor=archlinux
app.distributor.channel=$pkgbase
app.partner.archlinux=archlinux
END

  local i theme=official
  for i in 16 22 24 32 48 64 128 256; do
    install -Dvm644 browser/branding/$theme/default$i.png \
      "$pkgdir/usr/share/icons/hicolor/${i}x${i}/apps/$pkgbase.png"
  done
  install -Dvm644 browser/branding/$theme/content/about-logo.png \
    "$pkgdir/usr/share/icons/hicolor/192x192/apps/$pkgbase.png"
  install -Dvm644 browser/branding/$theme/content/about-logo@2x.png \
    "$pkgdir/usr/share/icons/hicolor/384x384/apps/$pkgbase.png"
  install -Dvm644 browser/branding/$theme/content/about-logo.svg \
    "$pkgdir/usr/share/icons/hicolor/scalable/apps/$pkgbase.svg"
  install -Dvm644 ../identity-icons-brand.svg \
    "$pkgdir/usr/share/icons/hicolor/symbolic/apps/$pkgbase-symbolic.svg"

  install -Dvm644 ../$pkgbase.desktop \
    "$pkgdir/usr/share/applications/$pkgbase.desktop"

  # Install a wrapper to avoid confusion about binary path
  install -Dvm755 /dev/stdin "$pkgdir/usr/bin/$pkgbase" <<END
#!/bin/sh
exec /usr/lib/$pkgbase/firefox "\$@"
END

  # Replace duplicate binary with wrapper
  # https://bugzilla.mozilla.org/show_bug.cgi?id=658850
  ln -srfv "$pkgdir/usr/bin/$pkgbase" "$pkgdir/usr/lib/$pkgbase/firefox-bin"

  # Use system certificates
  local nssckbi="$pkgdir/usr/lib/$pkgbase/libnssckbi.so"
  if [[ -e $nssckbi ]]; then
    ln -srfv "$pkgdir/usr/lib/libnssckbi.so" "$nssckbi"
  fi

  local sprovider="$pkgdir/usr/share/gnome-shell/search-providers/$pkgbase.search-provider.ini"
  install -Dvm644 /dev/stdin "$sprovider" <<END
[Shell Search Provider]
DesktopId=$pkgbase.desktop
BusName=org.mozilla.${pkgbase//-/}.SearchProvider
ObjectPath=/org/mozilla/${pkgbase//-/}/SearchProvider
Version=2
END

  export SOCORRO_SYMBOL_UPLOAD_TOKEN_FILE="$startdir/.crash-stats-api.token"
  if [[ -f $SOCORRO_SYMBOL_UPLOAD_TOKEN_FILE ]]; then
    make -C obj uploadsymbols
  else
    cp -fvt "$startdir" obj/dist/*crashreporter-symbols-full.tar.zst
  fi
}

source+=('unity-menubar.patch'
         'fix_csd_window_buttons.patch'
         'assert.patch')
sha256sums+=('74440d292e76426ac5cba9058a6f86763c37a9aa61b7afc47771140f1f53870b'
             '72b897d8a07e7cf3ddbe04a7e0a5bb577981d367c12f934907898fbf6ddf03e4'
             'ed84a17fa4a17faa70a0528556dbafeeb6ee59697451325881cb064b0ee8afec')
b2sums+=('4b3837b398c5391ac036a59c8df51f9ad170b2d8c3d5d2011a63bacd9e24a81de4505ddf7ef722a0a6920b02bb8dbc2bb7b6f151e2aa7843baccec0572cc56c0'
         'bafaf2663380ab7ba1c4a03c49debc965f4197a35058a5066be421eae172dd9cc5ba7ae7a26a9fd0c9f1d4c9a7670f425261071e01f71e7641531568754baf74'
         'bbc69752492649f288e0ceef6ce4a1703030cc98abd2442b7ebfba2be786eea643f594af5dc237a6e3c04fd0c8b147f529fd9e790f04c64b9f10abb3c826827f')
provides=(firefox)
conflicts=(firefox)
