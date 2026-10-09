/* Apresentação exibida durante a instalação do WinRise OS */
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    function onActivate() { }
    function onLeave() { }

    Timer {
        interval: 12000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    component WinRiseSlide: Slide {
        id: s
        property string titulo: ""
        property string texto: ""
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1f6fd1" }
                GradientStop { position: 1.0; color: "#0b2550" }
            }
        }
        Image {
            id: logo
            source: "winrise-logo.png"
            width: 96; height: 96
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.12
        }
        Text {
            id: t
            text: s.titulo
            color: "white"
            font.pixelSize: 30
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo.bottom
            anchors.topMargin: 24
        }
        Text {
            text: s.texto
            color: "#dcecff"
            font.pixelSize: 17
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            width: parent.width * 0.75
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: t.bottom
            anchors.topMargin: 16
        }
    }

    WinRiseSlide {
        titulo: "Bem-vindo ao WinRise OS"
        texto: "Seu novo sistema está sendo instalado. Isso leva só alguns minutos — enquanto isso, conheça um pouco do WinRise."
    }
    WinRiseSlide {
        titulo: "Visual familiar"
        texto: "Barra de tarefas, menu Iniciar, Este Computador, Lixeira e os atalhos que você já conhece: Win, Win+E, Win+D, Alt+Tab e Ctrl+Shift+Esc."
    }
    WinRiseSlide {
        titulo: "Leve e rápido"
        texto: "Base Debian estável e KDE Plasma configurado no essencial. Mais memória e processador sobrando para o que importa: você."
    }
    WinRiseSlide {
        titulo: "Sem bloatware"
        texto: "Nada de notícias, clima, anúncios, telemetria ou apps empurrados. Só o que você precisa: navegador, arquivos, editor, terminal e loja de apps."
    }
    WinRiseSlide {
        titulo: "Instale o que quiser"
        texto: "Abra a Discover para instalar programas com um clique, ou dê duplo clique em arquivos .deb e AppImage."
    }
}
