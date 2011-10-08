/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2011 Andrey Korotaev <unC0Rr@gmail.com>
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

#include "AbstractPage.h"

AbstractPage::AbstractPage(QWidget* parent)
{
    Q_UNUSED(parent);

    font14 = new QFont("MS Shell Dlg", 14);
}

void AbstractPage::initPage()
{
    QGridLayout * pageLayout = new QGridLayout(this);

    // stretch grid space for body and footer
    pageLayout->setColumnStretch(0,0);
    pageLayout->setColumnStretch(1,1);
    pageLayout->setRowStretch(0,1);
    pageLayout->setRowStretch(1,0);

    // add back/exit button
    btnBack = formattedButton(":/res/Exit.png", true);
    pageLayout->addWidget(btnBack, 1, 0, 1, 1, Qt::AlignLeft | Qt::AlignBottom);

    // add body layout as defined by the subclass
    pageLayout->addLayout(bodyLayoutDefinition(), 0, 0, 1, 2);

    // add footer layout
    QLayout * fld = footerLayoutDefinition();
    if (fld != NULL)
        pageLayout->addLayout(fld, 1, 1);

    // connect signals
    connect(btnBack, SIGNAL(clicked()), this, SIGNAL(goBack()));
    connectSignals();
}

QPushButton * AbstractPage::formattedButton(const QString & btname, bool hasIcon)
{
    QPushButton * btn = new QPushButton(this);

    if (hasIcon)
    {
        const QIcon& lp=QIcon(btname);
        QSize sz = lp.actualSize(QSize(65535, 65535));
        btn->setIcon(lp);
        btn->setFixedSize(sz);
        btn->setIconSize(sz);
        btn->setFlat(true);
        btn->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
    }
    else
    {
        btn->setFont(*font14);
        btn->setText(btname);
    }
    return btn;
}

QPushButton * AbstractPage::addButton(const QString & btname, QGridLayout* grid, int wy, int wx, bool hasIcon)
{
    QPushButton * btn = formattedButton(btname, hasIcon);
    grid->addWidget(btn, wy, wx);
    return btn;
}

QPushButton * AbstractPage::addButton(const QString & btname, QGridLayout* grid, int wy, int wx, int rowSpan, int columnSpan, bool hasIcon)
{
    QPushButton * btn = formattedButton(btname, hasIcon);
    grid->addWidget(btn, wy, wx, rowSpan, columnSpan);
    return btn;
}

QPushButton * AbstractPage::addButton(const QString & btname, QBoxLayout* box, int where, bool hasIcon)
{
    QPushButton * btn = formattedButton(btname, hasIcon);
    box->addWidget(btn, where);
    return btn;
}

void AbstractPage::setBackButtonVisible(bool visible)
{
    btnBack->setVisible(visible);
}