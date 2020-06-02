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
import AlfrescoAuth

public typealias AvailableAuthTypeCallback<AuthType> = (Result<AuthType, APIError>) -> Void

class LoginService: Service {
    private (set) var authParameters: AuthSettingsParameters
    private (set) lazy var alfrescoAuth: AlfrescoAuth = {
        let authConfig = authConfiguration()
        return AlfrescoAuth.init(configuration: authConfig)
    }()

    var session: AlfrescoAuthSession?

    init(with authenticationParameters: AuthSettingsParameters) {
        self.authParameters = authenticationParameters
    }

    func update(authenticationParameters: AuthSettingsParameters) {
        self.authParameters = authenticationParameters
    }

    func availableAuthType(handler: @escaping AvailableAuthTypeCallback<AvailableAuthType>) {
        let authConfig = authConfiguration()
        alfrescoAuth.update(configuration: authConfig)
        alfrescoAuth.availableAuthType(handler: handler)
    }

    func aimsAuthentication(on viewController: UIViewController, delegate: AlfrescoAuthDelegate) {
        let authConfig = AuthConfiguration(baseUrl: authParameters.fullContentURL,
                                           clientID: authParameters.clientID,
                                           realm: authParameters.realm,
                                           redirectURI: authParameters.redirectURI.encoding())
        alfrescoAuth.update(configuration: authConfig)
        alfrescoAuth.pkceAuth(onViewController: viewController, delegate: delegate)
    }

    func basicAuthentication(username: String, password: String, handler: @escaping ((Result<Bool, NSError>) -> Void)) {
        guard let loginData = String(format: "%@:%@", username, password).data(using: String.Encoding.utf8),
            let url = URL(string: authParameters.fullHostnameBasicAuthGetProfileURL) else {
            handler(.failure(NSError()))
            return
        }
        let base64LoginString = loginData.base64EncodedString()
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        let session = URLSession(configuration: .default)

        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                handler(.failure(error as NSError))
                return
            }
            guard let data = data, let response = response as? HTTPURLResponse else {
                handler(.failure(NSError()))
                return
            }
            guard (StatusCodes.Code200OK.code ... StatusCodes.Code209IMUsed.code) ~= response.statusCode else {
                do {
                    if let errorDictionary = try data.convertToDictionary() {
                        handler(.failure(NSError(domain: "basicAuth", code: 404, userInfo: errorDictionary)))
                    } else {
                        handler(.failure(NSError()))
                    }
                } catch {
                    handler(.failure(error as NSError))
                }
                return
            }
            handler(.success(true))
        }
        task.resume()
    }

    func saveAuthParameters() {
        authParameters.save()
    }

    // MARK: - Private

    private func authConfiguration() -> AuthConfiguration {
        let authConfig = AuthConfiguration(baseUrl: authParameters.fullHostnameURL,
                                           clientID: authParameters.clientID,
                                           realm: authParameters.realm,
                                           redirectURI: authParameters.redirectURI.encoding())
        return authConfig
    }

}

extension Data {
    func convertToDictionary() throws -> [String: Any]? {
        return try JSONSerialization.jsonObject(with: self, options: []) as? [String: Any]
    }
}
