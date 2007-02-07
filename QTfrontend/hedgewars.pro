TEMPLATE = app
TARGET = hedgewars
DEPENDPATH += .
INCLUDEPATH += .
DESTDIR	= ../bin

win32 {
	RC_FILE	= ./res/hedgewars.rc
}

QT += network svg

HEADERS += binds.h \
           game.h \
           hwform.h \
           sdlkeys.h \
           team.h \
           netclient.h \
           teamselect.h \
           teamselhelper.h \
           frameTeam.h \
           vertScrollArea.h \
           gameuiconfig.h \
           ui_hwform.h \
           gamecfgwidget.h \
           predefteams.h \
           pages.h \
           SquareLabel.h \
           hedgehogerWidget.h \
           hwmap.h \
           mapContainer.h \
           tcpBase.h \
           about.h \
           KB.h \
           proto.h \
           fpsedit.h \
           netserver.h \
           newnetclient.h \
           netudpserver.h \
           netudpwidget.h
           
           
SOURCES += game.cpp \
           main.cpp \
           hwform.cpp \
           team.cpp \
           netclient.cpp \
           teamselect.cpp \
           teamselhelper.cpp \
           frameTeam.cpp \
           vertScrollArea.cpp \
           gameuiconfig.cpp \
           ui_hwform.cpp \
           gamecfgwidget.cpp \
           pages.cpp \
           SquareLabel.cpp \
           hedgehogerWidget.cpp \
           hwmap.cpp \
           mapContainer.cpp \
           tcpBase.cpp \
           about.cpp \
           proto.cpp \
           fpsedit.cpp \
           netserver.cpp \
           newnetclient.cpp \
           netudpserver.cpp \
           netudpwidget.cpp

TRANSLATIONS += translations/hedgewars_ru.ts

RESOURCES += hedgewars.qrc
