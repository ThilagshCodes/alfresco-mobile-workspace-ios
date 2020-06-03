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

class BasicAuthenticationProvider: AuthenticationProviderProtocol, Encodable {
    let credential: BasicAuthCredential

    required init(with credential: BasicAuthCredential) {
        self.credential = credential
    }

    func authorizationHeader() -> String {
        guard let loginData = String(format: "%@:%@", credential.username, credential.password).data(using: String.Encoding.utf8) else {
            return ""
        }
        let base64LoginString = loginData.base64EncodedString()
        return String("Basic \(base64LoginString)")
    }

    func areCredentialsValid() -> Bool {
        true
    }
}
