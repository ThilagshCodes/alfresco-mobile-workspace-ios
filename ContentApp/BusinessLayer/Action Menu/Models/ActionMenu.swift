//
// Copyright (C) 2005-2020 Alfresco Software Limited.
//
// This file is part of the Alfresco Content Mobile iOS App.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

class ActionMenu {
    var title: String
    var type: ActionMenuType {
        didSet {
            self.icon = UIImage(named: self.type.rawValue) ?? UIImage()
        }
    }
    var icon: UIImage
    var analyticEventName: String
    
    init(title: String, type: ActionMenuType, icon: UIImage? = nil) {
        self.title = title
        self.type = type
        if let icon = icon {
            self.icon = icon
        } else {
            self.icon = UIImage(named: self.type.rawValue) ?? UIImage()
        }
        analyticEventName = "\(type)"
    }
    
}

enum ActionMenuType: String {

    var isGenericActions: Bool {
        return [.more].contains(self)
    }

    var isFavoriteActions: Bool {
        return [.addFavorite, .removeFavorite].contains(self)
    }

    var isMoveActions: Bool {
        return [.moveTrash, .restore, .permanentlyDelete, .moveToFolder].contains(self)
    }

    var isDownloadActions: Bool {
        return [.download, .markOffline, .removeOffline].contains(self)
    }

    var isCreateActions: Bool {
        return [.createMSWord, .createMSExcel, .createMSPowerPoint,
                .createFolder, .renameNode,
                .createMedia, .uploadMedia, .uploadFiles].contains(self)
    }

    var isMoreAction: Bool {
        return [.more].contains(self)
    }

    // MARK: - Generic
    case placeholder = "ic-placeholder"
    case node = "ic-node"
    case more = "ic-action-more"

    // MARK: - Nodes
    case addFavorite = "ic-action-outline-favorite"
    case removeFavorite = "ic-action-fill-favorite"

    case moveTrash = "ic-action-delete"
    case restore = "ic-restore"
    case permanentlyDelete = "ic-action-delete-forever"
    case moveToFolder = "ic-action-mov-to-folder"

    case download = "ic-action-download"
    case markOffline = "ic-action-outline-offline"
    case removeOffline = "ic-action-fill-offline"

    // MARK: - Create
    case createFolder = "ic-action-create-folder"
    case createMSExcel = "ic-ms_spreadsheet"
    case createMSWord = "ic-ms_document"
    case createMSPowerPoint = "ic-ms_presentation"
    case createMedia = "ic-action-capture-media"
    case uploadMedia = "ic-action-upload-media-files"
    case uploadFiles = "ic-action-upload-files"
    case renameNode = "ic-action-rename"
}
