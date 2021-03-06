/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2007 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2004-2013 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

#ifndef _HWMAP_CONTAINER_INCLUDED
#define _HWMAP_CONTAINER_INCLUDED

#include <QWidget>
#include <QGridLayout>
#include <QVBoxLayout>
#include <QComboBox>
#include <QLabel>
#include <QByteArray>
#include <QLineEdit>

#include "DataManager.h"

#include "hwmap.h"
#include "drawmapscene.h"
#include "MapModel.h"

class QPushButton;
class IconedGroupBox;
class QListView;
class SeparatorPainter;
class QListWidget;

class MapFileErrorException
{
};

class HWMapContainer : public QWidget
{
        Q_OBJECT

        Q_PROPERTY(bool master READ isMaster WRITE setMaster)

    public:
        HWMapContainer(QWidget * parent=0);
        QString getCurrentSeed() const;
        QString getCurrentMap() const;
        QString getCurrentTheme() const;
        int     getCurrentHHLimit() const;
        QString getCurrentScheme() const;
        QString getCurrentWeapons() const;
        quint32 getTemplateFilter() const;
        MapGenerator get_mapgen(void) const;
        int getMazeSize(void) const;
        bool getCurrentIsMission() const;
        QByteArray getDrawnMapData();
        DrawMapScene * getDrawMapScene();
        void mapDrawingFinished();
        QLineEdit* seedEdit;
        bool isMaster();

    public slots:
        void askForGeneratedPreview();
        void setSeed(const QString & seed);
        void setMap(const QString & map);
        void setTheme(const QString & theme);
        void setTemplateFilter(int);
        void setMapgen(MapGenerator m);
        void setMazeSize(int size);
        void setDrawnMapData(const QByteArray & ar);
        void setAllMapParameters(const QString & map, MapGenerator m, int mazesize, const QString & seed, int tmpl);
        void updateModelViews();
        void onPreviewMapDestroyed(QObject * map);
        void setMaster(bool master);

    signals:
        void seedChanged(const QString & seed);
        void mapChanged(const QString & map);
        void themeChanged(const QString & theme);
        void newTemplateFilter(int filter);
        void mapgenChanged(MapGenerator m);
        void mazeSizeChanged(int s);
        void drawMapRequested();
        void drawnMapChanged(const QByteArray & data);

    private slots:
        void setImage(const QImage newImage);
        void setHHLimit(int hhLimit);
        void setRandomSeed();
        void setRandomTheme();
        void setRandomMap();
        void addInfoToPreview(QPixmap image);
        void setNewSeed(const QString & newSeed);
        void mapTypeChanged(int);
        void showThemePrompt();
        void updateTheme(const QModelIndex & current);
        void staticMapChanged(const QModelIndex & map, const QModelIndex & old = QModelIndex());
        void missionMapChanged(const QModelIndex & map, const QModelIndex & old = QModelIndex());
        void loadDrawing();
        void showSeedPrompt();
        void previewClicked();

    protected:
        virtual void resizeEvent ( QResizeEvent * event );
        virtual void showEvent ( QShowEvent * event );

    private:
        QVBoxLayout mainLayout;
        QPushButton* mapPreview;
        QComboBox* chooseMap;
        MapModel * m_staticMapModel;
        MapModel * m_missionMapModel;
        IconedGroupBox* gbThemes;
        QListView* lvThemes;
        ThemeModel * m_themeModel;
        HWMap* pMap;
        QString m_seed;
        QPushButton* seedSet;
        QLabel* seedLabel;
        int hhLimit;
        int templateFilter;
        QPixmap hhSmall;
        QLabel* lblFilter;
        QComboBox* cbTemplateFilter;
        QLabel *maze_size_label;
        QComboBox *cbMazeSize;
        MapGenerator mapgen;
        DrawMapScene drawMapScene;
        QComboBox * cType;
        QListView * staticMapList;
        QListView * missionMapList;
        QListWidget * generationStyles;
        QListWidget * mazeStyles;
        QLabel * lblMapList;
        QLabel * lblDesc;
        QPushButton * btnTheme;
        QPushButton * btnLoadMap;
        QPushButton * btnEditMap;
        QPushButton * btnRandomize;
        QString selectedTheme;
        QPushButton * btnSeed;
        bool m_master;
        QList<QWidget *> m_childWidgets;
        bool m_previewEnabled;
        bool m_missionsViewSetup;
        bool m_staticViewSetup;

        void intSetSeed(const QString & seed);
        void intSetMap(const QString & map);
        void intSetMapgen(MapGenerator m);
        void intSetTemplateFilter(int);
        void intSetMazeSize(int size);
        void intSetIconlessTheme(const QString & name);
        void mapChanged(const QModelIndex & map, int type, const QModelIndex & old = QModelIndex());
        void setMapInfo(MapModel::MapInfo mapInfo);
        void changeMapType(MapModel::MapType type, const QModelIndex & newMap = QModelIndex());
        void updatePreview();
        void updateThemeButtonSize();
        void setupMissionMapsView();
        void setupStaticMapsView();

        MapModel::MapInfo m_mapInfo;
        int m_themeID;
        QString m_theme;
        QString m_curMap;

        QLinearGradient linearGrad; ///< for preview background
        QSize m_previewSize;
};

#endif // _HWMAP_CONTAINER_INCLUDED
