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

import Foundation
import AlfrescoContentServices

class UserProfile {
    static func persistUserProfile(person: Person, withAccountIdentifier identifier: String) {
        var profileName = person.firstName
        if let lastName = person.lastName {
            profileName = "\(profileName) \(lastName)"
        }
        if let displayName = person.displayName {
            profileName = displayName
        }

        let defaults = UserDefaults.standard
        defaults.set(profileName, forKey: "\(identifier)-\(kSaveDiplayProfileName)")
        defaults.set(person.email, forKey: "\(identifier)-\(kSaveEmailProfile)")
        defaults.synchronize()
    }

    static func removeUserProfile(withAccountIdentifier identifier: String) {
        UserDefaults.standard.removeObject(forKey: "\(identifier)-\(kSaveDiplayProfileName)")
        UserDefaults.standard.removeObject(forKey: "\(identifier)-\(kSaveEmailProfile)")
    }

    static func getProfileName(withAccountIdentifier identifier: String) -> String {
        return  UserDefaults.standard.object(forKey: "\(identifier)-\(kSaveDiplayProfileName)") as? String ?? ""
    }

    static func getEmail(withAccountIdentifier identifier: String) -> String {
        return  UserDefaults.standard.object(forKey: "\(identifier)-\(kSaveEmailProfile)") as? String ?? ""
    }
}
