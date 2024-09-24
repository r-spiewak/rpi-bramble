---
title: "Ncurses Installation"
date: 2024-04-04
order: 7
id: install-ncurses
---

{% comment %}
`sudo apt-get install libncurses-dev`
{% endcomment %}

On the head node, first get the most recent release (at this time, it seems to be 6.4):
```
sudo wget -P /clusterfs/scratch https://invisible-island.net/archives/ncurses/ncurses-6.4.tar.gz
```

Change to the correct directory and extract the archive:
```
cd /clusterfs/scratch
tar xzf ncurses-6.4.tar.gz
```

{% comment %}
```
./configure --prefix=/clusterfs   \
    --exec-prefix=
    #--runstatedir=
    #--host=$LFS_TGT              \
    #--build=$(./config.guess)    \
    #--mandir=/clusterfs/share/man \
    #--datadir=/clusterfs/share \
    --with-shared           \
    --without-debug         \
    --without-normal        \
    --with-cxx-shared       \
    --enable-pc-files       \
    --enable-widec          \
    --without-ada           \
    --disable-stripping     \
    --disable-overwrite
    #--with-pkg-config-libdir=/usr/lib/pkgconfig
```
{% endcomment %}
Try these `configure` options:
```
./configure --prefix=/clusterfs   \
    --exec-prefix=/clusterfs/usr \
    --with-shared           \
    --without-debug         \
    --with-normal        \
    --with-cxx-shared       \
    --enable-pc-files       \
    --enable-widec          \
    --without-ada           \
    --disable-stripping     \
    --disable-overwrite
```
{% comment %}
Looks like `--with-shared` is not recognized...
But then it doesn't build the so files????
No, I forgot a backslash, so everything after it didn't work...
Also, I used `--with-normal` instead of the `--without-normal`. But that was probably a waste...
{% endcomment %}

Now make it it and install it:
```
make
make install
```
{% comment %}
(probably remove the custom `DESTDIR` since it is prepended to the custom locations already created in the `configure` step...)
```
make DESTDIR=$PWD/dest install
#install -vm755 dest/usr/lib/libncursesw.so.6.4 /usr/lib
```
{% endcomment %}

Since we enabled the wide codec, we may need to modify a header file to allow the non-wide version as well (according to [this post](https://www.linuxfromscratch.org/lfs/view/development/chapter06/ncurses.html)). The command below will supposedly do that. 
```
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i dest/clusterfs/include/ncurses/curses.h
```
But I'm not sure what it's actually changing, since the `grep` below shows the following output:
```
grep "#if.*XOPEN.*$" dest/clusterfs/include/ncurses/curses.h 
#if defined(_XOPEN_SOURCE_EXTENDED) || (defined(_XOPEN_SOURCE) && (_XOPEN_SOURCE - 0 >= 500))
```
From looking at the `sed` line and the file, it seems like it will replace the condition with 1, so the post always wants the definition `define NCURSES_WIDECHAR 1`. But we can instead keep the original version by adding the 1 as an or condition first (using `nano dest/clusterfs/include/ncurses/curses.h` to make the edits):
```
#if 1||defined(_XOPEN_SOURCE_EXTENDED) || (defined(_XOPEN_SOURCE) && (_XOPEN_SOURCE - 0 >= 500))
```
(Note that we'll likely have to point to the correct include directory for it later also.)
{% comment %}
```
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h
for lib in ncurses form panel menu ; do
    ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
done
ln -sfv libncursesw.so /usr/lib/libcurses.so
```
{% endcomment %}
For the same reason, we must also make links to the wide versions from the regular versions:
```
for lib in form menu ncurses ncurses++ panel ; do
    for ext in a so so.6 so.6.4 ; do
        sudo ln -s /clusterfs/usr/lib/lib${lib}w.${ext} /clusterfs/usr/lib/lib${lib}.${ext}
    done
    sudo ln -s /clusterfs/usr/lib/pkgconfig/${lib}w.pc /clusterfs/usr/lib/pkgconfig/${lib}.pc
done
```
(More links can also be created later, if necessary.)

On every node, link all the library files:
```
for version in "" w ; do
    for lib in form menu ncurses ncurses++ panel ; do
        for ext in a so so.6 so.6.4 ; do
            sudo ln -s /clusterfs/usr/lib/lib${lib}${version}.${ext} /usr/lib/lib${lib}${version}.${ext}
        done
        sudo ln -s /clusterfs/usr/lib/pkgconfig/${lib}${version}.pc /usr/lib/pkgconfig/${lib}${version}.pc
    done
done
```

Note: It's entirely possible that this library only needs to be present on the node actually building other programs, and not actually on each node to run the other programs.
