//
// Copyright (C) 2005-2022 Alfresco Software Limited.
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

class PriorityTableCellViewModel: RowViewModel {
    
    var title: String?
    var priority: String?
    var priorityTextColor: UIColor
    var priorityBackgroundColor: UIColor
    var isEditMode = false
    var isHideEditImage: Bool {
        return !isEditMode
    }
    var didSelectEditPriority: (() -> Void)?
    
    func cellIdentifier() -> String {
        return "PriorityTableViewCell"
    }
    
    init(title: String?,
         priority: String?,
         priorityTextColor: UIColor,
         priorityBackgroundColor: UIColor,
         isEditMode: Bool) {
        self.title = title
        self.priority = priority
        self.priorityTextColor = priorityTextColor
        self.priorityBackgroundColor = priorityBackgroundColor
        self.isEditMode = isEditMode
    }
}
