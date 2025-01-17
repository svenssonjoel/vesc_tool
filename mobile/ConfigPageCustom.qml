/*
    Copyright 2022 Benjamin Vedder	benjamin@vedder.se

    This file is part of VESC Tool.

    VESC Tool is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    VESC Tool is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    */

import QtQuick 2.7
import QtQuick.Controls 2.10
import QtQuick.Layouts 1.3

import Vedder.vesc.vescinterface 1.0
import Vedder.vesc.commands 1.0
import Vedder.vesc.configparams 1.0
import Vedder.vesc.utility 1.0

Item {
    id: appPageItem
    property Commands mCommands: VescIf.commands()
    property bool isHorizontal: width > height
    property int confInd: 0

    ParamEditors {
        id: editors
    }

    onIsHorizontalChanged: {
        updateEditors()
    }

    function reloadConfig() {
        if (VescIf.customConfig(confInd) === null) {
            return
        }

        tabBox.model = VescIf.customConfig(confInd).getParamSubgroups("General")
        updateEditors()
    }

    function addSeparator(text) {
        var e = editors.createSeparator(scrollCol, text)
        e.Layout.columnSpan = isHorizontal ? 2 : 1
    }

    function destroyEditors() {
        for(var i = scrollCol.children.length;i > 0;i--) {
            scrollCol.children[i - 1].destroy(1) // Only works with delay on android, seems to be a bug
        }
    }

    function createEditorCustom(param) {
        var e = editors.createEditorCustom(scrollCol, param, confInd)
        e.Layout.preferredWidth = 500
        e.Layout.fillsWidth = true
    }

    function updateEditors() {
        if (tabBox.currentText == "") {
            return
        }

        destroyEditors()

        if (VescIf.customConfig(confInd) === null) {
            return
        }

        var params = VescIf.customConfig(confInd).getParamsFromSubgroup("General", tabBox.currentText)

        for (var i = 0;i < params.length;i++) {
            if (params[i].startsWith("::sep::")) {
                addSeparator(params[i].substr(7))
            } else {
                createEditorCustom(params[i])
            }
        }
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 0

        ComboBox {
            id: tabBox
            Layout.fillWidth: true

            onCurrentTextChanged: {
                updateEditors()
            }
        }

        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: column.width
            clip: true

            GridLayout {
                id: scrollCol
                anchors.fill: parent
                columns: isHorizontal ? 2 : 1
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Button {
                Layout.preferredWidth: 100
                Layout.fillWidth: true
                text: "Write"

                onClicked: {
                    if (VescIf.customConfig(confInd) === null) {
                        return
                    }

                    mCommands.customConfigSet(confInd, VescIf.customConfig(confInd))
                }
            }

            Button {
                Layout.preferredWidth: 100
                Layout.fillWidth: true
                text: "Read"

                onClicked: {
                    mCommands.customConfigGet(confInd, false)
                }
            }

            Button {
                Layout.preferredWidth: 100
                Layout.fillWidth: true
                text: "Read Default"

                onClicked: {
                    mCommands.customConfigGet(confInd, true)
                }
            }
        }
    }

    Connections {
        target: VescIf

        onCustomConfigLoadDone: {
            updateEditors()
        }
    }
}
