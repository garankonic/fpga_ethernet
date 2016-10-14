#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include "QtNetwork/qudpsocket.h"

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = 0);
    QUdpSocket *socket;
    void sendDatagram();
    ~MainWindow();

private slots:
    void command_changed(int id);
    void readDatagram();
    void readError(QAbstractSocket::SocketError error);
    void readState(QAbstractSocket::SocketState error);

    void on_pushButton_clicked();

private:
    Ui::MainWindow *ui;
};

#endif // MAINWINDOW_H
