LUADIR=lua-5.0.2

REVISION=$(shell svn info |grep Revision| cut -b 11-)

COMMON_CFLAGS  = -std=gnu99 -Wall -DREVISION="$(REVISION)" -I$(LUADIR)/include/ 
COMMON_CFLAGS += -O3 -fexpensive-optimizations -finline-functions -fomit-frame-pointer -DNDEBUG
# COMMON_CFLAGS += -ggdb

ifdef WINDOWS
	MINGW  = $(HOME)/progs/mingw32/
	SDLDIR = $(MINGW)
	CC     = /opt/xmingw/bin/i386-mingw32msvc-gcc
	CFLAGS = $(COMMON_CFLAGS) -I$(MINGW)/include
	WINDRES= /opt/xmingw/bin/i386-mingw32msvc-windres
else
	SDLDIR = $(shell sdl-config --prefix)
	CFLAGS = $(COMMON_CFLAGS)
endif

CFLAGS     += -I$(SDLDIR)/include/SDL 

LDFLAGS 	= -L$(LUADIR)/lib -levent -lSDL -llua -llualib -lm -lpthread

ifdef WINDOWS
	MINGW=/home/dividuum/progs/mingw32/
	GUI_LDFLAGS += $(MINGW)/lib/libSGE.a $(MINGW)/lib/libevent.a \
                   $(MINGW)/lib/libSDL_image.a $(MINGW)/lib/libSDL_gfx.a  $(MINGW)/lib/libSDL.a \
	               -lmingw32 -lstdc++ -lwsock32 -lwinmm -mwindows -Wl,-s
	RES=infon.res				   
	GUI_EXECUTABLE=infon.exe
else
	GUI_LDFLAGS = -L$(SDLDIR)/lib -levent -lSDL -lSDL_image -lSGE -lSDL_gfx
	GUI_EXECUTABLE=infon
endif

all: infond $(GUI_EXECUTABLE)

dist:
	$(MAKE) clean
	WINDOWS=1 $(MAKE) win32-client-dist
	$(MAKE) clean
	$(MAKE) linux-client-dist linux-server-dist

win32-client-dist: $(GUI_EXECUTABLE)
	/opt/xmingw/bin/i386-mingw32msvc-strip $(GUI_EXECUTABLE)
	zip      infon-win32-r$(REVISION).zip $(GUI_EXECUTABLE) gfx/*.fnt gfx/*.gif gfx/*.png gfx/*.bmp 

linux-client-dist: $(GUI_EXECUTABLE)
	strip $(GUI_EXECUTABLE)
	tar cfvz infon-linux-r$(REVISION).tgz $(GUI_EXECUTABLE) gfx/*.fnt gfx/*.gif gfx/*.png gfx/*.bmp 

linux-server-dist: infond
	strip infond infond-static
	tar cfvz infond-linux-r$(REVISION).tgz infond infond-static *.lua

infond: lua-5.0.2/lib/liblua.a  infond.o server.o listener.o map.o path.o misc.o packet.o player.o world.o creature.o scroller.o 
	$(CC) $^ $(LDFLAGS) -o $@
	$(CC) $^ $(LDFLAGS) -static -o $@-static

$(GUI_EXECUTABLE): infon.o client.o packet.o misc.o gui_player.o gui_world.o gui_creature.o gui_scroller.o video.o sprite.o $(RES)
	$(CC) $^ $(GUI_LDFLAGS) -o $@ 

infon.res: infon.rc
	$(WINDRES) -i $^ --input-format=rc -o $@ -O coff

lua-5.0.2/lib/liblua.a:
	$(MAKE) -C $(LUADIR)

clean:
	$(MAKE) -C $(LUADIR) clean
	-rm -f *.o infond infond-static infon infon.exe infon.res tags 

distclean: clean
	-rm -f infon*.zip infon*.tgz
