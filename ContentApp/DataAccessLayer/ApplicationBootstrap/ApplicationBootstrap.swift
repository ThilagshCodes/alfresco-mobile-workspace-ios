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
import UIKit

class ApplicationBootstrap {
    private static var sharedApplicationBootstrap: ApplicationBootstrap = {
        let applicationBootstrap = ApplicationBootstrap()
        return applicationBootstrap
    }()

    let serviceRepository: ServiceRepository

    private init() {
        self.serviceRepository = ServiceRepository()
        self.serviceRepository.register(service: themingService())
        self.serviceRepository.register(service: authenticationService())
        self.serviceRepository.register(service: accountService())
        self.serviceRepository.register(service: applicationRouter())
        self.serviceRepository.register(service: eventBusService())
    }

    class func shared() -> ApplicationBootstrap {
        return sharedApplicationBootstrap
    }

    private func themingService() -> ThemingService {
        let themingService = MaterialDesignThemingService()
        themingService.register(theme: DefaultTheme())
        themingService.register(theme: DarkTheme())
        themingService.saveTheme(mode: themingService.getThemeMode())
        return themingService
    }

    private func authenticationService() -> AuthenticationService {
        return AuthenticationService(with: AuthenticationParameters.parameters())
    }

    private func accountService() -> AccountService {
        return AccountService()
    }

    private func applicationRouter() -> Router {
        return Router()
    }

    private func eventBusService() -> EventBusService {
        return EventBusService()
    }
}
