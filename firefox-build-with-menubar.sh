#!/bin/sh

########################################################################################################################
# This script takes the Arch stable firefox PKGBUILD, revises it to add the appmenu/menubar patches, and optionally
# builds the modified firefox.
########################################################################################################################

# Download current PKGBUILD from Arch
wget -q -O- https://gitlab.archlinux.org/archlinux/packaging/packages/firefox/-/archive/main/firefox-main.tar.gz | \
  tar -xzf - --strip-components=1

# Download menubar patch from firefox-appmenu-112.0-1
wget -q -N https://raw.githubusercontent.com/archlinux/aur/1ab4aad0eaaa2f5313aee62606420b0b92c3d238/unity-menubar.patch

# Generate assert.patch
cat << EOF > assert.patch
--- a/xpcom/base/nsCOMPtr.h	2023-06-29 13:34:21.000000000 -0400
+++ b/xpcom/base/nsCOMPtr.h	2023-07-06 11:03:59.049048830 -0400
@@ -815,10 +815,6 @@
                                  const nsIID& aIID) {
   // Allow QIing to nsISupports from nsISupports as a special-case, since
   // SameCOMIdentity uses it.
-  static_assert(
-      std::is_same_v<T, nsISupports> ||
-          !(std::is_same_v<T, U> || std::is_base_of<T, U>::value),
-      "don't use do_QueryInterface for compile-time-determinable casts");
   void* newRawPtr;
   if (NS_FAILED(aQI(aIID, &newRawPtr))) {
     newRawPtr = nullptr;
EOF

# Generate fix_csd_window_buttons.patch
cat << EOF > fix_csd_window_buttons.patch
--- a/browser/base/content/browser.css
+++ b/browser/base/content/browser.css
@@ -334,5 +334,5 @@ toolbar[customizing] #whats-new-menu-button {
 %ifdef MENUBAR_CAN_AUTOHIDE
 #toolbar-menubar[autohide=true]:not([inactive]) + #TabsToolbar > .titlebar-buttonbox-container {
-  visibility: hidden;
+  visibility: visible;
 }
 %endif
EOF

# Save original PKGBUILD
cp PKGBUILD PKGBUILD.orig

# Revise maintainer string
printf "Enter maintainer string: "
read -r maintainer
if [[ -n $maintainer ]]; then
  sed -i "s/# Maintainer:/# Contributor:/g;
          1i # Maintainer: $maintainer" PKGBUILD
fi

# Add menubar patches
patch -s -p1 <<'EOF'
--- firefox/PKGBUILD	2023-08-30 02:15:49.000000000 -0400
+++ firefox2/PKGBUILD	2023-09-09 10:04:52.241855178 -0400
@@ -98,6 +98,11 @@
   mkdir mozbuild
   cd firefox-$pkgver
 
+  # Appmenu patches
+  patch -Np1 -i ../unity-menubar.patch
+  patch -Np1 -i ../fix_csd_window_buttons.patch
+  patch -Np1 -i ../assert.patch
+
   echo -n "$_google_api_key" >google-api-key
   echo -n "$_mozilla_api_key" >mozilla-api-key
 
EOF

sed -i '/# vim/d' PKGBUILD

cat <<'EOF' >> PKGBUILD
source+=('unity-menubar.patch'
         'fix_csd_window_buttons.patch'
         'assert.patch')
sha256sums+=('74440d292e76426ac5cba9058a6f86763c37a9aa61b7afc47771140f1f53870b'
             '72b897d8a07e7cf3ddbe04a7e0a5bb577981d367c12f934907898fbf6ddf03e4'
             'ed84a17fa4a17faa70a0528556dbafeeb6ee59697451325881cb064b0ee8afec')
b2sums+=('4b3837b398c5391ac036a59c8df51f9ad170b2d8c3d5d2011a63bacd9e24a81de4505ddf7ef722a0a6920b02bb8dbc2bb7b6f151e2aa7843baccec0572cc56c0'
         'bafaf2663380ab7ba1c4a03c49debc965f4197a35058a5066be421eae172dd9cc5ba7ae7a26a9fd0c9f1d4c9a7670f425261071e01f71e7641531568754baf74'
         'bbc69752492649f288e0ceef6ce4a1703030cc98abd2442b7ebfba2be786eea643f594af5dc237a6e3c04fd0c8b147f529fd9e790f04c64b9f10abb3c826827f')
EOF

# Default to -appmenu suffix
printf "Append -appmenu to package name? [Y/n] "
read -r ans
if [[ "$ans" != n && "$ans" != no ]]; then
  sed -i '/pkgname=firefox/i pkgbase=firefox
       s/pkgname=firefox/pkgname=$pkgbase-appmenu/g;
       s/$pkgname/$pkgbase/g;
       s/${pkgname/${pkgbase/g' PKGBUILD
  cat <<'EOF' >> PKGBUILD
provides=(firefox)
conflicts=(firefox)
EOF
fi

# Build
printf "PKGBUILD generated. Continue with build? [y/N] "
read -r ans
if [[ "$ans" == y || "$ans" == yes ]]; then
  makepkg --skippgpcheck -s
fi
