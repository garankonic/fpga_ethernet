#include "mainwindow.h"
#include "ui_mainwindow.h"


MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    ui->buttonGroup->setId(ui->command_0,0);
    ui->buttonGroup->setId(ui->command_1,1);
    ui->buttonGroup->setId(ui->command_2,2);
    ui->buttonGroup->setId(ui->command_last,10);
    connect(ui->buttonGroup, SIGNAL(buttonClicked(int)), this, SLOT(command_changed(int)));
    ui->command_0->setChecked(true);
    command_changed(0);

    socket = new QUdpSocket(this);
    socket->bind(QHostAddress::AnyIPv4, 1025);
    connect(socket,SIGNAL(readyRead()),this, SLOT(readDatagram()));
    connect(socket,SIGNAL(error(QAbstractSocket::SocketError)), this, SLOT(readError(QAbstractSocket::SocketError)));
    connect(socket,SIGNAL(stateChanged(QAbstractSocket::SocketState)), this, SLOT(readState(QAbstractSocket::SocketState)));
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::command_changed(int id)
{
    if(id == 0) {
        ui->counter_value->setEnabled(false);
        ui->other_command->setEnabled(false);
        ui->gbt_text->setEnabled(false);
    }
    else if (id == 1) {
        ui->counter_value->setEnabled(true);
        ui->other_command->setEnabled(false);
        ui->gbt_text->setEnabled(false);
    }
    else if (id == 2) {
        ui->counter_value->setEnabled(false);
        ui->other_command->setEnabled(false);
        ui->gbt_text->setEnabled(true);
    }
    else if (id == 10) {
        ui->counter_value->setEnabled(false);
        ui->other_command->setEnabled(true);
        ui->gbt_text->setEnabled(false);
    }
}

void MainWindow::readError(QAbstractSocket::SocketError error)
{
    qDebug()<< error;
}
void MainWindow::readState(QAbstractSocket::SocketState error)
{
    qDebug()<< error;
}


void MainWindow::readDatagram()
{
    QByteArray datagram;
    datagram.resize(socket->pendingDatagramSize());
    QHostAddress *address = new QHostAddress();
    QByteArray command_counter = QByteArray::fromHex(QString("01").toUtf8());
    QByteArray command_gbt = QByteArray::fromHex(QString("02").toUtf8());
    QByteArray command_undefined = QByteArray::fromHex(QString("ff").toUtf8());

    socket->readDatagram(datagram.data(), datagram.size(), address);
    QString converted_data("");

    if (datagram.mid(0,1) == command_counter) {
        bool ok;
        int number = datagram.mid(1).toHex().toInt(&ok,16);
        converted_data = QString("Increased number is: %1").arg(number);
    }
//    else if (datagram.mid(0,1) == command_gbt) {
//        for(int i=1; i< datagram.size();i++) converted_data.append(datagram.at(i));
//    }
    else if (datagram.mid(0,1) == command_undefined) converted_data = "Unknown Command";
    else for(int i=1; i< datagram.size();i++) converted_data.append(datagram.at(i));


    ui->response->setText(converted_data);
}

void MainWindow::sendDatagram()
{
    int command = ui->buttonGroup->checkedId();
    QString command_hex;

    switch (command) {
            case 0:
        {
                command_hex = "00";
                break;
        }
            case 1:
        {
                command_hex = "01";
                QString value;
                value.setNum(ui->counter_value->value(),16);
                int length = value.length();
                if(length<4) {
                    for(int i=0; i<(4-length);i++) value.insert(0,QLatin1String("0"));
                }
                command_hex += value;
                break;
        }
            case 2:
        {
                command_hex = "02";
                command_hex +=ui->gbt_text->text();
                break;
        }
            case 10:
        {
                command_hex = ui->other_command->text();
                break;
        }
    }
    QByteArray ba1 = QByteArray::fromHex(command_hex.toLatin1());
    socket->writeDatagram(ba1,QHostAddress("192.168.0.255"),1024);
}

void MainWindow::on_pushButton_clicked()
{
    sendDatagram();
}
