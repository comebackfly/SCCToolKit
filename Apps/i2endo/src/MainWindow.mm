/*=========================================================================
 
 Program:   Small Computings for Clinicals Project
 Module:    $HeadURL: $
 Date:      $Date: $
 Version:   $Revision: $
 URL:       http://scc.pj.aist.go.jp
 
 (c) 2013- Kiyoyuki Chinzei, Ph.D., AIST Japan, All rights reserved.
 
 Acknowledgement: This work is/was supported by many research fundings.
 See Acknowledgement.txt
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.  See License.txt for license terms.
 
 =========================================================================*/
/**
 * @file
 * Main window class implementations.
 */

#include <QSettings>
#include <QtDebug>

#include <opencv2/core/core.hpp>
#include "MainWindow.h"
#include "Settings.h"
#include "ChromaWindow.h"

#define BUFLEN 1024

MainWindow::MainWindow(QWidget* parent)
    : QDialog (parent)
    , mChromaWindow(nullptr)
{
    // Set up the UI generated by Designer.
    setupUi(this);
    viewL->paintMode = Cap::kPaintModeScaleAspectFill;
    viewL->setCircleMaskVisibility(true);
    viewL->clear();
    
    mChromaWindow = new ChromaWindow(this);
	setConnections();
	//emit setApplicationStatus(mStatus);
}


MainWindow::~MainWindow()
{
    delete mChromaWindow;
}

void MainWindow::resizeUi_and_showWindow(int screenWidth)
{
    if (screenWidth < 1024) {
        viewL->setGeometry(QRect(0, 30, 480, 480));
        label_msg->setGeometry(QRect(0, 510, 850, 31));
        btn_setChroma->setGeometry(QRect(848, 512, 114, 32));
        label_camname->setGeometry(QRect(0, 12, 480, 16));
        label_logo->setGeometry(QRect(900, 4, 55, 22));
        this->resize(960, 540);
        if (screenWidth == 960) {
            this->showFullScreen();
        } else {
            this->show();
        }
    } else if (screenWidth < 1920) {
    //} else {
        viewL->setGeometry(QRect(192, 36, 640, 640));
        label_logo->setGeometry(QRect(790, 10, 220, 90));
        label_msg->setGeometry(QRect(20, 733, 981, 31));
        btn_setChroma->setGeometry(QRect(900, 730, 114, 32));
        label_camname->setGeometry(QRect(16, 704, 988, 16));
        label_scc->setGeometry(QRect(10, 10, 140, 90));
        this->resize(1024, 768);
        if (screenWidth == 1024) {
            this->showFullScreen();
        } else {
            this->show();
        }
    //}
    } else {
        viewL->setGeometry(QRect(448, 28, 1024, 1024));
        label_scc->setGeometry(QRect(10, 10, 140, 90));
        label_logo->setGeometry(QRect(1690, 10, 220, 90));
        
        btn_setChroma->setGeometry(QRect(960, 1790, 114, 32));
        label_msg->setGeometry(QRect(20, 1056, 900, 20));
        label_camname->setGeometry(QRect(20, 1056, 900, 20));
        this->resize(1920, 1080);
        if (screenWidth == 1920) {
            this->showFullScreen();
        } else {
            this->show();
        }
    }
}

int MainWindow::getViewH(void)
{
    QRect r = viewL->geometry();
    QSize s = r.size();
    return s.height();
}

int MainWindow::getViewW(void)
{
    QRect r = viewL->geometry();
    QSize s = r.size();
    return s.width();
}

// PUBLIC SLOTS ////////////////////////////////////////////////////////
//
void MainWindow::onSetApplicationStatus( ApplicationStatus& status )
{
	mStatus = status;
}

void MainWindow::on_btn_setChroma_clicked()
{
    viewL->paintMode = Cap::kPaintModeScaleAspectFit;
    viewL->setCircleMaskVisibility(false);
    viewL->clear();
    
    /*
     Start ChromaWindow UI
     */
    mChromaWindow->onUpdateChroma(mStatus.hueMin, mStatus.hueMax, mStatus.valMin, mStatus.valMax);
    mChromaWindow->show();
    mStatusBuf = mStatus;
    mStatus.adjustChromaMode = true;
    emit setApplicationStatus(mStatus);
}

void MainWindow::onMsgLabelUpdate(const QString* str)
{
    QString s = (str == nullptr)? QString("") : *str;
    label_msg->setText(s);
}

void MainWindow::onViewLLabelUpdate(const QString* str)
{
    QString s1 = QString(tr("Camera 2 : "));
    if (str) s1 += *str;
    label_camname->setText(s1);
}

//
// "Quit"
//
void MainWindow::reject()
{
	emit reqQuit();
}

void MainWindow::onUpdateImages(CIImage *img1)
{
    viewL->updateImage(img1);
}

void MainWindow::onUpdateChroma(float hueMin, float hueMax, float valMin, float valMax)
{
    mStatus.hueMin = hueMin;
    mStatus.hueMax = hueMax;
    mStatus.valMin = valMin;
    mStatus.valMax = valMax;
    emit setApplicationStatus(mStatus);    
}

void MainWindow::onAcceptChroma(void)
{
    viewL->paintMode = Cap::kPaintModeScaleAspectFill;
    viewL->clear();
    viewL->setCircleMaskVisibility(true);

    mChromaWindow->hide();
    mStatus.adjustChromaMode = false;
    emit setApplicationStatus(mStatus);
}

void MainWindow::onRevertChroma(void)
{
    viewL->paintMode = Cap::kPaintModeScaleAspectFill;
    viewL->clear();
    viewL->setCircleMaskVisibility(true);

    mChromaWindow->hide();
    mStatus.adjustChromaMode = false;
    mStatus = mStatusBuf;
    emit setApplicationStatus(mStatus);
}

void MainWindow::onRejectChromaWindow(void)
{
    viewL->paintMode = Cap::kPaintModeScaleAspectFill;
    viewL->clear();
    viewL->setCircleMaskVisibility(true);

    mStatus.adjustChromaMode = false;
    mStatus = mStatusBuf;
    emit setApplicationStatus(mStatus);
}

void MainWindow::onEraseViewL(void)
{
    viewL->update(viewL->rect());
    emit reqEraseChromaWindow();
}

// PRIVATE METHODS /////////////////////////////////////////////////////
//
// Set signal-slot connections.
//
void MainWindow::setConnections(void)
{
	connect(this,       SIGNAL(reqUpdateChroma(float, float, float, float)),
			mChromaWindow, SLOT(onUpdateChroma(float, float, float, float)));
    connect(this,       SIGNAL(reqUpdateChromaImage(CIImage *)),
			mChromaWindow, SLOT(onUpdateChromaImage(CIImage *)));

	connect(mChromaWindow, SIGNAL(reqUpdateChroma(float, float, float, float)),
			this,             SLOT(onUpdateChroma(float, float, float, float)));
	connect(mChromaWindow, SIGNAL(reqAcceptChroma(void)),
			this,             SLOT(onAcceptChroma(void)));
	connect(mChromaWindow, SIGNAL(reqRevertChroma(void)),
			this,             SLOT(onRevertChroma(void)));
	connect(mChromaWindow, SIGNAL(reqRejectChromaWindow(void)),
			this,             SLOT(onRejectChromaWindow(void)));

}