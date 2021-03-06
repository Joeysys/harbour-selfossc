import QtQuick 2.2
import Sailfish.Silica 1.0

import '../js/selfoss.js' as Selfoss

ListItem {
    id: listItem

    property bool _showThumb: false
    property var item

    width: parent.width
    contentHeight: itemContent.height + Theme.paddingMedium * 3

    menu: ContextMenu {
        MenuItem {
            text: starred === "0" ? qsTr("Star") : qsTr("Unstar")
            onClicked: toggleStarred(starred === "0" ? 'starr' : 'unstarr')
        }
        MenuItem  {
            text: unread === "0" ? qsTr("Mark as unread") : qsTr("Mark above as read")
            onClicked: {
                if (unread === '0') {
                    toggleRead('unread');
                } else {
                    markAboveRead();
                }
            }
        }
        MenuItem {
            text: qsTr("Open in Browser")
            onClicked: {
                Qt.openUrlExternally(link);
                if (item.unread === '1')
                    toggleRead('read');
            }
        }
    }

    Item {
        id: itemContent
        width: parent.width - Theme.paddingMedium * 2
        height: childrenRect.height
        anchors.top: parent.top
        anchors.topMargin: Theme.paddingMedium * 1.5
        anchors.horizontalCenter: parent.horizontalCenter

        Image {
            id: itemIcon
            height: Theme.iconSizeSmall
            width: height
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingSmall
            source: icon ? (Selfoss.site + '/favicons/' + icon) : "image://theme/icon-cover-people"
        }
        Image {
            id: thumbIcon
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingSmall
            anchors.right: parent.right
            height: Theme.iconSizeSmall
            width: height
            source: "image://theme/icon-m-image"
            visible: thumbnail && !_showThumb
        }
        Label {
            id: authorLabel
            anchors.left: itemIcon.right
            anchors.leftMargin: Theme.paddingMedium
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingSmall / 2
            width: parent.width - itemIcon.width - thumbIcon.width - Theme.paddingMedium
            height: Theme.fontSizeSmall
            text: author ? author : qsTr("Unknown")
            color: {
                switch (unread + starred) {
                    case "00":
                        return Theme.secondaryColor;
                    case "01":
                        return Theme.secondaryHighlightColor;
                    case "10":
                        return Theme.primaryColor;
                    case "11":
                        return Theme.highlightColor;
                }
            }
            font.bold: true
            font.pixelSize: Theme.fontSizeSmall
            elide: TruncationMode.Elide
        }
        Label {
            id: titleLabel
            anchors.top: authorLabel.bottom
            anchors.left: parent.left
            anchors.topMargin: Theme.paddingMedium
            width: parent.width
            text: title
            wrapMode: Text.WordWrap
            textFormat: Text.StyledText
            font.pixelSize: Theme.fontSizeSmall
            color: authorLabel.color
            linkColor: starred === "0" ? Theme.secondaryColor : Theme.secondaryHighlightColor
            onLinkActivated: {
                // TODO confirm dialog
                Qt.openUrlExternally(link);
            }
            Component.onCompleted: {
                if (!title) titleLabel.height = 0;
            }
        }
        Label {
            id: sourceLabel
            anchors.top: titleLabel.bottom
            anchors.left: parent.left
            height: Theme.fontSizeSmall
            text: qsTr("via ") + sourcetitle
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
        }
        Label {
            id: timeLabel
            anchors.top: titleLabel.bottom
            anchors.right: parent.right
            height: Theme.fontSizeSmall
            text: Selfoss.changeZone(datetime, true)
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
        }

        Loader {
            id: thumbLoader
            anchors {
                top: timeLabel.bottom
                topMargin: Theme.paddingMedium
            }
            height: childrenRect.height
            width: parent.width
        }

    }

    onClicked: {
        currentItem = JSON.parse(JSON.stringify(item));
        if (!item.content && !thumbnail) {
            pageStack.push('WebViewPage.qml', {'item': currentItem})
        } else {
            pageStack.push('DetailsPage.qml', {'item': currentItem, 'currentIdx': index})
        }
    }

    //Component.onCompleted: setThumbSource()

    on_ShowThumbChanged: setThumbSource()

    function setThumbSource() {
        if (thumbnail && _showThumb) {
            thumbLoader.setSource('ThumbnailComponent.qml', {
                'thumbnail': thumbnail,
                'site': Selfoss.site
            });
        } else {
            thumbLoader.source = '';
        }
    }

    function toggleStarred(stat) {
        Selfoss.toggleStat(stat, item.id, function(resp) {
            if (resp.success) {
                item.starred = (starred === "0" ? "1" : "0");
            } else {
                console.warn('Toggle starred failed!', stat, item.id);
            }
        });
    }

    function toggleRead(stat) {
        Selfoss.toggleStat(stat, item.id, function(resp) {
            if (resp.success) {
                if (stat === 'read') {
                    item.unread = '0';
                    if (statsUnread > 0)
                        statsUnread -= 1;
                } else {
                    item.unread = '1';
                    statsUnread += 1;
                }
            } else {
                console.warn('Toggle unread failed!', stat, item.id);
            }
        });
    }

    function markAboveRead() {
        var aboveIds = [];
        var thisIdx = -1;
        for (var i=0; i<currentIds[type].length; i++) {
            if (currentIds[type][i] == item.id) {
                thisIdx = i;
                break;
            }
        }
        if (thisIdx > -1) {
            aboveIds = currentIds[type].slice(0, thisIdx + 1);
        }
        requestLock = true;
        Selfoss.markAllRead(aboveIds, function(resp) {
            requestLock = false;
            if (resp && resp.success) {
                reloadItems();
            } else {
                console.warn('Mark above as read failed!');
            }
        });
    }
}
